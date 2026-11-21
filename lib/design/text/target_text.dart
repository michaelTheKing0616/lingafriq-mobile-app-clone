import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/typography.dart';

/// Target-language text. Andika at 18sp, leading 1.5, with the Noto script
/// fallbacks from [LingAfriqType.target]. The line box uses that leading so
/// stacked tone marks stay inside the glyph's box at large text scale.
class TargetText extends StatelessWidget {
  const TargetText({
    required this.text,
    this.textAlign,
    this.maxLines,
    this.softWrap = true,
    this.semanticsLabel,
    super.key,
  });

  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  /// Screen-reader label. When null, the text itself is the label.
  final String? semanticsLabel;

  static const TextHeightBehavior heightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const StrutStyle strut = StrutStyle(
    fontFamily: LingAfriqType.targetFamily,
    fontFamilyFallback: LingAfriqType.scriptFallback,
    fontSize: LingAfriqType.targetSize,
    height: LingAfriqType.targetHeight,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return Text(
      text,
      style: LingAfriqType.target.copyWith(
        color: color,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: TextOverflow.visible,
      textHeightBehavior: heightBehavior,
      strutStyle: strut,
      semanticsLabel: semanticsLabel,
    );
  }
}
