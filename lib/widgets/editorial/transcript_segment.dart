import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dual-language transcript block showing source text and translation.
///
/// Displays a source-language line with an optional translation below,
/// an optional speaker label, and a confidence indicator. Words in
/// [highlightedWords] are rendered with an accent background for
/// word-level attention. The [isActive] flag highlights the currently
/// spoken/selected segment.
class TranscriptSegment extends StatelessWidget {
  final String sourceText;
  final String? translationText;
  final String? speakerLabel;
  final double? confidence;
  final bool isActive;
  final List<String>? highlightedWords;
  final VoidCallback? onTap;

  const TranscriptSegment({
    super.key,
    required this.sourceText,
    this.translationText,
    this.speakerLabel,
    this.confidence,
    this.isActive = false,
    this.highlightedWords,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primaryContainer.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border(
            left: BorderSide(
              width: 3.w,
              color: isActive ? colors.primary : Colors.transparent,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (speakerLabel != null && speakerLabel!.isNotEmpty)
              _buildSpeakerRow(colors),
            _buildSourceText(context, colors),
            if (translationText != null && translationText!.isNotEmpty)
              _buildTranslationText(colors),
            if (confidence != null) _buildConfidenceBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerRow(ColorScheme colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            size: 13.sp,
            color: colors.primary,
          ),
          SizedBox(width: 5.w),
          Text(
            speakerLabel!,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceText(BuildContext context, ColorScheme colors) {
    final hasHighlights =
        highlightedWords != null && highlightedWords!.isNotEmpty;

    if (!hasHighlights) {
      return Text(
        sourceText,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: colors.onSurface,
        ),
      );
    }

    return Text.rich(
      _buildHighlightedSpan(sourceText, colors),
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: colors.onSurface,
      ),
    );
  }

  TextSpan _buildHighlightedSpan(String text, ColorScheme colors) {
    final lowerHighlights =
        highlightedWords!.map((w) => w.toLowerCase()).toSet();
    final words = text.split(' ');

    return TextSpan(
      children: words.asMap().entries.map((entry) {
        final isHighlighted =
            lowerHighlights.contains(entry.value.toLowerCase());
        final trailing = entry.key < words.length - 1 ? ' ' : '';
        return TextSpan(
          text: '${entry.value}$trailing',
          style: isHighlighted
              ? TextStyle(
                  backgroundColor: colors.primaryContainer.withOpacity(0.5),
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildTranslationText(ColorScheme colors) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Text(
        translationText!,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          height: 1.45,
          color: colors.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(ColorScheme colors) {
    final score = (confidence! * 100).round();
    final barColor = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 50
            ? const Color(0xFFFFA726)
            : colors.error;

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 60.w,
            height: 3.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: LinearProgressIndicator(
                value: confidence!,
                backgroundColor: colors.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}
