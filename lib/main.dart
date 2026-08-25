import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sauna_time/core/localization/app_localizations.dart';
import 'package:sauna_time/core/localization/locale_controller.dart';
import 'package:sauna_time/core/profile/user_profile_controller.dart';
import 'package:sauna_time/core/theme/app_colors.dart';
import 'package:sauna_time/core/theme/theme_controller.dart';
import 'package:sauna_time/features/home/presentation/main_scaffold.dart';
import 'package:sauna_time/features/http_server/services/http_server_service.dart';
import 'package:sauna_time/features/sessions/presentation/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionController = SessionController();
  final serverService = LocalHttpServerService(
    sessionController: sessionController,
  );
  final localeController = LocaleController();
  final themeController = ThemeController();
  final userProfileController = UserProfileController();

  serverService.startServer(port: 8080);

  runApp(
    SaunaTimeApp(
      sessionController: sessionController,
      serverService: serverService,
      localeController: localeController,
      themeController: themeController,
      userProfileController: userProfileController,
    ),
  );
}

/// "Warm and cold" palette: orange (warm) + blue (cold).
/// Color constants are located in `lib/core/theme/app_colors.dart`.

ColorScheme _buildColorScheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? AppColors.warmOrangeDark : AppColors.warmOrange,
    onPrimary: isDark ? const Color(0xFF3E1B00) : Colors.white,
    primaryContainer: isDark
        ? AppColors.warmContainerDark
        : AppColors.warmContainer,
    onPrimaryContainer: isDark
        ? AppColors.warmOnContainerDark
        : AppColors.warmOnContainer,
    secondary: isDark ? AppColors.coldBlueDark : AppColors.coldBlue,
    onSecondary: isDark ? const Color(0xFF00243E) : Colors.white,
    secondaryContainer: isDark
        ? AppColors.coldBlueContainerDark
        : AppColors.coldBlueContainer,
    onSecondaryContainer: isDark
        ? AppColors.coldBlueOnContainerDark
        : AppColors.coldBlueOnContainer,
    // Neutral (gray) card backgrounds — without the pink tint from the seed
    surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    surfaceContainerLowest: isDark
        ? AppColors.surfaceLowestDark
        : AppColors.surfaceLowestLight,
    surfaceContainerLow: isDark
        ? AppColors.surfaceLowDark
        : AppColors.surfaceLowLight,
    surfaceContainer: isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight,
    surfaceContainerHigh: isDark
        ? AppColors.surfaceHighDark
        : AppColors.surfaceHighLight,
    surfaceContainerHighest: isDark
        ? AppColors.surfaceHighestDark
        : AppColors.surfaceHighestLight,
    onSurface: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
    onSurfaceVariant: isDark
        ? AppColors.onSurfaceVariantDark
        : AppColors.onSurfaceVariantLight,
    outline: isDark ? AppColors.outlineDark : AppColors.outlineLight,
    outlineVariant: isDark
        ? AppColors.outlineVariantDark
        : AppColors.outlineVariantLight,
  );
}

ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _buildColorScheme(brightness),
  );
}

class SaunaTimeApp extends StatefulWidget {
  final SessionController sessionController;
  final LocalHttpServerService serverService;
  final LocaleController localeController;
  final ThemeController themeController;
  final UserProfileController userProfileController;

  const SaunaTimeApp({
    super.key,
    required this.sessionController,
    required this.serverService,
    required this.localeController,
    required this.themeController,
    required this.userProfileController,
  });

  @override
  State<SaunaTimeApp> createState() => _SaunaTimeAppState();
}

class _SaunaTimeAppState extends State<SaunaTimeApp> {
  @override
  void initState() {
    super.initState();
    widget.localeController.addListener(_onLocaleChanged);
    widget.themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.localeController.removeListener(_onLocaleChanged);
    widget.themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});
  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sauna Time',
      debugShowCheckedModeBanner: false,
      locale: widget.localeController.currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: widget.themeController.themeMode,
      home: MainScaffold(
        sessionController: widget.sessionController,
        serverService: widget.serverService,
        localeController: widget.localeController,
        themeController: widget.themeController,
        userProfileController: widget.userProfileController,
      ),
    );
  }
}
