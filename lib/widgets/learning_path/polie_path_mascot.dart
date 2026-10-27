import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';

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
        child: SizedBox(width: 120, height: 140, child: child),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_moodIcon(mood), size: 48, color: cs.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              poliePathMoodWireName(mood),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
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
