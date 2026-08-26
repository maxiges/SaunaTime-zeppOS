import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../http_server/services/http_server_service.dart';
import '../../sessions/domain/models/measurement_sample.dart';
import '../../sessions/domain/models/sauna_phase.dart';

class HttpServerScreen extends StatefulWidget {
  final LocalHttpServerService serverService;

  const HttpServerScreen({super.key, required this.serverService});

  @override
  State<HttpServerScreen> createState() => _HttpServerScreenState();
}

class _HttpServerScreenState extends State<HttpServerScreen> {
  /// Number of sauna phases to generate in the simulation (1 to 3).
  int _phaseCount = 3;

  LocalHttpServerService get serverService => widget.serverService;

  Future<void> _sendSimulatedWatchSession(BuildContext context) async {
    final random = math.Random();
    final now = DateTime.now();

    // Phases: heating, cooling, resting (always in this order).
    final phases = SaunaPhase.values.take(_phaseCount).toList();

    // Random phase durations (minutes).
    final durations = <int>[];
    for (final phase in phases) {
      switch (phase) {
        case SaunaPhase.heating:
          durations.add(8 + random.nextInt(12)); // 8-19 min
          break;
        case SaunaPhase.cooling:
          durations.add(2 + random.nextInt(6)); // 2-7 min
          break;
        case SaunaPhase.resting:
          durations.add(5 + random.nextInt(10)); // 5-14 min
          break;
      }
    }

    final totalMinutes = durations.fold<int>(0, (a, b) => a + b);
    final boundaries = <int>[];
    var accumulated = 0;
    for (final duration in durations) {
      accumulated += duration;
      boundaries.add(accumulated);
    }

    // Start and end parameters for each phase (for continuity and realism).
    final phaseConfigs =
        <SaunaPhase, ({double sHr, double eHr, double sT, double eT})>{};
    var currentHr = 68.0 + random.nextInt(12);
    var currentTemp = 72.0 + random.nextInt(8);

    for (final phase in phases) {
      double endHr;
      double endTemp;
      switch (phase) {
        case SaunaPhase.heating:
          endHr = 125.0 + random.nextInt(35); // 125-159
          endTemp = 85.0 + random.nextInt(20); // 85-104
          break;
        case SaunaPhase.cooling:
          endHr = 90.0 + random.nextInt(15); // 90-104
          endTemp = 78.0 + random.nextInt(8); // 78-85
          break;
        case SaunaPhase.resting:
          endHr = 70.0 + random.nextInt(12); // 70-81
          endTemp = 74.0 + random.nextInt(6); // 74-79
          break;
      }
      phaseConfigs[phase] = (
        sHr: currentHr,
        eHr: endHr,
        sT: currentTemp,
        eT: endTemp,
      );
      currentHr = endHr;
      currentTemp = endTemp;
    }

    SaunaPhase phaseAt(double minutes) {
      for (var i = 0; i < boundaries.length; i++) {
        if (minutes < boundaries[i]) return phases[i];
      }
      return phases.last;
    }

    double generateValue(double mfs, SaunaPhase phase, bool isHr) {
      final idx = phases.indexOf(phase);
      final start = idx == 0 ? 0.0 : boundaries[idx - 1].toDouble();
      final end = boundaries[idx].toDouble();
      final progress = (mfs - start) / math.max(1.0, end - start);

      final cfg = phaseConfigs[phase]!;
      final startVal = isHr ? cfg.sHr : cfg.sT;
      final endVal = isHr ? cfg.eHr : cfg.eT;

      final linear = startVal + (endVal - startVal) * progress;
      final noise = (random.nextDouble() - 0.5) * (isHr ? 4.0 : 1.2);
      return linear + noise;
    }

    final hrSamples = <MeasurementSample>[];
    // Heart rate samples every 30 seconds for a nicer chart.
    for (var i = 0; i <= totalMinutes * 60; i += 30) {
      final mfs = i / 60.0;
      final phase = phaseAt(mfs);
      hrSamples.add(
        MeasurementSample(
          timestamp: now.subtract(Duration(seconds: totalMinutes * 60 - i)),
          value: generateValue(mfs, phase, true),
          phase: phase,
        ),
      );
    }

    final tempSamples = <MeasurementSample>[];
    // Temperature samples every 1 minute.
    for (var i = 0; i <= totalMinutes * 60; i += 60) {
      final mfs = i / 60.0;
      final phase = phaseAt(mfs);
      tempSamples.add(
        MeasurementSample(
          timestamp: now.subtract(Duration(seconds: totalMinutes * 60 - i)),
          value: generateValue(mfs, phase, false),
          phase: phase,
        ),
      );
    }

    final avgHr =
        hrSamples.map((s) => s.value).reduce((a, b) => a + b) /
        hrSamples.length;
    final maxHr = hrSamples.map((s) => s.value).reduce(math.max).round();
    final maxTemp = tempSamples.map((s) => s.value).reduce(math.max);

    final startEpoch =
        now.subtract(Duration(minutes: totalMinutes)).millisecondsSinceEpoch ~/
        1000;
    final endEpoch = now.millisecondsSinceEpoch ~/ 1000;

    final payload = <String, dynamic>{
      'startTime': startEpoch,
      'endTime': endEpoch,
      'durationMinutes': totalMinutes,
      'temperature': maxTemp.roundToDouble(),
      'averageHeartRate': avgHr.round(),
      'maxHeartRate': maxHr,
      'phases': [for (final phase in phases) phase.code],
      'heartRateSamples': [
        for (final sample in hrSamples)
          {
            'timestamp': sample.timestamp.millisecondsSinceEpoch ~/ 1000,
            'value': sample.value,
            'phase': sample.phase?.code ?? 1,
          },
      ],
      'temperatureSamples': [
        for (final sample in tempSamples)
          {
            'timestamp': sample.timestamp.millisecondsSinceEpoch ~/ 1000,
            'value': sample.value,
            'phase': sample.phase?.code ?? 1,
          },
      ],
    };

    final success = await _deliverWatchPayload(payload);

    if (context.mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l.watchSessionImported(_phaseCount)
                : l['watch_session_failed'],
          ),
          backgroundColor: success ? Colors.green : AppColors.warmRed,
        ),
      );
    }
  }

  /// Sends the payload through the local HTTP server (full pipeline) or — when the server
  /// is stopped — parses it directly and saves the session.
  Future<bool> _deliverWatchPayload(Map<String, dynamic> payload) async {
    if (serverService.isRunning) {
      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:${serverService.port}/api/sessions'),
        );
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (_) {
        return false;
      } finally {
        client.close();
      }
    }

    final session = serverService.parseWatchPayload(payload);
    // Duplicate protection — the same session cannot be added twice,
    // even when the HTTP server is stopped (direct pipeline).
    if (await serverService.hasDuplicate(session)) {
      return true; // already exists — treat as success (idempotently)
    }
    return serverService.sessionController.addSession(session);
  }

  Future<void> _changePort(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final portController = TextEditingController(text: '${serverService.port}');
    final newPort = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['server_change_port_title']),
        content: TextField(
          controller: portController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l['server_port_number'],
            hintText: l['server_port_hint'],
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l['cancel']),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(portController.text.trim());
              if (parsed != null && parsed > 1024 && parsed < 65535) {
                Navigator.of(ctx).pop(parsed);
              }
            },
            child: Text(l['server_change_and_restart']),
          ),
        ],
      ),
    );

    if (newPort != null && context.mounted) {
      await serverService.stopServer();
      await serverService.startServer(port: newPort);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.serverRestarted(newPort))));
      }
    }
  }

  Future<void> _copyCurlCommand(BuildContext context) async {
    final port = serverService.port;
    final curlCmd =
        'curl -X POST http://localhost:$port/api/sessions -H "Content-Type: application/json" -d \'{"durationMinutes": 15, "temperature": 85.0, "averageHeartRate": 110, "notes": "Test curl"}\'';
    await Clipboard.setData(ClipboardData(text: curlCmd));

    if (context.mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l['curl_copied']),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Prints the ENTIRE HTTP log to the console (debugPrint) — method, status,
  /// address, User-Agent, time, request/response body and errors.
  void _printLogs(BuildContext context) {
    final l = AppLocalizations.of(context);
    final logs = serverService.logs;

    final buffer = StringBuffer()
      ..writeln('===== Sauna Time HTTP Logs (${logs.length}) =====');
    for (final log in logs) {
      buffer
        ..writeln('---')
        ..writeln(
          '[${log.timestamp.toIso8601String()}] '
          '${log.method} ${log.path} -> ${log.statusCode}',
        )
        ..writeln('Message: ${log.message}');
      if (log.remoteAddress != null) {
        buffer.writeln('Remote address: ${log.remoteAddress}');
      }
      if (log.userAgent != null) {
        buffer.writeln('User-Agent: ${log.userAgent}');
      }
      if (log.durationMs != null) {
        buffer.writeln('Duration: ${log.durationMs} ms');
      }
      if (log.requestBody != null && log.requestBody!.isNotEmpty) {
        buffer.writeln('Request body:\n${log.requestBody}');
      }
      if (log.responseBody != null && log.responseBody!.isNotEmpty) {
        buffer.writeln('Response body:\n${log.responseBody}');
      }
      if (log.error != null && log.error!.isNotEmpty) {
        buffer.writeln('Error: ${log.error}');
      }
    }
    buffer.writeln('===== End of logs =====');

    debugPrint(buffer.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.logsPrintedLabel(logs.length))));
    }
  }

  /// Shows details of an HTTP log entry (after tapping a log).
  Future<void> _showLogDetails(
    BuildContext context,
    HttpServerLogEntry log,
  ) async {
    final theme = Theme.of(context);
    final fullTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final statusColor = log.statusCode >= 200 && log.statusCode < 300
        ? Colors.green.shade800
        : AppColors.warmRed;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.method,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HTTP ${log.statusCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        fullTimeFormat.format(log.timestamp),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LogDetailRow(label: 'Path', value: log.path),
                  if (log.remoteAddress != null)
                    _LogDetailRow(
                      label: 'Remote address',
                      value: log.remoteAddress!,
                    ),
                  if (log.userAgent != null)
                    _LogDetailRow(label: 'User-Agent', value: log.userAgent!),
                  if (log.durationMs != null)
                    _LogDetailRow(
                      label: 'Duration',
                      value: '${log.durationMs} ms',
                    ),
                  if (log.error != null && log.error!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LogDetailBlock(label: 'Error', text: log.error!),
                  ],
                  if (log.requestBody != null &&
                      log.requestBody!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LogDetailBlock(
                      label: 'Request body',
                      text: log.requestBody!,
                    ),
                  ],
                  if (log.responseBody != null &&
                      log.responseBody!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LogDetailBlock(
                      label: 'Response body',
                      text: log.responseBody!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm:ss');
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: serverService,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final isRunning = serverService.isRunning;

        final serverCard = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRunning ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRunning ? l['server_active'] : l['server_stopped'],
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isRunning,
                      onChanged: (val) async {
                        if (val) {
                          await serverService.startServer();
                        } else {
                          await serverService.stopServer();
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l['server_port'],
                            style: theme.textTheme.labelSmall,
                          ),
                          Row(
                            children: [
                              Text(
                                '${serverService.port}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit, size: 14),
                                onPressed: () => _changePort(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l['server_post_endpoint'],
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            'api/sessions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isRunning && serverService.localIp != null) ...[
                  const SizedBox(height: 12),
                  Text(l['server_local_ip'], style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  SelectableText(
                    serverService.localIp!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l['server_localhost_note'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        final simulatorCard = Card(
          elevation: 1,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.watch_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l['watch_simulator'],
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l['phase_count_label'],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {_phaseCount},
                  onSelectionChanged: (selection) {
                    setState(() => _phaseCount = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _sendSimulatedWatchSession(context),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      l['generate_watch_session'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final logsHeader = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l['http_logs_title'],
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.print_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: serverService.logs.isEmpty
                      ? null
                      : () => _printLogs(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: serverService.logs.isEmpty
                      ? null
                      : serverService.clearLogs,
                ),
              ],
            ),
          ],
        );

        final logsList = serverService.logs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    l['no_http_logs'],
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: serverService.logs.length,
                itemBuilder: (context, index) {
                  final log = serverService.logs[index];
                  final isSuccess =
                      log.statusCode >= 200 && log.statusCode < 300;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () => _showLogDetails(context, log),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.method,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: isSuccess
                                ? Colors.green.shade800
                                : Colors.deepOrange,
                          ),
                        ),
                      ),
                      title: Text(
                        log.message,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        '${log.path} • ${log.statusCode}',
                        style: theme.textTheme.labelSmall,
                      ),
                      trailing: Text(
                        timeFormat.format(log.timestamp),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  );
                },
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(l['server_screen_title']),
            centerTitle: true,
            toolbarHeight: isLandscape ? 40 : null,
          ),
          body: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          serverCard,
                          const SizedBox(height: 12),
                          simulatorCard,
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _copyCurlCommand(context),
                            icon: const Icon(Icons.code_rounded),
                            label: Text(l['copy_curl']),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          logsHeader,
                          const SizedBox(height: 8),
                          logsList,
                        ],
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    serverCard,
                    const SizedBox(height: 12),
                    simulatorCard,
                    const SizedBox(height: 24),
                    logsHeader,
                    const SizedBox(height: 8),
                    logsList,
                  ],
                ),
        );
      },
    );
  }
}

class _LogDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _LogDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LogDetailBlock extends StatelessWidget {
  final String label;
  final String text;

  const _LogDetailBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
