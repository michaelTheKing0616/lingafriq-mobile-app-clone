import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/animations/polie_reaction_widget.dart';

/// Service for character (Polie) reactions without shipping Lottie JSON.
/// Uses [PolieReactionWidget] with CustomPainter + flutter_animate for
/// consistent, app-wide reaction animations.
class CharacterReactionService {
  CharacterReactionService._();

  /// Show a Polie reaction overlay on the given context (e.g. correct answer).
  static void showReaction(
    BuildContext context, {
    required PolieReactionState state,
    double size = 80,
    Duration duration = const Duration(milliseconds: 1200),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).size.height * 0.25,
        child: Center(
          child: PolieReactionWidget(
            state: state,
            size: size,
            onTap: () {
              entry.remove();
              onDismiss?.call();
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
        onDismiss?.call();
      }
    });
  }

  /// Correct-answer reaction (happy).
  static void showCorrect(BuildContext context) {
    showReaction(context, state: PolieReactionState.happy);
  }

  /// Wrong-answer reaction (sad).
  static void showIncorrect(BuildContext context) {
    showReaction(context, state: PolieReactionState.sad);
  }

  /// Milestone / level-up reaction (excited).
  static void showExcited(BuildContext context) {
    showReaction(context, state: PolieReactionState.excited);
  }
}
