import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/profile/user_profile.dart';
import '../../../../core/profile/user_profile_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sessions/domain/models/sauna_session.dart';

class WeeklyActivityCard extends StatefulWidget {
  final List<SaunaSession> sessions;
  final UserProfileController userProfileController;

  const WeeklyActivityCard({
    super.key,
    required this.sessions,
    required this.userProfileController,
  });

  @override
  State<WeeklyActivityCard> createState() => _WeeklyActivityCardState();
}

class _WeeklyActivityCardState extends State<WeeklyActivityCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(WeeklyActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions.length != widget.sessions.length) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.userProfileController,
      builder: (context, _) {
        final displayMode = widget.userProfileController.profile.activityDisplayMode;
        
        // Option to hide the widget entirely
        if (displayMode == ActivityDisplayMode.none) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final l = AppLocalizations.of(context);
        final now = DateTime.now();

        final days = List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return DateTime(d.year, d.month, d.day);
        });

        final minutesPerDay = <DateTime, int>{};
        final heatingMinutesPerDay = <DateTime, int>{};
        final sessionsCountPerDay = <DateTime, int>{};
        
        for (final d in days) {
          minutesPerDay[d] = 0;
          heatingMinutesPerDay[d] = 0;
          sessionsCountPerDay[d] = 0;
        }

        for (final session in widget.sessions) {
          final sessionDay = DateTime(
            session.startTime.year,
            session.startTime.month,
            session.startTime.day,
          );
          if (minutesPerDay.containsKey(sessionDay)) {
            minutesPerDay[sessionDay] = (minutesPerDay[sessionDay] ?? 0) + session.durationMinutes;
            heatingMinutesPerDay[sessionDay] = (heatingMinutesPerDay[sessionDay] ?? 0) + (session.heatingDurationMinutes ?? 0);
            sessionsCountPerDay[sessionDay] = (sessionsCountPerDay[sessionDay] ?? 0) + 1;
          }
        }

        final totalMinutesThisWeek = minutesPerDay.values.fold<int>(0, (sum, m) => sum + m);
        final totalHeatingMinutesThisWeek = heatingMinutesPerDay.values.fold<int>(0, (sum, m) => sum + m);
        final maxMinutes = minutesPerDay.values.fold<int>(1, (max, m) => m > max ? m : max);
        final maxSessions = sessionsCountPerDay.values.fold<int>(1, (max, c) => c > max ? c : max);

        final weekDayKeys = ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(l, theme, totalMinutesThisWeek, totalHeatingMinutesThisWeek, displayMode),
                const SizedBox(height: 20),
                if (displayMode == ActivityDisplayMode.line)
                  _buildFullLineChart(theme, days, minutesPerDay, maxMinutes)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days.map((day) {
                      final totalMins = minutesPerDay[day] ?? 0;
                      final heatingMins = heatingMinutesPerDay[day] ?? 0;
                      final sessionCount = sessionsCountPerDay[day] ?? 0;
                      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                      final dayLabel = l[weekDayKeys[day.weekday - 1]];

                      return Column(
                        children: [
                          _buildValueLabel(totalMins, heatingMins, sessionCount, displayMode),
                          const SizedBox(height: 8),
                          _buildChartElement(theme, totalMins, heatingMins, sessionCount, maxMinutes, maxSessions, isToday, displayMode),
                          const SizedBox(height: 10),
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? theme.colorScheme.primary : theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                if (displayMode != ActivityDisplayMode.totalOnly) ...[
                  const SizedBox(height: 16),
                  _buildLegend(theme, l, displayMode),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l, ThemeData theme, int total, int heating, ActivityDisplayMode mode) {
    IconData getIcon() {
      switch (mode) {
        case ActivityDisplayMode.intensity: return Icons.grid_view_rounded;
        case ActivityDisplayMode.rings: return Icons.donut_large_rounded;
        case ActivityDisplayMode.line: return Icons.show_chart_rounded;
        default: return Icons.bar_chart_rounded;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(getIcon(), color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l['weekly_activity'],
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$total ${l['weekly_total']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface),
            ),
            if ((mode == ActivityDisplayMode.sideBySide || mode == ActivityDisplayMode.stacked) && heating > 0)
              Text(
                '$heating ${l['weekly_heating']}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warmRed),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartElement(
    ThemeData theme, 
    int total, 
    int heating, 
    int sessions,
    int maxMins, 
    int maxSessions,
    bool isToday, 
    ActivityDisplayMode mode
  ) {
    final totalFactor = total > 0 ? (total / maxMins).clamp(0.08, 1.0) : 0.04;
    final heatingFactor = total > 0 ? (heating / total).clamp(0.0, 1.0) : 0.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animVal = _animation.value;
        final height = 80 * totalFactor * animVal.clamp(0.0, 2.0);

        switch (mode) {
          case ActivityDisplayMode.sideBySide:
            final hHeight = 80 * (heating > 0 ? (heating / maxMins).clamp(0.08, 1.0) : 0.04) * animVal.clamp(0.0, 2.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(theme, height, isToday ? theme.colorScheme.primary : theme.colorScheme.secondary, 12, total > 0),
                const SizedBox(width: 2),
                _bar(theme, hHeight, AppColors.warmRed, 12, heating > 0),
              ],
            );
          case ActivityDisplayMode.stacked:
            return Container(
              width: 26,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: total > 0 ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity, 
                    height: height, 
                    color: isToday ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.secondary.withValues(alpha: 0.3)
                  ),
                  if (heating > 0)
                    Container(
                      width: double.infinity,
                      height: height * heatingFactor,
                      decoration: const BoxDecoration(color: AppColors.warmRed),
                    ),
                ],
              ),
            );
          case ActivityDisplayMode.intensity:
            // Intensity based on session count
            final intensity = sessions > 0 ? (sessions / maxSessions).clamp(0.1, 1.0) : 0.0;
            return Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: sessions > 0 
                  ? (isToday ? theme.colorScheme.primary : theme.colorScheme.secondary).withValues(alpha: 0.15 + (intensity * 0.85 * animVal.clamp(0.0, 1.0)))
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
              ),
            );
          case ActivityDisplayMode.rings:
            // Rings based on 60 min daily goal
            final ringFactor = (total / 60.0).clamp(0.0, 1.0);
            return SizedBox(
              width: 30,
              height: 30,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: ringFactor * animVal.clamp(0.0, 1.0),
                  color: isToday ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            );
          case ActivityDisplayMode.totalOnly:
          default:
            return _bar(theme, height, isToday ? theme.colorScheme.primary : theme.colorScheme.secondary, 26, total > 0);
        }
      },
    );
  }

  Widget _buildFullLineChart(ThemeData theme, List<DateTime> days, Map<DateTime, int> data, int max) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 120, 
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              days: days,
              data: data,
              max: max,
              progress: _animation.value.clamp(0.0, 1.0),
              color: theme.colorScheme.primary,
              onSurfaceColor: theme.colorScheme.onSurface,
            ),
          ),
        );
      }
    );
  }

  Widget _bar(ThemeData theme, double h, Color c, double w, bool hasData) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: hasData ? c : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _buildValueLabel(int total, int heating, int sessions, ActivityDisplayMode mode) {
    if (total == 0 && mode != ActivityDisplayMode.intensity) return const SizedBox(height: 14);
    
    return Opacity(
      opacity: _animation.value.clamp(0.0, 1.0),
      child: () {
        if (mode == ActivityDisplayMode.sideBySide) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 12, child: Text('$total', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
              const SizedBox(width: 2),
              SizedBox(width: 12, child: heating > 0 ? Text('$heating', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.warmRed)) : const SizedBox()),
            ],
          );
        } else if (mode == ActivityDisplayMode.intensity) {
          return sessions > 0 ? Text('$sessions', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)) : const SizedBox(height: 14);
        } else {
          return Text('$total', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
        }
      }(),
    );
  }

  Widget _buildLegend(ThemeData theme, AppLocalizations l, ActivityDisplayMode mode) {
    if (mode == ActivityDisplayMode.intensity) {
       return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: theme.colorScheme.secondary.withValues(alpha: 0.3), label: '0'),
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: [
                theme.colorScheme.secondary.withValues(alpha: 0.2),
                theme.colorScheme.secondary,
              ]),
            ),
          ),
          const SizedBox(width: 4),
          _LegendItem(color: Colors.transparent, label: l['sessions_total']),
        ],
      );
    }

    final hasHeating = mode == ActivityDisplayMode.sideBySide || mode == ActivityDisplayMode.stacked;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: mode == ActivityDisplayMode.stacked ? theme.colorScheme.secondary.withValues(alpha: 0.4) : theme.colorScheme.secondary, 
          label: l['activity_mode_total']
        ),
        if (hasHeating) ...[
          const SizedBox(width: 16),
          _LegendItem(color: AppColors.warmRed, label: l['weekly_heating']),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _LineChartPainter extends CustomPainter {
  final List<DateTime> days;
  final Map<DateTime, int> data;
  final int max;
  final double progress;
  final Color color;
  final Color onSurfaceColor;

  _LineChartPainter({
    required this.days, 
    required this.data, 
    required this.max, 
    required this.progress, 
    required this.color,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    
    const double topPadding = 25.0;
    const double bottomPadding = 10.0;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (days.length - 1);
    
    // Grid lines
    final gridPaint = Paint()..color = onSurfaceColor.withValues(alpha: 0.1)..strokeWidth = 1;
    for (int j = 0; j <= 4; j++) {
      final gy = (size.height - bottomPadding) - (chartHeight * (j / 4));
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    for (int i = 0; i < days.length; i++) {
      final val = data[days[i]] ?? 0;
      final x = i * stepX;
      final y = (size.height - bottomPadding) - (chartHeight * (val / max) * progress);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - bottomPadding);
        fillPath.lineTo(x, y);
      } else {
        final prevVal = data[days[i-1]] ?? 0;
        final prevX = (i - 1) * stepX;
        final prevY = (size.height - bottomPadding) - (chartHeight * (prevVal / max) * progress);
        
        path.cubicTo(
          prevX + stepX * 0.4, prevY,
          x - stepX * 0.4, y,
          x, y,
        );
        fillPath.cubicTo(
          prevX + stepX * 0.4, prevY,
          x - stepX * 0.4, y,
          x, y,
        );
      }
      
      if (i == days.length - 1) {
        fillPath.lineTo(x, size.height - bottomPadding);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Points and Labels
    for (int i = 0; i < days.length; i++) {
      final val = data[days[i]] ?? 0;
      final x = i * stepX;
      final y = (size.height - bottomPadding) - (chartHeight * (val / max) * progress);
      
      if (val > 0) {
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = color);

        // Value text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$val',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => 
    oldDelegate.progress != progress || oldDelegate.color != color;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (color != Colors.transparent)
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      if (color != Colors.transparent)
        const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
    ]);
  }
}
