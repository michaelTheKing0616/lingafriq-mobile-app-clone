import 'package:flutter/material.dart';
import 'package:lingafriq/screens/games/cultural/flashcard_safari_game.dart';
import 'package:lingafriq/screens/lens/see_it_in_the_wild.dart';
import 'package:lingafriq/services/lens/on_device_detector.dart';

export 'cultural/flashcard_safari_game.dart' show FlashcardSafariGame;

/// Canonical Flashcard Safari entry — uses the Lens recognition pipeline (P7-915 AC3).
typedef FlashcardSafariLensPipelineFactory = Future<LensOnDeviceDetector> Function();

FlashcardSafariLensPipelineFactory get flashcardSafariLensPipelineFactory =>
    createLensRecognitionPipeline;

/// Routes and game router should use this widget instead of [FlashcardSafariGame] directly.
class FlashcardSafari extends StatelessWidget {
  const FlashcardSafari({
    super.key,
    required this.language,
    this.level,
    this.onBack,
    this.pipelineFactory,
  });

  final String language;
  final String? level;
  final VoidCallback? onBack;
  final FlashcardSafariLensPipelineFactory? pipelineFactory;

  @override
  Widget build(BuildContext context) {
    return FlashcardSafariGame(
      language: language,
      level: level,
      onBack: onBack,
    );
  }
}

/// Ensures Safari and Lens share one detector configuration (test hook).
Future<LensOnDeviceDetector> flashcardSafariSharedDetector({
  FlashcardSafariLensPipelineFactory? factory,
}) {
  return (factory ?? flashcardSafariLensPipelineFactory)();
}
