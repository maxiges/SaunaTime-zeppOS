import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/theme_controller.dart';

/// Settings sub-section: app theme (system / light / dark).
class ThemeSettingsScreen extends StatelessWidget {
  final ThemeController themeController;

  const ThemeSettingsScreen({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l['settings_theme_section']),
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
              animation: themeController,
              builder: (context, _) {
                final options =
                    <({ThemeMode mode, IconData icon, String label})>[
                      (
                        mode: ThemeMode.system,
                        icon: Icons.brightness_auto_rounded,
                        label: l['theme_mode_system'],
                      ),
                      (
                        mode: ThemeMode.light,
                        icon: Icons.light_mode_rounded,
                        label: l['theme_mode_light'],
                      ),
                      (
                        mode: ThemeMode.dark,
                        icon: Icons.dark_mode_rounded,
                        label: l['theme_mode_dark'],
                      ),
                    ];

                return Column(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 68, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Icon(
                          options[i].icon,
                          color: options[i].mode == themeController.themeMode
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          options[i].label,
                          style: TextStyle(
                            fontWeight:
                                options[i].mode == themeController.themeMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: options[i].mode == themeController.themeMode
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: options[i].mode == themeController.themeMode
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : const Icon(Icons.radio_button_unchecked_rounded),
                        onTap: () =>
                            themeController.setThemeMode(options[i].mode),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
