import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

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
      return SizedBox(height: GameKitFeedbackBudget.verdictSlotHeight);
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
        child: child,
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
      Duration(milliseconds: GameKitFeedbackBudget.celebrationMaxMs),
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

