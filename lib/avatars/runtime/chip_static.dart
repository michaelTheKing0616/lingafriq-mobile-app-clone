import 'package:flutter/material.dart';

import '../customisation/palette.dart';

/// Long lists use raster chips instead of live Rive artboards (EP-§4.5-06).
abstract final class ChipStaticPolicy {
  static const int longListItemThreshold = 8;

  static bool useStaticForList(int itemCount) =>
      itemCount >= longListItemThreshold;
}

/// Static chip face for list rows: brand skin tone + expression silhouette.
class StaticAvatarChip extends StatelessWidget {
  const StaticAvatarChip({
    super.key,
    required this.preset,
    required this.size,
    this.expression = 'neutral',
    this.skinToneId = 1,
  }) : assert(size == 32 || size == 48 || size == 64);

  final String preset;
  final String expression;
  final double size;
  final int skinToneId;

  @override
  Widget build(BuildContext context) {
    final safeId = skinToneId.clamp(1, AvatarSkinTone.catalog.length);
    final tone = AvatarSkinTone.byId(safeId);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$preset, $expression',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tone.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Icon(
            _expressionIcon(expression),
            size: size * 0.45,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  static IconData _expressionIcon(String expression) {
    switch (expression) {
      case 'happy':
      case 'proud':
        return Icons.sentiment_satisfied_alt_outlined;
      case 'encouraging':
        return Icons.emoji_emotions_outlined;
      case 'thinking':
        return Icons.psychology_outlined;
      case 'concerned':
        return Icons.sentiment_dissatisfied_outlined;
      default:
        return Icons.face_outlined;
    }
  }
}

/// Picks [staticChip] in long lists; otherwise builds [liveChip].
class ListAvatarChip extends StatelessWidget {
  const ListAvatarChip({
    super.key,
    required this.listItemCount,
    required this.staticChip,
    required this.liveChip,
  });

  final int listItemCount;
  final Widget staticChip;
  final Widget liveChip;

  @override
  Widget build(BuildContext context) {
    if (ChipStaticPolicy.useStaticForList(listItemCount)) {
      return staticChip;
    }
    return liveChip;
  }
}
