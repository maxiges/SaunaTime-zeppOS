import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models/measurement_sample.dart';
import '../domain/models/sauna_session.dart';
import '../domain/models/sauna_type.dart';
import '../domain/models/session_source.dart';
import 'session_controller.dart';

class AddSessionScreen extends StatefulWidget {
  final SessionController controller;
  final UserProfileController userProfileController;
  final SaunaSession? existingSession;

  const AddSessionScreen({
    super.key,
    required this.controller,
    required this.userProfileController,
    this.existingSession,
  });

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _durationController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _avgHrController;
  late final TextEditingController _minHrController;
  late final TextEditingController _maxHrController;
  late final TextEditingController _notesController;
  late SaunaType _selectedSaunaType;

  bool _isSubmitting = false;

  bool get _isWatchSession =>
      widget.existingSession?.source == SessionSource.watchHttp;

  @override
  void initState() {
    super.initState();
    final session = widget.existingSession;
    if (session != null) {
      _selectedDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(session.startTime);
      _durationController = TextEditingController(
        text: '${session.durationMinutes}',
      );
      _temperatureController = TextEditingController(
        text: session.temperature != null ? '${session.temperature}' : '',
      );
      _avgHrController = TextEditingController(
        text: session.averageHeartRate != null
            ? '${session.averageHeartRate}'
            : '',
      );
      _minHrController = TextEditingController(
        text: _minHrFromSamples(session.heartRateSamples),
      );
      _maxHrController = TextEditingController(
        text: session.maxHeartRate != null ? '${session.maxHeartRate}' : '',
      );
      _notesController = TextEditingController(text: session.notes ?? '');
      _selectedSaunaType = session.saunaType;
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.fromDateTime(now);
      _durationController = TextEditingController(text: '15');
      _temperatureController = TextEditingController();
      _avgHrController = TextEditingController();
      _minHrController = TextEditingController();
      _maxHrController = TextEditingController();
      _notesController = TextEditingController();
      _selectedSaunaType = widget.userProfileController.profile.preferredSaunaType;
    }
  }

