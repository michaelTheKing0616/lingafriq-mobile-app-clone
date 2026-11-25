import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Polie copy when the tutor cannot answer. The sample golden paints this.
///
/// The what-to-do line says Polie did not speak for the learner.
abstract final class LingAiUnavailableStateCopy {
  static const String whatHappened = 'No reply came back.';
  static const String why = 'The tutor cannot answer right now.';
  static const String whatToDo =
      'Try again later. Polie did not speak for you.';
  static const String actionLabel = 'Try again';
}

/// AI-unavailable anatomy. What happened, why, and what to do are required.
/// Omitting any of them, or the action, is a compile error.
///
/// [onAction] is the next step on this screen. It must not call the tutor
/// or the AI gateway. The painted line already says Polie did not speak.
class LingAiUnavailableState extends StatelessWidget {
  const LingAiUnavailableState({
    required this.whatHappened,
    required this.why,
    required this.whatToDo,
    required this.actionLabel,
    required this.onAction,
    this.unavailableLabel = 'Unavailable',
    super.key,
  });

  final String whatHappened;
  final String why;
  final String whatToDo;
  final String actionLabel;

  /// Non-AI next step. Callers pass a step that does not ask the tutor or
  /// the AI gateway to speak.
  final VoidCallback onAction;

  final String unavailableLabel;

  static Color infoFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? LingAfriqTokens.roleDarkInfo
        : LingAfriqTokens.roleLightInfo;
  }

  static Color infoMark(Brightness brightness) {
    return brightness == Brightness.dark
        ? LingAfriqTokens.roleDarkOnInfo
        : LingAfriqTokens.roleLightOnInfo;
  }

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final Brightness brightness = Theme.of(context).brightness;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: LingCueDisc(
              key: const ValueKey<String>('ling-ai-unavailable-disc'),
              fill: infoFill(brightness),
              mark: infoMark(brightness),
              kind: LingCueKind.info,
            ),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(whatHappened, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(why, lingBody(palette.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(whatToDo, lingBody(palette.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        LingButton(
          label: actionLabel,
          unavailableLabel: unavailableLabel,
          onPressed: onAction,
          role: LingButtonRole.accent,
        ),
      ],
    );
  }

  Widget _line(String text, TextStyle style) {
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Text(
          text,
          style: style,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
