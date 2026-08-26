import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models/sauna_session.dart';
import '../domain/models/session_source.dart';
import 'session_controller.dart';
import 'widgets/session_card.dart';

enum HistorySortOption {
  newestFirst('sort_newest'),
  oldestFirst('sort_oldest'),
  longestFirst('sort_longest'),
  shortestFirst('sort_shortest');

  final String labelKey;
  const HistorySortOption(this.labelKey);
}

class HistoryScreen extends StatefulWidget {
  final SessionController controller;
  final Function(SaunaSession)? onSessionTap;

  const HistoryScreen({super.key, required this.controller, this.onSessionTap});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SessionSource? _selectedSourceFilter;
  HistorySortOption _sortOption = HistorySortOption.newestFirst;

  List<SaunaSession> _getFilteredAndSortedSessions(
    List<SaunaSession> allSessions,
  ) {
    var list = allSessions;

    if (_selectedSourceFilter != null) {
      list = list.where((s) => s.source == _selectedSourceFilter).toList();
    } else {
      list = List.of(list);
    }

    switch (_sortOption) {
      case HistorySortOption.newestFirst:
        list.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case HistorySortOption.oldestFirst:
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case HistorySortOption.longestFirst:
        list.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
        break;
      case HistorySortOption.shortestFirst:
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
    }

    return list;
  }

  Future<void> _confirmDelete(SaunaSession session) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['delete_session_title']),
        content: Text(
          l.confirmDeleteSession(
            DateFormat('dd.MM.yyyy HH:mm').format(session.startTime),
            session.durationMinutes,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l['cancel']),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warmRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l['delete']),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l['session_deleted'] : l['error_delete_session'],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final allSessions = widget.controller.sessions;
        final filteredSessions = _getFilteredAndSortedSessions(allSessions);

        final filterBar = Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SessionSource?>(
                  value: _selectedSourceFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l['source_label'],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: theme.colorScheme.surface.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l['source_all'])),
                    DropdownMenuItem(value: SessionSource.manual, child: Text(l['source_manual'])),
                    DropdownMenuItem(value: SessionSource.watchHttp, child: Text(l['source_watch'])),
                  ],
                  onChanged: (val) => setState(() => _selectedSourceFilter = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<HistorySortOption>(
                  value: _sortOption,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l['sort_label'],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: theme.colorScheme.surface.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: HistorySortOption.values.map((opt) {
                    return DropdownMenuItem(value: opt, child: Text(l[opt.labelKey]));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortOption = val);
                  },
                ),
              ),
            ],
          ),
        );

        final content = filteredSessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      allSessions.isEmpty ? l['no_history_sessions'] : l['no_filtered_sessions'],
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => widget.controller.loadSessions(),
                child: isLandscape
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 170,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 1,
                        ),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) => _buildSessionItem(filteredSessions[index]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8), // Kontrolowany odstęp w ListView
                          child: _buildSessionItem(filteredSessions[index]),
                        ),
                      ),
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(l['history_title']),
            centerTitle: true,
            toolbarHeight: isLandscape ? 40 : null,
          ),
          body: Column(
            children: [
              filterBar,
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionItem(SaunaSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _confirmDelete(session);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.warmRed,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: SessionCard(
        session: session,
        onTap: () => widget.onSessionTap?.call(session),
      ),
    );
  }
}
