import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../learning/learner_model/error_taxonomy.dart';
import '../../models/game/game_content_models.dart';
import 'game_turn_context.dart';
import 'game_scoring.dart';

/// Tap-to-feedback budget (EP-§10.2-06).
class GameKitFeedbackBudget {
  static const int tapToFeedbackP95Ms = 160;
  static const int celebrationMaxMs = 1500;
  static const double verdictSlotHeight = 72;

  /// Streak counts that trigger a brief celebration (AC3).
  static const List<int> celebrationMilestones = [3, 5, 10];
}

/// Whether an answer can be judged on-device without a server round trip.
bool gameKitIsLocallyVerifiable({
  required String? selectedAnswer,
  required String? correctAnswer,
  required bool requiresServerScoring,
}) {
  if (requiresServerScoring) return false;
  if (selectedAnswer == null || correctAnswer == null) return false;
  if (selectedAnswer.isEmpty || correctAnswer.isEmpty) return false;
  return true;
}

bool gameKitLocalVerdict({
  required String selectedAnswer,
  required String correctAnswer,
}) {
  return selectedAnswer.trim() == correctAnswer.trim();
}

bool gameKitShouldTriggerCelebration(int correctStreak) {
  return GameKitFeedbackBudget.celebrationMilestones.contains(correctStreak);
}

/// Visible feedback phase for a single answer (AC1–AC2).
enum GameKitFeedbackPhase {
  idle,
  /// Local verdict shown immediately (MCQ).
  localVerdict,
  /// Server/scorer path: show after [GameKitFeedbackBudget.tapToFeedbackP95Ms].
  pending,
  finalVerdict,
}

class GameKitFeedbackTiming {
  final DateTime tappedAt;
  final bool locallyVerifiable;
  final bool? localCorrect;

  GameKitFeedbackTiming({
    required this.tappedAt,
    required this.locallyVerifiable,
    this.localCorrect,
  });

  Duration elapsedSinceTap(DateTime now) => now.difference(tappedAt);

  bool shouldShowPending(DateTime now) {
    if (locallyVerifiable) return false;
    return elapsedSinceTap(now).inMilliseconds >=
        GameKitFeedbackBudget.tapToFeedbackP95Ms;
  }
}

/// Fixed-height verdict strip — pending and final share the same box (no layout shift).
class GameKitVerdictSlot extends StatelessWidget {
  final GameKitFeedbackPhase phase;
  final bool isCorrect;
  final String correctLabel;
  final String wrongLabel;
  final String pendingLabel;
  final String? detailMessage;

  const GameKitVerdictSlot({
    super.key,
    required this.phase,
    required this.isCorrect,
    required this.correctLabel,
    required this.wrongLabel,
    required this.pendingLabel,
    this.detailMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == GameKitFeedbackPhase.idle) {
      return const SizedBox(height: GameKitFeedbackBudget.verdictSlotHeight);
    }

    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget child;
    switch (phase) {
      case GameKitFeedbackPhase.pending:
        child = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              pendingLabel,
              style: theme.textTheme.titleSmall,
            ),
          ],
        );
        break;
      case GameKitFeedbackPhase.localVerdict:
      case GameKitFeedbackPhase.finalVerdict:
        final ok = isCorrect;
        final icon = ok ? Icons.check_circle : Icons.cancel;
        final color = ok ? const Color(0xFF1B7F4A) : const Color(0xFFC62828);
        child = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32, semanticLabel: ok ? correctLabel : wrongLabel),
            const SizedBox(height: 4),
            Text(
              ok ? correctLabel : wrongLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (detailMessage != null && detailMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detailMessage!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
        break;
      case GameKitFeedbackPhase.idle:
        child = const SizedBox.shrink();
        break;
    }

    return Semantics(
      liveRegion: phase == GameKitFeedbackPhase.pending,
      label: phase == GameKitFeedbackPhase.pending ? pendingLabel : null,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
        height: GameKitFeedbackBudget.verdictSlotHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        // The slot height is fixed (no layout shift); long or scaled-up text
        // shrinks to fit instead of overflowing it.
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}

/// Brief streak celebration (AC3–AC4): ≤1.5 s, skippable, non-blocking.
class GameKitStreakCelebration extends StatefulWidget {
  final int streak;
  final VoidCallback onFinished;
  final bool reduceMotion;
  final String message;

  const GameKitStreakCelebration({
    super.key,
    required this.streak,
    required this.onFinished,
    required this.reduceMotion,
    required this.message,
  });

  @override
  State<GameKitStreakCelebration> createState() => _GameKitStreakCelebrationState();
}

class _GameKitStreakCelebrationState extends State<GameKitStreakCelebration> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: GameKitFeedbackBudget.celebrationMaxMs),
      _finish,
    );
  }

  void _finish() {
    _timer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFFE85D04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    semanticLabel: widget.message,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static confirmation when reduced motion is on (AC4).
class GameKitStaticCelebrationChip extends StatelessWidget {
  final String message;

  const GameKitStaticCelebrationChip({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check, size: 18),
      label: Text(message),
      backgroundColor: const Color(0xFF1B7F4A).withValues(alpha: 0.15),
    );
  }
}

/// Abstract feedback engine - generates user-facing feedback
abstract class GameFeedbackEngine {
  Future<GameFeedback> generate(GameTurnContext context, GameScore score);
}

