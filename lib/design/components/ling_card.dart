import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// A tappable container. The page behind it stays the ramp surface.
class LingCard extends StatelessWidget {
  const LingCard({
    required this.child,
    required this.semanticLabel,
    required this.unavailableLabel,
    this.onPressed,
    this.forcedState,
    super.key,
  });

  final Widget child;
  final String semanticLabel;
  final String unavailableLabel;
  final VoidCallback? onPressed;
  final LingForcedState? forcedState;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return LingInteraction(
      forcedState: forcedState,
      onPressed: onPressed,
      labelFor: (LingForcedState state) =>
          lingSemanticsLabel(state, semanticLabel, unavailableLabel),
      builder: (BuildContext context, LingForcedState state) {
        final bool reduced = MediaQuery.disableAnimationsOf(context);
        final LingPalette palette = LingPalette.of(brightness);
        return LingPanel(
          state: state,
          radius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiusmd),
          ),
          restingElevation: lingElevation(brightness, prominent: false),
          child: Padding(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state == LingForcedState.loading) ...[
                  LingBusyMark(
                    color: palette.onSurface,
                    reducedMotion: reduced,
                  ),
                  const SizedBox(height: LingAfriqTokens.spacing8),
                ],
                if (state == LingForcedState.disabled) ...[
                  Text(
                    unavailableLabel,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: LingAfriqTokens.spacing8),
                ],
                DefaultTextStyle(
                  style: lingBody(palette.onSurface),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
