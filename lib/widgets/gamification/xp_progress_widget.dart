import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/design_system.dart';
import '../../utils/utils.dart';

/// Material 3 compliant XP progress widget
/// Shows current XP, level, and progress to next level
class XPProgressWidget extends ConsumerWidget {
  final bool showTitle;
  final bool compact;
  final Color? progressColor;
  final Color? backgroundColor;

  const XPProgressWidget({
    Key? key,
    this.showTitle = true,
    this.compact = false,
    this.progressColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final isDark = context.isDarkMode;
    
    final currentXP = gamification.xp;
    final currentLevel = gamification.level;
    final levelTitle = gamification.levelTitle;
    
    // Calculate XP for current and next level
    final xpForCurrentLevel = _getXPForLevel(currentLevel);
    final xpForNextLevel = _getXPForLevel(currentLevel + 1);
    final xpInCurrentLevel = currentXP - xpForCurrentLevel;
    final xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel;
    final progress = xpNeededForNextLevel > 0 
        ? (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    final effectiveProgressColor = progressColor ?? 
        (isDark ? AppColors.accentGold : AppColors.primaryGreen);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    if (compact) {
      return _buildCompact(context, currentLevel, levelTitle, progress, 
          effectiveProgressColor, effectiveBackgroundColor, isDark);
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $currentLevel',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: effectiveProgressColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                  ),
                  child: Text(
                    '$currentXP XP',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: effectiveProgressColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            if (levelTitle.isNotEmpty)
              Text(
                levelTitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.adaptive54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 2.h),
          ],
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(effectiveProgressColor),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${xpInCurrentLevel.toStringAsFixed(0)} / $xpNeededForNextLevel XP',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.adaptive54,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% to Level ${currentLevel + 1}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.adaptive54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    int level,
    String levelTitle,
    double progress,
    Color progressColor,
    Color backgroundColor,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: progressColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level $level',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                  ),
                ),
                SizedBox(height: 0.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.h,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getXPForLevel(int level) {
    // Non-linear XP curve: level^2 * 100
    return (level * level * 100).round();
  }
}

/// XP gain animation widget
/// Shows animated XP gain when user earns XP
class XPGainAnimation extends StatefulWidget {
  final int xpGained;
  final VoidCallback? onComplete;

  const XPGainAnimation({
    Key? key,
    required this.xpGained,
    this.onComplete,
  }) : super(key: key);

  @override
  State<XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<XPGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.5),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
              boxShadow: DesignSystem.shadowLarge,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  '+${widget.xpGained} XP',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

