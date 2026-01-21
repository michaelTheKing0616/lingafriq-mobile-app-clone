/// Gamified Review Screen
/// African-themed, engaging review experience integrated with gamification

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/api_provider.dart';
import '../../services/review/intelligent_review_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/material3/haptic_button.dart';

class GamifiedReviewScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onDecline;

  const GamifiedReviewScreen({
    Key? key,
    this.onComplete,
    this.onDecline,
  }) : super(key: key);

  @override
  ConsumerState<GamifiedReviewScreen> createState() => _GamifiedReviewScreenState();
}

class _GamifiedReviewScreenState extends ConsumerState<GamifiedReviewScreen> {
  int? _selectedRating;
  bool _isSubmitting = false;
  String? _selectedReason;

  final List<Map<String, dynamic>> _ratingReasons = [
    {'emoji': '🌟', 'text': 'Loving the journey!', 'value': 'loving'},
    {'emoji': '📚', 'text': 'Great lessons', 'value': 'lessons'},
    {'emoji': '🎮', 'text': 'Fun games', 'value': 'games'},
    {'emoji': '🤖', 'text': 'Polie is amazing', 'value': 'polie'},
    {'emoji': '🏆', 'text': 'Gamification rocks!', 'value': 'gamification'},
    {'emoji': '🌍', 'text': 'Love African languages', 'value': 'languages'},
  ];

  Future<void> _submitRating(int rating) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(userProvider);
      if (user != null) {
        // Send to backend
        await ref.read(apiProvider.notifier).sendTelemetry({
          'eventType': 'user_rating',
          'userId': user.id,
          'metadata': {
            'rating': rating,
            'reason': _selectedReason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        });

        // Award gamification rewards
        if (rating >= 4) {
          // High rating rewards - XP automatically awards ngwenya (5 per XP)
          await ref.read(gamificationProvider.notifier).awardXP('review');
          
          // Award bonus currency for high ratings
          await ref.read(gamificationProvider.notifier).awardCurrency(
            cowries: 50, // Bonus cowries for review
            ancestralBeads: 5, // Bonus beads
          );
        }

        // Record completion
        await IntelligentReviewService.recordReviewCompleted(rating: rating);

        // Open app store if rating is high
        if (rating >= 4) {
          _openAppStore();
        }
      }

      if (mounted) {
        widget.onComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openAppStore() async {
    // Open app store for review
    final packageName = 'com.lingafriq.app'; // Update with actual package name
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _handleDecline({String? reason}) async {
    await IntelligentReviewService.recordReviewDeclined(reason: reason);
    widget.onDecline?.call();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade700,
              Colors.deepOrange.shade900,
              Colors.brown.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // African-themed header
                Text(
                  '🎉 Ancestral Blessing!',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().scale(),
                SizedBox(height: 8.h),
                Text(
                  'Your journey with LingAfriq has been remarkable!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Rating stars
                Text(
                  'How has your experience been?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = rating;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          _selectedRating != null && rating <= _selectedRating!
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 48.sp,
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: index * 100))
                        .fadeIn()
                        .scale();
                  }),
                ),
                SizedBox(height: 24.h),

                // Reason selection (if rating >= 4)
                if (_selectedRating != null && _selectedRating! >= 4) ...[
                  Text(
                    'What do you love most?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: _ratingReasons.map((reason) {
                      final isSelected = _selectedReason == reason['value'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReason = reason['value'] as String;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reason['emoji'] as String,
                                style: TextStyle(fontSize: 20.sp),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                reason['text'] as String,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideX();
                    }).toList(),
                  ),
                  SizedBox(height: 24.h),
                ],

                // Reward preview (if rating >= 4)
                if (_selectedRating != null && _selectedRating! >= 4) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🎁',
                          style: TextStyle(fontSize: 32.sp),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reward for your feedback!',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '50 Cowries + 5 Ancestral Beads',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(),
                  SizedBox(height: 24.h),
                ],

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    HapticTextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleDecline(reason: 'not_now'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.8),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    
                    // Submit button
                    if (_selectedRating != null)
                      HapticFilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitRating(_selectedRating!),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange.shade900,
                          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Share My Experience',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

