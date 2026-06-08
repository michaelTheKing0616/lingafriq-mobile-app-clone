// TTS Prefetch Service
//
// On lesson open, eagerly resolves audio for every vocab + dialogue line in
// the lesson so the user's first tap on "▶" is instantaneous. Resolution
// goes through AfricanTtsService (gold/silver/bronze) and the disk cache is
// populated as a side effect.
//
// Prefetch is best-effort and bounded: we limit concurrency to keep mobile
// data and CPU usage friendly, and abort silently when offline.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';

class PrefetchItem {
  final String language;
  final String text;
  final bool slow;
  const PrefetchItem({
    required this.language,
    required this.text,
    this.slow = false,
  });
}

class TtsPrefetchService {
  TtsPrefetchService._();
  static final TtsPrefetchService _i = TtsPrefetchService._();
  factory TtsPrefetchService() => _i;

  static const int _maxConcurrent = 3;
  final AfricanTtsService _tts = AfricanTtsService();
  final Set<String> _seen = <String>{};

  /// Prefetches every distinct (language, text, slow) tuple in [items].
  /// Returns once all in-flight resolves have completed (or timed out).
  Future<void> prefetch(Iterable<PrefetchItem> items) async {
    final unique = <PrefetchItem>[];
    for (final it in items) {
      if (it.text.trim().isEmpty || it.language.trim().isEmpty) continue;
      final key = '${it.language.toLowerCase()}|${it.slow ? 'slow' : 'native'}|${it.text}';
      if (_seen.contains(key)) continue;
      _seen.add(key);
      unique.add(it);
    }
    if (unique.isEmpty) return;

    final queue = List<PrefetchItem>.from(unique);
    final inflight = <Future<void>>[];
    while (queue.isNotEmpty || inflight.isNotEmpty) {
      while (inflight.length < _maxConcurrent && queue.isNotEmpty) {
        final next = queue.removeAt(0);
        final task = () async {
          try {
            await _tts
                .resolve(
                  language: next.language,
                  text: next.text,
                  slow: next.slow,
                )
                .timeout(const Duration(seconds: 12));
          } catch (e) {
            debugPrint('[TtsPrefetch] resolve failed: $e');
          }
        }();
        inflight.add(task);
        unawaited(
          task.whenComplete(() => inflight.remove(task)),
        );
      }
      if (inflight.isNotEmpty) {
        await Future.any(inflight);
      }
    }
  }

  /// Convenience for the Authentic Path lesson screen: prefetches vocab,
  /// dialogue, and exercise prompts in batch.
  Future<void> prefetchLessonContent({
    required String language,
    required List<String> vocab,
    required List<String> dialogueLines,
    required List<String> exercisePrompts,
  }) async {
    final items = <PrefetchItem>[
      for (final v in vocab) PrefetchItem(language: language, text: v),
      for (final v in vocab) PrefetchItem(language: language, text: v, slow: true),
      for (final d in dialogueLines) PrefetchItem(language: language, text: d),
      for (final e in exercisePrompts) PrefetchItem(language: language, text: e),
    ];
    await prefetch(items);
  }

  void resetSeen() => _seen.clear();
}
