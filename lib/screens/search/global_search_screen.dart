import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';
import 'package:lingafriq/services/lexicon_search_service.dart';
import 'package:lingafriq/services/lexicon_suggest_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    super.key,
    required this.languageCode,
    this.searchService,
    this.suggestClient,
  });

  final String languageCode;
  final LexiconSearchService? searchService;
  final LexiconSuggestClient? suggestClient;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 280));

  LexiconSearchResult? _result;
  bool _loading = false;

  LexiconSearchService get _search =>
      widget.searchService ??
      LexiconSearchService(languageCode: widget.languageCode);

  LexiconSuggestClient get _suggest =>
      widget.suggestClient ?? LexiconSuggestClient();

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _result = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final outcome = await _search.search(trimmed);
    if (!mounted) return;
    setState(() {
      _result = outcome;
      _loading = false;
    });
  }

  Future<void> _openSuggestSheet(String query) async {
    final glossController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(kSearchSuggestActionLabel),
          content: TextField(
            controller: glossController,
            decoration: const InputDecoration(
              labelText: 'English meaning (optional)',
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (submitted != true || !mounted) {
      glossController.dispose();
      return;
    }
    final lang = lensProfileLanguageToLexiconCode(widget.languageCode);
    try {
      await _suggest.submitSuggestion(
        language: lang,
        lemma: query.trim(),
        glossEn: glossController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — validators will review your suggestion.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send suggestion right now.')),
        );
      }
    }
    glossController.dispose();
  }

  void _openLexicon(VerifiedLexeme lexeme) {
    openLexiconEntryScreen(context, lexeme: lexeme);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _result;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Semantics(
              label: 'Search words and lessons',
              textField: true,
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  _debouncer.run(() => _runSearch(value));
                },
                onSubmitted: _runSearch,
              ),
            ),
          ),
          if (result != null && (result.usedOfflinePack || result.offlineOnly))
            MaterialBanner(
              content: const Text(kSearchOfflineBanner),
              leading: const Icon(Icons.cloud_off_outlined),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          Expanded(child: _buildBody(context, result)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LexiconSearchResult? result) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result == null || result.query.isEmpty) {
      return const Center(child: Text('Search the living lexicon'));
    }
    if (result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No results for “${result.query}”'),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: kSearchSuggestActionLabel,
                child: FilledButton.icon(
                  onPressed: () => _openSuggestSheet(result.query),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text(kSearchSuggestActionLabel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lexicon = result.hits
        .where((h) => h.kind == GlobalSearchResultKind.lexiconWord)
        .toList();
    final lessons = result.hits
        .where((h) => h.kind == GlobalSearchResultKind.lesson)
        .toList();

    final lexiconHeader = lexicon.isNotEmpty ? 1 : 0;
    final lessonHeader = lessons.isNotEmpty ? 1 : 0;
    final itemCount = lexiconHeader + lexicon.length + lessonHeader + lessons.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        var cursor = index;
        if (lexicon.isNotEmpty) {
          if (cursor == 0) {
            return Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  kSearchWordsSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
          cursor -= 1;
          if (cursor < lexicon.length) {
            final hit = lexicon[cursor];
            return _LexiconResultTile(
              hit: hit,
              onTap: () {
                final lexeme = hit.lexeme;
                if (lexeme != null) _openLexicon(lexeme);
              },
            );
          }
          cursor -= lexicon.length;
        }
        if (lessons.isNotEmpty) {
          if (cursor == 0) {
            return Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  'Lessons',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
          cursor -= 1;
          final hit = lessons[cursor];
          return ListTile(
            minVerticalPadding: 12,
            title: Text(hit.title),
            subtitle: hit.subtitle != null ? Text(hit.subtitle!) : null,
            leading: const Icon(Icons.menu_book_outlined),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LexiconResultTile extends StatelessWidget {
  const _LexiconResultTile({required this.hit, required this.onTap});

  final GlobalSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${hit.title} lexicon word',
      child: ListTile(
        minVerticalPadding: 12,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        leading: const Icon(Icons.translate_outlined),
        title: Text(hit.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: hit.subtitle != null ? Text(hit.subtitle!) : null,
      ),
    );
  }
}
