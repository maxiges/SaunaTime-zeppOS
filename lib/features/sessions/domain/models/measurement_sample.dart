import 'sauna_phase.dart';

/// Parses a timestamp, which may be:
///  - a Unix number (seconds, ~10 digits, or milliseconds, ~13 digits),
///  - an ISO-8601 string (e.g. `2026-08-24T18:00:00`).
/// Returns `null` when parsing fails.
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    final absolute = value.abs();
    return DateTime.fromMillisecondsSinceEpoch(
      absolute >= 1e12 ? value.toInt() : value.toInt() * 1000,
    );
  }
  if (value is String) {
    final trimmed = value.trim();
    final numeric = num.tryParse(trimmed);
    if (numeric != null) return parseTimestamp(numeric);
    return DateTime.tryParse(trimmed);
  }
  return null;
}

class MeasurementSample {
  final DateTime timestamp;
  final double value;

  /// Sauna phase this sample belongs to (optional — for watch data).
  final SaunaPhase? phase;

  const MeasurementSample({
    required this.timestamp,
    required this.value,
    this.phase,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'phase': phase?.name,
    };
  }

  factory MeasurementSample.fromJson(Map<String, dynamic> json) {
    return MeasurementSample(
      timestamp:
          parseTimestamp(json['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      value: _sampleValue(json['value']),
      phase: SaunaPhase.fromJson(json['phase']),
    );
  }

  /// Safe sample value — accepts `num` and numeric strings
  /// (e.g. `"34.8"`) to avoid a parse error when the watch sends a number
  /// as a string. Invalid value → `0`.
  static double _sampleValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementSample &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          value == other.value &&
          phase == other.phase;

  @override
  int get hashCode =>
      timestamp.hashCode ^ value.hashCode ^ (phase?.hashCode ?? 0);
}
