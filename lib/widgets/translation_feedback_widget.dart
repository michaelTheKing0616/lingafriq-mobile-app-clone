/// Translation Quality Feedback Widget
/// Allows users to rate and provide feedback on translations
/// 
/// Features:
/// - Star rating (1-5)
/// - Quick quality indicators
/// - Correction input
/// - Comment field
/// - Pan-African styled UI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/translation_quality_service.dart';
import '../utils/pan_african_design_system.dart';

/// Translation feedback bottom sheet
class TranslationFeedbackSheet extends StatefulWidget {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String model;
  final String? abTestVariant;
  final VoidCallback? onFeedbackSubmitted;

  const TranslationFeedbackSheet({
    Key? key,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
    this.abTestVariant,
    this.onFeedbackSubmitted,
  }) : super(key: key);

  /// Show the feedback sheet
  static Future<void> show(
    BuildContext context, {
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    required String model,
    String? abTestVariant,
    VoidCallback? onFeedbackSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationFeedbackSheet(
        sourceText: sourceText,
        translatedText: translatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        model: model,
        abTestVariant: abTestVariant,
        onFeedbackSubmitted: onFeedbackSubmitted,
      ),
    );
  }

  @override
  State<TranslationFeedbackSheet> createState() => _TranslationFeedbackSheetState();
}

class _TranslationFeedbackSheetState extends State<TranslationFeedbackSheet> {
  TranslationRating? _selectedRating;
  final TextEditingController _correctionController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _showCorrectionField = false;

  @override
  void dispose() {
    _correctionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final feedback = TranslationFeedback(
        sourceText: widget.sourceText,
        translatedText: widget.translatedText,
        sourceLang: widget.sourceLang,
        targetLang: widget.targetLang,
        model: widget.model,
        rating: _selectedRating!,
        correctedText: _correctionController.text.isNotEmpty 
            ? _correctionController.text 
            : null,
        userComment: _commentController.text.isNotEmpty 
            ? _commentController.text 
            : null,
        abTestVariant: widget.abTestVariant,
      );

      await TranslationQualityService().recordFeedback(feedback);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onFeedbackSubmitted?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback! 🙏'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? PanAfricanColors.surfaceContainerDark 
        : PanAfricanColors.surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(PanAfricanRadius.xl)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PanAfricanSpacing.lg,
          PanAfricanSpacing.md,
          PanAfricanSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + PanAfricanSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: PanAfricanColors.neutralMedium.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),

