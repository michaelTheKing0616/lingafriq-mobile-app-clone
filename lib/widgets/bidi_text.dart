import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// Direction of [text] from its first strong character, so a Latin or
/// Yorùbá sentence inside Arabic UI keeps its own word order and its full
/// stop at the end. Falls back to [fallback] when the text has no strong
/// character (digits, punctuation only).
TextDirection contentDirectionOf(String text, TextDirection fallback) {
  if (Bidi.startsWithRtl(text)) return TextDirection.rtl;
  if (Bidi.startsWithLtr(text)) return TextDirection.ltr;
  return fallback;
}

/// [Text] for lesson content: the run uses the content's own direction,
/// while the paragraph still aligns to the screen's start edge.
class BidiText extends StatelessWidget {
  const BidiText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ambient = Directionality.of(context);
    final dir = contentDirectionOf(data, ambient);
    final align =
        textAlign ??
        (ambient == TextDirection.rtl ? TextAlign.right : TextAlign.left);
    return Text(
      data,
      textDirection: dir,
      textAlign: align,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
