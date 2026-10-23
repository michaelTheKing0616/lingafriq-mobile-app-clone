import 'package:flutter/material.dart';
import 'package:lingafriq/screens/quiz/items/listen_choose_item.dart';
import 'package:lingafriq/services/quiz/feedback_resolver.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ItemFeedbackPanel extends StatelessWidget {
  const ItemFeedbackPanel({
    super.key,
    required this.feedback,
    this.audio,
  });

  final ItemFeedback feedback;
  final ItemAudio? audio;

  bool get _hasAudio =>
      feedback.audioRef != null && feedback.audioRef!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'item.feedback',
      explicitChildNodes: true,
      child: KeyedSubtree(
        key: ValueKey('phase-${feedback.phase}'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FeedbackCopy.correctForm,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: PanAfricanColors.textPrimary,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xxs),
              Text(
                feedback.correctForm,
                style: TextStyle(color: PanAfricanColors.textPrimary),
              ),
              if (_hasAudio) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                TextButton(
                  onPressed: () => audio?.play(feedback.audioRef!),
                  child: const Text('Replay the correct form'),
                ),
              ],
              if (feedback.phase == 'wrong' && feedback.rationale != null) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  FeedbackCopy.why,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PanAfricanColors.textPrimary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  feedback.rationale!,
                  style: TextStyle(color: PanAfricanColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
