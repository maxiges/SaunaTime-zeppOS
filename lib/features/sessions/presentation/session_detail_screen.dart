import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/calorie_calculator.dart';
import '../domain/models/sauna_phase.dart';
import '../domain/models/sauna_session.dart';
import '../domain/models/sauna_type.dart';
import '../domain/models/session_source.dart';
import 'add_session_screen.dart';
import 'session_controller.dart';
import 'widgets/telemetry_chart.dart';

class SessionDetailScreen extends StatefulWidget {
  final SaunaSession session;
  final SessionController controller;
  final UserProfileController userProfileController;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.controller,
    required this.userProfileController,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late SaunaSession _session;
  CalorieEstimate? calorieEstimate;
  bool _showExactDuration = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _calculateCalories();
  }

  void _calculateCalories() {
    final profile = widget.userProfileController.profile;
    setState(() {
      calorieEstimate = CalorieCalculator.estimateForSession(
        profile: profile,
        session: _session,
      );
    });
  }

  Future<void> _deleteSession() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l['delete_session_title']),
        content: Text(l['delete_session_confirm']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l['cancel']),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warmRed),
            child: Text(l['delete']),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.deleteSession(_session.id);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l['error_deleting_session'])),
          );
        }
      }
    }
  }

  void _showCalorieEstimate() {
    final l = AppLocalizations.of(context);
    final profile = widget.userProfileController.profile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.warmRed,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l['calorie_estimate_title'] ?? 'Szczegóły spalonych kalorii',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCalorieResultCard(context, l),
              const SizedBox(height: 24),
              Text(
                l['calorie_profile_used'] ?? 'Użyty profil:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildProfileSummary(context, l, profile),
              const SizedBox(height: 24),
              Text(
                l['calorie_formula_note_title'] ?? 'O kalkulacji',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l['calorie_formula_note_desc'] ?? 'Obliczenia opierają się na formule Keytela, biorąc pod uwagę tętno, wiek, wagę oraz płeć.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieResultCard(BuildContext context, AppLocalizations l) {
    final estimate = calorieEstimate;
    if (estimate == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warmRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${estimate.caloriesRounded}',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warmRed,
            ),
          ),
          Text(
            'kcal',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.warmRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMetric(
                l['calorie_per_min'] ?? 'kcal/min',
                '${estimate.perMinuteRounded} kcal',
              ),
              _buildSmallMetric(
                l['details_duration'],
                '${_session.durationMinutes} min',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileSummary(
    BuildContext context,
    AppLocalizations l,
    dynamic profile,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.4,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l['profile_sex']),
                Text(
                  profile.isMale ? l['profile_male'] : l['profile_female'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l['profile_weight']),
                Text(
                  '${profile.weightKg} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l['profile_age']),
                Text(
                  '${profile.ageYears} ${l['profile_age_unit']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final endTime =
        _session.endTime ??
        _session.startTime.add(Duration(minutes: _session.durationMinutes));

    final diff = endTime.difference(_session.startTime);
    final displayMins = diff.inMinutes;
    final displaySecs = diff.inSeconds % 60;
    
    final durationText = _showExactDuration 
        ? '$displayMins ${l['minutes_abbr']} $displaySecs ${l['seconds_abbr']}'
        : '${_session.durationMinutes} ${l['minutes_abbr']}';

    final allPhases = _collectPhases();
    final temperatureKind = classifyTemperature(_session.temperature);
    final estimate = calorieEstimate;

    // Split components for layout
    final basicInfoCard = Hero(
      tag: 'session_card_${_session.id}',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _session.source == SessionSource.watchHttp ? Icons.watch_rounded : Icons.edit_calendar_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFormat.format(_session.startTime),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(l.sourceLabel(_session.source),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: _session.source == SessionSource.watchHttp
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => setState(() => _showExactDuration = !_showExactDuration),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: _buildMetricTile(context, icon: Icons.timer_outlined, label: l['details_duration'],
                          value: durationText, color: theme.colorScheme.primary),
                    ),
                  ),
                  _buildMetricTile(context, icon: _session.saunaType == SaunaType.steam ? Icons.cloud_outlined : Icons.wb_sunny_outlined,
                      label: l['session_sauna_type'], value: _session.saunaType == SaunaType.steam ? l['sauna_type_steam'] : l['sauna_type_dry'],
                      color: theme.colorScheme.secondary),
                  _buildMetricTile(context, icon: Icons.access_time_rounded, label: l['details_time_range'],
                      value: '${timeFormat.format(_session.startTime)} - ${timeFormat.format(endTime)}', color: theme.colorScheme.tertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final measurementsSection = Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildValueCard(l, Icons.thermostat_outlined, Colors.deepOrange, 
                temperatureKind == TemperatureKind.sauna ? l['temp_kind_sauna'] : (temperatureKind == TemperatureKind.body ? l['temp_kind_body'] : l['details_temperature']),
                _session.temperature != null ? '${_session.temperature!.toStringAsFixed(1)} °C' : l['no_measurement'])),
            const SizedBox(width: 8),
            Expanded(child: _buildValueCard(l, Icons.favorite_rounded, AppColors.warmRed, l['details_avg_hr'],
                _session.averageHeartRate != null ? '${_session.averageHeartRate} ${l['bpm_abbr']}' : l['no_measurement'])),
          ],
        ),
        if (_session.maxHeartRate != null) ...[
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.speed_rounded, color: AppColors.warmRed, size: 20),
              title: Text(l['details_max_hr'], style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              trailing: Text('${_session.maxHeartRate} ${l['bpm_abbr']}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warmRed)),
            ),
          ),
        ],
      ],
    );

    final caloriesCard = Card(
      elevation: 1,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showCalorieEstimate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: AppColors.warmRed, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['calorie_button'], style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (estimate != null) ...[
                      Text('≈ ${estimate.caloriesRounded} kcal',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warmRed)),
                    ] else
                      Text(l['calorie_need_hr'], style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );

    final notesSection = (_session.notes != null && _session.notes!.isNotEmpty)
        ? Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(l['details_notes'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_session.notes!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l['details_title']),
        centerTitle: true,
        toolbarHeight: isLandscape ? 40 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSessionScreen(
                    existingSession: _session,
                    controller: widget.controller,
                    userProfileController: widget.userProfileController,
                  ),
                ),
              );
              if (result is SaunaSession) {
                setState(() {
                  _session = result;
                  _calculateCalories();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteSession,
          ),
        ],
      ),
      body: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Information
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      basicInfoCard,
                      const SizedBox(height: 8),
                      measurementsSection,
                      const SizedBox(height: 8),
                      caloriesCard,
                      const SizedBox(height: 8),
                      notesSection,
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right Column: Phases and Charts
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (allPhases.isNotEmpty) ...[
                        _buildPhasesCard(context, allPhases),
                        const SizedBox(height: 12),
                      ],
                      _buildTelemetrySection(context, allPhases),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                basicInfoCard,
                const SizedBox(height: 16),
                measurementsSection,
                const SizedBox(height: 16),
                caloriesCard,
                const SizedBox(height: 16),
                notesSection,
                const SizedBox(height: 16),
                if (allPhases.isNotEmpty) ...[
                  _buildPhasesCard(context, allPhases),
                  const SizedBox(height: 16),
                ],
                _buildTelemetrySection(context, allPhases),
              ],
            ),
    );
  }

  Widget _buildValueCard(AppLocalizations l, IconData icon, Color color, String label, String value) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildTelemetrySection(BuildContext context, List<SaunaPhase> allPhases) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final hasHeartData = _session.heartRateSamples.isNotEmpty;
    final hasTempData = _session.temperatureSamples.isNotEmpty;
    final phaseNames = {for (final phase in allPhases) phase: l.phaseLabel(phase)};

    if (!hasHeartData && !hasTempData) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.query_stats_rounded, size: 36, color: theme.colorScheme.outline),
              const SizedBox(height: 8),
              Text(l['no_telemetry_title'], style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(l['no_telemetry_desc'], textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (hasHeartData)
          TelemetryChart(
            title: l['chart_hr_title'],
            unit: 'bpm',
            samples: _session.heartRateSamples,
            lineColor: AppColors.warmRed,
            icon: Icons.favorite_rounded,
            phaseNames: phaseNames,
          ),
        if (hasHeartData && hasTempData) const SizedBox(height: 12),
        if (hasTempData)
          TelemetryChart(
            title: l['chart_temp_title'],
            unit: '°C',
            samples: _session.temperatureSamples,
            lineColor: Colors.deepOrange,
            icon: Icons.thermostat_rounded,
            phaseNames: phaseNames,
          ),
      ],
    );
  }

  List<SaunaPhase> _collectPhases() {
    final phases = <SaunaPhase>[..._session.phases];
    for (final sample in _session.heartRateSamples) {
      if (sample.phase != null && !phases.contains(sample.phase)) phases.add(sample.phase!);
    }
    for (final sample in _session.temperatureSamples) {
      if (sample.phase != null && !phases.contains(sample.phase)) phases.add(sample.phase!);
    }
    return phases;
  }

  Widget _buildPhasesCard(BuildContext context, List<SaunaPhase> phases) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stacked_line_chart_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(localizations['phases_label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: phases.map((phase) => _buildPhaseChip(context, localizations, phase)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseChip(BuildContext context, AppLocalizations l, SaunaPhase phase) {
    final duration = _session.durationForPhase(phase);
    final label = l.phaseLabel(phase);
    final displayText = duration != null ? '$label ($duration ${l['minutes_abbr']})' : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: phase.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: phase.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: phase.color, radius: 4),
          const SizedBox(width: 6),
          Text(displayText, style: TextStyle(color: phase.color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
