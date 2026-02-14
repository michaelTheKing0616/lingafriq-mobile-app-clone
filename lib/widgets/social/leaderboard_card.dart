import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Stunning card for leaderboard entries
class LeaderboardCard extends StatelessWidget {
  final int rank;
  final String username;
  final String? avatarUrl;
  final int xp;
  final int level;
  final String? tribe;
  final bool isCurrentUser;
  final Color? rankColor;

  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.username,
    this.avatarUrl,
    required this.xp,
    required this.level,
    this.tribe,
    this.isCurrentUser = false,
    this.rankColor,
  });

  Color get _rankColor {
    if (rankColor != null) return rankColor!;
    if (rank == 1) return PanAfricanColors.secondary;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return PanAfricanColors.primary;
  }

  IconData get _rankIcon {
    if (rank == 1) return Icons.emoji_events_rounded;
    if (rank == 2) return Icons.workspace_premium_rounded;
    if (rank == 3) return Icons.military_tech_rounded;
    return Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? _rankColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        border: Border.all(
          color: isCurrentUser
              ? _rankColor
              : Colors.grey.withOpacity(0.2),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: _rankColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank indicator
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isTopThree
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _rankColor,
                        _rankColor.withOpacity(0.7),
                      ],
                    )
                  : null,
              color: isTopThree ? null : Colors.grey[200],
              boxShadow: isTopThree
                  ? [
                      BoxShadow(
                        color: _rankColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      _rankIcon,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24.sp,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
            ),
          )
              .animate()
              .scale(delay: (rank * 50).ms, duration: 300.ms, curve: Curves.elasticOut),
          SizedBox(width: 16.w),
          // Avatar
          CircleAvatar(
            radius: 28.r,
            backgroundColor: _rankColor.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _rankColor,
                    ),
                  )
                : null,
          )
              .animate()
              .fadeIn(delay: (rank * 50 + 100).ms)
              .scale(delay: (rank * 50 + 100).ms, duration: 300.ms),
          SizedBox(width: 12.w),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _rankColor,
                          borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14.sp,
                      color: _rankColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (tribe != null) ...[
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        ),
                        child: Text(
                          tribe!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: _rankColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _rankColor,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: (rank * 50 + 200).ms)
              .slideX(begin: 0.1, delay: (rank * 50 + 200).ms),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (rank * 50).ms, duration: 400.ms)
        .slideX(begin: -0.1, delay: (rank * 50).ms, duration: 400.ms);
  }
}

