import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Selectable transcript lines for one media item.
///
/// An empty list is the missing state, not a blank. That state flags the
/// clip for content review. Each line wraps, and the semantics container
/// keeps the lines readable at large text. Existing audio and video
/// screens are not wired to this widget yet.
class LingTranscriptView extends StatelessWidget {
  const LingTranscriptView({required this.lines, super.key});

  final List<String> lines;

  static const String missingTitle = 'No transcript yet.';
  static const String missingDetail = 'This clip is waiting for review.';

  /// Lines that contain words. Blank entries are not a transcript.
  List<String> get visibleLines {
    return lines
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  /// True when this clip has no transcript, so it needs content review.
  bool get flaggedForReview => visibleLines.isEmpty;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final List<Widget> children = <Widget>[];
    if (flaggedForReview) {
      children.add(_plain(missingTitle, lingBody(palette.onSurface)));
      children.add(const SizedBox(height: LingAfriqTokens.spacing16));
      children.add(_plain(missingDetail, lingBody(palette.onSurfaceVariant)));
    } else {
      for (var index = 0; index < visibleLines.length; index++) {
        if (index > 0) {
          children.add(const SizedBox(height: LingAfriqTokens.spacing16));
        }
        children.add(
          _selectable(visibleLines[index], lingBody(palette.onSurface)),
        );
      }
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _plain(String text, TextStyle style) {
    return Text(
      text,
      style: style,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _selectable(String text, TextStyle style) {
    return SelectableText(
      text,
      style: style,
      textWidthBasis: TextWidthBasis.parent,
      semanticsLabel: text,
    );
  }
}
