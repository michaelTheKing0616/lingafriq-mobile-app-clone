import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class ModernDashboardScreen extends HookConsumerWidget {
  const ModernDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            _GreetingHeader(),
            SizedBox(height: 20.h),
            _ProgressHeroCard(),
            SizedBox(height: 24.h),
            _DailyRitualsCard(),
            SizedBox(height: 24.h),
            _ContinueLearningCard(),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(child: _VillageStatusCard()),
                SizedBox(width: 12.w),
                Expanded(child: _TribeActivityCard()),
              ],
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: ModernGriotTypography.bodyMedium()),
              SizedBox(height: 2.h),
              Text('Continue your journey',
                  style: ModernGriotTypography.headlineSmall()),
            ],
          ),
        ),
        GriotAvatar(initials: 'KA', size: 42),
      ],
    );
  }
}

class _ProgressHeroCard extends StatelessWidget {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Griot Apprentice',
                    style: ModernGriotTypography.headlineSmall(
                      color: ModernGriotColors.onPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Rank 2 · Yoruba Path',
                    style: ModernGriotTypography.bodySmall(
                      color: ModernGriotColors.onPrimary.withAlpha(180),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _BadgeIcon(Icons.auto_awesome_rounded),
                  SizedBox(width: 6.w),
                  _BadgeIcon(Icons.local_fire_department_rounded),
                  SizedBox(width: 6.w),
                  _BadgeIcon(Icons.star_rounded),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          GriotProgressBar(
            value: 0.42,
            height: 10,
            showGlowTip: true,
            backgroundColor: ModernGriotColors.onPrimary.withAlpha(40),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '420 / 1,000 XP to Pathfinder',
                style: ModernGriotTypography.bodySmall(
                  color: ModernGriotColors.onPrimary.withAlpha(200),
                ),
              ),
              Text(
                '42%',
                style: ModernGriotTypography.labelMedium(
                  color: ModernGriotColors.onPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              GriotBadgePill(
                icon: Icons.local_fire_department_rounded,
                label: '12 Day Streak',
                color: ModernGriotColors.onPrimary.withAlpha(40),
                textColor: ModernGriotColors.onPrimary,
              ),
              SizedBox(width: 8.w),
              GriotBadgePill(
                icon: Icons.bolt_rounded,
                label: '2,450 XP',
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

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.r,
      height: 34.r,
      decoration: BoxDecoration(
        color: ModernGriotColors.onPrimary.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16.sp, color: ModernGriotColors.onPrimary),
    );
  }
}

class _DailyRitualsCard extends StatelessWidget {
  static const _rituals = [
    _Ritual('Practice Vocabulary', true, Icons.translate_rounded),
    _Ritual('Listen to Lesson', false, Icons.headphones_rounded),
    _Ritual('Complete Quiz', false, Icons.quiz_rounded),
    _Ritual('Chat in Yoruba', false, Icons.chat_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = _rituals.where((r) => r.completed).length;

    return GriotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, size: 20.sp, color: cs.primary),
              SizedBox(width: 8.w),
              Text('Daily Rituals',
                  style: ModernGriotTypography.titleMedium()),
              const Spacer(),
              GriotBadgePill(
                label: '$completed / ${_rituals.length}',
                color: cs.secondaryContainer,
                textColor: cs.onSecondaryContainer,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: ModernGriotRadius.borderPill,
            child: LinearProgressIndicator(
              value: completed / _rituals.length,
              minHeight: 3.h,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.secondary),
            ),
          ),
          SizedBox(height: 14.h),
          ...List.generate(_rituals.length, (i) {
            final r = _rituals[i];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i < _rituals.length - 1 ? 10.h : 0),
              child: _RitualRow(ritual: r),
            );
          }),
        ],
      ),
    );
  }
}

class _Ritual {
  const _Ritual(this.label, this.completed, this.icon);
  final String label;
  final bool completed;
  final IconData icon;
}

class _RitualRow extends StatelessWidget {
  const _RitualRow({required this.ritual});
  final _Ritual ritual;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            color: ritual.completed
                ? ModernGriotColors.secondary
                : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            ritual.completed ? Icons.check_rounded : ritual.icon,
            size: 14.sp,
            color: ritual.completed
                ? ModernGriotColors.onSecondary
                : cs.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            ritual.label,
            style: ModernGriotTypography.bodyMedium(
              color: ritual.completed ? cs.onSurfaceVariant : cs.onSurface,
            ).copyWith(
              decoration:
                  ritual.completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (ritual.completed)
          Icon(Icons.check_circle_rounded,
              size: 18.sp, color: ModernGriotColors.secondary)
        else
          Icon(Icons.radio_button_unchecked_rounded,
              size: 18.sp, color: cs.outlineVariant),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      onTap: () => HapticFeedback.lightImpact(),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Icon(Icons.play_arrow_rounded,
                size: 28.sp, color: cs.onPrimary),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Greetings & Introductions',
                    style: ModernGriotTypography.titleMedium()),
                SizedBox(height: 4.h),
                Text('Lesson 3 of 8 · Yoruba Basics',
                    style: ModernGriotTypography.bodySmall()),
                SizedBox(height: 8.h),
                GriotProgressBar(value: 0.375, height: 6),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withAlpha(20),
                  cs.primary.withAlpha(10),
                ],
              ),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Column(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 16.sp, color: cs.primary),
                SizedBox(height: 2.h),
                Text(
                  'Continue\nJourney',
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.labelSmall(color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VillageStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      surfaceLevel: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_rounded,
                  size: 18.sp, color: ModernGriotColors.secondary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text('Village Status',
                    style: ModernGriotTypography.labelLarge(),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('24',
              style: ModernGriotTypography.headlineMedium(
                  color: cs.onSurface)),
          SizedBox(height: 2.h),
          Text('Active Learners',
              style: ModernGriotTypography.bodySmall()),
          SizedBox(height: 8.h),
          GriotBadgePill(
            label: 'Yoruba Village',
            icon: Icons.public_rounded,
            color: ModernGriotColors.secondaryContainer,
            textColor: ModernGriotColors.onSecondaryContainer,
          ),
        ],
      ),
    );
  }
}

class _TribeActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      surfaceLevel: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded,
                  size: 18.sp, color: ModernGriotColors.primaryContainer),
              SizedBox(width: 6.w),
              Expanded(
                child: Text('Tribe Activity',
                    style: ModernGriotTypography.labelLarge(),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('8',
              style: ModernGriotTypography.headlineMedium(
                  color: cs.onSurface)),
          SizedBox(height: 2.h),
          Text('Sessions Today',
              style: ModernGriotTypography.bodySmall()),
          SizedBox(height: 8.h),
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: EdgeInsets.only(right: 4.w),
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: ModernGriotColors.primaryContainer
                      .withAlpha(40 + i * 30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ['A', 'K', 'O', 'T'][i],
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
