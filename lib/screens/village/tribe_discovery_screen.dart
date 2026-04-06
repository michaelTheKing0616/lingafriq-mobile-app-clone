import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class TribeDiscoveryScreen extends ConsumerWidget {
  const TribeDiscoveryScreen({super.key});

  static const _tribes = [
    _DiscoverTribe('Warriors', '⚔️', 'Strength through mastery', 1284,
        Color(0xFFB91C1C)),
    _DiscoverTribe('Scholars', '📚', 'Knowledge is eternal', 968,
        Color(0xFF1D4ED8)),
    _DiscoverTribe('Traders', '🤝', 'Exchange builds bridges', 756,
        Color(0xFF526124)),
    _DiscoverTribe('Voices', '🎙️', 'Speak to be heard', 642,
        Color(0xFF7B5733)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      floatingActionButton: GriotFab(
        icon: Icons.add_rounded,
        onPressed: () {
          HapticFeedback.mediumImpact();
          VillageNavigation.pushTribeHub(context);
        },
        heroTag: 'create_tribe',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _buildHeader(context),
              SizedBox(height: 28.h),
              _buildLeaderboardPodium(context),
              SizedBox(height: 32.h),
              _buildFindTribeSection(context),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: ModernGriotColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  boxShadow: ModernGriotShadows.sm,
                ),
                child: Icon(Icons.arrow_back_rounded, size: 20.sp),
              ),
            ),
            SizedBox(width: 12.w),
            Text('Tribe Discovery',
                style: ModernGriotTypography.titleLarge()),
          ],
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 52.w),
          child: Text('Find your people. Compete. Rise together.',
              style: ModernGriotTypography.bodySmall()),
        ),
      ],
    );
  }

  Widget _buildLeaderboardPodium(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Global Leaderboard',
            style: ModernGriotTypography.titleMedium()),
        SizedBox(height: 16.h),
        SizedBox(
          height: 220.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildPodiumSlot(
                  context,
                  rank: 2,
                  name: 'Scholars',
                  emoji: '📚',
                  xp: 48200,
                  height: 140.h,
                  color: const Color(0xFFC0C0C0),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPodiumSlot(
                  context,
                  rank: 1,
                  name: 'Warriors',
                  emoji: '⚔️',
                  xp: 56800,
                  height: 200.h,
                  color: const Color(0xFFFFD700),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPodiumSlot(
                  context,
                  rank: 3,
                  name: 'Voices',
                  emoji: '🎙️',
                  xp: 41600,
                  height: 110.h,
                  color: const Color(0xFFCD7F32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumSlot(
    BuildContext context, {
    required int rank,
    required String name,
    required String emoji,
    required int xp,
    required double height,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(emoji, style: TextStyle(fontSize: 32.sp)),
        SizedBox(height: 6.h),
        Text(name, style: ModernGriotTypography.labelMedium()),
        SizedBox(height: 2.h),
        Text('${(xp / 1000).toStringAsFixed(1)}K XP',
            style: ModernGriotTypography.bodySmall(
                color: ModernGriotColors.primary)),
        SizedBox(height: 8.h),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withAlpha(200),
                color.withAlpha(80),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ModernGriotRadius.lg),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                  ),
                ),
                if (rank == 1) ...[
                  SizedBox(height: 4.h),
                  Icon(Icons.emoji_events_rounded,
                      size: 20.sp, color: const Color(0xFFFFD700)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFindTribeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find your Tribe', style: ModernGriotTypography.titleMedium()),
        SizedBox(height: 14.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.82,
          children: _tribes.map((tribe) {
            return _buildTribeCard(context, tribe);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTribeCard(BuildContext context, _DiscoverTribe tribe) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        VillageNavigation.pushTribeHub(context);
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: tribe.accent.withAlpha(20),
                borderRadius: ModernGriotRadius.borderLg,
              ),
              child: Center(
                  child: Text(tribe.emoji,
                      style: TextStyle(fontSize: 22.sp))),
            ),
            SizedBox(height: 12.h),
            Text(tribe.name, style: ModernGriotTypography.titleSmall()),
            SizedBox(height: 2.h),
            Text(tribe.motto,
                style: ModernGriotTypography.bodySmall(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.group_rounded,
                    size: 14.sp, color: ModernGriotColors.onSurfaceVariant),
                SizedBox(width: 4.w),
                Text('${tribe.members}',
                    style: ModernGriotTypography.labelSmall()),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: tribe.accent.withAlpha(20),
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Text('Join',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: tribe.accent,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverTribe {
  const _DiscoverTribe(
      this.name, this.emoji, this.motto, this.members, this.accent);
  final String name;
  final String emoji;
  final String motto;
  final int members;
  final Color accent;
}
