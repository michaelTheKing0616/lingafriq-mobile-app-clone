import 'dart:math';

import 'outbox_service.dart';

/// Backoff cap for a transient outbox failure. Delay is
/// `250ms * 2^(attempt-1)` plus jitter, and it never grows past this cap.
const int outboxBackoffCapMs = 60000;

const int outboxBackoffBaseMs = 250;

/// Same key applies the effect once. A second call returns the stored result.
class IdempotentLedger {
  final Map<String, Object?> _results = {};
  int applications = 0;

  Object? apply(String key, Object? Function() effect) {
    if (_results.containsKey(key)) return _results[key];
    applications += 1;
    final value = effect();
    _results[key] = value;
    return value;
  }
}

class OutboxItemResult {
  const OutboxItemResult({
    required this.clientOperationId,
    required this.ok,
    this.duplicate = false,
    this.error,
  });

  final String clientOperationId;
  final bool ok;
  final bool duplicate;
  final String? error;
}

class OutboxBatchResponse {
  const OutboxBatchResponse({
    required this.statusCode,
    this.results = const [],
    this.transportFailed = false,
  });

  final int? statusCode;
  final List<OutboxItemResult> results;
  final bool transportFailed;
}

abstract class OutboxTransport {
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch);
}

/// Errors the server will not accept on a retry. The row stays visible.
const Set<String> outboxPermanentErrors = {
  'invalid_idempotency_key',
  'invalid_client_operation_id',
  'unsupported_operation_type',
  'payload_too_large',
  'client_install_id_too_long',
  'client_app_version_too_long',
  'invalid_schema_version',
  'invalid_operation',
};

bool isPermanentOutboxStatus(int? status) {
  if (status == null) return false;
  if (status == 408 || status == 429) return false;
  return status >= 400 && status < 500;
}

int outboxBackoffMs(int attempt, int jitterMs) {
  final exponent = attempt <= 1 ? 0 : (attempt - 1).clamp(0, 8);
  final raw = outboxBackoffBaseMs * (1 << exponent);
  final limited = raw > outboxBackoffCapMs ? outboxBackoffCapMs : raw;
  final jitter = jitterMs.abs() % 1000;
  final total = limited + jitter;
  return total > outboxBackoffCapMs ? outboxBackoffCapMs : total;
}

class OutboxWorker {
  OutboxWorker({
    required this.store,
    required this.transport,
    required this.random,
    this.ledger,
  });

  final OutboxService store;
  final OutboxTransport transport;
  final Random random;
  final IdempotentLedger? ledger;

  Future<int> flush({int batchSize = 50}) async {
    final batch = store.due(batchSize: batchSize);
    if (batch.isEmpty) return 0;
    OutboxBatchResponse response;
    try {
      response = await transport.push(batch);
    } catch (error) {
      await _retryAll(batch, 'transport_error', null);
      return 0;
    }
    if (response.transportFailed || response.statusCode == null) {
      await _retryAll(batch, 'transport_error', response.statusCode);
      return 0;
    }
    final status = response.statusCode!;
    if (isPermanentOutboxStatus(status)) {
      for (final row in batch) {
        await store.deadLetter(row.id, error: 'http_$status', statusCode: status);
      }
      return 0;
    }
    if (status == 408 || status == 429 || status >= 500) {
      await _retryAll(batch, 'http_$status', status);
      return 0;
    }
    var completed = 0;
    final seen = <String>{};
    for (final result in response.results) {
      seen.add(result.clientOperationId);
      final row = store.byId(result.clientOperationId);
      if (row == null) continue;
      if (result.ok || result.duplicate) {
        ledger?.apply(row.idempotencyKey, () => result.clientOperationId);
        await store.complete(row.id);
        completed += 1;
        continue;
      }
      final error = result.error ?? 'sync_error';
      if (outboxPermanentErrors.contains(error)) {
        await store.deadLetter(row.id, error: error, statusCode: status);
        continue;
      }
      await store.scheduleRetry(
        row.id,
        error: error,
        statusCode: status,
        delay: Duration(milliseconds: outboxBackoffMs(row.attempts + 1, random.nextInt(1000))),
      );
    }
    for (final row in batch) {
      if (seen.contains(row.id)) continue;
      await store.scheduleRetry(
        row.id,
        error: 'missing_result',
        statusCode: status,
        delay: Duration(milliseconds: outboxBackoffMs(row.attempts + 1, random.nextInt(1000))),
      );
    }
    return completed;
  }

  Future<void> _retryAll(List<OutboxRecord> batch, String error, int? status) async {
    for (final row in batch) {
      await store.scheduleRetry(
        row.id,
        error: error,
        statusCode: status,
        delay: Duration(milliseconds: outboxBackoffMs(row.attempts + 1, random.nextInt(1000))),
      );
    }
  }
}
