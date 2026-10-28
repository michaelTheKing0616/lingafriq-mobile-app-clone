import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/screens/vocabulary/flashcard_review_screen.dart';
import 'package:lingafriq/screens/vocabulary/my_words_screen.dart';
import 'package:lingafriq/models/offline/local_vocabulary.dart';
import 'package:lingafriq/services/offline/vocabulary_store.dart';

/// copy_key: learn.words (P7-929).
const String kLearnWordsCopyKey = 'learn.words';
const String kLearnWordsTitle = 'Words';
const String kLearnWordsMyWordsLabel = 'My Words';
const String kLearnWordsReviewLabel = 'Review';
const String kLearnWordsReviewEmpty =
    'No words are due for review yet. Save words from lessons or Lens first.';

const double kLearnWordsMinTouch = 48;

/// Test hook: due-word count without opening [VocabularyStore].
typedef WordsDueCountResolver = int Function(String languageCode);

/// Learn → Words hub: My Words and SRS review entry points (P7-929 AC1).
class WordsTab extends ConsumerStatefulWidget {
  const WordsTab({
    super.key,
    this.languageCode = 'yo',
    this.vocabularyStore,
    this.dueWordsCount,
    this.dueWordsForReview,
    this.onMyWordsTap,
    this.onReviewTap,
  });

  final String languageCode;
  final VocabularyStore? vocabularyStore;
  final WordsDueCountResolver? dueWordsCount;
  final List<LocalVocabulary> Function(String languageCode)? dueWordsForReview;
  final VoidCallback? onMyWordsTap;
  final VoidCallback? onReviewTap;

  @override
  ConsumerState<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends ConsumerState<WordsTab> {
  late final VocabularyStore _store;
  int _dueCount = 0;

  @override
  void initState() {
    super.initState();
    _store = widget.vocabularyStore ?? VocabularyStore();
    _refreshDueCount();
  }

  void _refreshDueCount() {
    final count = widget.dueWordsCount?.call(widget.languageCode) ??
        _store.getWordsDueForReview(widget.languageCode).length;
    setState(() => _dueCount = count);
  }

  List<LocalVocabulary> _dueWords() {
    if (widget.dueWordsForReview != null) {
      return widget.dueWordsForReview!(widget.languageCode);
    }
    return _store.getWordsDueForReview(widget.languageCode);
  }

  void _openMyWords() {
    HapticFeedback.selectionClick();
    if (widget.onMyWordsTap != null) {
      widget.onMyWordsTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MyWordsScreen(),
      ),
    );
  }

  void _openReview() {
    HapticFeedback.selectionClick();
    if (widget.onReviewTap != null) {
      widget.onReviewTap!();
      return;
    }
    final due = _dueWords();
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(kLearnWordsReviewEmpty)),
      );
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => FlashcardReviewScreen(
              words: due,
              language: widget.languageCode,
            ),
          ),
        )
        .then((_) => _refreshDueCount());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: '$kLearnWordsCopyKey: $kLearnWordsTitle',
          child: const Text(kLearnWordsTitle),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WordsEntryTile(
            key: const Key('learn_words_my_words'),
            icon: Icons.bookmark_outline,
            title: kLearnWordsMyWordsLabel,
            subtitle: 'Personal word list with verified links when available',
            onTap: _openMyWords,
          ),
          const SizedBox(height: 12),
          _WordsEntryTile(
            key: const Key('learn_words_review'),
            icon: Icons.style_outlined,
            title: kLearnWordsReviewLabel,
            subtitle: _dueCount > 0
                ? '$_dueCount due for spaced repetition'
                : 'Spaced repetition when words are due',
            onTap: _openReview,
          ),
          if (_dueCount == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                kLearnWordsReviewEmpty,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _WordsEntryTile extends StatelessWidget {
  const _WordsEntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kLearnWordsMinTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
