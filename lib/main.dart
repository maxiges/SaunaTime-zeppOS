import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sauna_time/core/localization/app_localizations.dart';
import 'package:sauna_time/core/localization/locale_controller.dart';
import 'package:sauna_time/core/profile/user_profile_controller.dart';
import 'package:sauna_time/core/theme/app_colors.dart';
import 'package:sauna_time/core/theme/theme_controller.dart';
import 'package:sauna_time/features/home/presentation/splash_screen.dart';
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

/// Restored full ColorScheme mapping to maintain preferred aesthetics.
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
  final colorScheme = _buildColorScheme(brightness);
  
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // Global transparency for screens to reveal the builder-provided background
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface.withValues(alpha: 0.75),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.primary,
            size: 26,
            shadows: [
              Shadow(
                color: colorScheme.primary.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 12,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      indicatorColor: Colors.transparent,
      selectedIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 28,
        shadows: [
          Shadow(
            color: colorScheme.primary.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    ),
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
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bgImage = isDark ? 'assets/bg_d.png' : 'assets/bg_l.png';
        
        return Stack(
          children: [
            // Root background image
            Positioned.fill(
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),
            // Global glassmorphism effect (Blur + Tint)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.7 : 0.7),
                ),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
      home: SplashScreen(
        sessionController: widget.sessionController,
        serverService: widget.serverService,
        localeController: widget.localeController,
        themeController: widget.themeController,
        userProfileController: widget.userProfileController,
      ),
    );
  }
}
