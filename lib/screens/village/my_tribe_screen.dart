import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class MyTribeScreen extends ConsumerWidget {
  const MyTribeScreen({super.key});

  static const _feedPosts = [
    _FeedPost('Amina earned "Fire Starter" badge', '2m ago',
        Icons.local_fire_department_rounded),
    _FeedPost('Kwame completed Lesson 14', '8m ago', Icons.school_rounded),
    _FeedPost('Lila shared a proverb', '15m ago', Icons.format_quote_rounded),
    _FeedPost('Tribe duel won vs Scholars!', '1h ago', Icons.emoji_events_rounded),
  ];

  static const _leaderboard = [
    _LeaderEntry('Amina K.', 2450, 'AM'),
    _LeaderEntry('Kwame O.', 2380, 'KO'),
    _LeaderEntry('You', 2210, 'ME'),
    _LeaderEntry('Lila S.', 2100, 'LS'),
    _LeaderEntry('Juma M.', 1980, 'JM'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _buildTotemHeader(context),
              SizedBox(height: 20.h),
              _buildXpProgress(context),
              SizedBox(height: 24.h),
              _buildLiveDuel(context),
              SizedBox(height: 24.h),
              _buildFeedAndLeaderboard(context),
              SizedBox(height: 24.h),
              _buildEventCard(context),
              SizedBox(height: 20.h),
              _buildTotemBadges(context),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotemHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            gradient: ModernGriotGradients.signatureGradient,
            shape: BoxShape.circle,
            boxShadow: ModernGriotShadows.md,
          ),
          child: Icon(Icons.nights_stay_rounded,
              size: 28.sp, color: ModernGriotColors.onPrimary),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Night Owls', style: ModernGriotTypography.titleLarge()),
              SizedBox(height: 2.h),
              Text('Swahili Learning Tribe',
                  style: ModernGriotTypography.bodySmall()),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: ModernGriotGradients.signatureGradient,
            borderRadius: ModernGriotRadius.borderPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 14.sp, color: Colors.white),
              SizedBox(width: 4.w),
              Text('Rank 3rd',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXpProgress(BuildContext context) {
    return GriotCard(
      surfaceLevel: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tribe XP', style: ModernGriotTypography.titleSmall()),
              Text('8,450 / 12,000',
                  style: ModernGriotTypography.labelMedium(
                      color: ModernGriotColors.primaryContainer)),
            ],
          ),
          SizedBox(height: 10.h),
          GriotProgressBar(value: 8450 / 12000, showGlowTip: true),
          SizedBox(height: 8.h),
          Text('3,550 XP to next milestone',
              style: ModernGriotTypography.bodySmall()),
        ],
      ),
    );
  }

  Widget _buildLiveDuel(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text('LIVE TRIBE DUEL',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                    letterSpacing: 1.2,
                  )),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: _buildTeamSide('Eagles', '🦅', 1240, true)),
              SizedBox(width: 12.w),
              _buildVsBadge(),
              SizedBox(width: 12.w),
              Expanded(child: _buildTeamSide('Dragons', '🐉', 1180, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSide(
      String name, String emoji, int score, bool isLeft) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 28.sp)),
        SizedBox(height: 6.h),
        Text(name, style: ModernGriotTypography.titleSmall()),
        SizedBox(height: 4.h),
        Text('$score pts',
            style: ModernGriotTypography.headlineSmall(
                color: ModernGriotColors.primary)),
      ],
    );
  }

  Widget _buildVsBadge() {
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        shape: BoxShape.circle,
        boxShadow: ModernGriotShadows.fab,
      ),
      child: Center(
        child: Text('VS',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            )),
      ),
    );
  }

  Widget _buildFeedAndLeaderboard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tribe Feed', style: ModernGriotTypography.titleSmall()),
              SizedBox(height: 10.h),
              ..._feedPosts.map((post) => _buildFeedItem(context, post)),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: 140.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top 5', style: ModernGriotTypography.titleSmall()),
              SizedBox(height: 10.h),
              ..._leaderboard.asMap().entries.map(
                    (e) => _buildLeaderRow(context, e.key + 1, e.value)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedItem(BuildContext context, _FeedPost post) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderLg,
        ),
        child: Row(
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: ModernGriotColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(post.icon,
                  size: 14.sp, color: ModernGriotColors.primary),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.text,
                      style: ModernGriotTypography.bodySmall(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(post.time,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: ModernGriotColors.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderRow(
      BuildContext context, int rank, _LeaderEntry entry) {
    final isMe = entry.initials == 'ME';
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isMe
              ? ModernGriotColors.primary.withAlpha(15)
              : ModernGriotColors.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderMd,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18.w,
              child: Text('$rank',
                  style: ModernGriotTypography.labelSmall(
                      color: rank <= 3
                          ? ModernGriotColors.primaryContainer
                          : ModernGriotColors.onSurfaceVariant)),
            ),
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                color: isMe
                    ? ModernGriotColors.primary
                    : ModernGriotColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(entry.initials,
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: isMe ? Colors.white : ModernGriotColors.onSurface,
                    )),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(entry.name,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    color: ModernGriotColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context) {
    return GriotCard(
      surfaceLevel: 0,
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: ModernGriotColors.secondary.withAlpha(20),
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Icon(Icons.calendar_today_rounded,
                size: 22.sp, color: ModernGriotColors.secondary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proverb Night', style: ModernGriotTypography.titleSmall()),
                SizedBox(height: 2.h),
                Text('Saturday 8PM · 24 attending',
                    style: ModernGriotTypography.bodySmall()),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => HapticFeedback.mediumImpact(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: ModernGriotGradients.forestGrowth,
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text('RSVP',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotemBadges(BuildContext context) {
    final badges = [
      ('🦉', 'Wisdom', true),
      ('🔥', 'Streak', true),
      ('⚔️', 'Duelist', true),
      ('📖', 'Scholar', false),
      ('🌍', 'Explorer', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Totem Badges', style: ModernGriotTypography.titleSmall()),
        SizedBox(height: 10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: badges.map((b) {
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Opacity(
                  opacity: b.$3 ? 1.0 : 0.4,
                  child: Column(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: b.$3
                              ? ModernGriotColors.primary.withAlpha(15)
                              : ModernGriotColors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          boxShadow: b.$3 ? ModernGriotShadows.sm : null,
                        ),
                        child: Center(
                            child: Text(b.$1,
                                style: TextStyle(fontSize: 22.sp))),
                      ),
                      SizedBox(height: 4.h),
                      Text(b.$2,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: ModernGriotColors.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FeedPost {
  const _FeedPost(this.text, this.time, this.icon);
  final String text;
  final String time;
  final IconData icon;
}

class _LeaderEntry {
  const _LeaderEntry(this.name, this.xp, this.initials);
  final String name;
  final int xp;
  final String initials;
}
