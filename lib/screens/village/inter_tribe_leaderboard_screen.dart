import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class InterTribeLeaderboardScreen extends ConsumerStatefulWidget {
  const InterTribeLeaderboardScreen({super.key});

  @override
  ConsumerState<InterTribeLeaderboardScreen> createState() =>
      _InterTribeLeaderboardScreenState();
}

class _InterTribeLeaderboardScreenState
    extends ConsumerState<InterTribeLeaderboardScreen> {
  int _selectedFilter = 0;

  static const _filterLabels = ['Weekly', 'Monthly', 'All-Time'];

  static const _rankedTribes = [
    _RankedTribe('Warriors', '⚔️', 56800, _Trend.up),
    _RankedTribe('Scholars', '📚', 48200, _Trend.stable),
    _RankedTribe('Voices', '🎙️', 41600, _Trend.up),
    _RankedTribe('Traders', '🤝', 38900, _Trend.down),
    _RankedTribe('Night Owls', '🦉', 35400, _Trend.up),
    _RankedTribe('Storytellers', '📖', 32100, _Trend.down),
    _RankedTribe('Flamekeepers', '🔥', 29800, _Trend.stable),
  ];

  @override
  Widget build(BuildContext context) {
    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _buildHeader(context),
              SizedBox(height: 20.h),
              _buildFilterPills(context),
              SizedBox(height: 24.h),
              _buildPodium(context),
              SizedBox(height: 24.h),
              _buildYourTribeCard(context),
              SizedBox(height: 20.h),
              _buildRankList(context),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inter-Tribe Leaderboard',
                  style: ModernGriotTypography.titleLarge()),
              Text('Compete for continental glory',
                  style: ModernGriotTypography.bodySmall()),
            ],
          ),
        ),
        Icon(Icons.share_rounded,
            size: 22.sp, color: ModernGriotColors.onSurfaceVariant),
      ],
    );
  }

  Widget _buildFilterPills(BuildContext context) {
    return Row(
      children: _filterLabels.asMap().entries.map((e) {
        final isSelected = _selectedFilter == e.key;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GriotChip(
            label: e.value,
            selected: isSelected,
            onTap: () {
              setState(() => _selectedFilter = e.key);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPodium(BuildContext context) {
    final top3 = _rankedTribes.take(3).toList();
    final medals = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final heights = [180.h, 130.h, 100.h];

    return SizedBox(
      height: 240.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumColumn(
                top3[1], 2, medals[1], heights[1]),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _buildPodiumColumn(
                top3[0], 1, medals[0], heights[0]),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _buildPodiumColumn(
                top3[2], 3, medals[2], heights[2]),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
      _RankedTribe tribe, int rank, Color medal, double height) {
    final medalIcons = [
      Icons.workspace_premium_rounded,
      Icons.workspace_premium_rounded,
      Icons.workspace_premium_rounded,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: medal.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(tribe.emoji,
                  style: TextStyle(fontSize: 22.sp))),
        ),
        SizedBox(height: 4.h),
        Text(tribe.name,
            style: ModernGriotTypography.labelMedium(),
            textAlign: TextAlign.center),
        Text('${(tribe.xp / 1000).toStringAsFixed(1)}K',
            style: ModernGriotTypography.bodySmall(
                color: ModernGriotColors.primary)),
        SizedBox(height: 8.h),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [medal.withAlpha(180), medal.withAlpha(50)],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ModernGriotRadius.lg),
            ),
          ),
          child: Center(
            child: Icon(medalIcons[rank - 1],
                size: 28.sp, color: Colors.white.withAlpha(200)),
          ),
        ),
      ],
    );
  }

  Widget _buildYourTribeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9E3D00), Color(0xFFFF7A35)],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text('🦉', style: TextStyle(fontSize: 22.sp))),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Tribe — Night Owls',
                    style: ModernGriotTypography.titleSmall(
                        color: Colors.white)),
                SizedBox(height: 2.h),
                Text('35,400 XP',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withAlpha(200),
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text('#14',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildRankList(BuildContext context) {
    final remaining = _rankedTribes.skip(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rankings', style: ModernGriotTypography.titleSmall()),
        SizedBox(height: 10.h),
        ...remaining.asMap().entries.map((e) {
          final rank = e.key + 4;
          final tribe = e.value;
          return _buildRankRow(context, rank, tribe);
        }),
      ],
    );
  }

  Widget _buildRankRow(BuildContext context, int rank, _RankedTribe tribe) {
    final trendIcon = switch (tribe.trend) {
      _Trend.up => Icons.trending_up_rounded,
      _Trend.down => Icons.trending_down_rounded,
      _Trend.stable => Icons.trending_flat_rounded,
    };
    final trendColor = switch (tribe.trend) {
      _Trend.up => const Color(0xFF16A34A),
      _Trend.down => const Color(0xFFEF4444),
      _Trend.stable => ModernGriotColors.onSurfaceVariant,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderXl,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.w,
              child: Text('#$rank',
                  style: ModernGriotTypography.labelMedium(
                      color: ModernGriotColors.onSurfaceVariant)),
            ),
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: ModernGriotColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(tribe.emoji,
                      style: TextStyle(fontSize: 18.sp))),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tribe.name,
                      style: ModernGriotTypography.titleSmall()),
                  Text('${(tribe.xp / 1000).toStringAsFixed(1)}K XP',
                      style: ModernGriotTypography.bodySmall(
                          color: ModernGriotColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(trendIcon, size: 20.sp, color: trendColor),
          ],
        ),
      ),
    );
  }
}

enum _Trend { up, down, stable }

class _RankedTribe {
  const _RankedTribe(this.name, this.emoji, this.xp, this.trend);
  final String name;
  final String emoji;
  final int xp;
  final _Trend trend;
}
