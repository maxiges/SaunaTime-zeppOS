import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../sessions/domain/models/measurement_sample.dart';
import '../../sessions/domain/models/sauna_phase.dart';
import '../../sessions/domain/models/sauna_session.dart';
import '../../sessions/domain/models/session_source.dart';
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
  HttpServer? _server;
  int _port = 8080;
  bool _isRunning = false;
  String? _serverAddress;
  String? _localIp;
  final List<HttpServerLogEntry> _logs = [];

  LocalHttpServerService({required this.sessionController});

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
      'Origin, Content-Type, Accept',
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

    // Duplicate protection — never store the same session twice (e.g. when the
    // watch retries syncing the same session or sends a payload that already
    // exists in the database).
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

  SaunaSession parseWatchPayload(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? const Uuid().v4();

    // Time in the API is a Unix timestamp (seconds or milliseconds);
    // we also accept ISO-8601 for backward compatibility.
    final startTime =
        parseTimestamp(json['startTime'] ?? json['date']) ?? DateTime.now();
    final endTime = parseTimestamp(json['endTime']);

    // Duration with second accuracy.
    // Priority: 1) endTime - startTime, 2) durationSeconds,
    //           3) durationMinutes (can be a fraction, e.g. 12.5),
    //           4) default 15 min.
    final int? explicitDurationSeconds = _toInt(json['durationSeconds']);
    final num? durationMinutesRaw =
        _toDouble(json['durationMinutes']) ?? _toDouble(json['duration']);

    int durationSeconds;
    if (explicitDurationSeconds != null && explicitDurationSeconds > 0) {
      durationSeconds = explicitDurationSeconds;
    } else if (endTime != null) {
      durationSeconds = endTime.difference(startTime).inSeconds;
    } else if (durationMinutesRaw != null && durationMinutesRaw > 0) {
      durationSeconds = (durationMinutesRaw * 60).round();
    } else {
      durationSeconds = 15 * 60;
    }
    if (durationSeconds <= 0) {
      durationSeconds = 60;
    }

    // durationMinutes remains an integer (rounded), while
    // endTime is always precise to the second.
    final int durationMinutes = (durationSeconds / 60)
        .round()
        .clamp(1, 1 << 31)
        .toInt();

    final temperature =
        _toDouble(json['temperature']) ?? _toDouble(json['temp']);

    final averageHeartRate =
        _toInt(json['averageHeartRate']) ??
        _toInt(json['avgHr']) ??
        _toInt(json['avg_heart_rate']);

    final maxHeartRate =
        _toInt(json['maxHeartRate']) ??
        _toInt(json['maxHr']) ??
        _toInt(json['max_heart_rate']);

    final notes = json['notes'] as String? ?? json['comment'] as String?;

    // Sauna phases (from 1 to 3): heating, cooling, resting.
    final parsedPhases = _parsePhasesFromPayload(json);
    final effectiveEndTime =
        endTime ?? startTime.add(Duration(seconds: durationSeconds));

    final Map<SaunaPhase, int> phaseDurations = {};
    for (int i = 0; i < parsedPhases.phases.length; i++) {
      phaseDurations[parsedPhases.phases[i]] = parsedPhases.durationsMinutes[i];
    }

    // Parse samples
    final List<MeasurementSample> heartRateSamples = [];
    if (json['heartRateSamples'] is List) {
      for (final item in json['heartRateSamples'] as List) {
        if (item is Map<String, dynamic>) {
          heartRateSamples.add(MeasurementSample.fromJson(item));
        }
      }
    } else if (json['heart_rate_samples'] is List) {
      for (final item in json['heart_rate_samples'] as List) {
        if (item is Map<String, dynamic>) {
          heartRateSamples.add(MeasurementSample.fromJson(item));
        }
      }
    }

    final List<MeasurementSample> temperatureSamples = [];
    if (json['temperatureSamples'] is List) {
      for (final item in json['temperatureSamples'] as List) {
        if (item is Map<String, dynamic>) {
          temperatureSamples.add(MeasurementSample.fromJson(item));
        }
      }
    }

    // If the payload declares phases but samples don't have assigned phases,
    // we assign phases based on duration — so charts know how to color individual stages.
    final heartRateSamplesWithPhases = parsedPhases.phases.isEmpty
        ? heartRateSamples
        : _tagSamplesWithPhases(
            heartRateSamples,
            parsedPhases.phases,
            parsedPhases.durationsMinutes,
            startTime,
            effectiveEndTime,
          );
    final temperatureSamplesWithPhases = parsedPhases.phases.isEmpty
        ? temperatureSamples
        : _tagSamplesWithPhases(
            temperatureSamples,
            parsedPhases.phases,
            parsedPhases.durationsMinutes,
            startTime,
            effectiveEndTime,
          );

    return SaunaSession(
      id: id,
      startTime: startTime,
      endTime: effectiveEndTime,
      durationMinutes: durationMinutes,
      source: SessionSource.watchHttp,
      temperature: temperature,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      notes: notes,
      heartRateSamples: _defaultPhaseForSamples(heartRateSamplesWithPhases),
      temperatureSamples: _defaultPhaseForSamples(temperatureSamplesWithPhases),
      phases: parsedPhases.phases,
      phaseDurations: phaseDurations,
    );
  }

  /// No phase specified on the sample means phase 1 (heating).
  List<MeasurementSample> _defaultPhaseForSamples(
    List<MeasurementSample> samples,
  ) {
    return [
      for (final sample in samples)
        sample.phase != null
            ? sample
            : MeasurementSample(
                timestamp: sample.timestamp,
                value: sample.value,
                phase: SaunaPhase.heating,
              ),
    ];
  }

  _ParsedPhases _parsePhasesFromPayload(Map<String, dynamic> json) {
    final phases = <SaunaPhase>[];
    final durations = <int>[];

    final raw = json['phases'] ?? json['stages'] ?? json['etapy'];
    if (raw is List) {
      for (final item in raw) {
        SaunaPhase? phase;
        var durationMinutes = 0;
        if (item is num) {
          // Optimized API: phase as a number 1/2/3.
          phase = SaunaPhase.fromCode(item.toInt());
        } else if (item is String) {
          phase = SaunaPhase.fromJson(item);
        } else if (item is Map) {
          phase = SaunaPhase.fromJson(
            item['type'] ?? item['phase'] ?? item['name'] ?? item['etap'],
          );
          durationMinutes =
              _toInt(item['durationMinutes']) ??
              _toInt(item['duration']) ??
              _toInt(item['minutes']) ??
              0;
        }
        if (phase != null && !phases.contains(phase)) {
          phases.add(phase);
          durations.add(durationMinutes);
        }
      }
    }

    return _ParsedPhases(phases, durations);
  }

  /// Assigns phases (stages) to samples that don't have them, dividing the duration.
  List<MeasurementSample> _tagSamplesWithPhases(
    List<MeasurementSample> samples,
    List<SaunaPhase> phases,
    List<int> durationsMinutes,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (samples.isEmpty || phases.isEmpty) return samples;
    // All samples already have phases — no change.
    if (samples.every((s) => s.phase != null)) return samples;

    final totalMinutes = math.max(1, endTime.difference(startTime).inMinutes);

    // Phase boundaries (in minutes from session start).
    final boundaries = <double>[];
    final hasDurations = durationsMinutes.any((d) => d > 0);
    var accumulated = 0.0;
    if (hasDurations) {
      final totalDuration = durationsMinutes.fold<int>(0, (a, b) => a + b);
      for (var i = 0; i < phases.length; i++) {
        final duration = durationsMinutes[i] > 0
            ? durationsMinutes[i]
            : totalDuration ~/ phases.length;
        accumulated += duration;
        boundaries.add(accumulated);
      }
    } else {
      final slice = totalMinutes / phases.length;
      for (var i = 1; i <= phases.length; i++) {
        boundaries.add(slice * i);
      }
    }

    SaunaPhase phaseAt(double minutesFromStart) {
      var index = phases.length - 1;
      for (var i = 0; i < boundaries.length; i++) {
        if (minutesFromStart <= boundaries[i]) {
          index = i;
          break;
        }
      }
      return phases[index];
    }

    return [
      for (final sample in samples)
        sample.phase != null
            ? sample
            : MeasurementSample(
                timestamp: sample.timestamp,
                value: sample.value,
                phase: phaseAt(
                  sample.timestamp.difference(startTime).inSeconds / 60.0,
                ),
              ),
    ];
  }

  /// Ensures the current session list is loaded and then checks if the
  /// session is a duplicate (by id or content "fingerprint").
  /// Returns true if the session SHOULD NOT be saved again.
  Future<bool> hasDuplicate(SaunaSession session) async {
    if (sessionController.sessions.isEmpty) {
      await sessionController.loadSessions();
    }
    return isDuplicate(session);
  }

  /// Checks for duplicates against the currently loaded session list:
  ///  1. Same ID (id) — POST is idempotent.
  ///  2. Same content "fingerprint" (source + start to minute + duration)
  ///     — protects against adding the same entry multiple times, even if
  ///     the watch generates a new ID on each sync attempt.
  bool isDuplicate(SaunaSession session) {
    final fingerprint = _sessionFingerprint(session);
    return sessionController.sessions.any(
      (s) => s.id == session.id || _sessionFingerprint(s) == fingerprint,
    );
  }

  /// Stable session content identifier used for duplicate detection.
  /// Consists of source, start time (UTC, to minute accuracy)
  /// and duration in minutes.
  String _sessionFingerprint(SaunaSession session) {
    final startKey = session.startTime.toUtc().toIso8601String().substring(
      0,
      16,
    ); // YYYY-MM-DDTHH:MM
    return '${session.source.name}|$startKey|${session.durationMinutes}';
  }

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

/// Parsing result of phases: list of phases and (optionally) their durations in minutes.
class _ParsedPhases {
  final List<SaunaPhase> phases;
  final List<int> durationsMinutes;

  const _ParsedPhases(this.phases, this.durationsMinutes);
}

/// Safe conversion to a floating-point number — accepts numbers and
/// numeric strings (e.g. "34.8"). Returns null for invalid values.
/// This prevents internal errors when numeric values are sent as strings.
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

/// Like _toDouble, but returns an integer.
int? _toInt(dynamic value) {
  return _toDouble(value)?.toInt();
}
