import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/progress_metrics_model.dart';
import 'package:lingafriq/providers/progress_tracking_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';

/// What the progress screen renders, derived from on-device metrics.
class ProgressSnapshot {
  ProgressSnapshot({
    required this.metrics,
    required this.history,
    required this.today,
  });

  final ProgressMetrics metrics;

  /// Daily cumulative snapshots (one per day, up to 30).
  final List<ProgressMetrics> history;
  final DateTime today;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Minutes learned on each of the 28 days ending today (oldest first).
  /// History rows are cumulative, so a day's minutes are its total minus the
  /// previous recorded day's total.
  late final List<int> dailyMinutes = _daily(28);

  List<int> _daily(int days) {
    final rows = [...history]
      ..sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));
    final byDay = <DateTime, double>{};
    double prev = 0;
    for (final r in rows) {
      final d = _day(r.lastUpdated);
      final delta = r.timeSpentMinutes - prev;
      byDay[d] = (byDay[d] ?? 0) + (delta < 0 ? 0 : delta);
      prev = r.timeSpentMinutes;
    }
    final end = _day(today);
    return [
      for (var i = days - 1; i >= 0; i--)
        (byDay[DateTime(end.year, end.month, end.day - i)] ?? 0).round(),
    ];
  }

  List<int> get thisWeek => dailyMinutes.sublist(21);
  int get thisWeekTotal => thisWeek.fold(0, (a, b) => a + b);
  int get lastWeekTotal =>
      dailyMinutes.sublist(14, 21).fold(0, (a, b) => a + b);
  int get activeDays => dailyMinutes.where((m) => m > 0).length;

  /// Activities by hours, largest first.
  List<MapEntry<String, double>> get activities =>
      metrics.timeByActivity.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  bool get isEmpty =>
      metrics.wordsLearned == 0 &&
      metrics.knownWords == 0 &&
      metrics.timeSpentMinutes <= 0 &&
      metrics.listeningHours <= 0 &&
      metrics.speakingHours <= 0 &&
      activeDays == 0;
}

/// Clock for the dashboard (overridable in tests).
final progressClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Connectivity for the offline note (overridable in tests).
final progressOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

final progressSnapshotProvider = FutureProvider.autoDispose<ProgressSnapshot>((
  ref,
) async {
  ref.watch(progressTrackingProvider);
  final n = ref.read(progressTrackingProvider.notifier);
  await n.loaded;
  return ProgressSnapshot(
    metrics: n.metrics,
    history: n.history,
    today: ref.read(progressClockProvider)(),
  );
});
