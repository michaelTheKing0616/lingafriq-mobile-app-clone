import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/games/word_forge/word_forge_screen.dart';
import 'package:lingafriq/lessons/handwriting_practice.dart';
import 'package:lingafriq/lessons/stroke_order_view.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

import 'handwriting_recognizer.dart';
import 'script_sets.dart';
import 'script_sprint_game.dart';

enum ScriptSprintPhase {
  loading,
  ready,
  playing,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
  recognitionUnsure,
  scriptUnavailable,
}

/// Flagship Fidel Flight / Script Sprint (P8-927).
class ScriptSprintScreen extends StatefulWidget {
  const ScriptSprintScreen({
    super.key,
    required this.language,
    this.onBack,
    this.initialPhase,
    this.initialSet,
  });

  static const title = 'Fidel Flight';
  static const instructions =
      'Trace each character as it glides by. Stay on the stroke path — no uploads, all on your device.';
  static const whyWrongCopy =
      'Compare with the stroke guide and romanization, then trace again.';
  static const practiceLabel =
      'Practice — script rounds do not affect league rank until scoring is verified.';
  static const errorCopy =
      'Fidel Flight needs Amharic or Tigrinya for the Ge\'ez track. Pick one of those languages to play.';
  static const scriptUnavailableTitle = 'Script not ready yet';

  final String language;
  final VoidCallback? onBack;
  final ScriptSprintPhase? initialPhase;
  final ScriptSprintSet? initialSet;

  @override
  State<ScriptSprintScreen> createState() => _ScriptSprintScreenState();
}

