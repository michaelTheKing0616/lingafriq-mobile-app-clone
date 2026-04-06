import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ─── Mock data ──────────────────────────────────────────────────────────────

class _Trending {
  const _Trending(this.tag, this.postCount, this.category);
  final String tag, category;
  final int postCount;
}

const _trending = <_Trending>[
  _Trending('#SwahiliSunday', 2840, 'Language · Trending'),
  _Trending('#YorubaProverbs', 1620, 'Culture · Trending'),
  _Trending('#LearnTwi', 980, 'Education · Trending'),
  _Trending('#WolofMusic', 745, 'Entertainment · Trending'),
  _Trending('#AmharicScript', 512, 'Writing · Trending'),
];

const _speakers = [
  ('Aïcha Traoré', '@aicha_t', 'Bambara'),
  ('Tunde Adeyemi', '@tunde_a', 'Yoruba'),
  ('Zainab Mwangi', '@zainab_m', 'Swahili'),
  ('Kofi Adu', '@kofi_adu', 'Twi'),
  ('Mariama Bâ', '@mariama_b', 'Wolof'),
];

class _PreviewPost {
  const _PreviewPost(this.name, this.handle, this.text, this.likes,
      this.replies, this.reposts);
  final String name, handle, text;
  final int likes, replies, reposts;
}

const _previewPosts = [
  _PreviewPost(
    'Amina Diallo',
    '@amina_d',
    'The way #Wolof builds plurals is so elegant — completely different from European languages! Who knew?',
    86,
    14,
    22,
  ),
  _PreviewPost(
    'Kwame Asante',
    '@kwame_learns',
    'Just unlocked the Advanced #Twi module! The storytelling exercises are next level 🎉',
    214,
    38,
    55,
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class ExploreCommunityScreen extends ConsumerStatefulWidget {
  const ExploreCommunityScreen({super.key});

  @override
  ConsumerState<ExploreCommunityScreen> createState() =>
      _ExploreCommunityScreenState();
}

class _ExploreCommunityScreenState
    extends ConsumerState<ExploreCommunityScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Explore',
            style: ModernGriotTypography.titleLarge(context: context)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          GriotInput(
            controller: _searchCtrl,
            hintText: 'Search hashtags, phrases, topics…',
            prefixIcon: Icons.search_rounded,
          ),
          SizedBox(height: 20.h),

          // Featured trending card (full width)
          _FeaturedTrendCard(item: _trending.first),
          SizedBox(height: 12.h),

          // Smaller trending cards
          ...List.generate(
            _trending.length - 1,
            (i) => _TrendCard(item: _trending[i + 1], rank: i + 2),
          ),
          SizedBox(height: 24.h),

          // Horizontal "Who to Follow"
          Text('Who to Follow',
              style: ModernGriotTypography.titleSmall(context: context)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 160.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _speakers.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, i) {
                final s = _speakers[i];
                return _SpeakerCard(
                    name: s.$1, handle: s.$2, language: s.$3);
              },
            ),
          ),
          SizedBox(height: 24.h),

          // Feed preview posts
          Text('Popular Posts',
              style: ModernGriotTypography.titleSmall(context: context)),
          SizedBox(height: 12.h),
          ..._previewPosts.map((p) => _FeedPreviewCard(post: p)),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ─── Featured trend card ────────────────────────────────────────────────────

class _FeaturedTrendCard extends StatelessWidget {
  const _FeaturedTrendCard({required this.item});
  final _Trending item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                '#1 Trending',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(200),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            item.tag,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${_fmt(item.postCount)} posts · ${item.category}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Smaller trend card ─────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.item, required this.rank});
  final _Trending item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: GriotCard(
        surfaceLevel: 1,
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.tag,
                      style: ModernGriotTypography.titleSmall(
                          context: context)),
                  Text(
                    '${_fmt(item.postCount)} posts · ${item.category}',
                    style: ModernGriotTypography.labelSmall(
                        context: context, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// ─── Speaker card with native badge ─────────────────────────────────────────

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.name,
    required this.handle,
    required this.language,
  });

  final String name, handle, language;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140.w,
      child: GriotCard(
        surfaceLevel: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GriotAvatar(size: 48),
            SizedBox(height: 8.h),
            Text(
              name,
              style: ModernGriotTypography.titleSmall(context: context),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              handle,
              style: ModernGriotTypography.labelSmall(
                  context: context, color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 6.h),
            GriotBadgePill(
              label: '$language Native',
              icon: Icons.verified_rounded,
              color: cs.secondary,
              textColor: cs.onSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feed preview card ──────────────────────────────────────────────────────

class _FeedPreviewCard extends StatelessWidget {
  const _FeedPreviewCard({required this.post});
  final _PreviewPost post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = ModernGriotTypography.bodyMedium(context: context);
    final tagStyle =
        base.copyWith(color: cs.primary, fontWeight: FontWeight.w600);

    final spans = <TextSpan>[];
    final re = RegExp(r'(#\w+)');
    var last = 0;
    for (final m in re.allMatches(post.text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: post.text.substring(last, m.start)));
      }
      spans.add(TextSpan(text: m.group(0), style: tagStyle));
      last = m.end;
    }
    if (last < post.text.length) {
      spans.add(TextSpan(text: post.text.substring(last)));
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.name,
                          style: ModernGriotTypography.titleSmall(
                              context: context)),
                      Text(post.handle,
                          style: ModernGriotTypography.labelSmall(
                              context: context,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            RichText(text: TextSpan(style: base, children: spans)),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 16.sp, color: cs.onSurfaceVariant),
                SizedBox(width: 4.w),
                Text(_fmt(post.replies),
                    style: ModernGriotTypography.labelSmall(
                        context: context, color: cs.onSurfaceVariant)),
                SizedBox(width: 16.w),
                Icon(Icons.repeat_rounded,
                    size: 16.sp, color: cs.onSurfaceVariant),
                SizedBox(width: 4.w),
                Text(_fmt(post.reposts),
                    style: ModernGriotTypography.labelSmall(
                        context: context, color: cs.onSurfaceVariant)),
                SizedBox(width: 16.w),
                Icon(Icons.favorite_border_rounded,
                    size: 16.sp, color: cs.onSurfaceVariant),
                SizedBox(width: 4.w),
                Text(_fmt(post.likes),
                    style: ModernGriotTypography.labelSmall(
                        context: context, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
