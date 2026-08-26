import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../http_server/services/http_server_service.dart';
import '../../sessions/presentation/session_controller.dart';
import 'http_server_screen.dart';
import 'settings_about_screen.dart';
import 'settings_language_screen.dart';
import 'settings_profile_screen.dart';
import 'settings_theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  final LocaleController localeController;
  final ThemeController themeController;
  final UserProfileController userProfileController;
  final LocalHttpServerService serverService;
  final SessionController sessionController;

  const SettingsScreen({
    super.key,
    required this.localeController,
    required this.themeController,
    required this.userProfileController,
    required this.serverService,
    required this.sessionController,
  });

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _clearAllData(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['clear_data_confirm_title']),
        content: Text(l['clear_data_confirm_message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l['cancel']),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warmRed),
            child: Text(l['delete']),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await sessionController.clearAllSessions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l['clear_data_success'] : l['error_delete_session'],
            ),
            backgroundColor: success ? Colors.green : AppColors.warmRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final sections = [
      _SettingsTile(
        icon: Icons.translate_rounded,
        iconColor: Colors.indigo,
        title: l['settings_language_section'],
        subtitle: l['settings_language_subtitle'],
        onTap: () => _push(
          context,
          LanguageSettingsScreen(localeController: localeController),
        ),
      ),
      _SettingsTile(
        icon: Icons.palette_outlined,
        iconColor: Colors.purple,
        title: l['settings_theme_section'],
        subtitle: l['settings_theme_subtitle'],
        onTap: () => _push(
          context,
          ThemeSettingsScreen(themeController: themeController),
        ),
      ),
      _SettingsTile(
        icon: Icons.person_outline_rounded,
        iconColor: Colors.teal,
        title: l['settings_profile_section'],
        subtitle: l['settings_profile_subtitle'],
        onTap: () => _push(
          context,
          ProfileSettingsScreen(userProfileController: userProfileController),
        ),
      ),
      _SettingsTile(
        icon: Icons.watch_rounded,
        iconColor: Colors.deepOrange,
        title: l['settings_watch_section'],
        subtitle: l['settings_watch_subtitle'],
        onTap: () =>
            _push(context, HttpServerScreen(serverService: serverService)),
      ),
      _SettingsTile(
        icon: Icons.info_outline_rounded,
        iconColor: Colors.blueGrey,
        title: l['settings_about_section'],
        subtitle: l['settings_about_subtitle'],
        onTap: () => _push(context, const AboutSettingsScreen()),
      ),
    ];

    final dangerZone = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l['settings_danger_zone'],
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.warmRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.warmRed,
          title: l['settings_clear_data'],
          subtitle: l['settings_clear_data_subtitle'],
          onTap: () => _clearAllData(context),
        ),
      ],
    );

    return Scaffold(
      // Wysokie krycie (98%), aby tło było niemal jednolite, ale z lekkim "duchem" obrazka
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.98),
      appBar: AppBar(
        // Używa AppBarTheme z motywu (0.94 alpha)
        title: Text(l['settings_title']),
        centerTitle: true,
        toolbarHeight: isLandscape ? 40 : null,
      ),
      body: isLandscape
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GridView(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          mainAxisExtent: 90,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    children: sections,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [dangerZone],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...sections.map(
                  (tile) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: tile,
                  ),
                ),
                const SizedBox(height: 12),
                dangerZone,
              ],
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
