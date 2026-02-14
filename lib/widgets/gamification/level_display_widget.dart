import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../models/user_gamification_model.dart';

/// Displays user's current level and title with African-themed styling
class LevelDisplayWidget extends ConsumerWidget {
  final bool showXP;
  final bool compact;

  const LevelDisplayWidget({
    super.key,
    this.showXP = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationData = ref.watch(gamificationProvider.notifier).gamification;

    if (compact) {
      return _buildCompact(context, gamificationData);
    }

    return _buildFull(context, gamificationData);
  }

  Widget _buildCompact(BuildContext context, UserGamificationModel data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv. ${data.level}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, UserGamificationModel data) {
    final currentLevelXP = LevelTitles.getXPForLevel(data.level);
    final nextLevelXP = LevelTitles.getXPForLevel(data.level + 1);
    final currentLevelProgress = data.xp - currentLevelXP;
    final xpNeeded = nextLevelXP - currentLevelXP;
    final progress = xpNeeded > 0 ? (currentLevelProgress / xpNeeded).clamp(0.0, 1.0) : 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${data.level}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.levelTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showXP) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentLevelProgress.toString()} / ${xpNeeded.toString()} XP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

