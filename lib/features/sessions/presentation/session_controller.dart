import 'package:flutter/foundation.dart';
import '../data/session_storage.dart';
import '../domain/models/sauna_session.dart';

class SessionController extends ChangeNotifier {
  final SessionStorage _storage;

  List<SaunaSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  SessionController({SessionStorage? storage})
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
    try {
      final existingIds = _sessions.map((s) => s.id).toSet();
      final toAdd = newSessions.where((s) => !existingIds.contains(s.id)).toList();
      
      if (toAdd.isNotEmpty) {
        await _storage.saveSessions(toAdd);
        await loadSessions();
      }
      return toAdd.length;
    } catch (e) {
      _errorMessage = 'Błąd podczas importu sesji: $e';
      notifyListeners();
      return 0;
    }
  }

  Future<bool> deleteSession(String id) async {
    try {
      await _storage.deleteSession(id);
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = 'Błąd podczas usuwania sesji: $e';
      notifyListeners();
      return false;
    }
  }

  /// Usuwa wszystkie sesje z magazynu.
  Future<bool> clearAllSessions() async {
    try {
      await _storage.clearAll();
      await loadSessions();
      return true;
    } catch (e) {
      _errorMessage = 'Błąd podczas usuwania wszystkich sesji: $e';
      notifyListeners();
      return false;
    }
  }
}