/// Default feedback engine
class DefaultGameFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent! Perfect score!',
        animationEvent: AnimationEvent.proud,
      );
    }

    if (score.isFail) {
      return GameFeedback.failure(
        message: 'Not quite right. Try again!',
        animationEvent: AnimationEvent.encouraging,
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good job!',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Keep trying!',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

/// Feedback data
class GameFeedback {
  final String message;
  final AnimationEvent animationEvent;
  final Map<String, dynamic>? metadata;

  GameFeedback({
    required this.message,
    required this.animationEvent,
    this.metadata,
  });

  factory GameFeedback.success({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }

  factory GameFeedback.failure({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }

  factory GameFeedback.neutral({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }
}

/// Animation events that trigger Rive state changes
enum AnimationEvent {
  idle,
  thinking,
  listening,
  speaking,
  happy,
  proud,
  disappointed,
  encouraging,
  confused,
}

/// Warm URIs replay within the 300 ms GameKit budget (P8-904 AC3).
final Set<String> gameKitExplanationAudioWarmCache = <String>{};

/// Clears warm-cache state between tests.
void gameKitResetExplanationAudioCacheForTests() {
  gameKitExplanationAudioWarmCache.clear();
}

typedef GameKitExplanationAudioPlayFn = Future<void> Function(String uri);

/// Plays correct-answer audio; inject [playFn] in tests.
Future<void> gameKitPlayExplanationAudio(
  String uri, {
  GameKitExplanationAudioPlayFn? playFn,
  AudioPlayer? player,
}) async {
  if (playFn != null) {
    await playFn(uri);
    return;
  }
  final p = player ?? AudioPlayer();
  try {
    if (uri.startsWith('asset:')) {
      await p.setAsset(uri.substring(6));
    } else if (uri.startsWith('assets/')) {
      await p.setAsset(uri);
    } else {
      await p.setUrl(uri);
    }
    await p.play();
  } finally {
    if (player == null) {
      await p.dispose();
    }
  }
}

enum GameKitWhyWrongAudioPhase { idle, loading, playing, noAudio }

/// Expandable wrong-answer explanation with taxonomy copy + audio (P8-904).
class GameKitWhyWrongPanel extends StatefulWidget {
  final String errorTypeId;
  final String correctAnswerText;
  final GameKitCorrectItemAudio audio;
  final String title;
  final String whyWrongLabel;
  final String playAudioLabel;
  final String noAudioLabel;
  final String loadingLabel;
  final GameKitExplanationAudioPlayFn? playFn;
  final bool initiallyExpanded;

  const GameKitWhyWrongPanel({
    super.key,
    required this.errorTypeId,
    required this.correctAnswerText,
    required this.audio,
    required this.title,
    required this.whyWrongLabel,
    required this.playAudioLabel,
    required this.noAudioLabel,
    required this.loadingLabel,
    this.playFn,
    this.initiallyExpanded = true,
  });

  @override
  State<GameKitWhyWrongPanel> createState() => _GameKitWhyWrongPanelState();
}

class _GameKitWhyWrongPanelState extends State<GameKitWhyWrongPanel> {
  late bool _expanded;
  GameKitWhyWrongAudioPhase _audioPhase = GameKitWhyWrongAudioPhase.idle;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _syncAudioPhase();
  }

  @override
  void didUpdateWidget(covariant GameKitWhyWrongPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio.uri != widget.audio.uri) {
      _audioPhase = GameKitWhyWrongAudioPhase.idle;
      _syncAudioPhase();
    }
  }

  void _syncAudioPhase() {
    if (!widget.audio.hasPlayableAudio) {
      _audioPhase = GameKitWhyWrongAudioPhase.noAudio;
    }
  }

  Future<void> _onPlayAudio() async {
    final uri = widget.audio.uri;
    if (uri == null || uri.isEmpty) return;
    if (widget.audio.syntheticDisallowed && uri.startsWith('tts:')) {
      return;
    }

    final cached = gameKitExplanationAudioWarmCache.contains(uri);
    if (cached) {
      setState(() => _audioPhase = GameKitWhyWrongAudioPhase.playing);
    } else {
      setState(() => _audioPhase = GameKitWhyWrongAudioPhase.loading);
    }

    await gameKitPlayExplanationAudio(uri, playFn: widget.playFn);
    gameKitExplanationAudioWarmCache.add(uri);
    if (!mounted) return;
    setState(() => _audioPhase = GameKitWhyWrongAudioPhase.playing);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = gameKitLearnerExplanationLine(widget.errorTypeId);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      label: widget.title,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: theme.colorScheme.error,
                        semanticLabel: widget.whyWrongLabel,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.whyWrongLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  explanation,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.correctAnswerText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAudioControl(theme, reduceMotion),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControl(ThemeData theme, bool reduceMotion) {
    if (_audioPhase == GameKitWhyWrongAudioPhase.noAudio ||
        !widget.audio.hasPlayableAudio) {
      return Row(
        children: [
          Icon(Icons.volume_off, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.noAudioLabel,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    if (_audioPhase == GameKitWhyWrongAudioPhase.loading) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(widget.loadingLabel, style: theme.textTheme.bodySmall),
        ],
      );
    }

    return SizedBox(
      height: 48,
      child: FilledButton.tonalIcon(
        onPressed: _onPlayAudio,
        icon: Icon(
          _audioPhase == GameKitWhyWrongAudioPhase.playing
              ? Icons.graphic_eq
              : Icons.volume_up,
        ),
        label: Text(widget.playAudioLabel),
      ),
    );
  }
}

