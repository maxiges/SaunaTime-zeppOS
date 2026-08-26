import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../http_server/services/http_server_service.dart';
import '../../sessions/domain/models/sauna_session.dart';
import '../../sessions/presentation/add_session_screen.dart';
import '../../sessions/presentation/calendar_screen.dart';
import '../../sessions/presentation/history_screen.dart';
import '../../sessions/presentation/session_controller.dart';
import '../../sessions/presentation/session_detail_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'home_screen.dart';

class MainScaffold extends StatefulWidget {
  final SessionController sessionController;
  final LocalHttpServerService serverService;
  final LocaleController localeController;
  final ThemeController themeController;
  final UserProfileController userProfileController;

  const MainScaffold({
    super.key,
    required this.sessionController,
    required this.serverService,
    required this.localeController,
    required this.themeController,
    required this.userProfileController,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSessionDetail(SaunaSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(
          session: session,
          controller: widget.sessionController,
          userProfileController: widget.userProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final List<Widget> screens = [
      HomeScreen(
        controller: widget.sessionController,
        localeController: widget.localeController,
        userProfileController: widget.userProfileController,
        onViewAllHistory: () => _onTabSelected(1),
        onSessionTap: _openSessionDetail,
      ),
      HistoryScreen(
        controller: widget.sessionController,
        onSessionTap: _openSessionDetail,
      ),
      CalendarScreen(
        controller: widget.sessionController,
        userProfileController: widget.userProfileController,
        onSessionTap: _openSessionDetail,
      ),
      SettingsScreen(
        localeController: widget.localeController,
        themeController: widget.themeController,
        userProfileController: widget.userProfileController,
        serverService: widget.serverService,
        sessionController: widget.sessionController,
      ),
    ];

    return AnimatedBuilder(
      animation: widget.localeController,
      builder: (context, _) {
        final l2 = AppLocalizations.of(context);
        
        Widget body;
        if (isLandscape) {
          body = Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabSelected,
                labelType: MediaQuery.of(context).size.height < 400
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                groupAlignment: -0.8,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: FloatingActionButton.small(
                    // Explicit heroTag to avoid collision with portrait FAB
                    heroTag: 'fab_main_landscape',
                    elevation: 0,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddSessionScreen(
                            controller: widget.sessionController,
                            userProfileController: widget.userProfileController,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard_rounded),
                    label: Text(l2['tab_dashboard']),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.history_outlined),
                    selectedIcon: const Icon(Icons.history_rounded),
                    label: Text(l2['tab_history']),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    selectedIcon: const Icon(Icons.calendar_month_rounded),
                    label: Text(l2['tab_calendar']),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings_rounded),
                    label: Text(l2['settings_title']),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _AnimatedTabSwitcher(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          );
        } else {
          body = _AnimatedTabSwitcher(
            index: _currentIndex,
            children: screens,
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: body,
          bottomNavigationBar: isLandscape ? null : NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: l2['tab_dashboard'],
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
                label: l2['tab_history'],
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: l2['tab_calendar'],
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: l2['settings_title'],
              ),
            ],
          ),
          floatingActionButton: !isLandscape && (_currentIndex == 0 || _currentIndex == 1)
              ? FloatingActionButton.extended(
                  // Explicit heroTag to avoid collision with landscape FAB
                  heroTag: 'fab_main_portrait',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddSessionScreen(
                          controller: widget.sessionController,
                          userProfileController: widget.userProfileController,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l['add_session']),
                )
              : null,
        );
      },
    );
  }
}

class _AnimatedTabSwitcher extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedTabSwitcher({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: children[index],
      ),
    );
  }
}
