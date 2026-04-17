import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/learning/living_dictionary_service.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';

class LivingDictionaryScreen extends ConsumerStatefulWidget {
  const LivingDictionaryScreen({super.key});

  @override
  ConsumerState<LivingDictionaryScreen> createState() => _LivingDictionaryScreenState();
}

class _LivingDictionaryScreenState extends ConsumerState<LivingDictionaryScreen> {
  final _svc = LivingDictionaryService();
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _entries = const [];
  String? _nextBefore;
  final _searchController = TextEditingController();
  String _query = '';
  /// `cache` when [LivingDictionaryService] served last successful snapshot (offline).
  String? _listDataSource;
  static const int _pageSize = 200;

  String _defaultLanguageCode() {
    final s = ref.read(onboardingProvider).selectedLanguage?.trim();
    if (s == null || s.isEmpty) return 'yo';
    return s.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_searchController.text.trim() != _query) return;
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _entries = const [];
        _nextBefore = null;
        _listDataSource = null;
      }
    });
    try {
      final result = await _svc.listEntries(
        query: _query.isEmpty ? null : _query,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _entries = result.entries;
        _loading = false;
        _nextBefore = result.nextBefore;
        _listDataSource = result.source == 'cache' ? 'cache' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndDeleteEntry(Map<String, dynamic> entry) async {
    final id = (entry['_id'] ?? entry['id']).toString();
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove entry?'),
        content: const Text(
          'This permanently removes this word from your personal dictionary on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _svc.deleteEntry(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry removed')),
      );
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final before = _nextBefore;
    if (before == null || before.isEmpty) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final result = await _svc.listEntries(
        query: _query.isEmpty ? null : _query,
        before: before,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _entries = [..._entries, ...result.entries];
        _nextBefore = result.nextBefore;
        if (result.source == 'cache') _listDataSource = 'cache';
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMore = false;
      });
    }
  }

  Future<void> _openAddEntrySheet() async {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final lemmaCtrl = TextEditingController();
    final translationCtrl = TextEditingController();
    final languageCtrl = TextEditingController(text: _defaultLanguageCode());
    var idiom = false;
    var consentStorage = true;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (modalContext, setModal) {
              Future<void> submit() async {
                final lemma = lemmaCtrl.text.trim();
                final lang = languageCtrl.text.trim();
                if (lemma.isEmpty || lang.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Language and word / phrase are required')),
                  );
                  return;
                }
                if (!consentStorage) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Confirm storage consent to save this entry')),
                  );
                  return;
                }
                setModal(() => saving = true);
                try {
                  await _svc.addEntry(
                    language: lang,
                    lemma: lemma,
                    translation: translationCtrl.text.trim().isEmpty ? null : translationCtrl.text.trim(),
                    idiom: idiom,
                    consentAcknowledged: consentStorage,
                  );
                  if (!mounted) return;
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  messenger.showSnackBar(const SnackBar(content: Text('Entry saved')));
                  await _load(reset: true);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                } finally {
                  if (modalContext.mounted) {
                    setModal(() => saving = false);
                  }
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add to living dictionary', style: ModernGriotTypography.titleSmall()),
                    const SizedBox(height: 16),
                    TextField(
                      controller: languageCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Language code',
                        hintText: 'e.g. yo, ig, ha',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lemmaCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Word or phrase',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: translationCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Translation (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mark as idiom'),
                      value: idiom,
                      onChanged: saving ? null : (v) => setModal(() => idiom = v),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Save to my personal dictionary on this device account'),
                      subtitle: const Text('Required for storage and sync with the server.'),
                      value: consentStorage,
                      onChanged: saving
                          ? null
                          : (v) => setModal(() => consentStorage = v ?? false),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: saving ? null : submit,
                      child: saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    lemmaCtrl.dispose();
    translationCtrl.dispose();
    languageCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showEmpty = !_loading && _error == null && _entries.isEmpty;
    final itemCount = showEmpty ? 3 : _entries.length + 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Living Dictionary'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _load(reset: true);
            },
          ),
        ],
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              onPressed: _openAddEntrySheet,
              tooltip: 'Add entry',
              child: const Icon(Icons.add_rounded),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Could not load entries.',
                          style: ModernGriotTypography.titleSmall(),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_listDataSource == 'cache')
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            'Offline: showing your last saved word list for this search.',
                            style: ModernGriotTypography.bodySmall(),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _load(reset: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: itemCount,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                      if (i == 0) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).colorScheme.surfaceContainerLow
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search words / phrases',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    _searchController.clear();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        );
                      }

                      if (showEmpty) {
                        if (i == 1) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No entries yet',
                                  style: ModernGriotTypography.titleSmall(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Save words you hear in media import, or add them manually with +.',
                                  style: ModernGriotTypography.bodySmall(),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      if (i == _entries.length + 1) {
                        final canLoadMore =
                            _nextBefore != null && _nextBefore!.isNotEmpty && _entries.isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: canLoadMore
                                ? OutlinedButton(
                                    onPressed: _loadingMore ? null : _loadMore,
                                    child: _loadingMore
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Load more'),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final entryIndex = i - 1;
                      final e = _entries[entryIndex];
                      final lemma = (e['lemma'] ?? '').toString();
                      final translation = (e['translation'] ?? '').toString();
                      final language = (e['language'] ?? '').toString();
                      final idiom = e['idiom'] == true;
                      final contextText = (e['context'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lemma.isEmpty ? '(untitled)' : lemma,
                                    style: ModernGriotTypography.titleSmall(),
                                  ),
                                ),
                                if (idiom)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Idiom',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  tooltip: 'Remove from dictionary',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _confirmAndDeleteEntry(e);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.public_rounded, size: 14, color: Theme.of(context).hintColor),
                                const SizedBox(width: 6),
                                Text(language, style: ModernGriotTypography.bodySmall()),
                              ],
                            ),
                            if (translation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                translation,
                                style: ModernGriotTypography.bodyMedium(),
                              ),
                            ],
                            if (contextText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                contextText,
                                style: ModernGriotTypography.bodySmall(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                          ),
                        ),
                      ),
                    ],
                  ),
    );
  }
}
