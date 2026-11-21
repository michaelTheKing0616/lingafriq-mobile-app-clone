import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Content flagged for review. The sample golden paints [waiting].
abstract final class LingUnderReviewStateCopy {
  static const String waiting = 'This clip is waiting for review.';
}

/// Shown when an item is flagged for review.
///
/// The item title stays visible. The item is not playable: this state has
/// no play control.
class LingUnderReviewState extends StatelessWidget {
  const LingUnderReviewState({required this.title, super.key});

  /// Name of the item that is waiting. A clip title is the usual value.
  final String title;

  /// A flagged item is shown and cannot be played.
  static const bool playable = false;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _line(title, lingBody(palette.onSurface)),
          const SizedBox(height: LingAfriqTokens.spacing16),
          _line(
            LingUnderReviewStateCopy.waiting,
            lingBody(palette.onSurfaceVariant),
          ),
        ],
      ),
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
