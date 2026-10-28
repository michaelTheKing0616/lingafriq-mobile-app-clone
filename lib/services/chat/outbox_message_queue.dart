import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local send state for WA/private chat messages (P9-909).
enum ChatOutboxState {
  queued,
  sending,
  sent,
  failed,
}

extension ChatOutboxStateWire on ChatOutboxState {
  String get wire => name;

  static ChatOutboxState parse(String? raw) {
    return ChatOutboxState.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => ChatOutboxState.queued,
    );
  }
}

class ChatOutboxEntry {
  ChatOutboxEntry({
    required this.id,
    required this.recipientId,
    required this.message,
    required this.clientMessageId,
    required this.state,
    required this.createdAt,
    required this.attempts,
    this.lastError,
    this.serverPayload,
  });

  final String id;
  final String recipientId;
  final String message;
  final String clientMessageId;
  ChatOutboxState state;
  final DateTime createdAt;
  int attempts;
  String? lastError;
  Map<String, dynamic>? serverPayload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientId': recipientId,
        'message': message,
        'clientMessageId': clientMessageId,
        'state': state.wire,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        if (lastError != null) 'lastError': lastError,
        if (serverPayload != null) 'serverPayload': serverPayload,
      };

  factory ChatOutboxEntry.fromJson(Map<String, dynamic> json) {
    return ChatOutboxEntry(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipientId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      clientMessageId: json['clientMessageId']?.toString() ?? '',
      state: ChatOutboxStateWire.parse(json['state']?.toString()),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      attempts: int.tryParse(json['attempts']?.toString() ?? '') ?? 0,
      lastError: json['lastError']?.toString(),
      serverPayload: json['serverPayload'] is Map
          ? Map<String, dynamic>.from(json['serverPayload'] as Map)
          : null,
    );
  }

  /// Shown when retries are exhausted (AC2).
  bool get showFailedTapToRetry => state == ChatOutboxState.failed;

  String get failedUserHint => 'failed, tap to retry';
}

typedef ChatOutboxSendFn = Future<Map<String, dynamic>?> Function(ChatOutboxEntry entry);

/// Durable FIFO queue for chat sends while offline.
class ChatOutboxMessageQueue {
  ChatOutboxMessageQueue({
    SharedPreferences? prefs,
    this.maxAttempts = 5,
    this.storageKey = 'chat_outbox_message_queue_v1',
    Uuid? uuid,
  })  : _prefsFuture = prefs != null ? Future.value(prefs) : SharedPreferences.getInstance(),
        _uuid = uuid ?? const Uuid();

  final Future<SharedPreferences> _prefsFuture;
  final Uuid _uuid;
  final String storageKey;
  final int maxAttempts;

  Future<List<ChatOutboxEntry>> _loadAll() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => ChatOutboxEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _saveAll(List<ChatOutboxEntry> rows) async {
    final prefs = await _prefsFuture;
    final encoded = jsonEncode(rows.map((r) => r.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  Future<ChatOutboxEntry> enqueue({
    required String recipientId,
    required String message,
    String? clientMessageId,
  }) async {
    final rows = await _loadAll();
    final id = clientMessageId?.trim().isNotEmpty == true
        ? clientMessageId!.trim()
        : _uuid.v4();
    final existing = rows.indexWhere((r) => r.clientMessageId == id);
    if (existing >= 0) {
      return rows[existing];
    }
    final entry = ChatOutboxEntry(
      id: _uuid.v4(),
      recipientId: recipientId.trim(),
      message: message,
      clientMessageId: id,
      state: ChatOutboxState.queued,
      createdAt: DateTime.now().toUtc(),
      attempts: 0,
    );
    rows.add(entry);
    await _saveAll(rows);
    return entry;
  }

  Future<List<ChatOutboxEntry>> listOrdered({bool includeSent = false}) async {
    final rows = await _loadAll();
    if (includeSent) return rows;
    return rows.where((r) => r.state != ChatOutboxState.sent).toList();
  }

  Future<void> retry(String clientMessageId) async {
    final rows = await _loadAll();
    for (final row in rows) {
      if (row.clientMessageId == clientMessageId && row.state == ChatOutboxState.failed) {
        row.state = ChatOutboxState.queued;
        row.lastError = null;
        row.attempts = 0;
      }
    }
    await _saveAll(rows);
  }

  int backoffMsForAttempt(int attempts) {
    final step = attempts.clamp(1, 8);
    return 250 * (1 << (step - 1));
  }

  /// Sends queued rows in order when [isOnline] is true.
  Future<void> flush({
    required bool Function() isOnline,
    required ChatOutboxSendFn send,
  }) async {
    if (!isOnline()) return;

    final rows = await _loadAll();
    var dirty = false;

    for (final row in rows) {
      if (row.state == ChatOutboxState.sent) continue;
      if (row.state == ChatOutboxState.failed) continue;
      if (row.state == ChatOutboxState.sending) continue;

      row.state = ChatOutboxState.sending;
      dirty = true;
      await _saveAll(rows);

      row.attempts += 1;
      try {
        final result = await send(row);
        if (result != null) {
          row.state = ChatOutboxState.sent;
          row.serverPayload = result;
          row.lastError = null;
        } else {
          _markRetryOrFailed(row);
        }
      } catch (e) {
        row.lastError = e.toString();
        _markRetryOrFailed(row);
      }
      dirty = true;
      await _saveAll(rows);

      if (row.state == ChatOutboxState.queued && !isOnline()) {
        break;
      }
    }

    if (dirty) {
      await _saveAll(rows);
    }
  }

  void _markRetryOrFailed(ChatOutboxEntry row) {
    if (row.attempts >= maxAttempts) {
      row.state = ChatOutboxState.failed;
    } else {
      row.state = ChatOutboxState.queued;
    }
  }
}
