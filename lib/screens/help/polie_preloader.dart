import 'package:flutter/material.dart';
import 'package:lingafriq/screens/help/feature_preloader_screen.dart';

/// Pre-loader screen for Polie AI features
/// Shown when users first use AI chat
class PoliePreloader extends StatelessWidget {
  final VoidCallback? onComplete;

  const PoliePreloader({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return FeaturePreloaderScreen(
      featureName: 'Meet Polie',
      featureDescription: 'Your AI language assistant with 6 powerful modes for comprehensive learning.',
      icon: Icons.smart_toy_rounded,
      terms: [
        FeatureTerm(
          term: 'CEFR',
          definition: 'Common European Framework of Reference - Language proficiency levels from A1 (beginner) to C2 (master).',
          example: 'You\'re currently at B1 level',
        ),
        FeatureTerm(
          term: 'SRS',
          definition: 'Spaced Repetition System - Algorithm that schedules reviews at optimal intervals for memory retention.',
          example: 'Words you struggle with appear more often',
        ),
        FeatureTerm(
          term: 'Diacritics',
          definition: 'Accent marks and tone indicators in African languages (e.g., à, é, ọ, ẹ). Polie automatically corrects them.',
          example: 'Polie corrects "bawo" to "Báwo"',
        ),
        FeatureTerm(
          term: 'Adaptive Difficulty',
          definition: 'Polie adjusts the difficulty of questions based on your success/failure streak.',
          example: 'After 3 correct answers, difficulty increases',
        ),
      ],
      tips: [
        FeatureTip(
          title: 'Choose Your Mode',
          description: 'Select Translation, Tutor, Roleplay, Conversation, Vocab, or Review mode based on your needs.',
          icon: Icons.tune_rounded,
        ),
        FeatureTip(
          title: 'Practice Regularly',
          description: 'Use Polie daily to maintain your streak and improve faster.',
          icon: Icons.schedule_rounded,
        ),
        FeatureTip(
          title: 'Ask Questions',
          description: 'Don\'t hesitate to ask Polie to explain grammar, cultural context, or pronunciation.',
          icon: Icons.help_outline_rounded,
        ),
        FeatureTip(
          title: 'Use Roleplay',
          description: 'Practice real-world scenarios like market bargaining or doctor visits.',
          icon: Icons.theater_comedy_rounded,
        ),
      ],
      onComplete: onComplete,
    );
  }
}

