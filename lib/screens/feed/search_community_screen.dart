import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ─── Mock data ──────────────────────────────────────────────────────────────

const _trendingTopics = [
  '#LearnYoruba',
  '#SwahiliDaily',
  '#WolofVibes',
  '#TwiChallenge',
  '#ZuluPhrases',
  '#AmharicScript',
  '#IgboProverbs',
  '#HausaMusic',
];

const _usersToFollow = [
  ('Amina Diallo', '@amina_d', 'Wolof native'),
  ('Kwame Asante', '@kwame_learns', 'Twi tutor'),
  ('Fatou Sow', '@fatou_sow', 'Yoruba speaker'),
  ('Yusuf Okafor', '@yusuf_o', 'Swahili learner'),
  ('Nia Mensah', '@nia_m', 'Twi native'),
  ('Ousmane Bah', '@ousmane_bah', 'Wolof teacher'),
];

const _communities = [
  ('Swahili', '12.4K members', Color(0xFF2563EB), Color(0xFF60A5FA)),
  ('Yoruba', '9.8K members', Color(0xFF9E3D00), Color(0xFFFF7A35)),
  ('Zulu', '7.2K members', Color(0xFF16A34A), Color(0xFF4ADE80)),
  ('Amharic', '5.6K members', Color(0xFF7C3AED), Color(0xFFA78BFA)),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class SearchCommunityScreen extends ConsumerStatefulWidget {
  const SearchCommunityScreen({super.key});

  @override
  ConsumerState<SearchCommunityScreen> createState() =>
      _SearchCommunityScreenState();
}

class _SearchCommunityScreenState
    extends ConsumerState<SearchCommunityScreen> {
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
        title: Text('Discover',
            style: ModernGriotTypography.titleLarge(context: context)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          GriotInput(
            controller: _searchCtrl,
            hintText: 'Search languages, topics, people…',
            prefixIcon: Icons.search_rounded,
          ),
          SizedBox(height: 20.h),

          // Trending topics
          Text('Trending Topics',
              style: ModernGriotTypography.titleSmall(context: context)),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _trendingTopics
                .map((tag) => GriotChip(
                      label: tag,
                      onTap: () {},
                    ))
                .toList(),
          ),
          SizedBox(height: 28.h),

          // Who to follow
          Text('Who to Follow',
              style: ModernGriotTypography.titleSmall(context: context)),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.85,
            ),
            itemCount: _usersToFollow.length,
            itemBuilder: (_, i) {
              final user = _usersToFollow[i];
              final tilt = i.isEven ? -0.03 : 0.03;
              return _UserFollowCard(
                name: user.$1,
                handle: user.$2,
                bio: user.$3,
                tilt: tilt,
              );
            },
          ),
          SizedBox(height: 28.h),

          // Language communities bento
          Text('Language Communities',
              style: ModernGriotTypography.titleSmall(context: context)),
          SizedBox(height: 12.h),
          _CommunitiesBento(),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ─── User follow card with tilt ─────────────────────────────────────────────

class _UserFollowCard extends StatelessWidget {
  const _UserFollowCard({
    required this.name,
    required this.handle,
    required this.bio,
    this.tilt = 0,
  });

  final String name, handle, bio;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Transform.rotate(
      angle: tilt,
      child: GriotCard(
        surfaceLevel: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GriotAvatar(size: 52),
            SizedBox(height: 8.h),
            Text(
              name,
              style: ModernGriotTypography.titleSmall(context: context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              handle,
              style: ModernGriotTypography.labelSmall(
                  context: context, color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 4.h),
            GriotBadgePill(label: bio),
            SizedBox(height: 10.h),
            SizedBox(
              height: 32.h,
              child: GriotGradientButton(
                label: 'Follow',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Communities bento grid ──────────────────────────────────────────────────

class _CommunitiesBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _communities.length,
      itemBuilder: (_, i) {
        final c = _communities[i];
        return _CommunityTile(
          language: c.$1,
          members: c.$2,
          from: c.$3,
          to: c.$4,
        );
      },
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.language,
    required this.members,
    required this.from,
    required this.to,
  });

  final String language, members;
  final Color from, to;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [from, to],
        ),
        borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
        child: InkWell(
          onTap: () => HapticFeedback.lightImpact(),
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          splashColor: Colors.white24,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  members,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
