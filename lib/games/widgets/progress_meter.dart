import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../gamekit/game_engine_service.dart';

/// Lobby / round / results strip for duel opponents (P8-908).
enum GamekitDuelSurfacePhase { lobby, playing, results }

class GamekitDuelOpponentStrip extends StatelessWidget {
  const GamekitDuelOpponentStrip({
    super.key,
    required this.isBot,
    required this.levelLabel,
    required this.phase,
    this.opponentScore,
    this.selfScore,
  });

  final bool isBot;
  final String levelLabel;
  final GamekitDuelSurfacePhase phase;
  final int? opponentScore;
  final int? selfScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final displayName = duelOpponentDisplayName(isBot: isBot, levelLabel: levelLabel);
    final subtitle = isBot
        ? '${GamekitBotLabelCopy.practiceLabel} · ${GamekitBotLabelCopy.levelSubtitle}: $levelLabel'
        : '${GamekitBotLabelCopy.levelSubtitle}: $levelLabel';

    final avatar = CircleAvatar(
      radius: 24.sp,
      backgroundColor: isBot
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.primaryContainer,
      child: Icon(
        isBot ? Icons.smart_toy_outlined : Icons.person_outline,
        semanticLabel: isBot ? GamekitBotLabelCopy.title : 'Opponent',
        size: 28.sp,
      ),
    );

    final nameRow = Row(
      children: [
        Expanded(
          child: Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isBot)
          Chip(
            label: Text(GamekitBotLabelCopy.title, style: TextStyle(fontSize: 11.sp)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
          ),
      ],
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nameRow,
                  SizedBox(height: 0.25.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (phase == GamekitDuelSurfacePhase.results &&
            selfScore != null &&
            opponentScore != null) ...[
          SizedBox(height: 1.h),
          Text(
            'You $selfScore · $displayName $opponentScore',
            style: theme.textTheme.labelLarge,
          ),
        ],
      ],
    );

    if (!reduceMotion && phase == GamekitDuelSurfacePhase.playing) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          );
    }

    return Semantics(
      label: isBot
          ? '${GamekitBotLabelCopy.title} opponent, $levelLabel'
          : 'Opponent, $levelLabel',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          child: content,
        ),
      ),
    );
  }
}

/// Animated progress meter - shows game progress
class ProgressMeter extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final double height;
  final String? label;
  final GamekitDuelOpponentStrip? duelOpponent;

  const ProgressMeter({
    super.key,
    required this.progress,
    this.color,
    this.height = 8.0,
    this.label,
    this.duelOpponent,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Colors.green;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (duelOpponent != null) ...[
          duelOpponent!,
          SizedBox(height: 1.h),
        ],
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 0.5.h),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor,
                        progressColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
                    .animate(autoPlay: !reduceMotion)
                    .fadeIn(duration: 300.ms)
                    .slideX(
                      begin: -0.5,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

