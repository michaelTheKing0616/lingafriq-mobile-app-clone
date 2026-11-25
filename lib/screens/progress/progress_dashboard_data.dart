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

  /// Consecutive practice days ending today (or yesterday, if today has no
  /// practice yet, so the streak is not shown as broken before the day ends).
  late final int streak = () {
    final d = dailyMinutes;
    var i = d.length - 1;
    if (d[i] == 0) i--;
    var n = 0;
    while (i >= 0 && d[i] > 0) {
      n++;
      i--;
    }
    return n;
  }();

  static const milestones = [3, 7, 14, 30, 60, 100, 365];

  /// The next streak milestone above [streak] (the last one once passed).
  int get nextMilestone =>
      milestones.firstWhere((m) => m > streak, orElse: () => milestones.last);

  /// The milestone just reached today, if any (for the celebration).
  int? get milestoneHit =>
      milestones.contains(streak) && dailyMinutes.last > 0 ? streak : null;

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

/// Local reads either work or show the error state; no silent auto-retry.
final progressSnapshotProvider = FutureProvider.autoDispose<ProgressSnapshot>(
  retry: (_, _) => null,
  (ref) async {
    ref.watch(progressTrackingProvider);
    final n = ref.read(progressTrackingProvider.notifier);
    await n.loaded;
    return ProgressSnapshot(
      metrics: n.metrics,
      history: n.history,
      today: ref.read(progressClockProvider)(),
    );
  },
);
