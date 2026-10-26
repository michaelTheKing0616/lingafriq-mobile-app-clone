import 'dart:convert';

import 'package:lingafriq/utils/api_service.dart';

/// POST `/api/v2/item-reports`
const String itemReportApiPath = '/api/v2/item-reports';

const String itemReportPendingPrefsKey = 'item_report_pending_v1';

enum ItemReportSubmitState {
  idle,
  submitting,
  sent,
  queuedOffline,
  error,
}

typedef ItemReportPost = Future<void> Function(Map<String, Object?> body);

class ItemReportService {
  ItemReportService({
    ItemReportPost? post,
    Future<List<Map<String, Object?>>> Function()? loadPending,
    Future<void> Function(List<Map<String, Object?>> pending)? savePending,
    Future<bool> Function()? isOnline,
  })  : _post = post ?? _defaultPost,
        _loadPending = loadPending ?? _defaultLoadPending,
        _savePending = savePending ?? _defaultSavePending,
        _isOnline = isOnline ?? (() async => true);

  final ItemReportPost _post;
  final Future<List<Map<String, Object?>>> Function() _loadPending;
  final Future<void> Function(List<Map<String, Object?>> pending) _savePending;
  final Future<bool> Function() _isOnline;

  int _pendingCount = 0;

  int get pendingCount => _pendingCount;

  static Future<void> _defaultPost(Map<String, Object?> body) async {
    await ApiService.initialize();
    await ApiService.post(itemReportApiPath, data: body);
  }

  static Future<List<Map<String, Object?>>> _defaultLoadPending() async {
    return [];
  }

  static Future<void> _defaultSavePending(List<Map<String, Object?>> pending) async {}

  Future<void> refreshPendingCount() async {
    final pending = await _loadPending();
    _pendingCount = pending.length;
  }

  Future<ItemReportSubmitState> submitReport({
    required String itemId,
    required String packVersion,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      return ItemReportSubmitState.error;
    }

    final body = <String, Object?>{
      'item_id': itemId,
      'pack_version': packVersion,
      'reason': trimmedReason,
    };

    if (!await _isOnline()) {
      await _enqueuePending(body);
      return ItemReportSubmitState.queuedOffline;
    }

    try {
      await _post(body);
      return ItemReportSubmitState.sent;
    } catch (_) {
      await _enqueuePending(body);
      return ItemReportSubmitState.queuedOffline;
    }
  }

  Future<void> flushPending() async {
    if (!await _isOnline()) {
      return;
    }
    final pending = await _loadPending();
    if (pending.isEmpty) {
      _pendingCount = 0;
      return;
    }
    final remaining = <Map<String, Object?>>[];
    for (final body in pending) {
      try {
        await _post(body);
      } catch (_) {
        remaining.add(body);
      }
    }
    await _savePending(remaining);
    _pendingCount = remaining.length;
  }

  Future<void> _enqueuePending(Map<String, Object?> body) async {
    final pending = await _loadPending();
    pending.add(body);
    await _savePending(pending);
    _pendingCount = pending.length;
  }
}

/// In-memory pending store for tests and optional injection.
class InMemoryItemReportPendingStore {
  final List<Map<String, Object?>> _rows = [];

  Future<List<Map<String, Object?>>> load() async =>
      _rows.map((e) => Map<String, Object?>.from(e)).toList();

  Future<void> save(List<Map<String, Object?>> pending) async {
    _rows
      ..clear()
      ..addAll(pending.map((e) => Map<String, Object?>.from(e)));
  }

  String encode() => jsonEncode(_rows);
}
