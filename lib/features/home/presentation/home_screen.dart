import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadSessions();
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
      animation: widget.controller,
      builder: (context, _) {
        final sessions = widget.controller.sessions;
        final recentSessions = _sessionsInLast7Days(sessions);
        final recentMinutes = recentSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

        final summaryCard = Card(
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
        );

        final activityCard = WeeklyActivityCard(
          sessions: sessions,
          localeController: widget.localeController,
        );

        final caloriesCard = AnimatedBuilder(
          animation: widget.userProfileController,
          builder: (context, _) => _buildCaloriesCard(context, sessions),
        );

        final sessionListHeader = Row(
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
        );

        final sessionList = sessions.isEmpty
            ? [_NoSessionsPlaceholder(l: l)]
            : sessions.take(5).map((session) => SessionCard(
                  session: session,
                  onTap: () => widget.onSessionTap?.call(session),
                )).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l['app_title']),
            centerTitle: true,
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
                            // Left side: Stats and Charts
                            Expanded(
                              flex: 4,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  summaryCard,
                                  const SizedBox(height: 12),
                                  caloriesCard,
                                  const SizedBox(height: 12),
                                  activityCard,
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            // Right side: Recent Sessions
                            Expanded(
                              flex: 3,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  sessionListHeader,
                                  const SizedBox(height: 8),
                                  ...sessionList,
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            summaryCard,
                            const SizedBox(height: 16),
                            activityCard,
                            const SizedBox(height: 16),
                            caloriesCard,
                            const SizedBox(height: 24),
                            sessionListHeader,
                            const SizedBox(height: 8),
                            ...sessionList,
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
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.25),
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
