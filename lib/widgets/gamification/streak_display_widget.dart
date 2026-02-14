import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';

/// Displays user's streak with fire animation
class StreakDisplayWidget extends ConsumerStatefulWidget {
  final bool showFreeze;
  final bool compact;

  const StreakDisplayWidget({
    super.key,
    this.showFreeze = true,
    this.compact = false,
  });

  @override
  ConsumerState<StreakDisplayWidget> createState() => _StreakDisplayWidgetState();
}

class _StreakDisplayWidgetState extends ConsumerState<StreakDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    if (widget.compact) {
      return _buildCompact(context, gamification);
    }

    return _buildFull(context, gamification);
  }

  Widget _buildCompact(BuildContext context, gamification) {
    final streakCount = gamification.dailyStreak;
    final opacity = (0.7 + (streakCount.clamp(0, 30) / 30) * 0.3).clamp(0.7, 1.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange,
            Colors.red,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5 * opacity),
                          blurRadius: 8 * _pulseAnimation.value,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      '🔥',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, gamification) {
    final streakCount = gamification.dailyStreak;
    final opacity = (0.7 + (streakCount.clamp(0, 30) / 30) * 0.3).clamp(0.7, 1.0);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade100,
              Colors.red.shade100,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5 * opacity),
                                blurRadius: 12 * _pulseAnimation.value,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Text(
                            '🔥',
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${gamification.dailyStreak}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                    ),
                    Text(
                      'Day Streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            if (gamification.perfectWeekStreak > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${gamification.perfectWeekStreak} Perfect Week${gamification.perfectWeekStreak > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
            if (widget.showFreeze && gamification.freezeLeft > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${gamification.freezeLeft} Freeze${gamification.freezeLeft > 1 ? 's' : ''} Left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

