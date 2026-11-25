import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// A tappable row. Quiet, so the fill is the container role.
class LingListRow extends StatelessWidget {
  const LingListRow({
    required this.label,
    required this.unavailableLabel,
    this.onPressed,
    this.forcedState,
    super.key,
  });

  final String label;
  final String unavailableLabel;
  final VoidCallback? onPressed;
  final LingForcedState? forcedState;

  @override
  Widget build(BuildContext context) {
    return LingInteraction(
      forcedState: forcedState,
      onPressed: onPressed,
      labelFor: (LingForcedState state) =>
          lingSemanticsLabel(state, label, unavailableLabel),
      builder: (BuildContext context, LingForcedState state) {
        return LingLabeledControl(
          state: state,
          label: label,
          unavailableLabel: unavailableLabel,
          role: LingFillRole.container,
          chevron: true,
          radius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiussm),
          ),
        );
      },
    );
  }
}
