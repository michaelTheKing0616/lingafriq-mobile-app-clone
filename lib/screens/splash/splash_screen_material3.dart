import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/app_logo.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/screens/onboarding/onboarding_screen_material3.dart';

/// Beautiful Material 3 Splash Screen with Pan-African Design
class SplashScreenMaterial3 extends ConsumerStatefulWidget {
  const SplashScreenMaterial3({super.key});

  @override
  ConsumerState<SplashScreenMaterial3> createState() => _SplashScreenMaterial3State();
}

class _SplashScreenMaterial3State extends ConsumerState<SplashScreenMaterial3> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        await ref
            .read(authProvider.notifier)
            .navigateBasedOnCondition()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                if (mounted) {
                  ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
                }
              },
            );
      } catch (e, st) {
        if (mounted) {
          ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: ResponsiveSafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AppLogo(
                  width: 0.6.sw,
                  logoOverride: Images.splash,
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    )
                    .then()
                    .shimmer(
                      duration: 1000.ms,
                      color: PanAfricanColors.secondary.withOpacity(0.3),
                    ),

                SizedBox(height: 32.h),

                // Loading Indicator
                CircularProgressIndicator(
                  color: PanAfricanColors.secondary,
                  strokeWidth: 3.w,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 400.ms)
                    .then()
                    .fadeOut(duration: 400.ms),

                SizedBox(height: 24.h),

                // Tagline
                Text(
                  'Connecting Africa Through Language',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: isDark
                        ? PanAfricanColors.textPrimaryDark
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

