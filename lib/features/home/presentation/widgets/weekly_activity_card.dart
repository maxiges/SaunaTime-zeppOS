import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../sessions/domain/models/sauna_session.dart';

class WeeklyActivityCard extends StatelessWidget {
  final List<SaunaSession> sessions;
  final LocaleController localeController;

  const WeeklyActivityCard({
    super.key,
    required this.sessions,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();

    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final minutesPerDay = <DateTime, int>{};
    for (final d in days) {
      minutesPerDay[d] = 0;
    }

    for (final session in sessions) {
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      if (minutesPerDay.containsKey(sessionDay)) {
        minutesPerDay[sessionDay] =
            (minutesPerDay[sessionDay] ?? 0) + session.durationMinutes;
      }
    }

    final totalMinutesThisWeek =
        minutesPerDay.values.fold<int>(0, (sum, m) => sum + m);
    final maxMinutes =
        minutesPerDay.values.fold<int>(1, (max, m) => m > max ? m : max);

    // Get weekday names from localization
    final weekDayKeys = [
      'day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l['weekly_activity'],
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$totalMinutesThisWeek ${l['weekly_total']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final mins = minutesPerDay[day] ?? 0;
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                final heightFactor =
                    mins > 0 ? (mins / maxMinutes).clamp(0.15, 1.0) : 0.04;
                final dayLabel = l[weekDayKeys[day.weekday - 1]];

                return Column(
                  children: [
                    if (mins > 0)
                      Text(
                        '$mins',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    else
                      const SizedBox(height: 14),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 60 * heightFactor,
                      decoration: BoxDecoration(
                        color: mins > 0
                            ? (isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
