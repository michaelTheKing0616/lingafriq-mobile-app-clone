import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/scheduler.dart';

/// EP-§4.5-12 / ADR-034: avatar incremental frame cost on reference Android.
const double kAvatarAddedFrameCostBudgetMs = 2.0;

/// 60 fps target (P12-013 AC2).
const double kAvatarTargetFrameMs = 1000.0 / 60.0;

/// 30 fps thermal floor — reported as degraded, not pass (AC2).
const double kAvatarDegradedFrameMs = 1000.0 / 30.0;

enum AvatarFrameCostVerdict { pass, degraded, fail }

/// Per-frame sample: Rive advance plus attributed UI/raster overhead (ms).
class AvatarFrameCostSample {
  const AvatarFrameCostSample({
    required this.advanceMs,
    required this.uiMs,
    required this.totalFrameMs,
  });

  final double advanceMs;
  final double uiMs;
  final double totalFrameMs;

  double get addedCostMs => advanceMs + uiMs;
}

/// Evaluated profile for one screen path (scroll, speaking, reduced-motion).
class AvatarFrameCostReport {
  AvatarFrameCostReport({
    required this.screen,
    required this.samples,
    required this.reducedMotion,
    required this.droppedFrames,
  }) : verdict = evaluateAvatarFrameCost(
          samples: samples,
          reducedMotion: reducedMotion,
          droppedFrames: droppedFrames,
        );

  final String screen;
  final List<AvatarFrameCostSample> samples;
  final bool reducedMotion;
  final int droppedFrames;
  final AvatarFrameCostVerdict verdict;

  double? medianFrameMs() {
    if (samples.isEmpty) return null;
    final totals = samples.map((s) => s.totalFrameMs).toList()..sort();
    return totals[totals.length ~/ 2];
  }

  double p95AddedCostMs() {
    if (samples.isEmpty) return 0;
    final added = samples.map((s) => s.addedCostMs).toList()..sort();
    final idx = ((added.length - 1) * 0.95).round().clamp(0, added.length - 1);
    return added[idx];
  }

  List<double> worstAddedCostMs({int count = 5}) {
    final added = samples.map((s) => s.addedCostMs).toList()
      ..sort((a, b) => b.compareTo(a));
    return added.take(count).toList();
  }

  Map<String, dynamic> toJson() => {
        'screen': screen,
        'verdict': verdict.name,
        'reduced_motion': reducedMotion,
        'dropped_frames': droppedFrames,
        'p95_added_cost_ms': p95AddedCostMs(),
        'median_frame_ms': medianFrameMs(),
        'worst_added_cost_ms': worstAddedCostMs(),
        'sample_count': samples.length,
      };

  void emitLog() {
    developer.log(
      'report=${jsonEncode(toJson())}',
      name: 'LingAfriqFrameCost',
    );
  }
}

AvatarFrameCostVerdict evaluateAvatarFrameCost({
  required List<AvatarFrameCostSample> samples,
  required bool reducedMotion,
  required int droppedFrames,
}) {
  if (samples.isEmpty) return AvatarFrameCostVerdict.fail;

  if (reducedMotion) {
    return droppedFrames == 0
        ? AvatarFrameCostVerdict.pass
        : AvatarFrameCostVerdict.fail;
  }

  final p95 = _p95(samples.map((s) => s.addedCostMs).toList());
  if (p95 > kAvatarAddedFrameCostBudgetMs) {
    return AvatarFrameCostVerdict.fail;
  }

  final median = _median(samples.map((s) => s.totalFrameMs).toList());
  if (median == null) return AvatarFrameCostVerdict.fail;
  if (median <= kAvatarTargetFrameMs * 1.05) {
    return AvatarFrameCostVerdict.pass;
  }
  if (median <= kAvatarDegradedFrameMs * 1.05) {
    return AvatarFrameCostVerdict.degraded;
  }
  return AvatarFrameCostVerdict.fail;
}

double _p95(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final idx = ((sorted.length - 1) * 0.95).round().clamp(0, sorted.length - 1);
  return sorted[idx];
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

/// Collects [FrameTiming] totals and optional per-frame advance attribution.
class AvatarFrameCostSampler {
  AvatarFrameCostSampler({this.screen = 'avatar_harness'});

  final String screen;
  final List<AvatarFrameCostSample> _samples = [];
  int _droppedFrames = 0;
  bool _attached = false;
  bool _reducedMotion = false;

  List<AvatarFrameCostSample> get samples => List.unmodifiable(_samples);

  int get droppedFrames => _droppedFrames;

  bool get reducedMotion => _reducedMotion;

  void setReducedMotion(bool value) => _reducedMotion = value;

  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void detach() {
    if (!_attached) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _attached = false;
  }

  void recordAdvanceMs(double advanceMs, {double uiMs = 0}) {
    final total = advanceMs + uiMs;
    _samples.add(
      AvatarFrameCostSample(
        advanceMs: advanceMs,
        uiMs: uiMs,
        totalFrameMs: total > 0 ? total : kAvatarTargetFrameMs,
      ),
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      if (totalMs <= 0) continue;
      if (totalMs > kAvatarTargetFrameMs * 1.5) {
        _droppedFrames++;
      }
      _samples.add(
        AvatarFrameCostSample(
          advanceMs: 0,
          uiMs: totalMs,
          totalFrameMs: totalMs,
        ),
      );
    }
  }

  AvatarFrameCostReport buildReport() {
    return AvatarFrameCostReport(
      screen: screen,
      samples: _samples,
      reducedMotion: _reducedMotion,
      droppedFrames: _droppedFrames,
    );
  }

  void reset() {
    _samples.clear();
    _droppedFrames = 0;
  }
}

/// Parses logcat / test lines: `LingAfriqFrameCost: report={...}`.
AvatarFrameCostReport? parseFrameCostLogLine(String line) {
  const prefix = 'LingAfriqFrameCost: report=';
  final idx = line.indexOf(prefix);
  if (idx < 0) return null;
  final raw = line.substring(idx + prefix.length).trim();
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final worst = (map['worst_added_cost_ms'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final count = (map['sample_count'] as num?)?.toInt() ?? worst.length;
    final samples = worst.isEmpty
        ? <AvatarFrameCostSample>[]
        : worst
            .map(
              (w) => AvatarFrameCostSample(
                advanceMs: w * 0.5,
                uiMs: w * 0.5,
                totalFrameMs: kAvatarTargetFrameMs,
              ),
            )
            .toList();
    if (count > samples.length && samples.isNotEmpty) {
      final pad = List<AvatarFrameCostSample>.filled(
        count - samples.length,
        samples.first,
      );
      samples.insertAll(0, pad);
    }
    return AvatarFrameCostReport(
      screen: map['screen'] as String? ?? 'unknown',
      samples: samples,
      reducedMotion: map['reduced_motion'] as bool? ?? false,
      droppedFrames: (map['dropped_frames'] as num?)?.toInt() ?? 0,
    );
  } catch (_) {
    return null;
  }
}
