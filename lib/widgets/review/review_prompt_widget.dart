/// Review Prompt Widget
/// Intelligently shows review prompts at optimal times

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/review/intelligent_review_service.dart';
import '../../screens/review/gamified_review_screen.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/progress_tracking_provider.dart';
import '../../providers/user_provider.dart';

class ReviewPromptWidget extends ConsumerStatefulWidget {
  final Widget child;

  const ReviewPromptWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<ReviewPromptWidget> createState() => _ReviewPromptWidgetState();
}

class _ReviewPromptWidgetState extends ConsumerState<ReviewPromptWidget> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkReviewPrompt();
  }

  Future<void> _checkReviewPrompt() async {
    if (_hasChecked) return;
    _hasChecked = true;

    // Wait a bit for app to fully load
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = ref.read(userProvider);

    if (user == null) return;

    // Get engagement metrics from gamification + progress tracking
    final gamificationModel = ref.read(gamificationProvider.notifier).gamification;
    final progressMetrics = ref.read(progressTrackingProvider.notifier).metrics;

    final sessionCount = gamificationModel.xp ~/ 100; // Approximate sessions from XP
    final streakDays = gamificationModel.dailyStreak;

    // Approximate lessons/games from timeByActivity buckets
    final gamesHours = progressMetrics.timeByActivity['games'] ?? 0.0;
    final lessonsHours = progressMetrics.timeByActivity['lessons'] ?? 0.0;
    final gamesPlayed = (gamesHours * 60.0 / 5.0).round().clamp(0, 10000); // ~5 min/game
    final lessonsCompleted = (lessonsHours * 60.0 / 7.0).round().clamp(0, 10000); // ~7 min/lesson

    final lastActiveDate = progressMetrics.lastUpdated;

    // Check if should show
    final shouldShow = await IntelligentReviewService.shouldShowReviewPrompt(
      sessionCount: sessionCount,
      streakDays: streakDays,
      lessonsCompleted: lessonsCompleted,
      gamesPlayed: gamesPlayed,
      lastActiveDate: lastActiveDate,
    );

    if (shouldShow && mounted) {
      await IntelligentReviewService.recordReviewPromptShown();
      
      // Show review dialog
      _showReviewDialog();
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamifiedReviewScreen(
        onComplete: () {
          // Review completed
        },
        onDecline: () {
          // Review declined
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

