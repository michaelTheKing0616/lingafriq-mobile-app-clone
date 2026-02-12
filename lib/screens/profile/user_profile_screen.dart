import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/screens/settings/settings_screen.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/gamification/level_display_widget.dart';
import 'package:lingafriq/widgets/gamification/currency_display_widget.dart';
import 'package:lingafriq/widgets/gamification/streak_display_widget.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// User Profile Screen - Pan-African Design System
class UserProfileScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  const UserProfileScreen({Key? key, this.onBack, this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage:
          'Unable to load profile. Please check your connection and try again.',
      child: _buildProfile(context, ref),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final gamificationNotifier = ref.read(gamificationProvider.notifier);
    final gamification = gamificationNotifier.gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Get preferred language from user profile
    final preferredLanguage = user?.nationality ?? 'yoruba';

    // Format member since date from gamification lastLogin
    final memberSinceDate = gamification.lastLogin ?? DateTime.now();
    final memberSinceFormatted = DateFormat('MMMM yyyy').format(memberSinceDate);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.sunset,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PanAfricanRadius.xl),
                bottomRight: Radius.circular(PanAfricanRadius.xl),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(PanAfricanRadius.xl),
                      bottomRight: Radius.circular(PanAfricanRadius.xl),
                    ),
                    child: CustomPaint(
                      painter: _PatternPainter(
                        color: colorScheme.onPrimary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Column(
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: _HeaderIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              (onBack ?? () => Navigator.pop(context))();
                            },
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),

                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.onPrimary,
                              width: 4,
                            ),
                            boxShadow: PanAfricanShadows.lg,
                          ),
                          child: user?.avatar != null
                              ? ClipOval(
                                  child: LazyImage(
                                    imageUrl: user!.avatarUrl,
                                    width: 100.w,
                                    height: 100.w,
                                    placeholder: _AvatarPlaceholder(
                                      initial: (user.username ?? 'U')[0]
                                          .toUpperCase(),
                                    ),
                                  ),
                                )
                              : _AvatarPlaceholder(
                                  initial: (user?.username ?? 'U')[0]
                                      .toUpperCase(),
                                ),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),

                        // Username
                        Text(
                          user?.username ?? 'User',
                          style: PanAfricanTypography.headlineSmall(context)
                              .copyWith(color: colorScheme.onPrimary),
                        ),
                        SizedBox(height: PanAfricanSpacing.xxs),

                        // Email
                        Text(
                          user?.email ?? '',
                          style: PanAfricanTypography.bodyMedium(context)
                              .copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.9)),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Stats Row
                        Consumer(
                          builder: (context, ref, _) {
                            final gamification =
                                ref.watch(gamificationProvider.notifier).gamification;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _HeaderStatItem(
                                  value: 'Lv. ${gamification.level}',
                                  label: gamification.levelTitle,
                                ),
                                SizedBox(width: PanAfricanSpacing.lg),
                                _HeaderStatItem(
                                  value: '${gamification.xp}',
                                  label: 'XP',
                                ),
                                SizedBox(width: PanAfricanSpacing.lg),
                                _HeaderStatItem(
                                  value: '${gamification.dailyStreak}',
                                  label: 'Day Streak',
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  SizedBox(height: PanAfricanSpacing.sm),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? PanAfricanColors.cardDark
                          : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      boxShadow: PanAfricanShadows.sm,
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.language_rounded,
                          iconColor: PanAfricanColors.primary,
                          label: 'Learning',
                          value: preferredLanguage.toUpperCase(),
                          isDark: isDark,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: PanAfricanSpacing.md,
                          ),
                          child: Divider(
                            height: 1,
                            color: isDark
                                ? PanAfricanColors.borderDark
                                : PanAfricanColors.borderLight,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: PanAfricanColors.secondary,
                          label: 'Member since',
                          value: memberSinceFormatted,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Gamification Widgets
                  Consumer(
                    builder: (context, ref, _) {
                      return Column(
                        children: [
                          LevelDisplayWidget(showXP: true),
                          SizedBox(height: PanAfricanSpacing.md),
                          CurrencyDisplayWidget(compact: false, showLabels: true),
                          SizedBox(height: PanAfricanSpacing.md),
                          StreakDisplayWidget(showFreeze: true),
                        ],
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Action Buttons
                  _ActionButton(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        SmoothPageRoute(child: const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  _ActionButton(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: onLogout ??
                        () async {
                          HapticFeedback.mediumImpact();
                          final result = await ref
                              .read(dialogProvider(''))
                              .showPlatformDialogue(
                                title: "Logout",
                                content: const Text(
                                    "Are you sure you want to logout?"),
                                action1OnTap: true,
                                action2OnTap: false,
                                action1Text: "Logout",
                                action2Text: "Cancel",
                              );
                          if (result == true) {
                            await ref.read(authProvider.notifier).signOut();
                          }
                        },
                    isDark: isDark,
                    isDestructive: true,
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.onPrimary.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Icon(icon, color: colorScheme.onPrimary, size: 24.sp),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String initial;

  const _AvatarPlaceholder({required this.initial});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 50.w,
      backgroundColor: colorScheme.surface,
      child: Text(
        initial,
        style: PanAfricanTypography.headlineLarge(context).copyWith(
          color: PanAfricanColors.tertiary,
        ),
      ),
    );
  }
}

class _HeaderStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderStatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: PanAfricanTypography.titleLarge(context)
              .copyWith(color: colorScheme.onPrimary),
        ),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context)
              .copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24.sp,
          ),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: PanAfricanTypography.bodySmall(context),
              ),
              Text(
                value,
                style: PanAfricanTypography.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDestructive
          ? PanAfricanColors.error.withOpacity(0.1)
          : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            border: Border.all(
              color: isDestructive
                  ? PanAfricanColors.error.withOpacity(0.3)
                  : (isDark
                      ? PanAfricanColors.borderDark
                      : PanAfricanColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.sm),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? PanAfricanColors.error.withOpacity(0.1)
                      : PanAfricanColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? PanAfricanColors.error
                      : PanAfricanColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Text(
                label,
                style: PanAfricanTypography.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? PanAfricanColors.error : null,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive
                    ? PanAfricanColors.error
                    : PanAfricanColors.neutralMedium,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 35.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
