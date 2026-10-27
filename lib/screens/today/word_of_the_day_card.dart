import 'package:flutter/material.dart';
import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';
import 'package:lingafriq/services/word_of_the_day_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Today-tab word-of-the-day card (P7-926). Embed on the learner Today/home surface.
class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({
    super.key,
    required this.snapshot,
    this.onOpenEntry,
    this.reduceMotion = false,
  });

  final WordOfTheDay? snapshot;
  final void Function(WordOfTheDay word)? onOpenEntry;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final word = snapshot!;
    final lemma = word.lexeme.standardOrthography.trim().isNotEmpty
        ? word.lexeme.standardOrthography.trim()
        : word.lexeme.lemma.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark
        ? PanAfricanColors.primaryLight
        : PanAfricanColors.primary;

    void openEntry() {
      if (onOpenEntry != null) {
        onOpenEntry!(word);
        return;
      }
      openLexiconEntryScreen(context, lexeme: word.lexeme);
    }

    return Semantics(
      label: '$kWotdTitle. $lemma. ${word.story}',
      button: true,
      child: Material(
        color: isDark
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        elevation: 2,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: InkWell(
          onTap: openEntry,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_outlined, color: accent),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: Text(
                          kWotdTitle,
                          style: PanAfricanTypography.titleMedium(context)
                              .copyWith(color: accent),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    lemma,
                    style: PanAfricanTypography.headlineSmall(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Text(
                    word.story,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
