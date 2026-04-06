import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            _buildHeader(context),
            SizedBox(height: 24.h),
            _TotalHonorCard(),
            SizedBox(height: 20.h),
            _RankCard(),
            SizedBox(height: 24.h),
            _TotemGridSection(),
            SizedBox(height: 24.h),
            _CertificatePreview(),
            SizedBox(height: 20.h),
            _buildCTAs(context),
            SizedBox(height: 24.h),
            _PathContinuesBanner(),
            SizedBox(height: 32.h),
          ],
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
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20.sp),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text('Achievements',
              style: ModernGriotTypography.headlineSmall()),
        ),
        Icon(Icons.share_rounded,
            size: 22.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }

  Widget _buildCTAs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: GriotGradientButton(
            label: 'Download PDF',
            icon: Icons.download_rounded,
            onPressed: () => HapticFeedback.mediumImpact(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              height: 52.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(
                  color: cs.primary.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, size: 18.sp, color: cs.primary),
                  SizedBox(width: 8.w),
                  Text(
                    'Share Path',
                    style: ModernGriotTypography.labelLarge(
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalHonorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Honor',
            style: ModernGriotTypography.labelLarge(
              color: ModernGriotColors.onPrimary.withAlpha(180),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '12,450 XP',
            style: ModernGriotTypography.displaySmall(
              color: ModernGriotColors.onPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              GriotBadgePill(
                label: 'Today +150',
                icon: Icons.trending_up_rounded,
                color: ModernGriotColors.onPrimary.withAlpha(40),
                textColor: ModernGriotColors.onPrimary,
              ),
              SizedBox(width: 8.w),
              GriotBadgePill(
                label: 'Top 5%',
                icon: Icons.star_rounded,
                color: ModernGriotColors.onPrimary.withAlpha(40),
                textColor: ModernGriotColors.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFCD116), Color(0xFFFF9800)],
              ),
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Icon(Icons.shield_rounded,
                size: 28.sp, color: Colors.white),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Griot',
                        style: ModernGriotTypography.titleLarge()),
                    SizedBox(width: 8.w),
                    GriotBadgePill(
                      label: 'Rank 3',
                      color: cs.secondaryContainer,
                      textColor: cs.onSecondaryContainer,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                GriotProgressBar(
                  value: 0.72,
                  height: 8,
                  showGlowTip: true,
                ),
                SizedBox(height: 4.h),
                Text(
                  '2,800 XP to Elder',
                  style: ModernGriotTypography.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotemGridSection extends StatelessWidget {
  static const _totems = [
    _Totem('Greetings', Icons.waving_hand_rounded, true),
    _Totem('Numbers', Icons.tag_rounded, true),
    _Totem('Family', Icons.family_restroom_rounded, true),
    _Totem('Market', Icons.storefront_rounded, true),
    _Totem('Nature', Icons.eco_rounded, false),
    _Totem('Travel', Icons.flight_rounded, false),
    _Totem('Culture', Icons.theater_comedy_rounded, false),
    _Totem('Mastery', Icons.auto_awesome_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Totems', style: ModernGriotTypography.titleLarge()),
            const Spacer(),
            Text('4 / 8 unlocked',
                style: ModernGriotTypography.bodySmall()),
          ],
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
          ),
          itemCount: _totems.length,
          itemBuilder: (context, i) {
            final t = _totems[i];
            return _TotemCell(totem: t);
          },
        ),
      ],
    );
  }
}

class _Totem {
  const _Totem(this.label, this.icon, this.unlocked);
  final String label;
  final IconData icon;
  final bool unlocked;
}

class _TotemCell extends StatelessWidget {
  const _TotemCell({required this.totem});
  final _Totem totem;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: totem.unlocked ? cs.surfaceContainerLow : cs.surface,
        borderRadius: ModernGriotRadius.borderXl,
        border: totem.unlocked
            ? null
            : Border.all(
                color: cs.outlineVariant.withAlpha(80),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
        boxShadow: totem.unlocked ? ModernGriotShadows.sm : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: totem.unlocked ? 1.0 : 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  totem.icon,
                  size: 24.sp,
                  color: totem.unlocked ? cs.primary : cs.onSurfaceVariant,
                ),
                SizedBox(height: 4.h),
                Text(
                  totem.label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (totem.unlocked)
            Positioned(
              top: 6.r,
              right: 6.r,
              child: Container(
                width: 16.r,
                height: 16.r,
                decoration: const BoxDecoration(
                  color: ModernGriotColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 10.sp, color: ModernGriotColors.onSecondary),
              ),
            ),
          if (!totem.unlocked)
            Icon(Icons.lock_rounded,
                size: 14.sp, color: cs.onSurfaceVariant.withAlpha(100)),
        ],
      ),
    );
  }
}

class _CertificatePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(
            color: ModernGriotColors.primaryContainer.withAlpha(100),
            width: 2,
          ),
          boxShadow: ModernGriotShadows.md,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded,
                    size: 20.sp, color: ModernGriotColors.primaryContainer),
                SizedBox(width: 8.w),
                Text('Certificate of Achievement',
                    style: ModernGriotTypography.labelLarge(
                      color: ModernGriotColors.primary,
                    )),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ModernGriotColors.primaryContainer.withAlpha(80),
                  width: 3,
                ),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  size: 24.sp, color: ModernGriotColors.primary),
            ),
            SizedBox(height: 12.h),
            Text(
              'Yoruba Griot — Level 3',
              style: ModernGriotTypography.titleMedium(),
            ),
            SizedBox(height: 4.h),
            Text(
              'Awarded for mastering 4 totem collections',
              style: ModernGriotTypography.bodySmall(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ModernGriotColors.primary.withAlpha(15),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(
                'April 3, 2026',
                style: ModernGriotTypography.labelSmall(
                    color: ModernGriotColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathContinuesBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.forestGrowth,
        borderRadius: ModernGriotRadius.borderXl,
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded,
              size: 24.sp, color: ModernGriotColors.onSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Path Continues',
                  style: ModernGriotTypography.titleSmall(
                    color: ModernGriotColors.onSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '4 more totems to collect on your journey',
                  style: ModernGriotTypography.bodySmall(
                    color: ModernGriotColors.onSecondary.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              size: 20.sp, color: ModernGriotColors.onSecondary),
        ],
      ),
    );
  }
}
