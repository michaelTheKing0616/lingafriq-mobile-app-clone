import 'package:flutter/material.dart';
import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';

/// copy_keys: sameidea.title, sameidea.unavailable (P7-927).
const String kSameIdeaTitle = 'Same idea in other languages';
const String kSameIdeaUnavailable = 'Not yet available in this language';

/// Pan-African "same idea" strip — verified concept links only (P7-927).
class SameIdeaView extends StatelessWidget {
  const SameIdeaView({
    super.key,
    required this.rows,
    this.title = kSameIdeaTitle,
    this.onLexemeTap,
  });

  final List<LexiconSameIdeaRow> rows;
  final String title;
  final void Function(LexiconSameIdeaRow row)? onLexemeTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final row in rows) _SameIdeaChip(row: row, onTap: onLexemeTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _SameIdeaChip extends StatelessWidget {
  const _SameIdeaChip({required this.row, this.onTap});

  final LexiconSameIdeaRow row;
  final void Function(LexiconSameIdeaRow row)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = row.verified
        ? '${row.languageLabel}: ${row.lemma}'
        : '${row.languageLabel}: $kSameIdeaUnavailable';
    final child = Chip(
      label: Text(
        row.verified
            ? '${row.languageLabel} · ${row.lemma}'
            : '${row.languageLabel} · $kSameIdeaUnavailable',
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
    return Semantics(
      label: label,
      button: onTap != null && row.verified && row.lexemeId != null,
      child: onTap != null && row.verified && row.lexemeId != null
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => onTap!(row),
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            )
          : child,
    );
  }
}
