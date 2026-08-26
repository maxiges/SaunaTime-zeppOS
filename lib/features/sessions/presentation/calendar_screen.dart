import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/calorie_calculator.dart';
import '../domain/models/sauna_session.dart';
import 'session_controller.dart';
import 'widgets/session_card.dart';

class CalendarScreen extends StatefulWidget {
  final SessionController controller;
  final UserProfileController userProfileController;
  final Function(SaunaSession)? onSessionTap;

  const CalendarScreen({
    super.key,
    required this.controller,
    required this.userProfileController,
    this.onSessionTap,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isRangeMode = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    // Select today by default
    _rangeStart = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDateInRange(DateTime date) {
    if (_rangeStart == null) return false;
    if (_rangeEnd == null) return _isSameDay(date, _rangeStart!);

    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    final e = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);

    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  List<SaunaSession> _getSessionsForSelection(List<SaunaSession> allSessions) {
    if (_rangeStart == null) return [];

    final s = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    if (_rangeEnd == null) {
      return allSessions
          .where((sess) => _isSameDay(sess.startTime, s))
          .toList();
    }

    final e = DateTime(
      _rangeEnd!.year,
      _rangeEnd!.month,
      _rangeEnd!.day,
      23,
      59,
      59,
    );
    return allSessions
        .where(
          (sess) =>
              sess.startTime.isAfter(s.subtract(const Duration(seconds: 1))) &&
              sess.startTime.isBefore(e.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  int _countSelectedDays() {
    if (_rangeStart == null) return 0;
    if (_rangeEnd == null) return 1;
    return _rangeEnd!.difference(_rangeStart!).inDays.abs() + 1;
  }

  Set<int> _getDaysWithSessionsInMonth(
    List<SaunaSession> allSessions,
    DateTime month,
  ) {
    final days = <int>{};
    for (final s in allSessions) {
      if (s.startTime.year == month.year && s.startTime.month == month.month) {
        days.add(s.startTime.day);
      }
    }
    return days;
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (!_isRangeMode) {
        if (_rangeStart != null &&
            _isSameDay(day, _rangeStart!) &&
            _rangeEnd == null) {
          _rangeStart = null;
        } else {
          _rangeStart = day;
          _rangeEnd = null;
        }
      } else {
        if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
          _rangeStart = day;
          _rangeEnd = null;
        } else if (_rangeStart != null && _rangeEnd == null) {
          if (day.isBefore(_rangeStart!)) {
            _rangeStart = day;
          } else if (day.isAfter(_rangeStart!)) {
            _rangeEnd = day;
          } else {
            _rangeStart = null;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final monthFormat = DateFormat.yMMMM(l.locale.languageCode);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.userProfileController,
      ]),
      builder: (context, _) {
        final allSessions = widget.controller.sessions;
        final selectedSessions = _getSessionsForSelection(allSessions);
        final daysWithSessions = _getDaysWithSessionsInMonth(
          allSessions,
          _displayedMonth,
        );
        final totalMinutes = selectedSessions.fold<int>(
          0,
          (sum, s) => sum + s.durationMinutes,
        );
        final selectedDaysCount = _countSelectedDays();

        double totalCalories = 0;
        final profile = widget.userProfileController.profile;
        for (final session in selectedSessions) {
          final est = CalorieCalculator.estimateForSession(
            profile: profile,
            session: session,
          );
          if (est != null) totalCalories += est.calories;
        }

        final calendarCard = Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallNavButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => setState(
                        () => _displayedMonth = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month - 1,
                          1,
                        ),
                      ),
                    ),
                    Text(
                      monthFormat.format(_displayedMonth),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _SmallNavButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: () => setState(
                        () => _displayedMonth = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month + 1,
                          1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 12, endIndent: 12),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeekDayLabel(l['day_mon']),
                        _WeekDayLabel(l['day_tue']),
                        _WeekDayLabel(l['day_wed']),
                        _WeekDayLabel(l['day_thu']),
                        _WeekDayLabel(l['day_fri']),
                        _WeekDayLabel(l['day_sat']),
                        _WeekDayLabel(l['day_sun']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildMonthGrid(daysWithSessions),
                  ],
                ),
              ),
            ],
          ),
        );

        final statStrip = _rangeStart != null
            ? _StatStrip(
                days: selectedDaysCount,
                sessions: selectedSessions.length,
                minutes: totalMinutes,
                calories: totalCalories.round(),
                isCompact: isLandscape,
              )
            : const SizedBox.shrink();

        final sessionsList = selectedSessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    _rangeStart == null
                        ? (l['calendar_no_selection'] ?? 'Wybierz datę')
                        : l['calendar_no_sessions'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: selectedSessions.map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1.0),
                    child: SessionCard(
                      session: session,
                      onTap: () {
                        if (widget.onSessionTap != null) {
                          widget.onSessionTap!(session);
                        }
                      },
                    ),
                  );
                }).toList(),
              );

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(l['calendar_title']),
            centerTitle: true,
            toolbarHeight: isLandscape ? 40 : null,
            actions: [
              IconButton(
                icon: Icon(
                  _isRangeMode ? Icons.date_range_rounded : Icons.today_rounded,
                  size: 22,
                ),
                onPressed: () => setState(() {
                  _isRangeMode = !_isRangeMode;
                  if (!_isRangeMode && _rangeEnd != null) _rangeEnd = null;
                }),
                tooltip: _isRangeMode
                    ? l['calendar_mode_range']
                    : l['calendar_mode_single'],
              ),
              if (_rangeStart != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: () => setState(() {
                    _rangeStart = null;
                    _rangeEnd = null;
                  }),
                ),
            ],
          ),
          body: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            calendarCard,
                            const SizedBox(height: 12),
                            statStrip,
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [sessionsList],
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                  children: [
                    calendarCard,
                    const SizedBox(height: 10),
                    statStrip,
                    const SizedBox(height: 8),
                    sessionsList,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMonthGrid(Set<int> daysWithSessions) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday;

    final paddingDays = firstWeekday - 1;
    final totalCells = ((daysInMonth + paddingDays + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.25,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayOffset = index - paddingDays;
        final dayNumber = dayOffset + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          dayNumber,
        );
        final isToday = _isSameDay(cellDate, today);
        final hasSession = daysWithSessions.contains(dayNumber);

        final isRangeStart =
            _rangeStart != null && _isSameDay(cellDate, _rangeStart!);
        final isRangeEnd =
            _rangeEnd != null && _isSameDay(cellDate, _rangeEnd!);
        final isInRange = _isDateInRange(cellDate);

        BorderRadius borderRadius = BorderRadius.circular(8);
        if (_isRangeMode && _rangeEnd != null && isInRange) {
          if (isRangeStart) {
            borderRadius = const BorderRadius.horizontal(
              left: Radius.circular(8),
            );
          } else if (isRangeEnd) {
            borderRadius = const BorderRadius.horizontal(
              right: Radius.circular(8),
            );
          } else {
            borderRadius = BorderRadius.zero;
          }
        }

        Color? bgColor;
        if (isRangeStart || isRangeEnd) {
          bgColor = theme.colorScheme.primary;
        } else if (_isRangeMode && isInRange) {
          bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        } else if (isToday) {
          bgColor = theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.2,
          );
        }

        final textColor = (isRangeStart || isRangeEnd)
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

        return InkWell(
          onTap: () => _onDayTap(cellDate),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: 2,
              horizontal: (_isRangeMode && isInRange && _rangeEnd != null)
                  ? 0
                  : 2,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: isToday && !isRangeStart && !isRangeEnd
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: (isRangeStart || isRangeEnd || isToday)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
                if (hasSession)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: (isRangeStart || isRangeEnd)
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SmallNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _SmallNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  final String label;
  const _WeekDayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 8,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  final int days;
  final int sessions;
  final int minutes;
  final int calories;
  final bool isCompact;

  const _StatStrip({
    required this.days,
    required this.sessions,
    required this.minutes,
    required this.calories,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: isCompact
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CompactStatItem(
                      icon: Icons.calendar_today_rounded,
                      value: '$days',
                      label: 'dni',
                      color: theme.colorScheme.primary,
                    ),
                    _CompactStatItem(
                      icon: Icons.hot_tub_rounded,
                      value: '$sessions',
                      label: 'sesji',
                      color: AppColors.warmOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CompactStatItem(
                      icon: Icons.timer_outlined,
                      value: '$minutes',
                      label: 'min',
                      color: Colors.indigo,
                    ),
                    _CompactStatItem(
                      icon: Icons.local_fire_department_rounded,
                      value: '$calories',
                      label: 'kcal',
                      color: AppColors.warmRed,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CompactStatItem(
                  icon: Icons.calendar_today_rounded,
                  value: '$days',
                  label: 'dni',
                  color: theme.colorScheme.primary,
                ),
                _CompactStatItem(
                  icon: Icons.hot_tub_rounded,
                  value: '$sessions',
                  label: 'sesji',
                  color: AppColors.warmOrange,
                ),
                _CompactStatItem(
                  icon: Icons.timer_outlined,
                  value: '$minutes',
                  label: 'min',
                  color: Colors.indigo,
                ),
                _CompactStatItem(
                  icon: Icons.local_fire_department_rounded,
                  value: '$calories',
                  label: 'kcal',
                  color: AppColors.warmRed,
                ),
              ],
            ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                height: 0.9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySessionsState extends StatelessWidget {
  final String message;
  const _EmptySessionsState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant
                .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
