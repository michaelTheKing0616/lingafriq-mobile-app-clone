import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Today offline copy from the deck. The sample golden paints this.
abstract final class LingOfflineStateCopy {
  static const String whatHappened = 'The phone has no network.';
  static const String why = 'This plan is not saved on the phone.';
  static const String whatToDo = 'Connect, then try again.';
  static const String actionLabel = 'Try again';
  static const String nothingWaiting = 'Nothing is waiting to send.';
}

/// Offline anatomy. The three lines and the queue count are required.
/// Omitting any of them is a compile error. The count is a sentence.
class LingOfflineState extends StatelessWidget {
  const LingOfflineState({
    required this.whatHappened,
    required this.why,
    required this.whatToDo,
    required this.queuedActions,
    this.actionLabel,
    this.onAction,
    this.unavailableLabel = 'Unavailable',
    super.key,
  }) : assert(queuedActions >= 0, 'A queue count is zero or more.'),
       assert(
         (actionLabel == null) == (onAction == null),
         'An offline action needs a label and a callback.',
       );

  final String whatHappened;
  final String why;
  final String whatToDo;
  final int queuedActions;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String unavailableLabel;

  /// Zero is [LingOfflineStateCopy.nothingWaiting]. One names a single
  /// action. Any larger count names the actions. No percent is shown.
  static String queuedActionsLine(int count) {
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'count',
        'A queue count is zero or more.',
      );
    }
    if (count == 0) return LingOfflineStateCopy.nothingWaiting;
    final String noun = count == 1 ? 'action' : 'actions';
    return '$count $noun will send when you connect.';
  }

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
    final String waiting = queuedActionsLine(queuedActions);
    final String? label = actionLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: LingCueDisc(
              key: const ValueKey<String>('ling-offline-disc'),
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
        _line(waiting, lingBody(palette.onSurface)),
        if (label != null) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing16),
          LingButton(
            label: label,
            unavailableLabel: unavailableLabel,
            onPressed: onAction,
            role: LingButtonRole.accent,
          ),
        ],
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
