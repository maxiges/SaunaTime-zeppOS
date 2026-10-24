import 'package:flutter/foundation.dart';

import '../data/session_storage.dart';
import '../domain/models/sauna_session.dart';

class SessionController extends ChangeNotifier {
  final SessionStorage _storage;
  final Future<void> Function(List<String> ids)? onSessionsDeleted;

  List<SaunaSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  SessionController({SessionStorage? storage, this.onSessionsDeleted})
    : _storage = storage ?? SharedPrefsSessionStorage();

  List<SaunaSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _storage.getSessions();
    } catch (e) {
      _errorMessage = 'Błąd podczas ładowania sesji: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSession(SaunaSession session) async {
    try {
      await _storage.saveSession(session);
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = 'Błąd podczas zapisywania sesji: $e';
      notifyListeners();
      return false;
    }
  }

  /// Imports many sessions at once, avoiding duplicates (at the storage level).
  Future<int> importSessions(List<SaunaSession> newSessions) async {
    _errorMessage = null;
    try {
      final existing = await _storage.getSessions();
      final existingIds = existing.map((s) => s.id).toSet();
      final toAdd = newSessions.where((s) => existingIds.add(s.id)).toList();

      if (toAdd.isNotEmpty) {
        await _storage.saveSessions(toAdd);
      }
      _sessions = await _storage.getSessions();
      notifyListeners();
      return toAdd.length;
    } catch (e) {
      _errorMessage = 'Błąd podczas importu sesji: $e';
      notifyListeners();
      return 0;
    }
  }

  Future<bool> deleteSession(String id) async {
    _errorMessage = null;
    try {
      await onSessionsDeleted?.call([id]);
      await _storage.deleteSession(id);
      _sessions = await _storage.getSessions();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Błąd podczas usuwania sesji: $e';
      notifyListeners();
      return false;
    }
  }

  /// Usuwa wszystkie sesje z magazynu.
  Future<bool> clearAllSessions({bool syncDeletions = true}) async {
    _errorMessage = null;
    try {
      if (syncDeletions) {
        final sessions = await _storage.getSessions();
        await onSessionsDeleted?.call(sessions.map((s) => s.id).toList());
      }
      await _storage.clearAll();
      _sessions = await _storage.getSessions();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Błąd podczas usuwania wszystkich sesji: $e';
      notifyListeners();
      return false;
    }
  }
}
