import 'package:flutter/foundation.dart';

import '../../../core/profile/user_profile.dart';
import 'models/measurement_sample.dart';
import 'models/sauna_session.dart';
import 'models/sauna_type.dart';
import 'models/sauna_phase.dart';

/// Type of temperature reported in the session:
///  - `sauna` — air temperature in the sauna (≥ [saunaTemperatureThresholdC]),
///  - `body`  — body/skin temperature of the person in the sauna,
///  - `unknown` — no value.
enum TemperatureKind { unknown, sauna, body }

/// Temperatures ≥ this threshold are considered sauna temperature (air);
/// lower ones are likely body/skin temperature.
const double saunaTemperatureThresholdC = 45;

/// Classifies temperature: ≥45°C → sauna, <45°C → body, none → unknown.
TemperatureKind classifyTemperature(double? temperature) {
  if (temperature == null) return TemperatureKind.unknown;
  return temperature >= saunaTemperatureThresholdC
      ? TemperatureKind.sauna
      : TemperatureKind.body;
}

/// Result of approximate calorie calculation.
@immutable
class CalorieEstimate {
  final double calories;
  final double caloriesPerMinute;

  /// Applied temperature factor (1.0 = no correction).
  final double temperatureFactor;

  /// How the temperature was treated (sauna / body / unknown).
  final TemperatureKind temperatureKind;

  const CalorieEstimate({
    required this.calories,
    required this.caloriesPerMinute,
    this.temperatureFactor = 1.0,
    this.temperatureKind = TemperatureKind.unknown,
  });

  int get caloriesRounded => calories.round();
  int get perMinuteRounded => caloriesPerMinute.round();
}

/// Approximate calorie calculation based on:
///  - duration (minutes),
///  - heart rate (bpm) — ideally segment-by-segment or phase-by-phase,
///  - user profile (sex, weight, age) — Keytel et al. formula,
///  - sauna type (dry / steam) and temperature correction.
class CalorieCalculator {
  CalorieCalculator._();

  /// Estimation based on AVERAGE heart rate — whole session as one segment.
  static CalorieEstimate estimate({
    required UserProfile profile,
    required int durationMinutes,
    required int averageHeartRate,
    double? averageTemperature,
    SaunaType saunaType = SaunaType.dry,
  }) {
    final temperatureKind = classifyTemperature(averageTemperature);
    final tempFactor = _temperatureFactor(averageTemperature, temperatureKind, saunaType);
    final perMinute =
        _basePerMinute(profile, averageHeartRate.toDouble()) * tempFactor;

    return CalorieEstimate(
      calories: perMinute * durationMinutes,
      caloriesPerMinute: perMinute,
      temperatureFactor: tempFactor,
      temperatureKind: temperatureKind,
    );
  }

