/// Review Prompt Widget
/// Intelligently shows review prompts at optimal times

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/review/intelligent_review_service.dart';
import '../../screens/review/gamified_review_screen.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/progress_tracking_provider.dart';
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

    final gamification = ref.read(gamificationProvider);
    final user = ref.read(userProvider);

    if (user == null || gamification == null) return;

    // Get engagement metrics
    final gamificationModel = ref.read(gamificationProvider.notifier).gamification;
    final sessionCount = gamificationModel.xp ~/ 100; // Approximate from XP
    final streakDays = gamificationModel.dailyStreak;
    
    // Get lessons completed from progress tracking (estimate from time spent)
    final progressMetrics = ref.read(progressTrackingProvider.notifier).metrics;
    final lessonsCompleted = (progressMetrics.timeByActivity['lessons'] ?? 0.0).toInt();
    
    // Get games played from progress tracking (estimate from time spent)
    final gamesPlayed = (progressMetrics.timeByActivity['games'] ?? 0.0).toInt();
    
    final lastActiveDate = gamificationModel.lastLogin ?? DateTime.now();

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

