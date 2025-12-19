import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/gamification_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/design_system.dart';

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentGreen.withOpacity(0.25),
              AppColors.accentGold.withOpacity(0.15),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'Ubuntu Streak',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGreen,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: isUbuntuOn,
                  activeColor: AppColors.accentGreen,
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
            SizedBox(height: 1.h),
            Text(
              isUbuntuOn
                  ? 'If you ever miss a day, your hard‑earned streak will be turned into lessons and XP for other learners instead of disappearing.'
                  : 'Turn this on to let your streak protect others: when you miss a day, your progress becomes a gift of lessons for the community.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 1.h),
            _buildDonationChips(context, gamification),
          ],
        ),
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
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        margin: EdgeInsets.only(top: 4.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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


