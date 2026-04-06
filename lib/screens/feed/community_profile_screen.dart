import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ─── Mock data ──────────────────────────────────────────────────────────────

const _profileName = 'Amina Diallo';
const _profileHandle = '@amina_d';
const _profileBio =
    'Wolof native speaker · Yoruba learner · Language enthusiast connecting cultures through words 🌍';
const _followers = '2.4K';
const _following = '318';
const _xp = '8,750';
const _learnedLanguages = ['Wolof', 'Yoruba', 'French', 'Swahili'];

const _profilePosts = [
  (
    'Just finished my first #Wolof conversation with a native speaker! 🎶',
    '42 likes · 8 replies',
  ),
  (
    'Learning #Yoruba proverbs is like discovering hidden wisdom 🌍',
    '256 likes · 45 replies',
  ),
  (
    'Day 14 of speaking only in African languages. My brain is rewiring itself!',
    '312 likes · 67 replies',
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class CommunityProfileScreen extends ConsumerStatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  ConsumerState<CommunityProfileScreen> createState() =>
      _CommunityProfileScreenState();
}

class _CommunityProfileScreenState
    extends ConsumerState<CommunityProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200.h,
            pinned: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _CoverHeader(),
            ),
          ),
          SliverToBoxAdapter(child: _ProfileInfo()),
          SliverToBoxAdapter(child: _StatsRow()),
          SliverToBoxAdapter(child: _LanguageBadges()),
          SliverToBoxAdapter(child: _JoinCta()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: ModernGriotTypography.labelLarge(context: context),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Replies'),
                  Tab(text: 'Media'),
                  Tab(text: 'Likes'),
                ],
              ),
              cs.surface,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _PostsTab(),
            _EmptyTab(label: 'No replies yet'),
            _MediaTab(),
            _EmptyTab(label: 'No likes yet'),
          ],
        ),
      ),
    );
  }
}

// ─── Cover header ───────────────────────────────────────────────────────────

class _CoverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Icon(
            Icons.landscape_rounded,
            size: 48.sp,
            color: Colors.white.withAlpha(60),
          ),
        ),
      ),
    );
  }
}

// ─── Profile info section ───────────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: Offset(0, -40.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 4),
                  ),
                  child: GriotAvatar(
                    size: 96,
                    badge: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: Icon(Icons.verified_rounded,
                          size: 14.sp, color: cs.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_profileName,
                    style:
                        ModernGriotTypography.titleLarge(context: context)),
                SizedBox(height: 2.h),
                Text(
                  _profileHandle,
                  style: ModernGriotTypography.bodyMedium(
                      context: context, color: cs.onSurfaceVariant),
                ),
                SizedBox(height: 8.h),
                Text(
                  _profileBio,
                  style: ModernGriotTypography.bodyMedium(context: context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GriotStatCard(
              icon: Icons.people_rounded,
              value: _followers,
              label: 'Followers',
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: GriotStatCard(
              icon: Icons.person_add_rounded,
              value: _following,
              label: 'Following',
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: GriotStatCard(
              icon: Icons.bolt_rounded,
              value: _xp,
              label: 'XP',
              iconColor: ModernGriotColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language totem badges ──────────────────────────────────────────────────

class _LanguageBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _learnedLanguages
            .map((lang) => GriotBadgePill(
                  label: lang,
                  icon: Icons.translate_rounded,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Join the tribe CTA ─────────────────────────────────────────────────────

class _JoinCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GriotGradientButton(
        label: 'Join the Tribe',
        icon: Icons.group_add_rounded,
        onPressed: () {},
      ),
    );
  }
}

// ─── Tab bar delegate ───────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, this.bgColor);
  final TabBar tabBar;
  final Color bgColor;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─── Posts tab ──────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: _profilePosts.length,
      itemBuilder: (_, i) {
        final p = _profilePosts[i];
        final base = ModernGriotTypography.bodyMedium(context: context);
        final tagStyle =
            base.copyWith(color: cs.primary, fontWeight: FontWeight.w600);
        final spans = <TextSpan>[];
        final re = RegExp(r'(#\w+)');
        var last = 0;
        for (final m in re.allMatches(p.$1)) {
          if (m.start > last) {
            spans.add(TextSpan(text: p.$1.substring(last, m.start)));
          }
          spans.add(TextSpan(text: m.group(0), style: tagStyle));
          last = m.end;
        }
        if (last < p.$1.length) {
          spans.add(TextSpan(text: p.$1.substring(last)));
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GriotCard(
            surfaceLevel: 1,
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GriotAvatar(size: 36),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profileName,
                            style: ModernGriotTypography.titleSmall(
                                context: context)),
                        Text(_profileHandle,
                            style: ModernGriotTypography.labelSmall(
                                context: context,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                RichText(text: TextSpan(style: base, children: spans)),
                SizedBox(height: 8.h),
                Text(
                  p.$2,
                  style: ModernGriotTypography.labelSmall(
                      context: context, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Media tab (asymmetric grid) ────────────────────────────────────────────

class _MediaTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      ModernGriotColors.primaryContainer,
      ModernGriotColors.secondary,
      ModernGriotColors.tertiary,
    ];

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large left image
          Expanded(
            flex: 2,
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                color: colors[0].withAlpha(60),
                borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              ),
              child: Center(
                child: Icon(Icons.image_rounded,
                    size: 40.sp, color: cs.onSurfaceVariant.withAlpha(80)),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Two stacked right images
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 105.h,
                  decoration: BoxDecoration(
                    color: colors[1].withAlpha(60),
                    borderRadius:
                        BorderRadius.circular(ModernGriotRadius.xl),
                  ),
                  child: Center(
                    child: Icon(Icons.image_rounded,
                        size: 28.sp,
                        color: cs.onSurfaceVariant.withAlpha(80)),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  height: 105.h,
                  decoration: BoxDecoration(
                    color: colors[2].withAlpha(60),
                    borderRadius:
                        BorderRadius.circular(ModernGriotRadius.xl),
                  ),
                  child: Center(
                    child: Icon(Icons.image_rounded,
                        size: 28.sp,
                        color: cs.onSurfaceVariant.withAlpha(80)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty tab placeholder ──────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 48.sp, color: cs.onSurfaceVariant.withAlpha(80)),
          SizedBox(height: 12.h),
          Text(label,
              style: ModernGriotTypography.bodyMedium(
                  context: context, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
