import 'dart:convert';
import 'package:intl/intl.dart';
import '../../sessions/domain/models/sauna_session.dart';

class BackupResult {
  final int importedCount;
  final int skippedCount;

  BackupResult({required this.importedCount, required this.skippedCount});
}

class BackupService {
  String exportSessionsToJson(List<SaunaSession> sessions) {
    final data = {
      'app': 'sauna_time',
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'sessionsCount': sessions.length,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String exportSessionsToCsv(List<SaunaSession> sessions) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Data,Godzina,Czas_trwania_min,Temperatura_C,Zrodlo,Srednie_tetno_bpm,Max_tetno_bpm,Notatki');

    for (final s in sessions) {
      final id = s.id;
      final date = dateFormat.format(s.startTime);
      final time = timeFormat.format(s.startTime);
      final duration = s.durationMinutes;
      final temp = s.temperature != null ? s.temperature!.toStringAsFixed(1) : '';
      final source = s.source.displayName;
      final avgHr = s.averageHeartRate != null ? '${s.averageHeartRate}' : '';
      final maxHr = s.maxHeartRate != null ? '${s.maxHeartRate}' : '';
      final notes = s.notes != null ? '"${s.notes!.replaceAll('"', '""')}"' : '""';

      buffer.writeln('$id,$date,$time,$duration,$temp,$source,$avgHr,$maxHr,$notes');
    }

    return buffer.toString();
  }

  List<SaunaSession> parseSessionsFromJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    final List<dynamic> sessionList;

    if (decoded is List) {
      sessionList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['sessions'] is List) {
      sessionList = decoded['sessions'] as List<dynamic>;
    } else {
      throw const FormatException('Nieprawidłowy format pliku kopii zapasowej');
    }

    return sessionList
        .map((item) => SaunaSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
