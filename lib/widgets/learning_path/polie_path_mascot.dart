import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Polie moods from polie_path.riv / PolieVM (v3).
enum PoliePathMood { idle, cheer, pointUp, sleepy }

String poliePathMoodWireName(PoliePathMood mood) {
  switch (mood) {
    case PoliePathMood.idle:
      return 'idle';
    case PoliePathMood.cheer:
      return 'cheer';
    case PoliePathMood.pointUp:
      return 'pointUp';
    case PoliePathMood.sleepy:
      return 'sleepy';
  }
}

const String kPoliePathRivAsset = 'assets/rive/path/polie_path.riv';

/// Polie on the lesson path: Rive when licensed asset exists; labelled still otherwise (P7-953 AC4).
class PoliePathMascot extends StatelessWidget {
  const PoliePathMascot({
    super.key,
    this.mood = PoliePathMood.idle,
    this.reducedMotion = false,
    this.bundleLicensed = true,
    this.rivAssetPresent = false,
    this.polieLabel = 'Polie, your learning guide',
    this.onTap,
  });

  final PoliePathMood mood;
  final bool reducedMotion;
  final bool bundleLicensed;
  /// Set true when [kPoliePathRivAsset] is in the asset bundle (F-007 copy).
  final bool rivAssetPresent;
  final String polieLabel;
  final VoidCallback? onTap;

  bool get _animateRive =>
      bundleLicensed && rivAssetPresent && !reducedMotion;

  @override
  Widget build(BuildContext context) {
    final child = _animateRive
        ? _PolieRiveHost(mood: mood, reducedMotion: reducedMotion)
        : PoliePathStillFrame(mood: mood, label: polieLabel);

    return Semantics(
      button: onTap != null,
      label: polieLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 120.w, height: 140.h, child: child),
      ),
    );
  }
}

/// Static Polie frame when Rive is absent, unlicensed, or reduced motion is on.
class PoliePathStillFrame extends StatelessWidget {
  const PoliePathStillFrame({
    super.key,
    required this.mood,
    required this.label,
  });

  final PoliePathMood mood;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label. ${poliePathMoodWireName(mood)}.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        // This frame renders inside a fixed-size box (see
        // `PoliePathMascot.build`'s `SizedBox(width: 120.w, height: 140.h)`),
        // but `label`/the mood name scale with the OS text-scale setting.
        // `maxLines`/`overflow` on the `Text`s below cap *wrapping*, not the
        // font's own height, so at large text-scale factors (e.g. 2.0x) the
        // Column's natural height still exceeds the fixed box. `FittedBox`
        // scales the whole frame contents down uniformly to fit instead of
        // overflowing, same remediation as the header's `GriotBadgePill`s.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_moodIcon(mood), size: 48.sp, color: cs.primary),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                // `FittedBox` gives its child unbounded width to measure its
                // natural size, which would otherwise render `label` as one
                // un-wrapped line instead of respecting `maxLines: 2` below.
                // Pinning a width here (matching the frame's own ~120.w
                // minus horizontal padding) keeps the intended two-line wrap
                // so `FittedBox` only has to scale down for genuine overflow
                // (e.g. large text-scale factors), not reflow the text.
                child: SizedBox(
                  width: 108.w,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              Text(
                poliePathMoodWireName(mood),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _moodIcon(PoliePathMood mood) {
    switch (mood) {
      case PoliePathMood.cheer:
        return Icons.celebration_outlined;
      case PoliePathMood.pointUp:
        return Icons.touch_app_outlined;
      case PoliePathMood.sleepy:
        return Icons.bedtime_outlined;
      case PoliePathMood.idle:
        return Icons.auto_awesome_outlined;
    }
  }
}

/// Host for v3 Rive once assets/rive/path/polie_path.riv is bundled (F-007).
class _PolieRiveHost extends StatelessWidget {
  const _PolieRiveHost({
    required this.mood,
    required this.reducedMotion,
  });

  final PoliePathMood mood;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    // Rive wiring lands with F-007 asset copy; still labelled if decode fails.
    return PoliePathStillFrame(
      mood: mood,
      label: 'Polie (animated)',
    );
  }
}
