import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/pan_african_design_system.dart';
import 'combo_tracker.dart';

/// Visual combo indicator with fire particles (combo >= 4) and screen flash on multiplier change
class ComboDisplayWidget extends StatefulWidget {
  final ComboTracker comboTracker;

  const ComboDisplayWidget({
    super.key,
    required this.comboTracker,
  });

  @override
  State<ComboDisplayWidget> createState() => _ComboDisplayWidgetState();
}

class _ComboDisplayWidgetState extends State<ComboDisplayWidget> {
  double _previousMultiplier = 1.0;
  bool _showFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _previousMultiplier = widget.comboTracker.currentMultiplier;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _checkMultiplierFlash(double multiplier) {
    if (multiplier != _previousMultiplier && multiplier > 1.0) {
      _previousMultiplier = multiplier;
      _flashTimer?.cancel();
      setState(() => _showFlash = true);
      _flashTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _showFlash = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.comboTracker,
      builder: (context, _) {
        final combo = widget.comboTracker.consecutiveCorrect;
        final multiplier = widget.comboTracker.currentMultiplier;
        final hasCombo = widget.comboTracker.hasCombo;

        _checkMultiplierFlash(multiplier);

        if (!hasCombo) {
          return const SizedBox.shrink();
        }

        final showParticles = combo >= 4;
        const int particleCount = 8;
        const double particleSize = 6.0;

        final badgeContent = AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PanAfricanColors.secondary,
              PanAfricanColors.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: PanAfricanColors.secondary.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire emoji icon
            Text(
              '🔥',
              style: TextStyle(fontSize: 20.sp),
            )
                .animate(key: ValueKey(combo))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.3, 1.3),
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.3, 1.3),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                ),
            SizedBox(width: 6.w),
            // Combo count
            Text(
              '$combo',
              style: PanAfricanTypography.titleMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate(key: ValueKey(combo))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                ),
            SizedBox(width: 8.w),
            // Multiplier badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${multiplier.toStringAsFixed(multiplier == 1.0 ? 0 : 1)}x',
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                .animate(key: ValueKey(multiplier))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 300.ms,
                  curve: Curves.elasticOut,
                )
                .shimmer(
                  delay: 100.ms,
                  duration: 500.ms,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                ),
          ],
        ),
        );

        final animatedBadge = badgeContent
            .animate(key: ValueKey(hasCombo))
            .fadeIn(duration: 200.ms)
            .slideY(
              begin: -0.2,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_showFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: PanAfricanColors.secondary.withOpacity(0.15),
                  )
                      .animate(key: const ValueKey('flash'))
                      .fadeIn(duration: 50.ms)
                      .then()
                      .fadeOut(duration: 130.ms),
                ),
              ),
            Positioned(
              top: 16.h,
              right: 16.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showParticles)
                    ...List.generate(particleCount, (i) {
                      final dx = 12.0 * (i % 2 == 0 ? 1 : -1) * (i ~/ 2);
                      return Positioned(
                        left: 24.w + dx,
                        bottom: -4.h - (i % 2) * 8,
                        child: Container(
                          width: particleSize + (i % 3),
                          height: particleSize + (i % 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              const Color(0xFFFF6B35),
                              const Color(0xFFFCD116),
                              (i % 3) / 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                            .animate(
                              key: ValueKey('particle_${combo}_$i'),
                              delay: Duration(milliseconds: i * 25),
                            )
                            .fadeIn(duration: 80.ms)
                            .slideY(begin: 0.0, end: -1.2, curve: Curves.easeOut)
                            .fadeOut(duration: 200.ms, curve: Curves.easeIn),
                      );
                    }),
                  animatedBadge,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Riverpod provider for combo tracker
final comboTrackerProvider = Provider.autoDispose<ComboTracker>((ref) {
  final tracker = ComboTracker();
  ref.onDispose(() => tracker.dispose());
  return tracker;
});
