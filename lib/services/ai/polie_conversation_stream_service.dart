/// Polie Conversation SSE Stream Client
///
/// Speaks to the backend `POST /api/v2/polie/conversation/stream` endpoint over
/// Server-Sent Events. Emits one `PolieConversationStreamEvent` per server
/// event so the UI can render token deltas in real time and then apply the
/// final structured sidecar (translation, correction, suggested replies,
/// vocab) atomically.
///
/// Production guarantees:
///   - Auth token is read from `auth_token` / `access_token` SharedPreferences
///     keys (same as `ApiService`) so all calls flow through the standard
///     auth/refresh path on the backend.
///   - Stream is parsed strictly per the SSE wire format (`event:` + `data:`
///     blocks separated by a blank line). Multi-line `data:` fields are joined
///     with `\n` as required by the spec.
///   - The returned `Stream` is single-subscription and closes when the
///     server emits `done` / `error` or when the underlying socket finishes.
///   - 60s idle timeout; keepalive comments (`:`) are tolerated.
///   - Backend errors are surfaced as `PolieConversationStreamErrorEvent`
///     (not exceptions) unless the HTTP handshake itself fails.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/services/env_config.dart';

/// One historical turn passed into the stream request body.
class PolieConversationTurnInput {
  final String role; // 'user' | 'assistant'
  final String text;
  const PolieConversationTurnInput({required this.role, required this.text});
  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// Base type for all events emitted by the conversation stream.
sealed class PolieConversationStreamEvent {
  const PolieConversationStreamEvent();
}

/// Emitted once at the start of the stream with provider/model metadata and
/// the canonical conversationId (whether server-assigned or echoed back).
class PolieConversationStreamMetaEvent extends PolieConversationStreamEvent {
  final String conversationId;
  final String language;
  final String persona;
  final String responseStyle;
  final String provider;
  final String model;
  const PolieConversationStreamMetaEvent({
    required this.conversationId,
    required this.language,
    required this.persona,
    required this.responseStyle,
    required this.provider,
    required this.model,
  });
}

/// Token / chunk delta emitted as the model streams its target-language reply.
class PolieConversationStreamDeltaEvent extends PolieConversationStreamEvent {
  final String text;
  const PolieConversationStreamDeltaEvent(this.text);
}

/// Final structured sidecar event emitted after the natural-language stream
/// completes. Contains the cleaned `messageTarget`, optional English
/// translation, correction object, suggested replies, and new vocab items.
class PolieConversationStreamFinalEvent extends PolieConversationStreamEvent {
  final String conversationId;
  final String messageTarget;
  final String? englishTranslation;
  final PolieConversationStreamCorrection correction;
  final List<String> suggestedReplies;
  final List<PolieConversationStreamVocab> newVocab;
  final String provider;
  final String model;
  final int durationMs;
  const PolieConversationStreamFinalEvent({
    required this.conversationId,
    required this.messageTarget,
    required this.englishTranslation,
    required this.correction,
    required this.suggestedReplies,
    required this.newVocab,
    required this.provider,
    required this.model,
    required this.durationMs,
  });
}

/// A recoverable / non-recoverable error surfaced by the backend.
class PolieConversationStreamErrorEvent extends PolieConversationStreamEvent {
  final String error;
  final bool retryable;
  const PolieConversationStreamErrorEvent({
    required this.error,
    required this.retryable,
  });
}

/// Terminal event indicating the server has finished cleanly.
class PolieConversationStreamDoneEvent extends PolieConversationStreamEvent {
  const PolieConversationStreamDoneEvent();
}

class PolieConversationStreamCorrection {
  final String tier; // 'correct' | 'close' | 'incorrect'
  final bool hasCorrection;
  final bool wasCorrect;
  final String? correction;
  final String note;
  const PolieConversationStreamCorrection({
    required this.tier,
    required this.hasCorrection,
    required this.wasCorrect,
    required this.correction,
    required this.note,
  });

  factory PolieConversationStreamCorrection.fromJson(Map<String, dynamic> json) {
    var tier = (json['tier'] ?? 'correct').toString().toLowerCase();
    if (tier != 'close' && tier != 'incorrect') tier = 'correct';
    final corrRaw = json['correction'];
    return PolieConversationStreamCorrection(
      tier: tier,
      hasCorrection: json['hasCorrection'] == true,
      wasCorrect: json['wasCorrect'] == true,
      correction: (corrRaw is String && corrRaw.trim().isNotEmpty) ? corrRaw : null,
      note: (json['note'] ?? '').toString(),
    );
  }
}

class PolieConversationStreamVocab {
  final String word;
  final String meaning;
  const PolieConversationStreamVocab({required this.word, required this.meaning});
  factory PolieConversationStreamVocab.fromJson(Map<String, dynamic> json) {
    return PolieConversationStreamVocab(
      word: (json['word'] ?? '').toString(),
      meaning: (json['meaning'] ?? '').toString(),
    );
  }
}

class PolieConversationStreamService {
  PolieConversationStreamService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  StreamSubscription<String>? _activeSub;
  StreamController<PolieConversationStreamEvent>? _activeController;
  Timer? _idleTimer;
  bool _disposed = false;

