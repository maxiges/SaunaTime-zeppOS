import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';

/// Settings sub-section: app language selection.
class LanguageSettingsScreen extends StatelessWidget {
  final LocaleController localeController;

  const LanguageSettingsScreen({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l['settings_language_section']),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: localeController,
              builder: (context, _) {
                return Column(
                  children: [
                    ...LocaleController.supportedLanguages.asMap().entries.map((
                      entry,
                    ) {
                      final idx = entry.key;
                      final lang = entry.value;
                      final isSelected =
                          localeController.currentLocale.languageCode ==
                          lang.code;
                      final isLast =
                          idx == LocaleController.supportedLanguages.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: Text(
                              lang.flag,
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              lang.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : const Icon(
                                    Icons.radio_button_unchecked_rounded,
                                  ),
                            onTap: () =>
                                localeController.setLanguage(lang.code),
                          ),
                          if (!isLast)
                            const Divider(height: 1, indent: 68, endIndent: 16),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
