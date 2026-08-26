import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/sauna_phase.dart';
import '../../domain/models/sauna_session.dart';
import '../../domain/models/sauna_type.dart';
import '../../domain/models/session_source.dart';

class SessionCard extends StatelessWidget {
  final SaunaSession session;
  final VoidCallback? onTap;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');

    final heatingMin = session.heatingDurationMinutes;
    final hasMultiplePhases = session.phases.length > 1;
    final showHeating = hasMultiplePhases && heatingMin != null;

    // Use theme card color or fallback to surface container with transparency
    final cardColor = theme.cardTheme.color ??
                      theme.colorScheme.surfaceContainer.withValues(alpha: 0.9);

    return Hero(
      tag: 'session_card_${session.id}',
      child: Container(
        margin: EdgeInsets.only(bottom: 5.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dateFormat.format(session.startTime),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              timeFormat.format(session.startTime),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDurationDisplay(context, l, showHeating, heatingMin),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),

                  // --- Metrics ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (session.temperature != null)
                        _MetricItem(
                          icon: Icons.thermostat_rounded,
                          value: '${session.temperature!.toStringAsFixed(0)}°',
                          color: Colors.orange,
                          label: l['details_temperature'],
                        ),
                      if (session.averageHeartRate != null)
                        _MetricItem(
                          icon: Icons.favorite_rounded,
                          value: '${session.averageHeartRate}',
                          color: AppColors.warmRed,
                          label: l['avg_abbr'],
                        ),
                      if (session.maxHeartRate != null)
                        _MetricItem(
                          icon: Icons.bolt_rounded,
                          value: '${session.maxHeartRate}',
                          color: AppColors.warmRed.withValues(alpha: 0.6),
                          label: 'MAX',
                          isSmall: true,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // --- Footer ---
                  Row(
                    children: [
                      _buildTypeBadge(context, l),
                      const SizedBox(width: 8),
                      if (session.source == SessionSource.watchHttp)
                        _buildSourceBadge(context, l),
                      if (session.notes != null && session.notes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.notes!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationDisplay(BuildContext context, AppLocalizations l, bool showHeating, int? heatingMin) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeating) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.phaseLabel(SaunaPhase.heating).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.warmRed)),
                Text('$heatingMin min',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warmRed)),
              ],
            ),
            const SizedBox(width: 6),
            Container(height: 14, width: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TOTAL', style: theme.textTheme.labelSmall?.copyWith(fontSize: 7, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              Text('${session.durationMinutes} min', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final isSteam = session.saunaType == SaunaType.steam;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSteam ? Icons.cloud_outlined : Icons.wb_sunny_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(isSteam ? l['sauna_type_steam'] : l['sauna_type_dry'],
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.watch_rounded, size: 12, color: theme.colorScheme.secondary),
          const SizedBox(width: 4),
          Text('WATCH', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, fontSize: 8)),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isSmall;

  const _MetricItem({required this.icon, required this.value, required this.label, required this.color, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isSmall ? 14 : 18, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.1)),
                ),
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
