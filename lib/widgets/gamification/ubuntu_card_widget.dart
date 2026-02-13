import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/gamification_provider.dart';
import '../../utils/pan_african_design_system.dart';

/// Ubuntu Streak card
/// -------------------
/// Explains the Ubuntu mechanic and shows how many lessons/XP the learner
/// has donated by protecting their streak when they miss a day.
class UbuntuCardWidget extends ConsumerWidget {
  const UbuntuCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final isUbuntuOn = gamification.ubuntuStreakActive;

    // For now we surface the flag; the backend keeps aggregate donation stats
    // in the gamification document (ubuntu_streak_active plus donation metrics).

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PanAfricanColors.primary.withOpacity(0.25),
            PanAfricanColors.secondary.withOpacity(0.15),
          ],
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.xs),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.xxs),
                Text(
                  'Ubuntu Streak',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: PanAfricanColors.primary,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: isUbuntuOn,
                  activeColor: PanAfricanColors.primary,
                  onChanged: (value) async {
                    final notifier = ref.read(gamificationProvider.notifier);
                    if (!value) {
                      await notifier.setUbuntuStreakActive(false);
                    } else {
                      await notifier.enableUbuntuStreak();
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.xxxs),
            Text(
              isUbuntuOn
                  ? 'If you ever miss a day, your hard‑earned streak will be turned into lessons and XP for other learners instead of disappearing.'
                  : 'Turn this on to let your streak protect others: when you miss a day, your progress becomes a gift of lessons for the community.',
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xxxs),
            _buildDonationChips(context, gamification),
          ],
        ),
    );
  }

  Widget _buildDonationChips(BuildContext context, dynamic gamification) {
    // Backend tracks aggregate donation metrics on the gamification document
    // (ubuntu_donations_count, ubuntu_donated_lessons, ubuntu_donated_xp)
    // which are surfaced here via UserGamificationModel.
    final int donatedLessons = gamification.ubuntuDonatedLessons ?? 0;
    final int donatedXp = gamification.ubuntuDonatedXp ?? 0;

    return Row(
      children: [
        _StatPill(
          icon: Icons.menu_book_rounded,
          label: 'Lessons gifted',
          value: donatedLessons > 0 ? '$donatedLessons' : '—',
        ),
        SizedBox(width: 4.w),
        _StatPill(
          icon: Icons.flash_on_rounded,
          label: 'XP shared',
          value: donatedXp > 0 ? '$donatedXp' : '—',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.xs,
          vertical: PanAfricanSpacing.xxs,
        ),
        margin: EdgeInsets.only(top: PanAfricanSpacing.xs),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.scrim.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PanAfricanRadius.round),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            SizedBox(width: PanAfricanSpacing.xxxs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PanAfricanTypography.labelSmall(context).copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


