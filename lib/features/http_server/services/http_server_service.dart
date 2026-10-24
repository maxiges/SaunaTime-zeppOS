import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/profile/user_profile_controller.dart';
import '../../cloud_sync/domain/services/crypto_service.dart';
import '../../cloud_sync/presentation/cloud_auth_controller.dart';
import '../../sessions/domain/models/sauna_session.dart';
import '../../sessions/domain/services/watch_session_parser.dart';
import '../../sessions/presentation/session_controller.dart';

class HttpServerLogEntry {
  final DateTime timestamp;
  final String method;
  final String path;
  final int statusCode;
  final String message;

  /// Client IP address (e.g. 192.168.1.10).
  final String? remoteAddress;

  /// Client `User-Agent` header.
  final String? userAgent;

  /// Raw request body (for POST requests).
  final String? requestBody;

  /// JSON response body sent back to the client.
  final String? responseBody;

  /// Detailed error info (if the request failed).
  final String? error;

  /// How long the request took to handle, in milliseconds.
  final int? durationMs;

  HttpServerLogEntry({
    required this.timestamp,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.message,
    this.remoteAddress,
    this.userAgent,
    this.requestBody,
    this.responseBody,
    this.error,
    this.durationMs,
  });
}

class LocalHttpServerService extends ChangeNotifier {
  final SessionController sessionController;
  final CloudAuthController? cloudAuthController;
  final UserProfileController? userProfileController;
  HttpServer? _server;
  int _port = 8080;
  bool _isRunning = false;
  String? _serverAddress;
  String? _localIp;
  final List<HttpServerLogEntry> _logs = [];

  LocalHttpServerService({
    required this.sessionController,
    this.cloudAuthController,
    this.userProfileController,
  });

  bool get isRunning => _isRunning;
  int get port => _port;
  String? get serverAddress => _serverAddress;
  String? get localIp => _localIp;
  List<HttpServerLogEntry> get logs => List.unmodifiable(_logs);

