import 'package:flutter/material.dart';

/// Sauna phases sent by a smartwatch.
///
/// A watch session can contain from 1 to 3 phases (not always all three):
///  1. Heating (red color)
///  2. Cooling (blue color)
///  3. Resting (green color)
///
/// In the API, phases are sent as numbers: `1` = heating, `2` = cooling,
/// `3` = resting. Missing value defaults to `1` (heating).
enum SaunaPhase {
  heating(labelKey: 'watch_phase_heating', color: Colors.red, code: 1),
  cooling(labelKey: 'watch_phase_cooling', color: Colors.blue, code: 2),
  resting(labelKey: 'watch_phase_resting', color: Colors.green, code: 3);

  const SaunaPhase({
    required this.labelKey,
    required this.color,
    required this.code,
  });

  /// Translation key (AppLocalizations) for the phase name.
  final String labelKey;

  /// Dedicated phase color (used in charts and legend).
  final Color color;

  /// Phase number in the API: 1 = heating, 2 = cooling, 3 = resting.
  final int code;

  String toJson() => name;

  /// Returns a phase by its number (1/2/3) or `null` for an unknown code.
  static SaunaPhase? fromCode(int code) {
    for (final phase in values) {
      if (phase.code == code) return phase;
    }
    return null;
  }

  /// Tolerant parser: accepts numbers (1/2/3), numeric strings
  /// ("1"/"2"/"3") and names (heating, cooling...).
  static SaunaPhase? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return fromCode(value.toInt());
    }
    if (value is String) {
      final trimmed = value.trim();
      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return fromCode(numeric);
      }
      value = trimmed;
    }
    switch (value.toString().trim().toLowerCase()) {
      case 'heating':
      case 'warmup':
      case 'warm-up':
      case 'heat':
      case 'sauna':
      case 'nagrzewanie':
      case 'saunowanie':
        return SaunaPhase.heating;
      case 'cooling':
      case 'cool':
      case 'cold':
      case 'chłodzenie':
      case 'chlodzenie':
      case 'schladzanie':
        return SaunaPhase.cooling;
      case 'resting':
      case 'rest':
      case 'relax':
      case 'odpoczywanie':
      case 'odpoczynek':
        return SaunaPhase.resting;
      default:
        return null;
    }
  }
}
