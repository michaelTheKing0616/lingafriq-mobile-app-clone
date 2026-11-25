import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Play control and one caption line for a single media item.
///
/// [captionsOn] is the contract. Pass the choice in. This widget does not
/// read a live system captions channel. That channel is not available on
/// every target, and a missing channel must not blank the line.
///
/// When [captionsOn] is true and [caption] is null or blank, the missing
/// copy is shown. That copy is the review flag for this clip. Existing
/// audio and video screens are not wired to this widget yet.
class LingCaptionPlayer extends StatelessWidget {
  const LingCaptionPlayer({
    required this.title,
    required this.captionsOn,
    required this.playing,
    required this.onPressed,
    this.caption,
    super.key,
  });

  final String title;

  /// Caption for this clip. Null or blank means the caption is missing.
  final String? caption;

  /// When true, a caption or the missing state is visible. When false, the
  /// caption line is hidden and the play control stays.
  final bool captionsOn;

  final bool playing;
  final VoidCallback onPressed;

  static const String playLabel = 'Play';
  static const String pauseLabel = 'Pause';
  static const String missingTitle = 'No captions for this clip.';
  static const String missingDetail = 'It is waiting for review.';
  static const String unavailableLabel = 'Unavailable';

  bool get hasCaption {
    final String? text = caption?.trim();
    return text != null && text.isNotEmpty;
  }

  /// True when this clip has no caption text, so it needs content review.
  bool get flaggedForReview => !hasCaption;

  bool get showsCaption => captionsOn && hasCaption;

  bool get showsMissing => captionsOn && flaggedForReview;

  String get controlLabel => playing ? pauseLabel : playLabel;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String? visibleCaption = showsCaption ? caption?.trim() : null;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _line(title, lingBody(palette.onSurface)),
          if (visibleCaption != null) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing16),
            _line(visibleCaption, lingBody(palette.onSurface)),
          ],
          if (showsMissing) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing16),
            _line(missingTitle, lingBody(palette.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _line(missingDetail, lingBody(palette.onSurfaceVariant)),
          ],
          const SizedBox(height: LingAfriqTokens.spacing16),
          LingButton(
            label: controlLabel,
            unavailableLabel: unavailableLabel,
            onPressed: onPressed,
            role: LingButtonRole.accent,
          ),
        ],
      ),
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
