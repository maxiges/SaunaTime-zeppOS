import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../models/measurement_sample.dart';
import '../models/sauna_phase.dart';
import '../models/sauna_session.dart';
import '../models/session_source.dart';

/// The same watch payload format is accepted over local HTTP and cloud sync.
class WatchSessionParser {
  static SaunaSession parse(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? const Uuid().v4();

    // Time in the API is a Unix timestamp (seconds or milliseconds);
    // we also accept ISO-8601 for backward compatibility.
    final startTime =
        parseTimestamp(json['startTime'] ?? json['date']) ?? DateTime.now();
    final endTime = parseTimestamp(json['endTime']);

    // Duration with second accuracy.
    final int? explicitDurationSeconds = _toInt(json['durationSeconds']);
    final num? durationMinutesRaw =
        _toDouble(json['durationMinutes']) ?? _toDouble(json['duration']);

    int durationSeconds;
    if (explicitDurationSeconds != null && explicitDurationSeconds > 0) {
      durationSeconds = explicitDurationSeconds;
    } else if (endTime != null) {
      durationSeconds = endTime.difference(startTime).inSeconds;
    } else if (durationMinutesRaw != null && durationMinutesRaw > 0) {
      durationSeconds = (durationMinutesRaw * 60).round();
    } else {
      durationSeconds = 15 * 60;
    }
    if (durationSeconds <= 0) {
      durationSeconds = 60;
    }

    final int durationMinutes = (durationSeconds / 60)
        .round()
        .clamp(1, 1 << 31)
        .toInt();

    final temperature =
        _toDouble(json['temperature']) ?? _toDouble(json['temp']);

    final averageHeartRate =
        _toInt(json['averageHeartRate']) ??
        _toInt(json['avgHr']) ??
        _toInt(json['avg_heart_rate']);

    final maxHeartRate =
        _toInt(json['maxHeartRate']) ??
        _toInt(json['maxHr']) ??
        _toInt(json['max_heart_rate']);

    final notes = json['notes'] as String? ?? json['comment'] as String?;

    // Sauna phases (from 1 to 3): heating, cooling, resting.
    final parsedPhases = _parsePhasesFromPayload(json);
    final effectiveEndTime =
        endTime ?? startTime.add(Duration(seconds: durationSeconds));

    final Map<SaunaPhase, int> phaseDurations = {};
    for (int i = 0; i < parsedPhases.phases.length; i++) {
      phaseDurations[parsedPhases.phases[i]] = parsedPhases.durationsMinutes[i];
    }

    // Parse samples
    final List<MeasurementSample> heartRateSamples = [];
    if (json['heartRateSamples'] is List) {
      for (final item in json['heartRateSamples'] as List) {
        if (item is Map<String, dynamic>) {
          heartRateSamples.add(MeasurementSample.fromJson(item));
        }
      }
    } else if (json['heart_rate_samples'] is List) {
      for (final item in json['heart_rate_samples'] as List) {
        if (item is Map<String, dynamic>) {
          heartRateSamples.add(MeasurementSample.fromJson(item));
        }
      }
    }

    final List<MeasurementSample> temperatureSamples = [];
    if (json['temperatureSamples'] is List) {
      for (final item in json['temperatureSamples'] as List) {
        if (item is Map<String, dynamic>) {
          temperatureSamples.add(MeasurementSample.fromJson(item));
        }
      }
    }

    final heartRateSamplesWithPhases = parsedPhases.phases.isEmpty
        ? heartRateSamples
        : _tagSamplesWithPhases(
            heartRateSamples,
            parsedPhases.phases,
            parsedPhases.durationsMinutes,
            startTime,
            effectiveEndTime,
          );
    final temperatureSamplesWithPhases = parsedPhases.phases.isEmpty
        ? temperatureSamples
        : _tagSamplesWithPhases(
            temperatureSamples,
            parsedPhases.phases,
            parsedPhases.durationsMinutes,
            startTime,
            effectiveEndTime,
          );

    return SaunaSession(
      id: id,
      startTime: startTime,
      endTime: effectiveEndTime,
      durationMinutes: durationMinutes,
      source: SessionSource.watchHttp,
      temperature: temperature,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      notes: notes,
      heartRateSamples: _defaultPhaseForSamples(heartRateSamplesWithPhases),
      temperatureSamples: _defaultPhaseForSamples(temperatureSamplesWithPhases),
      phases: parsedPhases.phases,
      phaseDurations: phaseDurations,
    );
  }

