import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/sauna_session.dart';

abstract class SessionStorage {
  Future<List<SaunaSession>> getSessions();
  Future<SaunaSession?> getSessionById(String id);
  Future<void> saveSession(SaunaSession session);
  Future<void> saveSessions(List<SaunaSession> sessions);
  Future<void> deleteSession(String id);
  Future<void> clearAll();
}

class SharedPrefsSessionStorage implements SessionStorage {
  static const String _storageKey = 'sauna_sessions_data_v1';
  final SharedPreferences? _prefsInstance;

  SharedPrefsSessionStorage([this._prefsInstance]);

  Future<SharedPreferences> get _prefs async =>
      _prefsInstance ?? await SharedPreferences.getInstance();

  @override
  Future<List<SaunaSession>> getSessions() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final sessions = decoded
          .map((item) => SaunaSession.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SaunaSession?> getSessionById(String id) async {
    final sessions = await getSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(SaunaSession session) async {
    await saveSessions([session]);
  }

  @override
  Future<void> saveSessions(List<SaunaSession> newSessions) async {
    if (newSessions.isEmpty) return;

    final sessions = await getSessions();
    final Map<String, SaunaSession> sessionMap = {
      for (var s in sessions) s.id: s
    };

    for (var ns in newSessions) {
      sessionMap[ns.id] = ns;
    }

    final mergedList = sessionMap.values.toList();
    final prefs = await _prefs;
    final jsonList = mergedList.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  @override
  Future<void> deleteSession(String id) async {
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == id);

    final prefs = await _prefs;
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_storageKey);
  }
}