  /// Detailed segment calculation: heart rate profile (`heartRateSamples`)
  /// is divided into segments between consecutive samples.
  /// Temperature correction is applied ONLY during the 'heating' (sauna) phase.
  static CalorieEstimate estimateFromSamples({
    required UserProfile profile,
    required List<MeasurementSample> heartRateSamples,
    required int durationMinutes,
    double? averageTemperature,
    SaunaType saunaType = SaunaType.dry,
  }) {
    final temperatureKind = classifyTemperature(averageTemperature);
    // Base temperature factor for the sauna part.
    final saunaTempFactor = _temperatureFactor(averageTemperature, temperatureKind, saunaType);

    // Not enough samples for segment measurement — fallback to average heart rate.
    if (heartRateSamples.length < 2) {
      final singleHr = heartRateSamples.isEmpty
          ? null
          : heartRateSamples.first.value;
      if (singleHr == null) {
        return const CalorieEstimate(
          calories: 0,
          caloriesPerMinute: 0,
          temperatureFactor: 1.0,
          temperatureKind: TemperatureKind.unknown,
        );
      }
      // If we only have one sample, assume it's sauna (heating) phase if not specified.
      final isHeating = heartRateSamples.isEmpty || 
                        heartRateSamples.first.phase == null || 
                        heartRateSamples.first.phase == SaunaPhase.heating;
      
      final factor = isHeating ? saunaTempFactor : 1.0;
      final perMinute = _basePerMinute(profile, singleHr) * factor;
      
      return CalorieEstimate(
        calories: perMinute * durationMinutes,
        caloriesPerMinute: perMinute,
        temperatureFactor: factor,
        temperatureKind: temperatureKind,
      );
    }

    final samples = [...heartRateSamples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var totalCalories = 0.0;
    var tracedMinutes = 0.0;
    
    for (var i = 0; i < samples.length - 1; i++) {
      final start = samples[i];
      final end = samples[i + 1];
      final minutes =
          end.timestamp.difference(start.timestamp).inSeconds / 60.0;
      if (minutes <= 0) continue;
      
      final hr = (start.value + end.value) / 2;
      
      // Apply temperature factor ONLY if the segment is in heating phase.
      // If phase is null, we assume the first segment is heating (sauna) 
      // as per user instructions ("The first measurement is when the person sat in a hot sauna").
      bool isHeating = start.phase == SaunaPhase.heating;
      if (start.phase == null && i == 0) {
        isHeating = true; 
      }
      
      final currentFactor = isHeating ? saunaTempFactor : 1.0;
      final perMinute = _basePerMinute(profile, hr) * currentFactor;
      
      totalCalories += perMinute * minutes;
      tracedMinutes += minutes;
    }

    final caloriesPerMinute = tracedMinutes > 0
        ? totalCalories / tracedMinutes
        : 0.0;

    return CalorieEstimate(
      calories: totalCalories,
      caloriesPerMinute: caloriesPerMinute,
      temperatureFactor: saunaTempFactor, // We report the sauna factor as reference
      temperatureKind: temperatureKind,
    );
  }

  /// Calculation for the WHOLE session: uses segment-based heart rate if available,
  /// otherwise average heart rate.
  static CalorieEstimate? estimateForSession({
    required UserProfile profile,
    required SaunaSession session,
  }) {
    if (session.heartRateSamples.length >= 2) {
      return estimateFromSamples(
        profile: profile,
        heartRateSamples: session.heartRateSamples,
        durationMinutes: session.durationMinutes,
        averageTemperature: session.temperature,
        saunaType: session.saunaType,
      );
    }
    final avgHr = session.averageHeartRate;
    if (avgHr == null) return null;
    return estimate(
      profile: profile,
      durationMinutes: session.durationMinutes,
      averageHeartRate: avgHr,
      averageTemperature: session.temperature,
      saunaType: session.saunaType,
    );
  }

  /// Keytel et al. formula: calories per minute from heart rate, sex, weight, and age.
  static double _basePerMinute(UserProfile profile, double h) {
    final w = profile.weightKg;
    final a = profile.ageYears.toDouble();
    double basePerMinute;
    if (profile.isMale) {
      basePerMinute = (-55.0969 + 0.6309 * h + 0.1988 * w + 0.2017 * a) / 4.184;
    } else {
      basePerMinute = (-20.4022 + 0.4472 * h - 0.1263 * w + 0.074 * a) / 4.184;
    }
    if (basePerMinute < 0) basePerMinute = 0;
    return basePerMinute;
  }

  /// Temperature correction factor.
  /// Dry sauna reference ~75°C.
  /// Steam sauna reference ~45°C.
  static double _temperatureFactor(
    double? averageTemperature,
    TemperatureKind kind,
    SaunaType saunaType,
  ) {
    if (kind != TemperatureKind.sauna) return 1.0;
    final double referenceTemp = saunaType == SaunaType.steam ? 45.0 : 75.0;
    return 1 + ((averageTemperature! - referenceTemp) * 0.004).clamp(-0.10, 0.25);
  }
}