  static const String _streamPath = '/api/v2/polie/conversation/stream';
  static const Duration _handshakeTimeout = Duration(seconds: 30);
  static const Duration _idleTimeout = Duration(seconds: 60);

  Uri _endpoint(String path) {
    final base = EnvConfig.backendBaseUrl.endsWith('/')
        ? EnvConfig.backendBaseUrl
            .substring(0, EnvConfig.backendBaseUrl.length - 1)
        : EnvConfig.backendBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<String?> _authToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('access_token');
  }

  /// Sends one conversation turn and returns a stream of structured events.
  ///
  /// The stream closes when the server emits a `done` or `error` event, when
  /// the underlying response stream ends, when the idle-timeout fires, or
  /// when the caller cancels the subscription. Callers must cancel the
  /// subscription (via `await for` `break` or `subscription.cancel()`) to
  /// terminate early.
  Stream<PolieConversationStreamEvent> sendConversationTurn({
    required String language,
    required String userMessage,
    String? conversationId,
    String responseStyle = 'witty',
    bool wantsEnglish = false,
    String persona = 'encouraging_mentor',
    List<PolieConversationTurnInput> history = const [],
  }) async* {
    if (_disposed) {
      throw StateError('PolieConversationStreamService has been disposed.');
    }

    final uri = _endpoint(_streamPath);
    final token = await _authToken();
    final body = jsonEncode({
      if (conversationId != null && conversationId.isNotEmpty)
        'conversationId': conversationId,
      'language': language,
      'userMessage': userMessage,
      'responseStyle': responseStyle,
      'wantsEnglish': wantsEnglish,
      'persona': persona,
      'history': history.map((t) => t.toJson()).toList(),
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = body;

    final streamed = await _client.send(request).timeout(_handshakeTimeout);

    if (streamed.statusCode != 200) {
      final fallback = await streamed.stream.bytesToString();
      throw HttpException(
        'Polie SSE handshake failed (${streamed.statusCode}): '
        '${fallback.substring(0, fallback.length.clamp(0, 240))}',
      );
    }

    final controller = StreamController<PolieConversationStreamEvent>();
    _activeController = controller;

    void armIdle() {
      _idleTimer?.cancel();
      _idleTimer = Timer(_idleTimeout, () {
        if (!controller.isClosed) {
          controller.add(const PolieConversationStreamErrorEvent(
            error: 'Conversation stream idle for too long',
            retryable: true,
          ));
          controller.close();
          _activeSub?.cancel();
        }
      });
    }

    final parser = _SseParser(
      onEvent: (event) {
        if (controller.isClosed) return;
        controller.add(event);
        if (event is PolieConversationStreamDoneEvent ||
            event is PolieConversationStreamErrorEvent) {
          _idleTimer?.cancel();
          controller.close();
          _activeSub?.cancel();
        } else {
          armIdle();
        }
      },
      onParseError: (err) {
        if (kDebugMode) debugPrint('[PolieSSE] parse error: $err');
      },
    );

    armIdle();
    _activeSub = streamed.stream.transform(utf8.decoder).listen(
      parser.feed,
      onError: (Object err, StackTrace st) {
        if (!controller.isClosed) {
          controller.add(PolieConversationStreamErrorEvent(
            error: err.toString(),
            retryable: true,
          ));
          controller.close();
        }
        _idleTimer?.cancel();
      },
      onDone: () {
        parser.flush();
        if (!controller.isClosed) {
          controller.add(const PolieConversationStreamDoneEvent());
          controller.close();
        }
        _idleTimer?.cancel();
      },
      cancelOnError: true,
    );

    controller.onCancel = () async {
      _idleTimer?.cancel();
      await _activeSub?.cancel();
    };

    yield* controller.stream;
  }

  /// Releases the underlying HTTP client (if it was created by this service)
  /// and cancels any in-flight stream subscription. Safe to call multiple
  /// times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _idleTimer?.cancel();
    _activeSub?.cancel();
    if (_activeController != null && !_activeController!.isClosed) {
      _activeController!.close();
    }
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Parses a Server-Sent Events byte stream into structured events. Strict per
/// the EventSource specification: events are delimited by blank lines; each
/// non-blank line is `field: value`; `data` fields concatenate with `\n`.
class _SseParser {
  _SseParser({required this.onEvent, required this.onParseError});

  final void Function(PolieConversationStreamEvent event) onEvent;
  final void Function(String error) onParseError;

  String _buffer = '';
  String _eventName = '';
  final StringBuffer _dataBuf = StringBuffer();

  void feed(String chunk) {
    _buffer += chunk;
    while (true) {
      final newlineIdx = _buffer.indexOf('\n');
      if (newlineIdx < 0) break;
      var line = _buffer.substring(0, newlineIdx);
      _buffer = _buffer.substring(newlineIdx + 1);
      if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
      _processLine(line);
    }
  }

  void flush() {
    if (_buffer.isNotEmpty) {
      _processLine(_buffer);
      _buffer = '';
    }
    _dispatch();
  }

  void _processLine(String line) {
    if (line.isEmpty) {
      _dispatch();
      return;
    }
    if (line.startsWith(':')) {
      // Comment / keepalive — ignore per spec.
      return;
    }
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        _eventName = value;
        break;
      case 'data':
        if (_dataBuf.isNotEmpty) _dataBuf.write('\n');
        _dataBuf.write(value);
        break;
      case 'id':
      case 'retry':
        // Unused by our application logic.
        break;
      default:
        // Unknown field — ignore per spec.
        break;
    }
  }

  void _dispatch() {
    if (_dataBuf.isEmpty && _eventName.isEmpty) return;
    final raw = _dataBuf.toString();
    final name = _eventName.isEmpty ? 'message' : _eventName;
    _eventName = '';
    _dataBuf.clear();

    Map<String, dynamic>? json;
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (e) {
        onParseError('JSON decode failed for event "$name": $e');
        return;
      }
    }

    switch (name) {
      case 'meta':
        if (json == null) return;
        onEvent(PolieConversationStreamMetaEvent(
          conversationId: (json['conversationId'] ?? '').toString(),
          language: (json['language'] ?? '').toString(),
          persona: (json['persona'] ?? 'encouraging_mentor').toString(),
          responseStyle: (json['responseStyle'] ?? 'witty').toString(),
          provider: (json['provider'] ?? '').toString(),
          model: (json['model'] ?? '').toString(),
        ));
        break;
      case 'delta':
        if (json == null) return;
        final text = (json['text'] ?? '').toString();
        if (text.isNotEmpty) onEvent(PolieConversationStreamDeltaEvent(text));
        break;
      case 'final':
        if (json == null) return;
        final replies = (json['suggestedReplies'] is List)
            ? (json['suggestedReplies'] as List)
                .map((e) => e.toString())
                .toList()
            : <String>[];
        final vocab = (json['newVocab'] is List)
            ? (json['newVocab'] as List)
                .whereType<Map>()
                .map((e) => PolieConversationStreamVocab.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList()
            : <PolieConversationStreamVocab>[];
        final correctionRaw = json['correction'];
        final correction = correctionRaw is Map
            ? PolieConversationStreamCorrection.fromJson(
                Map<String, dynamic>.from(correctionRaw))
            : const PolieConversationStreamCorrection(
                tier: 'correct',
                hasCorrection: false,
                wasCorrect: true,
                correction: null,
                note: '',
              );
        onEvent(PolieConversationStreamFinalEvent(
          conversationId: (json['conversationId'] ?? '').toString(),
          messageTarget: (json['messageTarget'] ?? '').toString(),
          englishTranslation: (json['englishTranslation'] is String &&
                  (json['englishTranslation'] as String).trim().isNotEmpty)
              ? json['englishTranslation'] as String
              : null,
          correction: correction,
          suggestedReplies: replies,
          newVocab: vocab,
          provider: (json['provider'] ?? '').toString(),
          model: (json['model'] ?? '').toString(),
          durationMs: (json['durationMs'] is num)
              ? (json['durationMs'] as num).toInt()
              : 0,
        ));
        break;
      case 'error':
        if (json == null) return;
        onEvent(PolieConversationStreamErrorEvent(
          error: (json['error'] ?? 'Unknown error').toString(),
          retryable: json['retryable'] != false,
        ));
        break;
      case 'done':
        onEvent(const PolieConversationStreamDoneEvent());
        break;
      default:
        // Unknown event name — ignore.
        break;
    }
  }
}
