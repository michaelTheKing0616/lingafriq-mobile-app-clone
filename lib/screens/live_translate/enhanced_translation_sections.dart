import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/live_translate/enhanced_translation_parse.dart';

/// Alternatives, grammar, and cultural notes under the live caption.
class EnhancedTranslationSections extends StatelessWidget {
  const EnhancedTranslationSections({super.key, required this.view});

  final EnhancedTranslationView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final grammar = view.grammar.where(enhancedGrammarRowVisible).toList();
    final cultural = view.cultural;
    final cultureText = cultural?.context;
    final usageText = cultural?.usageNote;
    final hasCulture = (cultureText != null && cultureText.isNotEmpty) ||
        (usageText != null && usageText.isNotEmpty);
    if (view.alternatives.isEmpty && grammar.isEmpty && !hasCulture) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (view.alternatives.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final alternative in view.alternatives) ...[
            Text(alternative.translation, style: theme.textTheme.bodyLarge),
            if (alternative.context != null && alternative.context!.isNotEmpty)
              Text(alternative.context!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
          ],
        ],
        if (grammar.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.gmCatGrammar, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          for (final item in grammar) ...[
            Text(item.word, style: theme.textTheme.titleSmall),
            Text(item.partOfSpeech, style: theme.textTheme.bodySmall),
            if (item.explanation != null && item.explanation!.isNotEmpty)
              Text(item.explanation!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
          ],
        ],
        if (hasCulture) ...[
          const SizedBox(height: 8),
          Text(l10n.gmCatCultural, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          if (cultureText != null && cultureText.isNotEmpty)
            Text(cultureText, style: theme.textTheme.bodyMedium),
          if (usageText != null && usageText.isNotEmpty)
            Text(usageText, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
