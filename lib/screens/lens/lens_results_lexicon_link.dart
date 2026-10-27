import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

/// Opens verified lexicon entry from Lens result rows (P7-929 AC2).
typedef LensLexiconFetch = Future<VerifiedLexeme?> Function(String lexemeId);

const double kLensLexiconLinkMinTouch = 48;
const String kLensLexiconLinkLabel = 'Open lexicon entry';
const String kLensLexiconLinkMissing = 'Lexicon entry is not available offline.';

class LensResultsLexiconLink extends StatelessWidget {
  const LensResultsLexiconLink({
    super.key,
    required this.lexemeId,
    required this.displayWord,
    this.gloss,
    this.fetchLexeme,
  });

  final String lexemeId;
  final String displayWord;
  final String? gloss;
  final LensLexiconFetch? fetchLexeme;

  Future<void> _openLexicon(BuildContext context) async {
    HapticFeedback.selectionClick();
    final id = lexemeId.trim();
    if (id.isEmpty) {
      _showSnack(context, kLensLexiconLinkMissing);
      return;
    }
    final fetch = fetchLexeme ?? _unconfiguredFetch;
    final lexeme = await fetch(id);
    if (!context.mounted) return;
    if (lexeme == null) {
      _showSnack(context, kLensLexiconLinkMissing);
      return;
    }
    await showWordCardSheet(context, lexeme: lexeme);
  }

  static Future<VerifiedLexeme?> _unconfiguredFetch(String _) async => null;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = gloss?.trim().isNotEmpty == true ? gloss!.trim() : idLabel(lexemeId);
    return Semantics(
      button: true,
      label: '$kLensLexiconLinkLabel: $displayWord',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _openLexicon(context),
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kLensLexiconLinkMinTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayWord, style: theme.textTheme.titleSmall),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.menu_book_outlined, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
String idLabel(String lexemeId) => lexemeId.trim().isEmpty ? '—' : lexemeId;
