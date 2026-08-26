import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../sessions/domain/calorie_calculator.dart';
import '../../sessions/domain/models/sauna_session.dart';
import '../../sessions/presentation/session_controller.dart';
import '../presentation/widgets/weekly_activity_card.dart';
import '../../sessions/presentation/widgets/session_card.dart';

class HomeScreen extends StatefulWidget {
  final SessionController controller;
  final LocaleController localeController;
  final UserProfileController userProfileController;
  final VoidCallback? onViewAllHistory;
  final Function(SaunaSession)? onSessionTap;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.localeController,
    required this.userProfileController,
    this.onViewAllHistory,
    this.onSessionTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadSessions();
    });
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _openBackup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BackupScreen(controller: widget.controller),
      ),
    );
  }

  List<SaunaSession> _sessionsInLast7Days(List<SaunaSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));
    
    return sessions.where((s) {
      final day = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return !day.isBefore(weekAgo) && !day.isAfter(today);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _entranceController]),
      builder: (context, _) {
        final sessions = widget.controller.sessions;
        final recentSessions = _sessionsInLast7Days(sessions);
        final recentMinutes = recentSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

        final summaryCard = _AnimatedEntrance(
          controller: _entranceController,
          delay: 0,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStat(
                    icon: Icons.hot_tub_rounded,
                    color: theme.colorScheme.primary,
                    value: '${recentSessions.length}',
                    label: l['sessions_total'],
                  ),
                  Container(height: 40, width: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  _SummaryStat(
                    icon: Icons.timer_rounded,
                    color: theme.colorScheme.secondary,
                    value: '$recentMinutes',
                    unit: l['minutes_abbr'],
                    label: l['sauna_time_total'],
                  ),
                ],
              ),
            ),
          ),
        );

        final activityCard = _AnimatedEntrance(
          controller: _entranceController,
          delay: 0.1,
          child: WeeklyActivityCard(
            sessions: sessions,
            userProfileController: widget.userProfileController,
          ),
        );

        final caloriesCard = _AnimatedEntrance(
          controller: _entranceController,
          delay: 0.2,
          child: AnimatedBuilder(
            animation: widget.userProfileController,
            builder: (context, _) => _buildCaloriesCard(context, sessions),
          ),
        );

        final sessionListHeader = _AnimatedEntrance(
          controller: _entranceController,
          delay: 0.3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l['recent_sessions'],
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (sessions.isNotEmpty && widget.onViewAllHistory != null)
                TextButton(
                  onPressed: widget.onViewAllHistory,
                  child: Text(l['view_all']),
                ),
            ],
          ),
        );

        final sessionItems = sessions.isEmpty
            ? [_AnimatedEntrance(
                controller: _entranceController,
                delay: 0.4,
                child: _NoSessionsPlaceholder(l: l),
              )]
            : sessions.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value;
                return _AnimatedEntrance(
                  controller: _entranceController,
                  delay: 0.4 + (index * 0.1),
                  child: SessionCard(
                    session: session,
                    onTap: () => widget.onSessionTap?.call(session),
                  ),
                );
              }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            title: Text(l['app_title']),
            centerTitle: true,
            toolbarHeight: isLandscape ? 40 : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.backup_outlined),
                tooltip: l['backup_title'],
                onPressed: _openBackup,
              ),
            ],
          ),
          body: widget.controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => widget.controller.loadSessions(),
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  summaryCard,
                                  activityCard,
                                  const SizedBox(height: 12),
                                  caloriesCard,
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              flex: 3,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  sessionListHeader,
                                  const SizedBox(height: 8),
                                  ...sessionItems,
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            summaryCard,
                            activityCard,
                            const SizedBox(height: 12),
                            caloriesCard,
                            const SizedBox(height: 24),
                            sessionListHeader,
                            const SizedBox(height: 8),
                            ...sessionItems,
                          ],
                        ),
                ),
        );
      },
    );
  }

  Widget _buildCaloriesCard(BuildContext context, List<SaunaSession> sessions) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final profile = widget.userProfileController.profile;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    bool hasHrData(SaunaSession s) => s.heartRateSamples.length >= 2 || s.averageHeartRate != null;

    double caloriesFor(List<SaunaSession> list) => list.fold<double>(0, (sum, s) {
          final estimate = CalorieCalculator.estimateForSession(profile: profile, session: s);
          return estimate == null ? sum : sum + estimate.calories;
        });

    final todaySessions = sessions.where((s) => _isSameDay(s.startTime, today)).toList();
    final weekSessions = sessions.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return !d.isBefore(weekStart) && !d.isAfter(today);
    }).toList();

    final todayCalories = caloriesFor(todaySessions);
    final weekCalories = caloriesFor(weekSessions);
    final todayHasHr = todaySessions.any(hasHrData);
    final weekHasHr = weekSessions.any(hasHrData);

    String formatKcal(bool hasHr, bool isEmpty, double kcal) {
      if (hasHr) return '${kcal.round()} kcal';
      if (isEmpty) return '0 kcal';
      return '—';
    }

    final todayValue = formatKcal(todayHasHr, todaySessions.isEmpty, todayCalories);
    final weekValue = formatKcal(weekHasHr, weekSessions.isEmpty, weekCalories);

    final withHrCount = sessions.where(hasHrData).length;
    String? hint;
    if (sessions.isNotEmpty) {
      if (withHrCount == 0) hint = l['calorie_need_hr'];
      else if (withHrCount < sessions.length) hint = l.homeCaloriesBasedOn(withHrCount);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: AppColors.warmRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l['calorie_estimate'],
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l['home_calories_today']}: $todayValue  •  ${l['home_calories_week']}: $weekValue',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final double delay;

  const _AnimatedEntrance({
    required this.child,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay;
    final end = (delay + 0.6).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final curve = CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        );
        
        final opacity = curve.value.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String? unit;
  final String label;

  const _SummaryStat({required this.icon, required this.color, required this.value, this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(unit!, style: theme.textTheme.labelMedium?.copyWith(color: color)),
            ],
          ],
        ),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _NoSessionsPlaceholder extends StatelessWidget {
  final AppLocalizations l;
  const _NoSessionsPlaceholder({required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.spa_outlined, size: 40, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(l['no_sessions_yet'], style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l['add_first_session_prompt'],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
