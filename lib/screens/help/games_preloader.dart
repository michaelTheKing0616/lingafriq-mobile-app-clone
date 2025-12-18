import 'package:flutter/material.dart';
import 'package:lingafriq/screens/help/feature_preloader_screen.dart';

/// Pre-loader screen for games features
/// Shown when users first access games
class GamesPreloader extends StatelessWidget {
  final VoidCallback? onComplete;

  const GamesPreloader({Key? key, this.onComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeaturePreloaderScreen(
      featureName: '35 Language Games',
      featureDescription: 'Learn through play! 35 unique games designed for African language learning.',
      icon: Icons.games_rounded,
      terms: [
        FeatureTerm(
          term: 'SRS Integration',
          definition: 'Games automatically update your spaced repetition schedule based on performance.',
          example: 'Correct answers increase review intervals',
        ),
        FeatureTerm(
          term: 'Pronunciation Scoring',
          definition: 'AI-powered feedback on your pronunciation accuracy.',
          example: 'Get 85% score on pronunciation',
        ),
        FeatureTerm(
          term: 'Tone Trainer',
          definition: 'Unique game for learning tones in tonal languages like Yoruba and Igbo.',
          example: 'Match the correct tone pattern',
        ),
        FeatureTerm(
          term: 'Cultural Games',
          definition: '21 games that teach cultural context alongside language.',
          example: 'Market Bargaining, Drum Rhythm, Proverb Unlocker',
        ),
      ],
      tips: [
        FeatureTip(
          title: 'Start with Core Games',
          description: 'Begin with WordMatch+Audio and Pronunciation Duel to build fundamentals.',
          icon: Icons.star_rounded,
        ),
        FeatureTip(
          title: 'Try Cultural Games',
          description: 'Explore unique games like Market Bargaining and Drum Rhythm for cultural learning.',
          icon: Icons.celebration_rounded,
        ),
        FeatureTip(
          title: 'Track Your Progress',
          description: 'Games automatically track accuracy, speed, and update your SRS schedule.',
          icon: Icons.analytics_rounded,
        ),
        FeatureTip(
          title: 'Earn Rewards',
          description: 'Complete games to earn XP, currencies, and unlock badges.',
          icon: Icons.card_giftcard_rounded,
        ),
      ],
      onComplete: onComplete,
    );
  }
}

