import 'measurement_sample.dart';
import 'sauna_phase.dart';
import 'sauna_type.dart';
import 'session_source.dart';

class SaunaSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final SessionSource source;
  final double? temperature;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final String? notes;
  final List<MeasurementSample> heartRateSamples;
  final List<MeasurementSample> temperatureSamples;
  final SaunaType saunaType;

  /// Sauna phases reported by the watch (from 1 to 3: heating, cooling, resting).
  final List<SaunaPhase> phases;

  /// Duration of individual phases in minutes.
  final Map<SaunaPhase, int> phaseDurations;

  const SaunaSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.source = SessionSource.manual,
    this.temperature,
    this.averageHeartRate,
    this.maxHeartRate,
    this.notes,
    this.heartRateSamples = const [],
    this.temperatureSamples = const [],
    this.phases = const [],
    this.saunaType = SaunaType.dry,
    this.phaseDurations = const {},
  });

  /// Returns the duration of a specific phase in minutes.
  /// It checks explicitly saved values first, then attempts to estimate from samples.
  int? durationForPhase(SaunaPhase phase) {
    // 1. Check if we have a directly saved value (must be > 0)
    if (phaseDurations.containsKey(phase) && phaseDurations[phase]! > 0) {
      return phaseDurations[phase];
    }

    // 2. If it's a single-phase session and it matches the requested phase
    if (phases.length <= 1) {
       final currentPhase = phases.isEmpty ? SaunaPhase.heating : phases.first;
       if (currentPhase == phase) return durationMinutes;
       // If we only have samples for one phase, we might still want to return durationMinutes
       final uniqueSamplePhases = heartRateSamples
           .map((s) => s.phase)
           .whereType<SaunaPhase>()
           .toSet();
       if (uniqueSamplePhases.length == 1 && uniqueSamplePhases.first == phase) {
         return durationMinutes;
       }
    }

    // 3. Try to estimate based on samples if available
    final samples = heartRateSamples.where((s) => s.phase == phase).toList();
    if (samples.length >= 2) {
      samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final diff = samples.last.timestamp.difference(samples.first.timestamp);
      // We use rounding to be more accurate than simple truncation (inMinutes).
      final mins = (diff.inSeconds / 60.0).round();
      return mins > 0 ? mins : 1;
    }

    return null;
  }

  /// Convenience getter for heating phase duration.
  int? get heatingDurationMinutes => durationForPhase(SaunaPhase.heating);

  SaunaSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    SessionSource? source,
    double? temperature,
    int? averageHeartRate,
    int? maxHeartRate,
    String? notes,
    List<MeasurementSample>? heartRateSamples,
    List<MeasurementSample>? temperatureSamples,
    List<SaunaPhase>? phases,
    SaunaType? saunaType,
    Map<SaunaPhase, int>? phaseDurations,
  }) {
    return SaunaSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      source: source ?? this.source,
      temperature: temperature ?? this.temperature,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      notes: notes ?? this.notes,
      heartRateSamples: heartRateSamples ?? this.heartRateSamples,
      temperatureSamples: temperatureSamples ?? this.temperatureSamples,
      phases: phases ?? this.phases,
      saunaType: saunaType ?? this.saunaType,
      phaseDurations: phaseDurations ?? this.phaseDurations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'source': source.toJson(),
      'temperature': temperature,
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'notes': notes,
      'heartRateSamples': heartRateSamples.map((e) => e.toJson()).toList(),
      'temperatureSamples': temperatureSamples.map((e) => e.toJson()).toList(),
      'phases': phases.map((e) => e.toJson()).toList(),
      'saunaType': saunaType.toJson(),
      'phaseDurations': phaseDurations.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory SaunaSession.fromJson(Map<String, dynamic> json) {
    final Map<SaunaPhase, int> phaseDurations = {};
    if (json['phaseDurations'] != null) {
      final Map<String, dynamic> durations =
          json['phaseDurations'] as Map<String, dynamic>;
      durations.forEach((key, value) {
        final phase = SaunaPhase.values.firstWhere((p) => p.name == key,
            orElse: () => SaunaPhase.heating);
        phaseDurations[phase] = value as int;
      });
    }

    return SaunaSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
      source: SessionSource.fromJson(json['source'] as String? ?? 'manual'),
      temperature: (json['temperature'] as num?)?.toDouble(),
      averageHeartRate: json['averageHeartRate'] as int?,
      maxHeartRate: json['maxHeartRate'] as int?,
      notes: json['notes'] as String?,
      heartRateSamples: (json['heartRateSamples'] as List<dynamic>?)
              ?.map(
                (e) => MeasurementSample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      temperatureSamples: (json['temperatureSamples'] as List<dynamic>?)
              ?.map(
                (e) => MeasurementSample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      phases: (json['phases'] as List<dynamic>?)
              ?.map((e) => SaunaPhase.fromJson(e))
              .whereType<SaunaPhase>()
              .toList() ??
          const [],
      saunaType: SaunaType.fromJson(json['saunaType'] as String?),
      phaseDurations: phaseDurations,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaunaSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
