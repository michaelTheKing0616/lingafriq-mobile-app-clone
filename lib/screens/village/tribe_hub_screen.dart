import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class TribeHubScreen extends ConsumerWidget {
  const TribeHubScreen({super.key});

  static const _notices = [
    _Notice('Weekly Challenge', 'Complete 5 lessons to earn bonus XP',
        Icons.flag_rounded, 'Apr 3'),
    _Notice('New Elder', 'Elder Nia has joined the tribe!',
        Icons.person_add_rounded, 'Apr 2'),
    _Notice('Maintenance', 'Practice rooms update — v2.4',
        Icons.build_rounded, 'Apr 1'),
  ];

  static const _achievements = [
    _Achievement('First Word', Icons.abc_rounded, true),
    _Achievement('10 Day Streak', Icons.local_fire_department_rounded, true),
    _Achievement('Duel Winner', Icons.emoji_events_rounded, true),
    _Achievement('100 Words', Icons.library_books_rounded, false),
    _Achievement('Night Owl', Icons.nights_stay_rounded, false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(context),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildStatsBento(context),
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildTwoColumnSection(context),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildReactionBar(context),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ModernGriotRadius.xxl),
          bottomRight: Radius.circular(ModernGriotRadius.xxl),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10.w,
            top: -10.h,
            child: Icon(
              Icons.nights_stay_rounded,
              size: 120.sp,
              color: Colors.white.withAlpha(18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 24.sp, color: Colors.white),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pushNamed('/settings');
                    },
                    child: Icon(Icons.settings_rounded,
                        size: 22.sp, color: Colors.white.withAlpha(180)),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text('Night Owls',
                  style: ModernGriotTypography.headlineLarge(
                      color: Colors.white)),
              SizedBox(height: 4.h),
              Text('Tribe Hub — Swahili Seekers',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withAlpha(200),
                  )),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _buildStatPill(
                    context,
                    '32 Members',
                    Icons.group_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/my-tribe'),
                  ),
                  SizedBox(width: 8.w),
                  _buildStatPill(
                    context,
                    'Rank #3',
                    Icons.leaderboard_rounded,
                    onTap: () => Navigator.of(context)
                        .pushNamed('/${VillageRouteNames.interTribeLeaderboard}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: child,
    );
  }

  Widget _buildStatsBento(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GriotStatCard(
            icon: Icons.auto_stories_rounded,
            value: 'Elder',
            label: 'Village Level',
            iconColor: ModernGriotColors.primary,
            onTap: () => Navigator.of(context).pushNamed('/elder-hut'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.trending_up_rounded,
            value: 'Sage',
            label: 'Next Tier',
            iconColor: ModernGriotColors.secondary,
            onTap: () => Navigator.of(context)
                .pushNamed('/${VillageRouteNames.tonalLesson}'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.person_search_rounded,
            value: '18',
            label: 'Active Seekers',
            iconColor: ModernGriotColors.primaryContainer,
            onTap: () =>
                Navigator.of(context).pushNamed('/tribe-discovery'),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Noticeboard', style: ModernGriotTypography.titleSmall()),
              SizedBox(height: 10.h),
              ..._notices.map((n) => _buildNoticeCard(context, n)),
            ],
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Achievements', style: ModernGriotTypography.titleSmall()),
              SizedBox(height: 10.h),
              ..._achievements.map((a) => _buildAchievementRow(context, a)),
              SizedBox(height: 16.h),
              _buildLiveDuelSidebar(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(BuildContext context, _Notice notice) {
    void openNotice() {
      switch (notice.title) {
        case 'Weekly Challenge':
          Navigator.of(context).pushNamed('/daily_goals');
          return;
        case 'New Elder':
          Navigator.of(context).pushNamed('/my-tribe');
          return;
        case 'Maintenance':
          Navigator.of(context).pushNamed('/features_guide');
          return;
        default:
          Navigator.of(context).pushNamed('/practice-room-setup');
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GriotCard(
        surfaceLevel: 1,
        padding: EdgeInsets.all(12.r),
        onTap: openNotice,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(notice.icon,
                    size: 16.sp, color: ModernGriotColors.primary),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(notice.title,
                      style: ModernGriotTypography.labelMedium(),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(notice.body,
                style: ModernGriotTypography.bodySmall(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            Text(notice.date,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: ModernGriotColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementRow(BuildContext context, _Achievement achievement) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Opacity(
        opacity: achievement.unlocked ? 1.0 : 0.4,
        child: Row(
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: achievement.unlocked
                    ? ModernGriotColors.primary.withAlpha(20)
                    : ModernGriotColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(achievement.icon,
                  size: 14.sp,
                  color: achievement.unlocked
                      ? ModernGriotColors.primary
                      : ModernGriotColors.onSurfaceVariant),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(achievement.name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: ModernGriotColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis),
            ),
            if (achievement.unlocked)
              Icon(Icons.check_circle_rounded,
                  size: 14.sp, color: ModernGriotColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDuelSidebar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushNamed('/${VillageRouteNames.tribalDuel}');
      },
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9E3D00), Color(0xFFFF7A35)],
          ),
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.md,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
                Text('LIVE',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    )),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Duel Active',
                style: ModernGriotTypography.labelMedium(
                    color: Colors.white)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text('Contribute XP',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar(BuildContext context) {
    final reactions = [
      ('🔥', 'Fire', 42),
      ('🗡️', 'Spear', 18),
      ('🙏', 'Respect', 87),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: reactions.map((r) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ModernGriotColors.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderPill,
                boxShadow: ModernGriotShadows.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.$1, style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 6.w),
                  Text('${r.$3}',
                      style: ModernGriotTypography.labelMedium(
                          color: ModernGriotColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Notice {
  const _Notice(this.title, this.body, this.icon, this.date);
  final String title;
  final String body;
  final IconData icon;
  final String date;
}

class _Achievement {
  const _Achievement(this.name, this.icon, this.unlocked);
  final String name;
  final IconData icon;
  final bool unlocked;
}