class _ScriptSprintScreenState extends State<ScriptSprintScreen>
    with SingleTickerProviderStateMixin {
  ScriptSprintPhase _phase = ScriptSprintPhase.loading;
  ScriptSprintSessionPlan? _plan;
  int _roundCursor = 0;
  int _correctCount = 0;
  final List<bool> _roundResults = [];
  final Random _rng = Random();
  AnimationController? _flightController;
  double _flightProgress = 0;

  ScriptSprintRound? get _activeRound {
    final plan = _plan;
    if (plan == null || _roundCursor >= plan.rounds.length) return null;
    return plan.rounds[_roundCursor];
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPhase != null) {
      _phase = widget.initialPhase!;
      if (widget.initialSet != null) {
        if (widget.initialSet!.isPlayable) {
          _plan = buildScriptSprintSession(
            set: widget.initialSet!,
            rng: _rng,
          );
          if (_phase == ScriptSprintPhase.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startFlightAnimation();
            });
          }
        } else {
          _plan = ScriptSprintSessionPlan(
            set: widget.initialSet!,
            rounds: const [],
            practiceNotScored: true,
          );
        }
      }
    } else {
      unawaited(_bootstrap());
    }
  }

  @override
  void dispose() {
    _flightController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final lang = widget.language.toLowerCase();
    if (lang != 'am' && lang != 'ti') {
      setState(() => _phase = ScriptSprintPhase.error);
      return;
    }
    try {
      final set = await loadScriptSprintSetForLanguage(lang);
      if (!set.isPlayable) {
        setState(() => _phase = ScriptSprintPhase.scriptUnavailable);
        _plan = ScriptSprintSessionPlan(
          set: set,
          rounds: const [],
          practiceNotScored: true,
        );
        return;
      }
      final plan = buildScriptSprintSession(set: set, rng: _rng);
      setState(() {
        _plan = plan;
        _phase = ScriptSprintPhase.playing;
      });
      _startFlightAnimation();
    } catch (_) {
      setState(() => _phase = ScriptSprintPhase.error);
    }
  }

  void _startFlightAnimation() {
    _flightController?.dispose();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _flightProgress = 0.5;
      return;
    }
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _flightController!.addListener(() {
      if (mounted) {
        setState(() => _flightProgress = _flightController!.value);
      }
    });
    _flightController!.forward();
  }

  void _onTraceRecognized() {
    _correctCount++;
    _roundResults.add(true);
    setState(() => _phase = ScriptSprintPhase.correct);
  }

  void _onTraceUnsure() {
    setState(() => _phase = ScriptSprintPhase.recognitionUnsure);
  }

  void _onTraceMismatch() {
    _roundResults.add(false);
    setState(() => _phase = ScriptSprintPhase.wrong);
  }

  void _nextRound() {
    final plan = _plan;
    if (plan == null) return;
    if (_roundCursor + 1 >= plan.rounds.length) {
      setState(() => _phase = ScriptSprintPhase.results);
      _flightController?.stop();
      return;
    }
    setState(() {
      _roundCursor++;
      _phase = ScriptSprintPhase.playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LingAfriqScaffoldLite(
      title: ScriptSprintScreen.title,
      onBack: widget.onBack,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_plan?.practiceNotScored == true &&
                  _phase != ScriptSprintPhase.scriptUnavailable)
                Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                  child: Text(
                    ScriptSprintScreen.practiceLabel,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(child: _body(context, reduceMotion)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool reduceMotion) {
    switch (_phase) {
      case ScriptSprintPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case ScriptSprintPhase.error:
        return _StateMessage(
          message: ScriptSprintScreen.errorCopy,
          icon: Icons.flight_rounded,
        );
      case ScriptSprintPhase.scriptUnavailable:
        return _StateMessage(
          message: _plan?.set.unavailableReason ??
              'This script is not available on device yet.',
          icon: Icons.hide_source_rounded,
          title: ScriptSprintScreen.scriptUnavailableTitle,
        );
      case ScriptSprintPhase.results:
        return _ResultsPane(
          correct: _correctCount,
          total: _plan?.rounds.length ?? 0,
          onDone: widget.onBack,
        );
      case ScriptSprintPhase.correct:
        return _FeedbackPane(
          headline: 'Clean trace',
          detail: _activeRound?.glyph.romanization ?? '',
          isCorrect: true,
          onContinue: _nextRound,
        );
      case ScriptSprintPhase.wrong:
      case ScriptSprintPhase.whyWrong:
        return _FeedbackPane(
          headline: 'Keep practicing',
          detail: ScriptSprintScreen.whyWrongCopy,
          isCorrect: false,
          showWhy: _phase == ScriptSprintPhase.wrong,
          onWhy: () => setState(() => _phase = ScriptSprintPhase.whyWrong),
          onContinue: () => setState(() => _phase = ScriptSprintPhase.playing),
        );
      case ScriptSprintPhase.recognitionUnsure:
        return _FeedbackPane(
          headline: 'Not sure yet',
          detail:
              'We could not judge that trace. Try again with clearer strokes.',
          isCorrect: false,
          onContinue: () => setState(() => _phase = ScriptSprintPhase.playing),
        );
      case ScriptSprintPhase.playing:
      case ScriptSprintPhase.ready:
      case ScriptSprintPhase.offline:
      case ScriptSprintPhase.practiceMode:
        return _PlayingPane(
          round: _activeRound,
          catalog: _plan?.set.strokeCatalog ?? kDefaultStrokeCatalog,
          flightProgress: _flightProgress,
          reduceMotion: reduceMotion,
          onRecognized: _onTraceRecognized,
          onUnsure: _onTraceUnsure,
          onMismatch: _onTraceMismatch,
        );
    }
  }
}

class _PlayingPane extends StatelessWidget {
  const _PlayingPane({
    required this.round,
    required this.catalog,
    required this.flightProgress,
    required this.reduceMotion,
    required this.onRecognized,
    required this.onUnsure,
    required this.onMismatch,
  });

  final ScriptSprintRound? round;
  final StrokeCatalog catalog;
  final double flightProgress;
  final bool reduceMotion;
  final VoidCallback onRecognized;
  final VoidCallback onUnsure;
  final VoidCallback onMismatch;

  @override
  Widget build(BuildContext context) {
    if (round == null) {
      return const _StateMessage(message: ScriptSprintScreen.errorCopy);
    }
    final glyph = round!.glyph;
    final laneHeight = 120.h;
    final drift = reduceMotion ? 0.0 : (flightProgress * 2 - 1);

    return ListView(
      children: [
        Text(
          ScriptSprintScreen.instructions,
          style: PanAfricanTypography.bodyMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Semantics(
          label: 'Flight lane. Target character ${glyph.character}, '
              'romanization ${glyph.romanization}',
          child: Container(
            height: laneHeight,
            decoration: BoxDecoration(
              color: PanAfricanColors.primaryContainer.withValues(alpha: 0.25),
              borderRadius: PanAfricanRadius.mdBR,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CloudLanePainter(phase: flightProgress),
                  ),
                ),
                Align(
                  alignment: Alignment(drift.clamp(-0.85, 0.85), 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          glyph.character,
                          style: PanAfricanTypography.displaySmall(context)
                              .copyWith(fontSize: 40.sp),
                        ),
                        Text(
                          glyph.romanization,
                          style: PanAfricanTypography.labelLarge(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        if (glyph.soundLabel.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
            child: Text(
              glyph.soundLabel,
              style: PanAfricanTypography.bodySmall(context),
            ),
          ),
        _ScriptTracePad(
          character: glyph.character,
          catalog: catalog,
          onRecognized: onRecognized,
          onUnsure: onUnsure,
          onMismatch: onMismatch,
        ),
      ],
    );
  }
}

class _ScriptTracePad extends StatefulWidget {
  const _ScriptTracePad({
    required this.character,
    required this.catalog,
    required this.onRecognized,
    required this.onUnsure,
    required this.onMismatch,
  });

  final String character;
  final StrokeCatalog catalog;
  final VoidCallback onRecognized;
  final VoidCallback onUnsure;
  final VoidCallback onMismatch;

  @override
  State<_ScriptTracePad> createState() => _ScriptTracePadState();
}

class _ScriptTracePadState extends State<_ScriptTracePad> {
  final List<Offset> _points = [];

  void _clear() {
    setState(() => _points.clear());
  }

  void _finishStroke() {
    final recognition = recognizeScriptSprintStroke(
      points: List<Offset>.from(_points),
      character: widget.character,
      catalog: widget.catalog,
    );
    if (scriptSprintConfidenceAccepts(recognition)) {
      widget.onRecognized();
      return;
    }
    if (recognition.isUnsure) {
      widget.onUnsure();
      return;
    }
    widget.onMismatch();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _points.isEmpty
        ? HandwritingCopyKeys.drawPrompt
        : handwritingFeedbackFor(HandwritingUiState.drawing);
    return Semantics(
      label: '${widget.character}. $feedback',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(feedback, style: PanAfricanTypography.bodyLarge(context)),
          SizedBox(height: PanAfricanSpacing.xs),
          Semantics(
            button: true,
            label: 'Trace box for ${widget.character}',
            child: GestureDetector(
              onPanStart: (d) => setState(() => _points.add(d.localPosition)),
              onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
              onPanEnd: (_) => _finishStroke(),
              child: Container(
                height: 200.h,
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  border: Border.all(color: PanAfricanColors.outline),
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                child: CustomPaint(
                  painter: _TracePainter(points: _points),
                ),
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clear,
              child: const Text('Clear trace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudLanePainter extends CustomPainter {
  _CloudLanePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PanAfricanColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final x = ((phase + i * 0.25) % 1.0) * size.width;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.height * 0.35),
          width: 56,
          height: 28,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudLanePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = PanAfricanColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.title,
  });

  final String message;
  final IconData icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.sp, color: PanAfricanColors.primary),
            if (title != null) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(title!, style: PanAfricanTypography.titleMedium(context)),
            ],
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackPane extends StatelessWidget {
  const _FeedbackPane({
    required this.headline,
    required this.detail,
    required this.isCorrect,
    required this.onContinue,
    this.showWhy = false,
    this.onWhy,
  });

  final String headline;
  final String detail;
  final bool isCorrect;
  final VoidCallback onContinue;
  final bool showWhy;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCorrect ? Icons.check_circle_rounded : Icons.refresh_rounded,
          size: 56.sp,
          color: isCorrect ? PanAfricanColors.success : PanAfricanColors.warning,
          semanticLabel: isCorrect ? 'Correct' : 'Try again',
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text(headline, style: PanAfricanTypography.titleLarge(context)),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: PanAfricanTypography.bodyMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        if (showWhy && onWhy != null)
          TextButton(onPressed: onWhy, child: const Text('Why?')),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ResultsPane extends StatelessWidget {
  const _ResultsPane({
    required this.correct,
    required this.total,
    this.onDone,
  });

  final int correct;
  final int total;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Run complete',
          style: PanAfricanTypography.headlineSmall(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          '$correct of $total traced well',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        FilledButton(
          onPressed: onDone ?? () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
