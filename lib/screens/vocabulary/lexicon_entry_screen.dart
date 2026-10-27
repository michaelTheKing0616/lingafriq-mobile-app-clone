import 'package:flutter/material.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

/// copy_keys: entry.proverbs, entry.culture (P7-924).
const String kLexiconEntryProverbsTitle = 'Proverbs';
const String kLexiconEntryCultureTitle = 'Culture notes';
const String kLexiconEntrySameIdeaTitle = 'Same idea in other languages';
const String kLexiconEntryLoadError = 'Could not load this lexicon entry.';
const String kLexiconEntrySameIdeaUnavailable =
    'Not yet available in this language';

class LexiconProverbLine {
  const LexiconProverbLine({required this.text, this.gloss});

  final String text;
  final String? gloss;
}

class LexiconSameIdeaRow {
  const LexiconSameIdeaRow({
    required this.languageCode,
    required this.languageLabel,
    required this.lemma,
    this.lexemeId,
    this.verified = true,
  });

  final String languageCode;
  final String languageLabel;
  final String lemma;
  final String? lexemeId;
  final bool verified;
}

@visibleForTesting
List<LexiconProverbLine> parseLexiconProverbs(Map<String, dynamic> entry) {
  final raw = entry['proverbs'] ?? entry['related_proverbs'];
  if (raw == null) return const [];
  if (raw is String) {
    final text = raw.trim();
    return text.isEmpty ? const [] : [LexiconProverbLine(text: text)];
  }
  if (raw is! List) return const [];
  final out = <LexiconProverbLine>[];
  for (final item in raw) {
    if (item is String) {
      final text = item.trim();
      if (text.isNotEmpty) out.add(LexiconProverbLine(text: text));
      continue;
    }
    if (item is! Map) continue;
    final map = item.cast<String, dynamic>();
    final text = (map['text'] ?? map['proverb'] ?? map['target'] ?? '')
        .toString()
        .trim();
    if (text.isEmpty) continue;
    final gloss = (map['gloss_en'] ?? map['meaning'] ?? map['gloss'])
        ?.toString()
        .trim();
    out.add(
      LexiconProverbLine(
        text: text,
        gloss: gloss != null && gloss.isNotEmpty ? gloss : null,
      ),
    );
  }
  return out;
}

@visibleForTesting
List<String> parseLexiconCultureNotes(Map<String, dynamic> entry) {
  final raw = entry['culture_notes'] ??
      entry['cultural_notes'] ??
      entry['culture_note'];
  if (raw == null) return const [];
  if (raw is String) {
    final text = raw.trim();
    return text.isEmpty ? const [] : [text];
  }
  if (raw is List) {
    final out = <String>[];
    for (final item in raw) {
      if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) out.add(text);
      } else if (item is Map) {
        final text = (item['text'] ?? item['note'] ?? '').toString().trim();
        if (text.isNotEmpty) out.add(text);
      }
    }
    return out;
  }
  if (raw is Map) {
    final text = (raw['text'] ?? raw['note'] ?? '').toString().trim();
    return text.isEmpty ? const [] : [text];
  }
  return const [];
}

@visibleForTesting
String languageLabelForCode(String code) {
  switch (code.trim().toLowerCase()) {
    case 'yo':
      return 'Yoruba';
    case 'ig':
      return 'Igbo';
    case 'ha':
      return 'Hausa';
    case 'pcm':
      return 'Nigerian Pidgin';
    case 'sw':
      return 'Swahili';
    case 'zu':
      return 'Zulu';
    case 'xh':
      return 'Xhosa';
    default:
      return code.isEmpty ? '—' : code;
  }
}

