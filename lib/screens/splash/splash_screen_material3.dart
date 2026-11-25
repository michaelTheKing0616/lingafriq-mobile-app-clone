import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/app_logo.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/screens/splash/splash_ready_gate.dart';

/// Splash that leaves when the app is ready.
///
/// [ready] is a test seam. Production waits for startup navigation, which
/// opens the unified onboarding flow when onboarding is still incomplete.
class SplashScreenMaterial3 extends ConsumerStatefulWidget {
  const SplashScreenMaterial3({super.key, this.ready});

  final Future<void>? ready;

  @override
  ConsumerState<SplashScreenMaterial3> createState() => _SplashScreenMaterial3State();
}

class _SplashScreenMaterial3State extends ConsumerState<SplashScreenMaterial3> {
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = widget.ready ?? _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      // navigateBasedOnCondition() may need to read PackageInfo,
      // SharedPreferences, and attempt auto-login (network call).
      // The previous 3-second timeout was causing onboarding and
      // auth checks to be bypassed entirely on slower devices.
      await ref.read(authProvider.notifier).navigateBasedOnCondition().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              if (mounted) {
                ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
              }
            },
          );
    } catch (_) {
      if (mounted) {
        ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashReadyGate(
      ready: _ready,
      builder: (context, showProgress) => SplashArtwork(showProgress: showProgress),
    );
  }
}

/// Pan-African splash artwork. The progress cue appears only for a slow start.
class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key, required this.showProgress});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.forest,
        ),
        child: ResponsiveSafeArea(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      color: context.panSecondary.withValues(alpha: 0.3),
                    ),
                SizedBox(height: 32.h),
                showProgress ? const SplashProgressCue() : SizedBox(width: 36.w, height: 36.w),
                SizedBox(height: 24.h),
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
      ),
    );
  }
}
