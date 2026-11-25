import 'package:lingafriq/services/sync/outbox_service.dart';
import 'package:lingafriq/services/sync/outbox_worker.dart';

/// How the next outbox push should fail (P12-019 fault injection).
enum NetworkFault {
  none,
  transportDrop,
  http500,
  http503,
  timeout,
}

/// Idempotent server stub — each idempotency key applies at most once.
class RecordingOutboxTransport implements OutboxTransport {
  RecordingOutboxTransport({IdempotentLedger? ledger}) : ledger = ledger ?? IdempotentLedger();

  final IdempotentLedger ledger;
  final Set<String> appliedIdempotencyKeys = {};
  int pushCallCount = 0;

  @override
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch) async {
    pushCallCount += 1;
    final results = <OutboxItemResult>[];
    for (final row in batch) {
      final duplicate = appliedIdempotencyKeys.contains(row.idempotencyKey);
      if (!duplicate) {
        ledger.apply(row.idempotencyKey, () => row.id);
        appliedIdempotencyKeys.add(row.idempotencyKey);
      }
      results.add(
        OutboxItemResult(
          clientOperationId: row.id,
          ok: true,
          duplicate: duplicate,
        ),
      );
    }
    return OutboxBatchResponse(statusCode: 200, results: results);
  }
}

/// Wraps a transport and injects drops, 5xx, or timeouts on a schedule.
class FaultInjectingOutboxTransport implements OutboxTransport {
  FaultInjectingOutboxTransport({
    required this.inner,
    this.flapOnCallNumbers = const {},
    this.flapPredicate,
    NetworkFault fault = NetworkFault.none,
  }) : _fault = fault;

  final OutboxTransport inner;
  final Set<int> flapOnCallNumbers;
  final bool Function(int call)? flapPredicate;
  NetworkFault _fault;
  int _calls = 0;

  int get callCount => _calls;

  void setFault(NetworkFault fault) => _fault = fault;

  @override
  Future<OutboxBatchResponse> push(List<OutboxRecord> batch) async {
    _calls += 1;
    if (flapOnCallNumbers.contains(_calls) || (flapPredicate?.call(_calls) ?? false)) {
      return const OutboxBatchResponse(statusCode: null, transportFailed: true);
    }
    switch (_fault) {
      case NetworkFault.transportDrop:
        return const OutboxBatchResponse(statusCode: null, transportFailed: true);
      case NetworkFault.http500:
        return const OutboxBatchResponse(statusCode: 500, results: []);
      case NetworkFault.http503:
        return const OutboxBatchResponse(statusCode: 503, results: []);
      case NetworkFault.timeout:
        return const OutboxBatchResponse(statusCode: 408, results: []);
      case NetworkFault.none:
        return inner.push(batch);
    }
  }
}

/// Flap every [period] push attempts (simulates 5 s cadence when paired with clock steps).
FaultInjectingOutboxTransport periodicFlapTransport({
  required OutboxTransport inner,
  required int period,
}) {
  return FaultInjectingOutboxTransport(
    inner: inner,
    flapPredicate: (call) => period > 0 && call % period == 0,
  );
}
