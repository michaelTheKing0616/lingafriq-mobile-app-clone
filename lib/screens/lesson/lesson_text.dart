import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/lexicon_selectable_text.dart';

/// Lesson body copy with shared Word Card long-press (P7-923).
class LessonText extends StatelessWidget {
  const LessonText({
    super.key,
    required this.text,
    required this.languageCode,
    this.style,
    this.textAlign,
    this.lookup,
    this.onSuggest,
  });

  final String text;
  final String languageCode;
  final TextStyle? style;
  final TextAlign? textAlign;
  final LexiconWordCardLookup? lookup;
  final LexiconSuggestHandler? onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LexiconSelectableText(
      text: text,
      languageCode: languageCode,
      style: style ?? theme.textTheme.bodyLarge,
      textAlign: textAlign,
      lookup: lookup,
      onSuggest: onSuggest,
    );
  }
}
