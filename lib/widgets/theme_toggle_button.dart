import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/theme_mode_provider.dart';

/// Easy-to-find dark mode toggle button
/// Can be placed in app bar, drawer, or as a floating action button
class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final bool isFloating;
  final EdgeInsets? padding;

  const ThemeToggleButton({
    Key? key,
    this.showLabel = false,
    this.isFloating = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isFloating) {
      return FloatingActionButton(
        mini: true,
        onPressed: () => _toggleTheme(context, ref),
        backgroundColor: isDark 
            ? AfricanTheme.primaryGreen 
            : AfricanTheme.accentGold,
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: Colors.white,
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(delay: 100.ms, duration: 300.ms);
    }

    return InkWell(
      onTap: () => _toggleTheme(context, ref),
      borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
      child: Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark 
              ? AfricanTheme.primaryGreen.withOpacity(0.1)
              : AfricanTheme.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
          border: Border.all(
            color: isDark 
                ? AfricanTheme.primaryGreen.withOpacity(0.3)
                : AfricanTheme.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20.sp,
              color: isDark ? AfricanTheme.primaryGreen : AfricanTheme.accentGold,
            ),
            if (showLabel) ...[
              SizedBox(width: 8.w),
              Text(
                isDark ? 'Light Mode' : 'Dark Mode',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AfricanTheme.primaryGreen : AfricanTheme.accentGold,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(delay: 100.ms, duration: 300.ms);
  }

  Future<void> _toggleTheme(BuildContext context, WidgetRef ref) async {
    await ref.read(themeModeProvider.notifier).toggleDarkMode();
    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dark mode ${isDark ? 'enabled' : 'disabled'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

