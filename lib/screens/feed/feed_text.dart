import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/lexicon_selectable_text.dart';

/// Feed / status copy with shared Word Card long-press (P7-923).
class FeedText extends StatelessWidget {
  const FeedText({
    super.key,
    required this.text,
    required this.languageCode,
    this.style,
    this.lookup,
    this.onSuggest,
  });

  final String text;
  final String languageCode;
  final TextStyle? style;
  final LexiconWordCardLookup? lookup;
  final LexiconSuggestHandler? onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LexiconSelectableText(
      text: text,
      languageCode: languageCode,
      style: style ?? theme.textTheme.bodyMedium,
      lookup: lookup,
      onSuggest: onSuggest,
    );
  }
}
