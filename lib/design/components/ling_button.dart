import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Primary action. [LingButtonRole.accent] is the one filled accent meaning.
/// [LingButtonRole.quiet] uses the container role.
class LingButton extends StatelessWidget {
  const LingButton({
    required this.label,
    required this.unavailableLabel,
    this.onPressed,
    this.forcedState,
    this.role = LingButtonRole.accent,
    super.key,
  });

  final String label;
  final String unavailableLabel;
  final VoidCallback? onPressed;
  final LingForcedState? forcedState;
  final LingButtonRole role;

  @override
  Widget build(BuildContext context) {
    final LingFillRole fill = role == LingButtonRole.accent
        ? LingFillRole.accent
        : LingFillRole.container;
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
          role: fill,
          radius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiussm),
          ),
        );
      },
    );
  }
}

enum LingButtonRole { accent, quiet }
