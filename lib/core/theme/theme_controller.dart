import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app theme (system / light / dark)
/// with persistence in `SharedPreferences`.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'sauna_time_app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeController() {
    _loadSavedThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      _themeMode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_prefKey, value);
    } catch (_) {}
  }
}
