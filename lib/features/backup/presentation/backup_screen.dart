import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../sessions/presentation/session_controller.dart';
import '../data/backup_service.dart';

class BackupScreen extends StatefulWidget {
  final SessionController controller;
  final BackupService? backupService;

  const BackupScreen({super.key, required this.controller, this.backupService});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final BackupService _backupService;

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? BackupService();
  }

  /// Exports sessions to a user-selected JSON file.
  Future<void> _exportToFile() async {
    final l = AppLocalizations.of(context);
    final sessions = widget.controller.sessions;
    final content = _backupService.exportSessionsToJson(sessions);
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    const ext = 'json';
    final fileName = 'sauna_time_$stamp.$ext';

    try {
      final result = await FilePicker.saveFile(
        dialogTitle: l['backup_export_title'],
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(content)),
        type: FileType.custom,
        allowedExtensions: [ext],
        mimeType: 'application/json',
      );

      if (result == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.backupExportSaved()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }

  /// Imports sessions from a selected backup file (.json).
  Future<void> _importFromFile() async {
    final l = AppLocalizations.of(context);

    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: l['backup_import_title'],
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      debugPrint('Import pick error: $e');
      file = null;
    }

    if (file == null || file.path == null) return;

    try {
      final content = await File(file.path!).readAsString();
      final sessionsToImport = _backupService.parseSessionsFromJson(content);

      // Using the new, optimized bulk import method
      final added = await widget.controller.importSessions(sessionsToImport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.backupImported(added)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.backupImportError('$e')),
            backgroundColor: AppColors.warmRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final sessionsCount = widget.controller.sessions.length;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(l['backup_title']),
        centerTitle: true,
        toolbarHeight: isLandscape ? 40 : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Export Section
          _buildBackupCard(
            context,
            icon: Icons.cloud_download_outlined,
            iconColor: theme.colorScheme.primary,
            title: l['backup_export_title'],
            description: l.backupExportDesc(sessionsCount),
            actions: [
              FilledButton.icon(
                onPressed: sessionsCount > 0 ? _exportToFile : null,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(l['backup_export_json_btn']),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Import Section
          _buildBackupCard(
            context,
            icon: Icons.cloud_upload_outlined,
            iconColor: theme.colorScheme.secondary,
            title: l['backup_import_title'],
            description: l['backup_import_desc'],
            actions: [
              FilledButton.tonalIcon(
                onPressed: _importFromFile,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l['backup_import_btn']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
