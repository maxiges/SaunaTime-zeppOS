import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../http_server/services/http_server_service.dart';
import '../../sessions/presentation/session_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/profile/user_profile_controller.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  final SessionController sessionController;
  final LocalHttpServerService serverService;
  final LocaleController localeController;
  final ThemeController themeController;
  final UserProfileController userProfileController;

  const SplashScreen({
    super.key,
    required this.sessionController,
    required this.serverService,
    required this.localeController,
    required this.themeController,
    required this.userProfileController,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start loading data while animation plays
    await Future.wait([
      widget.sessionController.loadSessions(),
      // Add a minimum delay for the splash screen to be visible
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainScaffold(
            sessionController: widget.sessionController,
            serverService: widget.serverService,
            localeController: widget.localeController,
            themeController: widget.themeController,
            userProfileController: widget.userProfileController,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hot_tub_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sauna Time',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  color: theme.colorScheme.primary,
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
