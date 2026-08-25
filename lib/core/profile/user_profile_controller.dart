import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/sessions/domain/models/sauna_type.dart';
import 'user_profile.dart';

/// Stores the user profile (sex, weight, age) with persistence
/// in `SharedPreferences`. Used for more accurate calorie calculation.
class UserProfileController extends ChangeNotifier {
  static const String _sexKey = 'sauna_time_user_sex';
  static const String _weightKey = 'sauna_time_user_weight_kg';
  static const String _ageKey = 'sauna_time_user_age';
  static const String _saunaTypeKey = 'sauna_time_preferred_sauna_type';

  UserProfile _profile = const UserProfile();

  UserProfileController() {
    _load();
  }

  UserProfile get profile => _profile;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sexStr = prefs.getString(_sexKey);
      final weight = prefs.getDouble(_weightKey);
      final age = prefs.getInt(_ageKey);
      final saunaTypeStr = prefs.getString(_saunaTypeKey);

      _profile = UserProfile(
        sex: sexStr == 'female' ? UserSex.female : UserSex.male,
        weightKg: (weight ?? 75).clamp(30, 250).toDouble(),
        ageYears: (age ?? 30).clamp(10, 120),
        preferredSaunaType: SaunaType.fromJson(saunaTypeStr),
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setSex(UserSex sex) async {
    if (_profile.sex == sex) return;
    _profile = _profile.copyWith(sex: sex);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sexKey, sex.name);
    } catch (_) {}
  }

  Future<void> setWeightKg(double weight) async {
    final clamped = weight.clamp(30, 250).toDouble();
    if (_profile.weightKg == clamped) return;
    _profile = _profile.copyWith(weightKg: clamped);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_weightKey, clamped);
    } catch (_) {}
  }

  Future<void> setAgeYears(int age) async {
    final clamped = age.clamp(10, 120);
    if (_profile.ageYears == clamped) return;
    _profile = _profile.copyWith(ageYears: clamped);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ageKey, clamped);
    } catch (_) {}
  }

  Future<void> setPreferredSaunaType(SaunaType type) async {
    if (_profile.preferredSaunaType == type) return;
    _profile = _profile.copyWith(preferredSaunaType: type);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_saunaTypeKey, type.name);
    } catch (_) {}
  }
}
