import 'dart:convert';
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