  /// No phase specified on the sample means phase 1 (heating).
  static List<MeasurementSample> _defaultPhaseForSamples(
    List<MeasurementSample> samples,
  ) {
    return [
      for (final sample in samples)
        sample.phase != null
            ? sample
            : MeasurementSample(
                timestamp: sample.timestamp,
                value: sample.value,
                phase: SaunaPhase.heating,
              ),
    ];
  }

  static _ParsedPhases _parsePhasesFromPayload(Map<String, dynamic> json) {
    final phases = <SaunaPhase>[];
    final durations = <int>[];

    final raw = json['phases'] ?? json['stages'] ?? json['etapy'];
    if (raw is List) {
      for (final item in raw) {
        SaunaPhase? phase;
        var durationMinutes = 0;
        if (item is num) {
          phase = SaunaPhase.fromCode(item.toInt());
        } else if (item is String) {
          phase = SaunaPhase.fromJson(item);
        } else if (item is Map) {
          phase = SaunaPhase.fromJson(
            item['type'] ?? item['phase'] ?? item['name'] ?? item['etap'],
          );
          durationMinutes =
              _toInt(item['durationMinutes']) ??
              _toInt(item['duration']) ??
              _toInt(item['minutes']) ??
              0;
        }
        if (phase != null && !phases.contains(phase)) {
          phases.add(phase);
          durations.add(durationMinutes);
        }
      }
    }

    return _ParsedPhases(phases, durations);
  }

  static List<MeasurementSample> _tagSamplesWithPhases(
    List<MeasurementSample> samples,
    List<SaunaPhase> phases,
    List<int> durationsMinutes,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (samples.isEmpty || phases.isEmpty) return samples;
    if (samples.every((s) => s.phase != null)) return samples;

    final totalMinutes = math.max(1, endTime.difference(startTime).inMinutes);

    final boundaries = <double>[];
    final hasDurations = durationsMinutes.any((d) => d > 0);
    var accumulated = 0.0;
    if (hasDurations) {
      final totalDuration = durationsMinutes.fold<int>(0, (a, b) => a + b);
      for (var i = 0; i < phases.length; i++) {
        final duration = durationsMinutes[i] > 0
            ? durationsMinutes[i]
            : totalDuration ~/ phases.length;
        accumulated += duration;
        boundaries.add(accumulated);
      }
    } else {
      final slice = totalMinutes / phases.length;
      for (var i = 1; i <= phases.length; i++) {
        boundaries.add(slice * i);
      }
    }

    SaunaPhase phaseAt(double minutesFromStart) {
      var index = phases.length - 1;
      for (var i = 0; i < boundaries.length; i++) {
        if (minutesFromStart <= boundaries[i]) {
          index = i;
          break;
        }
      }
      return phases[index];
    }

    return [
      for (final sample in samples)
        sample.phase != null
            ? sample
            : MeasurementSample(
                timestamp: sample.timestamp,
                value: sample.value,
                phase: phaseAt(
                  sample.timestamp.difference(startTime).inSeconds / 60.0,
                ),
              ),
    ];
  }

  static DateTime? parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return parseTimestamp(asInt);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _ParsedPhases {
  final List<SaunaPhase> phases;
  final List<int> durationsMinutes;

  const _ParsedPhases(this.phases, this.durationsMinutes);
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

int? _toInt(dynamic value) {
  return _toDouble(value)?.toInt();
}
