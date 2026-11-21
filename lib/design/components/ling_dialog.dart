import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// A dialog panel. The panel is a container. The action is the accent button.
class LingDialog extends StatelessWidget {
  const LingDialog({
    required this.title,
    required this.actionLabel,
    required this.unavailableLabel,
    this.onAction,
    this.forcedState,
    super.key,
  });

  final String title;
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
      restingElevation: lingElevation(brightness, prominent: true),
      radius: const BorderRadius.all(Radius.circular(LingAfriqTokens.radiusmd)),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
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