@visibleForTesting
List<LexiconSameIdeaRow> parseSameIdeaInOtherLanguages(
  Map<String, dynamic> entry,
) {
  final raw = entry['same_idea_in_other_languages'] ?? entry['same_idea'];
  if (raw is! List) return const [];
  final out = <LexiconSameIdeaRow>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final map = item.cast<String, dynamic>();
    final lemma = (map['lemma'] ?? map['word'] ?? '').toString().trim();
    if (lemma.isEmpty) continue;
    final lang = (map['language'] ?? map['lang'] ?? '').toString().trim();
    final label = (map['language_label'] ?? map['label'] ?? '')
        .toString()
        .trim();
    final verified = map['verified'] != false && map['unavailable'] != true;
    final lexemeId = map['lexeme_id']?.toString().trim();
    out.add(
      LexiconSameIdeaRow(
        languageCode: lang,
        languageLabel:
            label.isNotEmpty ? label : languageLabelForCode(lang),
        lemma: lemma,
        lexemeId: lexemeId != null && lexemeId.isNotEmpty ? lexemeId : null,
        verified: verified,
      ),
    );
  }
  return out;
}

Future<void> openLexiconEntryScreen(
  BuildContext context, {
  required VerifiedLexeme lexeme,
  WordCardAudioPlayHandler? onPlayAudio,
  VoidCallback? onSave,
  VoidCallback? onPractise,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (ctx) => LexiconEntryScreen(
        lexeme: lexeme,
        onPlayAudio: onPlayAudio,
        onSave: onSave,
        onPractise: onPractise,
      ),
    ),
  );
}

class LexiconEntryScreen extends StatelessWidget {
  const LexiconEntryScreen({
    super.key,
    this.lexeme,
    this.isLoading = false,
    this.errorMessage,
    this.onPlayAudio,
    this.onSave,
    this.onPractise,
  });

  final VerifiedLexeme? lexeme;
  final bool isLoading;
  final String? errorMessage;
  final WordCardAudioPlayHandler? onPlayAudio;
  final VoidCallback? onSave;
  final VoidCallback? onPractise;

  String get _titleLemma {
    if (lexeme == null) return 'Lexicon entry';
    final ortho = lexeme!.standardOrthography.trim();
    if (ortho.isNotEmpty) return ortho;
    return lexeme!.lemma.trim().isNotEmpty ? lexeme!.lemma : 'Lexicon entry';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            _titleLemma,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (lexeme == null) {
      return Center(
        child: Text(
          kLexiconEntryLoadError,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }
    final model = WordCardSheetModel.fromLexeme(
      lexeme!,
      showsAiDraftBadge: wordCardSheetShowsAiDraft(lexeme: lexeme!),
    );
    final proverbs = parseLexiconProverbs(lexeme!.raw);
    final culture = parseLexiconCultureNotes(lexeme!.raw);
    final sameIdea = parseSameIdeaInOtherLanguages(lexeme!.raw);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WordCardSheet(
              model: model,
              onPlayAudio: onPlayAudio,
              onSave: onSave,
              onPractise: onPractise,
            ),
            if (proverbs.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SectionHeading(title: kLexiconEntryProverbsTitle),
              for (final proverb in proverbs)
                _ProverbTile(line: proverb),
            ],
            if (culture.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeading(title: kLexiconEntryCultureTitle),
              for (final note in culture)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
            if (sameIdea.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeading(title: kLexiconEntrySameIdeaTitle),
              _SameIdeaStrip(rows: sameIdea),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ProverbTile extends StatelessWidget {
  const _ProverbTile({required this.line});

  final LexiconProverbLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          if (line.gloss != null)
            Text(
              line.gloss!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _SameIdeaStrip extends StatelessWidget {
  const _SameIdeaStrip({required this.rows});

  final List<LexiconSameIdeaRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final row in rows)
          Semantics(
            label: row.verified
                ? '${row.languageLabel}: ${row.lemma}'
                : '${row.languageLabel}: $kLexiconEntrySameIdeaUnavailable',
            child: Chip(
              label: Text(
                row.verified
                    ? '${row.languageLabel} · ${row.lemma}'
                    : '${row.languageLabel} · $kLexiconEntrySameIdeaUnavailable',
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