  Future<bool> startServer({int port = 8080}) async {
    if (_isRunning) {
      return true;
    }

    _port = port;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;

      // Detect local IP address (first non-loopback IPv4)
      _localIp = await _findLocalIp();
      _serverAddress = 'http://${_localIp ?? '0.0.0.0'}:$_port';

      _addLog('SYSTEM', '/', 200, 'HTTP server started on port $_port');
      notifyListeners();

      _server!.listen(
        _handleRequest,
        onError: (error) {
          _addLog('ERROR', '/', 500, 'Server error: $error');
          notifyListeners();
        },
      );

      return true;
    } catch (e) {
      _isRunning = false;
      _addLog('ERROR', '/', 500, 'Failed to start server: $e');
      notifyListeners();
      return false;
    }
  }

  Future<String?> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> stopServer() async {
    if (!_isRunning) {
      return;
    }

    try {
      await _server?.close(force: true);
      _server = null;
      _isRunning = false;
      _localIp = null;
      _serverAddress = null;
      _addLog('SYSTEM', '/', 200, 'HTTP server stopped');
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', '/', 500, 'Error stopping server: $e');
      notifyListeners();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final method = request.method;
    final path = request.uri.path;
    final remoteAddress = request.connectionInfo?.remoteAddress.address;
    final userAgent = request.headers.value(HttpHeaders.userAgentHeader);
    final stopwatch = Stopwatch()..start();

    // CORS Headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Origin, Content-Type, Accept, X-PIN, X-User-Email, X-Sync-Key',
    );

    if (method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // Read the ENTIRE raw request body once — the full input that arrived is
    // logged verbatim (no truncation) for every request.
    var requestBody = '';
    try {
      requestBody = await utf8.decoder.bind(request).join();
    } catch (_) {
      requestBody = '';
    }
    final hasBody = requestBody.trim().isNotEmpty;

    try {
      if (method == 'GET' && (path == '/' || path == '/api/status')) {
        await _handleStatusEndpoint(request, requestBody: requestBody);
      } else if (method == 'GET' &&
          (path == '/api/watch/config' ||
              path == '/api/config' ||
              path == '/config')) {
        await _handleWatchConfigEndpoint(request, requestBody: requestBody);
      } else if (method == 'POST' &&
          (path == '/api/sessions' || path == '/session')) {
        await _handleSessionIngestion(request, requestBody: requestBody);
      } else {
        final body = jsonEncode({'error': 'Endpoint not found'});
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(body);
        _addLog(
          method,
          path,
          HttpStatus.notFound,
          '404 Not found',
          remoteAddress: remoteAddress,
          userAgent: userAgent,
          requestBody: hasBody ? requestBody : null,
          responseBody: body,
          durationMs: stopwatch.elapsedMilliseconds,
        );
        await request.response.close();
      }
    } catch (e) {
      final body = jsonEncode({'error': 'Internal error: $e'});
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      _addLog(
        method,
        path,
        HttpStatus.internalServerError,
        'Error: $e',
        remoteAddress: remoteAddress,
        userAgent: userAgent,
        requestBody: hasBody ? requestBody : null,
        responseBody: body,
        error: '$e',
        durationMs: stopwatch.elapsedMilliseconds,
      );
      await request.response.close();
    }

    notifyListeners();
  }

  Future<void> _handleStatusEndpoint(
    HttpRequest request, {
    String requestBody = '',
  }) async {
    final stopwatch = Stopwatch()..start();
    final remoteAddress = request.connectionInfo?.remoteAddress.address;
    final userAgent = request.headers.value(HttpHeaders.userAgentHeader);

    final body = jsonEncode({
      'status': 'ok',
      'app': 'sauna_time',
      'version': '1.0.0',
      'sessionsCount': sessionController.sessions.length,
      'hasCloudSync': cloudAuthController != null && cloudAuthController!.isLoggedIn,
    });

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);
    _addLog(
      'GET',
      request.uri.path,
      HttpStatus.ok,
      'Server status returned',
      remoteAddress: remoteAddress,
      userAgent: userAgent,
      requestBody: requestBody.trim().isNotEmpty ? requestBody : null,
      responseBody: body,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    await request.response.close();
  }

  /// Endpoint dedicated for Zepp OS watch to fetch all configurations:
  /// email, sync_key, cloud endpoint, local endpoint, and user profile.
  Future<void> _handleWatchConfigEndpoint(
    HttpRequest request, {
    String requestBody = '',
  }) async {
    final stopwatch = Stopwatch()..start();
    final remoteAddress = request.connectionInfo?.remoteAddress.address;
    final userAgent = request.headers.value(HttpHeaders.userAgentHeader);

    // Extract optional PIN from query ?pin=... or header X-PIN
    final pinQuery = request.uri.queryParameters['pin'];
    final pinHeader = request.headers.value('X-PIN');
    final providedPin = (pinQuery != null && pinQuery.trim().isNotEmpty)
        ? pinQuery.trim()
        : pinHeader?.trim();

    String? syncKey;
    bool isUnlocked = false;

    if (cloudAuthController != null) {
      if (cloudAuthController!.isUnlocked) {
        syncKey = cloudAuthController!.decryptedSyncKey;
        isUnlocked = true;
      } else if (providedPin != null && providedPin.length == 4) {
        final salt = cloudAuthController!.user?.salt;
        final encKey = cloudAuthController!.user?.encryptedSyncKey;
        if (salt != null && encKey != null) {
          try {
            final map = jsonDecode(encKey) as Map<String, dynamic>;
            syncKey = CryptoService.decryptWithPin(
              map['ciphertext'] as String,
              map['iv'] as String,
              providedPin,
              salt,
            );
            isUnlocked = true;
          } catch (_) {
            syncKey = null;
          }
        }
      }
    }

    final localUrl = 'http://${_localIp ?? 'localhost'}:$_port/api/sessions';
    final cloudUrl = cloudAuthController != null
        ? '${cloudAuthController!.backendUrl}/api/sync/session'
        : null;

    Map<String, dynamic> responseData;

    if (cloudAuthController == null || !cloudAuthController!.isLoggedIn) {
      request.response.statusCode = HttpStatus.ok;
      responseData = {
        'status': 'local_only',
        'is_logged_in': false,
        'message':
            'No cloud account connected. Watch can send sessions directly to local_upload_url.',
        'local_upload_url': localUrl,
        'server_port': _port,
      };
    } else if (isUnlocked && syncKey != null) {
      request.response.statusCode = HttpStatus.ok;
      responseData = {
        'status': 'ok',
        'is_logged_in': true,
        'is_unlocked': true,
        'email': cloudAuthController!.user?.email ?? '',
        'sync_key': syncKey,
        'cloud_upload_url': cloudUrl,
        'cloud_backend_url': cloudAuthController!.backendUrl,
        'local_upload_url': localUrl,
        'server_port': _port,
        'user_profile': userProfileController != null
            ? {
                'sex': userProfileController!.profile.sex.name,
                'weight': userProfileController!.profile.weightKg,
                'age': userProfileController!.profile.ageYears,
                'preferred_sauna_type':
                    userProfileController!.profile.preferredSaunaType.name,
              }
            : null,
      };
    } else {
      request.response.statusCode = HttpStatus.ok;
      responseData = {
        'status': 'locked',
        'is_logged_in': true,
        'is_unlocked': false,
        'message':
            'Sauna Time is locked with PIN. Please unlock the app or provide ?pin=XXXX in the request to get sync key.',
        'email': cloudAuthController!.user?.email ?? '',
        'cloud_upload_url': cloudUrl,
        'local_upload_url': localUrl,
        'server_port': _port,
      };
    }

    final body = jsonEncode(responseData);
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);

    _addLog(
      'GET',
      request.uri.path,
      HttpStatus.ok,
      'Watch config delivered (${responseData['status']})',
      remoteAddress: remoteAddress,
      userAgent: userAgent,
      requestBody: requestBody.trim().isNotEmpty ? requestBody : null,
      responseBody: body,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    await request.response.close();
  }

  Future<void> _handleSessionIngestion(
    HttpRequest request, {
    required String requestBody,
  }) async {
    final stopwatch = Stopwatch()..start();
    final remoteAddress = request.connectionInfo?.remoteAddress.address;
    final userAgent = request.headers.value(HttpHeaders.userAgentHeader);

    final content = requestBody;
    if (content.trim().isEmpty) {
      final body = jsonEncode({'error': 'Empty request body'});
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      _addLog(
        'POST',
        request.uri.path,
        HttpStatus.badRequest,
        'Empty payload',
        remoteAddress: remoteAddress,
        userAgent: userAgent,
        requestBody: content,
        responseBody: body,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      await request.response.close();
      return;
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      final body = jsonEncode({'error': 'Invalid JSON: $e'});
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      _addLog(
        'POST',
        request.uri.path,
        HttpStatus.internalServerError,
        'Invalid JSON: $e',
        remoteAddress: remoteAddress,
        userAgent: userAgent,
        requestBody: content,
        responseBody: body,
        error: '$e',
        durationMs: stopwatch.elapsedMilliseconds,
      );
      await request.response.close();
      return;
    }

    final session = parseWatchPayload(json);

    // Duplicate protection — never store the same session twice
    if (await hasDuplicate(session)) {
      final body = jsonEncode({
        'success': true,
        'duplicate': true,
        'sessionId': session.id,
        'message': 'Session already exists — skipped to avoid a duplicate',
      });
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      _addLog(
        'POST',
        request.uri.path,
        HttpStatus.ok,
        'Duplicate skipped: session from ${session.startTime.toIso8601String()}',
        remoteAddress: remoteAddress,
        userAgent: userAgent,
        requestBody: content,
        responseBody: body,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      await request.response.close();
      return;
    }

    await sessionController.addSession(session);

    // If auto-sync with cloud is enabled and app is unlocked, push to cloud in background
    if (cloudAuthController != null &&
        cloudAuthController!.isLoggedIn &&
        cloudAuthController!.isUnlocked &&
        cloudAuthController!.autoSync) {
      cloudAuthController!.syncWithCloud(sessionController).catchError((_) => false);
    }

    final body = jsonEncode({
      'success': true,
      'sessionId': session.id,
      'message': 'Session received and saved in Sauna Time',
    });
    request.response.statusCode = HttpStatus.created;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);

    _addLog(
      'POST',
      request.uri.path,
      HttpStatus.created,
      'Session received: ${session.durationMinutes} min, ${session.heartRateSamples.length} HR samples',
      remoteAddress: remoteAddress,
      userAgent: userAgent,
      requestBody: content,
      responseBody: body,
      durationMs: stopwatch.elapsedMilliseconds,
    );

    await request.response.close();
  }

  SaunaSession parseWatchPayload(Map<String, dynamic> json) => WatchSessionParser.parse(json);

  Future<bool> hasDuplicate(SaunaSession session) async {
    if (sessionController.sessions.isEmpty) {
      await sessionController.loadSessions();
    }
    return isDuplicate(session);
  }

  bool isDuplicate(SaunaSession session) {
    final fingerprint = _sessionFingerprint(session);
    return sessionController.sessions.any(
      (s) => s.id == session.id || _sessionFingerprint(s) == fingerprint,
    );
  }

  String _sessionFingerprint(SaunaSession session) {
    final startKey = session.startTime.toUtc().toIso8601String().substring(
      0,
      16,
    );
    return '${session.source.name}|$startKey|${session.durationMinutes}';
  }

  DateTime? parseTimestamp(dynamic value) => WatchSessionParser.parseTimestamp(value);

  void _addLog(
    String method,
    String path,
    int statusCode,
    String message, {
    String? remoteAddress,
    String? userAgent,
    String? requestBody,
    String? responseBody,
    String? error,
    int? durationMs,
  }) {
    _logs.insert(
      0,
      HttpServerLogEntry(
        timestamp: DateTime.now(),
        method: method,
        path: path,
        statusCode: statusCode,
        message: message,
        remoteAddress: remoteAddress,
        userAgent: userAgent,
        requestBody: requestBody,
        responseBody: responseBody,
        error: error,
        durationMs: durationMs,
      ),
    );
    if (_logs.length > 50) {
      _logs.removeLast();
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}

