import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Today empty copy from the deck. The catalogue golden paints this.
abstract final class LingEmptyStateCopy {
  static const String title = 'No plan yet';
  static const String whatHappened = 'Today has nothing queued.';
  static const String why = 'There is no review due, and no lesson is chosen.';
  static const String whatToDo = 'Open Path and start the first lesson.';
  static const String actionLabel = 'Open Path';
}

/// Forward empty state. Title, what happened, why, what to do, and one verb.
class LingEmptyState extends StatelessWidget {
  const LingEmptyState({
    required this.title,
    required this.whatHappened,
    required this.why,
    required this.whatToDo,
    required this.actionLabel,
    required this.onAction,
    this.unavailableLabel = 'Unavailable',
    super.key,
  });

  final String title;
  final String whatHappened;
  final String why;
  final String whatToDo;
  final String actionLabel;
  final VoidCallback onAction;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _line(title, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(whatHappened, lingBody(palette.onSurfaceVariant)),
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
    return Text(
      text,
      style: style,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}
