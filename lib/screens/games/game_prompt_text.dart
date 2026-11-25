import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/lexicon_selectable_text.dart';

/// Game prompt copy with shared Word Card long-press (P7-923).
class GamePromptText extends StatelessWidget {
  const GamePromptText({
    super.key,
    required this.prompt,
    required this.languageCode,
    this.style,
    this.lookup,
    this.onSuggest,
  });

  final String prompt;
  final String languageCode;
  final TextStyle? style;
  final LexiconWordCardLookup? lookup;
  final LexiconSuggestHandler? onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LexiconSelectableText(
      text: prompt,
      languageCode: languageCode,
      style: style ?? theme.textTheme.titleMedium,
      lookup: lookup,
      onSuggest: onSuggest,
    );
  }
}