              // Title
              Text(
                'How was this translation?',
                style: PanAfricanTypography.titleLarge(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: PanAfricanSpacing.md),

              // Translation preview
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark 
                      ? PanAfricanColors.surfaceDark 
                      : PanAfricanColors.surfaceContainerLight,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sourceText,
                      style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                        color: PanAfricanColors.neutralMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Divider(height: PanAfricanSpacing.lg),
                    Text(
                      widget.translatedText,
                      style: PanAfricanTypography.bodyLarge(context)?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xl),

              // Rating buttons
              Text(
                'Rate this translation',
                style: PanAfricanTypography.labelLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _buildRatingButtons(),
              SizedBox(height: PanAfricanSpacing.lg),

              // Show correction field for poor ratings
              if (_showCorrectionField) ...[
                Text(
                  'What\'s the correct translation?',
                  style: PanAfricanTypography.labelLarge(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                TextField(
                  controller: _correctionController,
                  decoration: InputDecoration(
                    hintText: 'Enter the correct translation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? PanAfricanColors.surfaceDark 
                        : Theme.of(context).colorScheme.surface,
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: PanAfricanSpacing.lg),
              ],

              // Comment field
              Text(
                'Any additional comments? (optional)',
                style: PanAfricanTypography.labelLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  filled: true,
                    fillColor: isDark 
                        ? PanAfricanColors.surfaceDark 
                        : Theme.of(context).colorScheme.surface,
                ),
                maxLines: 2,
              ),
              SizedBox(height: PanAfricanSpacing.xl),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                        ),
                      )
                    : const Text('Submit Feedback'),
              ),
              SizedBox(height: PanAfricanSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRatingButton(
          rating: TranslationRating.wrong,
          emoji: '😞',
          label: 'Wrong',
          color: Colors.red,
        ),
        _buildRatingButton(
          rating: TranslationRating.poor,
          emoji: '😕',
          label: 'Poor',
          color: Colors.orange,
        ),
        _buildRatingButton(
          rating: TranslationRating.okay,
          emoji: '😐',
          label: 'Okay',
          color: Colors.amber,
        ),
        _buildRatingButton(
          rating: TranslationRating.good,
          emoji: '🙂',
          label: 'Good',
          color: Colors.lightGreen,
        ),
        _buildRatingButton(
          rating: TranslationRating.excellent,
          emoji: '😄',
          label: 'Perfect',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required TranslationRating rating,
    required String emoji,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedRating == rating;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedRating = rating;
          // Show correction field for poor ratings
          _showCorrectionField = rating == TranslationRating.wrong || 
                                  rating == TranslationRating.poor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 28.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: PanAfricanTypography.labelSmall(context)?.copyWith(
                color: isSelected ? color : PanAfricanColors.neutralMedium,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline feedback button for translations
class TranslationFeedbackButton extends StatelessWidget {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String model;
  final String? abTestVariant;
  final bool compact;

  const TranslationFeedbackButton({
    Key? key,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
    this.abTestVariant,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: Icon(
          Icons.feedback_outlined,
          size: 20.sp,
          color: PanAfricanColors.neutralMedium,
        ),
        onPressed: () => _showFeedback(context),
        tooltip: 'Rate this translation',
      );
    }

    return TextButton.icon(
      onPressed: () => _showFeedback(context),
      icon: Icon(
        Icons.thumb_up_outlined,
        size: 16.sp,
      ),
      label: const Text('Rate'),
      style: TextButton.styleFrom(
        foregroundColor: PanAfricanColors.neutralMedium,
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.xs,
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    TranslationFeedbackSheet.show(
      context,
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      model: model,
      abTestVariant: abTestVariant,
    );
  }
}

/// Quick thumbs up/down feedback
class QuickTranslationFeedback extends StatefulWidget {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String model;

  const QuickTranslationFeedback({
    Key? key,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
  }) : super(key: key);

  @override
  State<QuickTranslationFeedback> createState() => _QuickTranslationFeedbackState();
}

class _QuickTranslationFeedbackState extends State<QuickTranslationFeedback> {
  bool? _isPositive;

  Future<void> _submitQuickFeedback(bool isPositive) async {
    if (_isPositive != null) return; // Already submitted

    setState(() => _isPositive = isPositive);
    HapticFeedback.lightImpact();

    final feedback = TranslationFeedback(
      sourceText: widget.sourceText,
      translatedText: widget.translatedText,
      sourceLang: widget.sourceLang,
      targetLang: widget.targetLang,
      model: widget.model,
      rating: isPositive ? TranslationRating.good : TranslationRating.poor,
    );

    await TranslationQualityService().recordFeedback(feedback);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPositive == true ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 18.sp,
            color: _isPositive == true 
                ? Colors.green 
                : PanAfricanColors.neutralMedium,
          ),
          onPressed: _isPositive == null ? () => _submitQuickFeedback(true) : null,
          tooltip: 'Good translation',
        ),
        IconButton(
          icon: Icon(
            _isPositive == false ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 18.sp,
            color: _isPositive == false 
                ? Colors.red 
                : PanAfricanColors.neutralMedium,
          ),
          onPressed: _isPositive == null ? () => _submitQuickFeedback(false) : null,
          tooltip: 'Poor translation',
        ),
      ],
    );
  }
}