  String _minHrFromSamples(List<MeasurementSample> samples) {
    if (samples.isEmpty) return '';
    var min = samples.first.value;
    for (final s in samples) {
      if (s.value < min) min = s.value;
    }
    return min.round().toString();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _temperatureController.dispose();
    _avgHrController.dispose();
    _minHrController.dispose();
    _maxHrController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
    });

    final duration = int.parse(_durationController.text.trim());
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final bool isWatch =
        widget.existingSession?.source == SessionSource.watchHttp;
    final existing = widget.existingSession;

    final temperature = isWatch
        ? existing?.temperature
        : _temperatureController.text.trim().isNotEmpty
        ? double.tryParse(_temperatureController.text.trim())
        : null;

    int? avgHr;
    int? minHr;
    int? maxHr;
    if (isWatch) {
      avgHr = existing?.averageHeartRate;
      maxHr = existing?.maxHeartRate;
    } else {
      avgHr = _avgHrController.text.trim().isNotEmpty
          ? int.tryParse(_avgHrController.text.trim())
          : null;
      minHr = _minHrController.text.trim().isNotEmpty
          ? int.tryParse(_minHrController.text.trim())
          : null;
      maxHr = _maxHrController.text.trim().isNotEmpty
          ? int.tryParse(_maxHrController.text.trim())
          : null;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    List<MeasurementSample> heartRateSamples = const [];
    if (isWatch) {
      heartRateSamples = existing?.heartRateSamples ?? const [];
    } else if (minHr != null && maxHr != null) {
      heartRateSamples = _generateLinearHrSamples(
        minHr: minHr,
        maxHr: maxHr,
        start: startDateTime,
        durationMinutes: duration,
      );
      avgHr ??= ((minHr + maxHr) / 2).round();
    }

    final SaunaSession sessionToSave;
    if (widget.existingSession != null) {
      sessionToSave = widget.existingSession!.copyWith(
        startTime: startDateTime,
        endTime: startDateTime.add(Duration(minutes: duration)),
        durationMinutes: duration,
        temperature: temperature,
        averageHeartRate: avgHr,
        maxHeartRate: maxHr,
        heartRateSamples: heartRateSamples,
        notes: notes,
        saunaType: _selectedSaunaType,
      );
    } else {
      sessionToSave = SaunaSession(
        id: const Uuid().v4(),
        startTime: startDateTime,
        endTime: startDateTime.add(Duration(minutes: duration)),
        durationMinutes: duration,
        source: SessionSource.manual,
        temperature: temperature,
        averageHeartRate: avgHr,
        maxHeartRate: maxHr,
        heartRateSamples: heartRateSamples,
        notes: notes,
        saunaType: _selectedSaunaType,
      );
    }

    final success = await widget.controller.addSession(sessionToSave);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingSession != null
                  ? l['session_updated_saved']
                  : l['session_saved'],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(sessionToSave);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l['error_saving_session']),
            backgroundColor: AppColors.warmRed,
          ),
        );
      }
    }
  }

  List<MeasurementSample> _generateLinearHrSamples({
    required int minHr,
    required int maxHr,
    required DateTime start,
    required int durationMinutes,
  }) {
    const count = 12;
    final end = start.add(Duration(minutes: durationMinutes));
    final totalMs = end.difference(start).inMilliseconds;
    return List.generate(count, (i) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final value = minHr + (maxHr - minHr) * t;
      return MeasurementSample(
        timestamp: start.add(Duration(milliseconds: (totalMs * t).round())),
        value: value.toDouble(),
      );
    });
  }

  String? _validateHr(String? value, {bool isMin = false, bool isMax = false}) {
    if (_isWatchSession) return null;
    final l = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      final otherFilled = isMin
          ? _maxHrController.text.trim().isNotEmpty
          : isMax
              ? _minHrController.text.trim().isNotEmpty
              : false;
      if (otherFilled) return l['error_hr_min_max_both'];
      return null;
    }
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 30 || parsed > 250) {
      return l['error_hr_range'];
    }
    if (isMin && _maxHrController.text.trim().isEmpty) {
      return l['error_hr_min_max_both'];
    }
    if (isMax && _minHrController.text.trim().isEmpty) {
      return l['error_hr_min_max_both'];
    }
    if (isMin) {
      final maxV = int.tryParse(_maxHrController.text.trim());
      if (maxV != null && parsed >= maxV) return l['error_hr_min_max_order'];
    }
    if (isMax) {
      final minV = int.tryParse(_minHrController.text.trim());
      if (minV != null && parsed <= minV) return l['error_hr_min_max_order'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEditing = widget.existingSession != null;
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final saveButton = FilledButton.icon(
      onPressed: _isSubmitting ? null : _saveSession,
      icon: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check_rounded),
      label: Text(
        _isSubmitting ? l['saving'] : (isEditing ? l['save_changes'] : l['save_session']),
        style: const TextStyle(fontSize: 16),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l[isEditing ? 'edit_session' : 'add_session_title']),
        actions: isLandscape ? [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSubmitting ? null : _saveSession,
              icon: const Icon(Icons.check_rounded),
              label: Text(l['save_session']),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
            ),
          ),
        ] : null,
      ),
      body: Form(
        key: _formKey,
        child: isLandscape 
          ? Row(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: _buildFormFields(l, theme, true),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: _buildFormFields(l, theme, false),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildFormFields(l, theme, true),
                  ..._buildFormFields(l, theme, false),
                  const SizedBox(height: 24),
                  saveButton,
                ],
              ),
            ),
      ),
    );
  }

  List<Widget> _buildFormFields(AppLocalizations l, ThemeData theme, bool firstPart) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    if (firstPart) {
      return [
        if (_isWatchSession) ...[
          _buildWatchLockNote(l, theme),
          const SizedBox(height: 20),
        ],
        _buildDateTimeCard(l, theme, dateFormat),
        const SizedBox(height: 20),
        Text(l['session_sauna_type'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        SegmentedButton<SaunaType>(
          segments: [
            ButtonSegment(value: SaunaType.dry, label: Text(l['sauna_type_dry']), icon: const Icon(Icons.wb_sunny_outlined)),
            ButtonSegment(value: SaunaType.steam, label: Text(l['sauna_type_steam']), icon: const Icon(Icons.cloud_outlined)),
          ],
          selected: {_selectedSaunaType},
          onSelectionChanged: (selection) => setState(() => _selectedSaunaType = selection.first),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l['duration_minutes'],
            hintText: l['duration_hint'],
            prefixIcon: const Icon(Icons.timer_outlined),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return l['error_duration_required'];
            final parsed = int.tryParse(value.trim());
            if (parsed == null || parsed <= 0) return l['error_duration_positive'];
            return null;
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [10, 15, 20, 30].map((mins) => ActionChip(
            label: Text('$mins min'),
            onPressed: () => _durationController.text = mins.toString(),
          )).toList(),
        ),
      ];
    } else {
      return [
        TextFormField(
          controller: _temperatureController,
          enabled: !_isWatchSession,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l['temperature_label'],
            hintText: l['temperature_hint'],
            prefixIcon: const Icon(Icons.thermostat_outlined),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (_isWatchSession) return null;
            if (value != null && value.trim().isNotEmpty) {
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed <= 0 || parsed > 140) return l['error_temperature_range'];
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Text(l['add_hr_section'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(l['hr_linear_hint'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _avgHrController,
          enabled: !_isWatchSession,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l['avg_hr_label'],
            hintText: l['bpm_abbr'],
            prefixIcon: const Icon(Icons.favorite_outline),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => _validateHr(value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minHrController,
                enabled: !_isWatchSession,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l['min_hr_label'],
                  prefixIcon: const Icon(Icons.trending_up_rounded),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => _validateHr(value, isMin: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _maxHrController,
                enabled: !_isWatchSession,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l['max_hr_label'],
                  prefixIcon: const Icon(Icons.trending_up_rounded),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => _validateHr(value, isMax: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l['notes_label'],
            hintText: l['notes_hint'],
            prefixIcon: const Icon(Icons.notes_rounded),
            border: const OutlineInputBorder(),
          ),
        ),
      ];
    }
  }

  Widget _buildWatchLockNote(AppLocalizations l, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(l['watch_edit_locked_note'], style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(AppLocalizations l, ThemeData theme, DateFormat dateFormat) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildPickerRow(l['session_date'], dateFormat.format(_selectedDate), _pickDate),
            const Divider(height: 16),
            _buildPickerRow(l['start_time'], _selectedTime.format(context), _pickTime),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(AppLocalizations.of(context)['change'])),
      ],
    );
  }
}
