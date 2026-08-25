import 'package:flutter/foundation.dart';

import '../../features/sessions/domain/models/sauna_type.dart';

/// User's sex — used in the approximate calculation of burned calories.
enum UserSex { male, female }

/// User profile (sex, weight, age) — allows a more accurate estimate of
/// calories burned based on heart rate.
@immutable
class UserProfile {
  final UserSex sex;
  final double weightKg;
  final int ageYears;
  final SaunaType preferredSaunaType;

  const UserProfile({
    this.sex = UserSex.male,
    this.weightKg = 75,
    this.ageYears = 30,
    this.preferredSaunaType = SaunaType.dry,
  });

  UserProfile copyWith({
    UserSex? sex,
    double? weightKg,
    int? ageYears,
    SaunaType? preferredSaunaType,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      ageYears: ageYears ?? this.ageYears,
      preferredSaunaType: preferredSaunaType ?? this.preferredSaunaType,
    );
  }

  bool get isMale => sex == UserSex.male;
}
