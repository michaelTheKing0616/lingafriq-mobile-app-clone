import 'package:flutter/material.dart';
import 'package:lingafriq/screens/help/feature_preloader_screen.dart';

/// Pre-loader screen for gamification features
/// Shown when users first encounter gamification
class GamificationPreloader extends StatelessWidget {
  final VoidCallback? onComplete;

  const GamificationPreloader({Key? key, this.onComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeaturePreloaderScreen(
      featureName: 'Gamification System',
      featureDescription: 'Earn XP, level up, collect currencies, and unlock badges as you learn!',
      icon: Icons.emoji_events_rounded,
      terms: [
        FeatureTerm(
          term: 'Ngwenya',
          definition: 'Main currency earned from all activities. Use for purchases and upgrades.',
          example: 'Earn 50 Ngwenya for completing a lesson',
        ),
        FeatureTerm(
          term: 'Cowries',
          definition: 'Traditional currency earned from daily check-ins and streaks.',
          example: 'Get 20 Cowries for your daily check-in',
        ),
        FeatureTerm(
          term: 'Ancestral Beads',
          definition: 'Rare currency from special achievements and cultural milestones.',
          example: 'Earn 5 Beads for perfect week streak',
        ),
        FeatureTerm(
          term: 'Ubuntu Streak',
          definition: 'A streak mode where breaking it helps others instead of resetting your progress.',
          example: 'If you miss a day, your streak helps another learner',
        ),
        FeatureTerm(
          term: 'Ask the Ancestors',
          definition: 'Streak freeze that prevents losing your streak if you miss a day.',
          example: 'Use a freeze to maintain your 30-day streak',
        ),
        FeatureTerm(
          term: 'Tribe',
          definition: 'Join a language community (Yoruba, Zulu, etc.) and compete in events.',
          example: 'Join the Yoruba tribe to compete in Tribe vs Tribe',
        ),
      ],
      tips: [
        FeatureTip(
          title: 'Daily Check-ins',
          description: 'Check in daily to maintain your streak and earn Cowries.',
          icon: Icons.calendar_today_rounded,
        ),
        FeatureTip(
          title: 'Complete Quests',
          description: 'Complete "The Great Journey" quests for bonus XP and rewards.',
          icon: Icons.flag_rounded,
        ),
        FeatureTip(
          title: 'Collect Badges',
          description: 'Earn badges from various activities. Collect them all!',
          icon: Icons.workspace_premium_rounded,
        ),
        FeatureTip(
          title: 'Join a Tribe',
          description: 'Choose your tribe and compete in Tribe vs Tribe events.',
          icon: Icons.people_rounded,
        ),
      ],
      onComplete: onComplete,
    );
  }
}

