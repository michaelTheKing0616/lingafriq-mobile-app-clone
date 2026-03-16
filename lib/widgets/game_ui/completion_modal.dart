import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class CompletionModal extends StatelessWidget {
  final String title;
  final int score;
  final int xp;
  final double accuracy;
  final int streakDelta;
  final VoidCallback onTryAgain;
  final VoidCallback onExit;
  final VoidCallback? onNextRound;

  const CompletionModal({
    super.key,
    required this.title,
    required this.score,
    required this.xp,
    required this.accuracy,
    required this.streakDelta,
    required this.onTryAgain,
    required this.onExit,
    this.onNextRound,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required int score,
    required int xp,
    required double accuracy,
    required int streakDelta,
    required VoidCallback onTryAgain,
    required VoidCallback onExit,
    VoidCallback? onNextRound,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (_) => CompletionModal(
        title: title,
        score: score,
        xp: xp,
        accuracy: accuracy,
        streakDelta: streakDelta,
        onTryAgain: onTryAgain,
        onExit: onExit,
        onNextRound: onNextRound,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: PanAfricanTypography.titleLarge(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Score', value: '$score'),
                _StatChip(label: 'XP', value: '+$xp'),
                _StatChip(label: 'Accuracy', value: '${(accuracy * 100).round()}%'),
                _StatChip(label: 'Streak', value: streakDelta >= 0 ? '+$streakDelta' : '$streakDelta'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    child: const Text('Exit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onTryAgain,
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
            if (onNextRound != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onNextRound,
                  child: const Text('Next Round'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PanAfricanColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PanAfricanColors.primary.withOpacity(0.35)),
      ),
      child: Text(
        '$label: $value',
        style: PanAfricanTypography.labelMedium(context),
      ),
    );
  }
}
