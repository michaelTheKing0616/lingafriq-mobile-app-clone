import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/speaking_grader.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Speaking prompt scored by an injected [SpeakingScorer].
///
/// Pass [HttpSpeakingScorer] for the hybrid-polie pronounce endpoint.
/// A missing scorer or recorder resolves to `unavailable` and does not invent
/// a score. When [storeAudio] is false (the default), the recording is
/// discarded after scoring returns, including unsure and unavailable results.
class SpeakingItem extends StatefulWidget {
  const SpeakingItem({
    super.key,
    required this.prompt,
    required this.referenceText,
    required this.language,
    this.scorer,
    this.recorder,
    this.storeAudio = false,
  });

  final String prompt;
  final String referenceText;
  final String language;
  final SpeakingScorer? scorer;
  final SpeakingRecorder? recorder;

  /// When false, raw audio is deleted after the scorer returns.
  final bool storeAudio;

  @override
  State<SpeakingItem> createState() => _SpeakingItemState();
}

class _SpeakingItemState extends State<SpeakingItem> {
  String _phase = 'idle';
  SpeakingGrade? _grade;
  var _busy = false;

  Future<void> _onPressed() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_phase == 'idle') {
        await _start();
      } else if (_phase == 'recording') {
        await _finish();
      }
    } finally {
      _busy = false;
    }
  }

  void _showUnavailable() {
    setState(() {
      _phase = 'unavailable';
      _grade = const SpeakingGrade(
        phase: 'unavailable',
        score: null,
        confidence: null,
      );
    });
  }

  Future<void> _start() async {
    final recorder = widget.recorder;
    if (recorder == null || widget.scorer == null) {
      _showUnavailable();
      return;
    }
    setState(() => _phase = 'recording');
    try {
      await recorder.start();
    } catch (_) {
      if (!mounted) return;
      _showUnavailable();
    }
  }

  Future<void> _finish() async {
    final recorder = widget.recorder;
    final scorer = widget.scorer;
    if (recorder == null || scorer == null) {
      _showUnavailable();
      return;
    }
    setState(() => _phase = 'scoring');
    String? path;
    var payload = const ScorerPayload(
      score: null,
      confidence: null,
      available: false,
    );
    try {
      path = await recorder.stop();
      payload = await scorer.score(
        audioPath: path,
        referenceText: widget.referenceText,
        language: widget.language,
      );
    } catch (_) {
      payload = const ScorerPayload(
        score: null,
        confidence: null,
        available: false,
      );
    }
    // No storage opt-in: drop the take after the scorer returns, including
    // when the result is unsure, unavailable, or the call failed.
    if (!widget.storeAudio && path != null) {
      try {
        await recorder.discard(path);
      } catch (_) {
        payload = const ScorerPayload(
          score: null,
          confidence: null,
          available: false,
        );
      }
    }
    if (!mounted) return;
    final grade = gradeSpeaking(payload);
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grade = _grade;
    final showScore =
        _phase == 'scored' &&
        grade != null &&
        grade.score != null &&
        grade.confidence != null;
    final showStop = _phase == 'recording' || _phase == 'scoring';
    final canPress = _phase == 'idle' || _phase == 'recording';
    return Semantics(
      key: ValueKey<String>('phase-$_phase'),
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              SpeakingCopy.speak,
              style: TextStyle(
                color: PanAfricanColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              widget.prompt,
              style: const TextStyle(color: PanAfricanColors.neutralDarkest),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Semantics(
              button: true,
              label: 'item.speak',
              child: FilledButton(
                onPressed: canPress ? () => unawaited(_onPressed()) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: PanAfricanColors.surfaceContainerLowestLight,
                  minimumSize: const Size(
                    AdaptiveLayout.minTouchTarget,
                    AdaptiveLayout.minTouchTarget,
                  ),
                ),
                child: Text(showStop ? SpeakingCopy.stop : SpeakingCopy.record),
              ),
            ),
            if (showScore) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                grade.score!.toString(),
                style: const TextStyle(
                  color: PanAfricanColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xxs),
              Text(
                grade.confidence!.toString(),
                style: const TextStyle(color: PanAfricanColors.neutralMedium),
              ),
            ] else if (_phase == 'unsure') ...[
              SizedBox(height: PanAfricanSpacing.md),
              const Text(
                SpeakingCopy.unsure,
                style: TextStyle(color: PanAfricanColors.warning),
              ),
            ] else if (_phase == 'unavailable') ...[
              SizedBox(height: PanAfricanSpacing.md),
              const Text(
                SpeakingCopy.unavailable,
                style: TextStyle(color: PanAfricanColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
