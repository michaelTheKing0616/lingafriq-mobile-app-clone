import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/services/advanced/smart_recommendations.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/settings/settings_screen.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/gamification/level_display_widget.dart';
import 'package:lingafriq/widgets/gamification/currency_display_widget.dart';
import 'package:lingafriq/widgets/gamification/streak_display_widget.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// User Profile Screen - Based on Figma Make Design
class UserProfileScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  
  const UserProfileScreen({Key? key, this.onBack, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Profile temporarily unavailable',
      child: _buildProfile(context, ref),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final gamification = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get preferred language from user profile or smart recommendations
    final preferredLanguage = user?.nationality ?? 'yoruba';
    
    // Format member since date from gamification lastLogin or use current date as fallback
    final memberSinceDate = gamification?.lastLogin ?? DateTime.now();
    final memberSinceFormatted = DateFormat('MMMM yyyy').format(memberSinceDate);
    
    return Scaffold(
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFCE1126), // Red
                  Color(0xFFFF6B35), // Orange
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        // Always show back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: onBack ?? () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // Avatar
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: user?.avatar != null
                              ? ClipOval(
                                  child: LazyImage(
                                    imageUrl: user!.avatar!,
                                    width: 24.w,
                                    height: 24.w,
                                    placeholder: CircleAvatar(
                                      radius: 12.w,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        (user.username ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: const Color(0xFFCE1126),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 12.w,
                                  backgroundColor: Colors.white,
                            child: user?.avatar == null
                                ? Text(
                                    (user?.username ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32.sp,
                                      color: const Color(0xFFCE1126),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          user?.username ?? 'User',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        // Gamification Stats
                        Consumer(
                          builder: (context, ref, _) {
                            final gamification = ref.watch(gamificationProvider.notifier).gamification;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatItem(
                                  value: 'Lv. ${gamification.level}',
                                  label: gamification.levelTitle,
                                ),
                                SizedBox(width: 4.w),
                                _StatItem(
                                  value: '${gamification.xp}',
                                  label: 'XP',
                                ),
                                SizedBox(width: 4.w),
                                _StatItem(
                                  value: '${gamification.dailyStreak}',
                                  label: 'Day Streak',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Positioned(
            top: 38.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      boxShadow: DesignSystem.shadowLarge,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: AfricanTheme.primaryGreen,
                              size: 20,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Learning',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    preferredLanguage.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 4.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: AfricanTheme.accentGold,
                              size: 20,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Member since',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    memberSinceFormatted,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                  // Gamification Widgets
                  Consumer(
                    builder: (context, ref, _) {
                      return Column(
                        children: [
                          LevelDisplayWidget(showXP: true),
                          SizedBox(height: 2.h),
                          CurrencyDisplayWidget(compact: false, showLabels: true),
                          SizedBox(height: 2.h),
                          StreakDisplayWidget(showFreeze: true),
                        ],
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                  // Action Buttons
                  _ActionButton(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(child: const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: 2.h),
                  _ActionButton(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: onLogout ?? () async {
                      final result = await ref.read(dialogProvider('')).showPlatformDialogue(
                        title: "Logout",
                        content: const Text("Are you sure you want to logout?"),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  
  const _StatItem({required this.value, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.8),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : (isDark ? AfricanTheme.stitchCardDark : Colors.white),
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withOpacity(0.3)
                  : (isDark ? AfricanTheme.stitchBorderDark : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
                size: 20,
              ),
              SizedBox(width: 3.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? Colors.red
                      : (isDark ? Colors.white : Colors.black87),
                ),
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

