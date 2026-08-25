import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}

class LocaleController extends ChangeNotifier {
  static const String _prefKey = 'sauna_time_app_language_code';

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', name: 'English', flag: '🇬🇧'),
    LanguageOption(code: 'pl', name: 'Polski', flag: '🇵🇱'),
    LanguageOption(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    LanguageOption(code: 'fr', name: 'Français', flag: '🇫🇷'),
  ];

  Locale _currentLocale = const Locale('en');

  LocaleController() {
    _loadSavedLocale();
  }

  Locale get currentLocale => _currentLocale;

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null &&
          supportedLanguages.any((lang) => lang.code == savedCode)) {
        _currentLocale = Locale(savedCode);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    if (!supportedLanguages.any((lang) => lang.code == languageCode)) return;

    _currentLocale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    } catch (_) {}
  }
}
