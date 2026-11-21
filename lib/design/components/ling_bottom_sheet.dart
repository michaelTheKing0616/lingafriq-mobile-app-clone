import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// A sheet panel. The panel is a container. The action is the accent button.
class LingBottomSheet extends StatelessWidget {
  const LingBottomSheet({
    required this.label,
    required this.actionLabel,
    required this.unavailableLabel,
    this.onAction,
    this.forcedState,
    super.key,
  });

  final String label;
  final String actionLabel;
  final String unavailableLabel;
  final VoidCallback? onAction;
  final LingForcedState? forcedState;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final LingForcedState state = forcedState ?? LingForcedState.atRest;
    final LingPalette palette = LingPalette.of(brightness);
    return LingPanel(
      state: state,
      restingElevation: lingElevation(brightness, prominent: false),
      radius: const BorderRadius.vertical(
        top: Radius.circular(LingAfriqTokens.radiuslg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.onSurfaceVariant,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(LingAfriqTokens.radiuspill),
                  ),
                ),
                child: const SizedBox(
                  width: LingAfriqTokens.spacing32,
                  height: LingAfriqTokens.spacing4,
                ),
              ),
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              label,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            LingButton(
              label: actionLabel,
              unavailableLabel: unavailableLabel,
              onPressed: onAction,
              forcedState: forcedState,
            ),
          ],
        ),
      ),
    );
  }
}
