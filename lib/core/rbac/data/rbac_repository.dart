import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import '../models/rbac_models.dart';

/// SSE progress event from the backend.
class SseProgressEvent {
  final String event;
  final Map<String, dynamic> data;

  const SseProgressEvent(this.event, this.data);

  int get total => data['total'] ?? 0;
  int get index => data['index'] ?? 0;
  String get flag => data['flag'] ?? '';
  String get name => data['name'] ?? '';
  int get subMenusCount => data['sub_menus_count'] ?? 0;
}

class RbacRepository {
  static final _baseUrl = dotenv.env['BASE_API_URL'] ?? 'http://localhost';
  static final _apiConsumer = dotenv.env['API_CONSUMER'] ?? '';

  /// Fetch eblood bank applications (original blocking call, no SSE).
  Future<List<RbacApplication>> fetchAgentApplications() async {
    final response = await getWithDio(
      '/static/data/get-ebloodbank-applications',
      queryParams: {
        'all_data': 'true',
        'output_data_type': 'default',
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load applications');
    }

    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => RbacApplication.fromJson(json)).toList();
  }

  /// Fetch applications WITH SSE progress streaming.
  /// Returns a record with:
  ///   - `progress`: stream of SSE events (init, app_complete, done)
  ///   - `result`: future that completes with the full application list
  ({Stream<SseProgressEvent> progress, Future<List<RbacApplication>> result})
      fetchAgentApplicationsWithSse() {
    final sseKey = DateTime.now().millisecondsSinceEpoch.toString();
    final controller = StreamController<SseProgressEvent>.broadcast();

    // Start SSE listener
    _listenSse(sseKey, controller);

    // Kick off the main GET (with sse_key appended)
    final resultFuture = _fetchWithSseKey(sseKey).whenComplete(() {
      if (!controller.isClosed) controller.close();
    });

    return (progress: controller.stream, result: resultFuture);
  }

  Future<List<RbacApplication>> _fetchWithSseKey(String sseKey) async {
    final response = await getWithDio(
      '/static/data/get-ebloodbank-applications',
      queryParams: {
        'all_data': 'true',
        'output_data_type': 'default',
        'sse_key': sseKey,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load applications');
    }

    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => RbacApplication.fromJson(json)).toList();
  }

  /// SSE listener with exponential backoff retry (max 3 attempts).
  /// Resilient on weak mobile networks — retries on connection failures
  /// without blocking the main GET request.
  Future<void> _listenSse(
    String sseKey,
    StreamController<SseProgressEvent> controller,
  ) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (controller.isClosed) return;

      // Exponential backoff: 0ms, 500ms, 2000ms
      if (attempt > 0) {
        final delay = baseDelay * (1 << (attempt - 1));
        if (kDebugMode) print('[SSE] Retry $attempt in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        if (controller.isClosed) return;
      }

      http.Client? client;
      try {
        const secureStorage = FlutterSecureStorage();
        final token = await secureStorage.read(key: 'auth_token');

        final url = '$_baseUrl/static/data/sse/apps-progress?sse_key=$sseKey';
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        if (_apiConsumer.isNotEmpty) {
          request.headers['api-consumer'] = _apiConsumer;
        }

        client = http.Client();
        // Connect timeout scales with attempt: 5s, 8s, 12s
        final connectTimeout = Duration(seconds: 5 + (attempt * 3));
        final response = await client.send(request).timeout(connectTimeout);

        if (response.statusCode != 200) {
          if (kDebugMode) print('[SSE] Attempt $attempt: status ${response.statusCode}');
          client.close();
          continue; // retry
        }

        if (kDebugMode) print('[SSE] Connected (attempt $attempt)');

        String buffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;

          while (buffer.contains('\n\n')) {
            final idx = buffer.indexOf('\n\n');
            final message = buffer.substring(0, idx);
            buffer = buffer.substring(idx + 2);

            final event = _parseSseMessage(message);
            if (event != null && !controller.isClosed) {
              controller.add(event);
              if (kDebugMode) print('[SSE] ${event.event}: ${event.data}');
              if (event.event == 'done') {
                client.close();
                return; // success — no more retries
              }
            }
          }
        }
        client.close();
        return; // stream ended cleanly
      } catch (e) {
        client?.close();
        if (kDebugMode) print('[SSE] Attempt $attempt failed: $e');
        // Loop continues to next retry
      }
    }
    if (kDebugMode) print('[SSE] All $maxRetries attempts exhausted — main GET still works');
  }

  SseProgressEvent? _parseSseMessage(String message) {
    String? eventName;
    String? dataStr;

    for (final line in message.split('\n')) {
      if (line.startsWith('event: ')) {
        eventName = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        dataStr = line.substring(6).trim();
      }
    }

    if (eventName == null || dataStr == null) return null;

    try {
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      return SseProgressEvent(eventName, data);
    } catch (_) {
      return null;
    }
  }
}
