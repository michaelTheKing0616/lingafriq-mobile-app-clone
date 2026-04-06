import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Word card displaying pronunciation, meaning, and action buttons.
///
/// Used in vocabulary lists and heritage word-of-the-day features.
/// Provides listen (audio), quiz, and bookmark actions. The card
/// adapts to the current theme and highlights the bookmark state.
class VocabularyCard extends StatelessWidget {
  final String word;
  final String? pronunciation;
  final String meaning;
  final String? language;
  final VoidCallback? onListen;
  final VoidCallback? onQuiz;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const VocabularyCard({
    super.key,
    required this.word,
    this.pronunciation,
    required this.meaning,
    this.language,
    this.onListen,
    this.onQuiz,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: colors.outline.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          SizedBox(height: 10.h),
          _buildMeaning(colors),
          SizedBox(height: 14.h),
          _buildActions(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              if (pronunciation != null && pronunciation!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    pronunciation!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (language != null && language!.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              language!,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeaning(ColorScheme colors) {
    return Text(
      meaning,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: colors.onSurface.withOpacity(0.75),
      ),
    );
  }

  Widget _buildActions(ColorScheme colors) {
    return Row(
      children: [
        if (onListen != null)
          _ActionChip(
            icon: Icons.volume_up_rounded,
            label: 'Listen',
            colors: colors,
            onTap: onListen!,
          ),
        if (onListen != null && onQuiz != null) SizedBox(width: 8.w),
        if (onQuiz != null)
          _ActionChip(
            icon: Icons.quiz_rounded,
            label: 'Quiz',
            colors: colors,
            onTap: onQuiz!,
          ),
        const Spacer(),
        if (onBookmark != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBookmark!();
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isBookmarked),
                size: 24.sp,
                color: isBookmarked
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: colors.primary),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
