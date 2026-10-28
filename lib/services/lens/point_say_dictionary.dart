/// Maps Point-and-Say / Lens ML Kit labels to Living Dictionary entries (P7-946).
library;

import 'package:flutter/material.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_audio_client.dart';
import 'package:lingafriq/services/lexicon_suggest_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/lens/lens_collection_service.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/point_say_audio.dart';
import 'package:lingafriq/services/lens/word_card_builder.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/utils/api_service.dart';

/// copy_keys: lens.point_say.not_in_dictionary, lens.point_say.suggest
const String lensPointSayNotInDictionary =
    'This word is not in the dictionary yet.';
const String lensPointSaySuggestLabel = 'Suggest this word for review';
const String lensPointSaySuggestionSent =
    'Thanks — your suggestion is in the review queue.';
const String lensPointSaySavedLabel = 'Saved to your Lens collection';
const String lensPointSayPlayExample = 'Play word';
const String lensPointSaySaveWord = 'Save for review';

enum PointSayDictionaryPhase {
  loading,
  entry,
  notInDictionary,
  suggestionSent,
  saved,
}

class PointSayDictionaryEntry {
  const PointSayDictionaryEntry({
    required this.card,
    required this.playbackHit,
    required this.mlKitLabel,
  });

  final LensWordCard card;
  final PointSayDictionaryHit playbackHit;
  final String mlKitLabel;
}

class PointSayDictionaryMiss {
  const PointSayDictionaryMiss({
    required this.mlKitLabel,
    this.objectSetId,
    this.lexemeId,
    required this.mappedObject,
  });

  final String mlKitLabel;
  final String? objectSetId;
  final String? lexemeId;
  final bool mappedObject;
}

typedef FetchLexiconAudioBundle = Future<LexiconAudioBundle?> Function(
  String lexemeId,
);

class PointSayDictionaryService {
  PointSayDictionaryService({
    required ObjectSetMapper mapper,
    required LexiconLabelResolver labelResolver,
    required FetchVerifiedLexeme fetchLexeme,
    WordCardBuilder? wordCardBuilder,
    FetchLexiconAudioBundle? fetchAudioBundle,
    PointSayAudio? pointSayAudio,
    LexiconSuggestClient? suggestClient,
    LensCollectionService? collectionService,
  })  : _mapper = mapper,
        _labelResolver = labelResolver,
        _fetchLexeme = fetchLexeme,
        _wordCards = wordCardBuilder ?? WordCardBuilder(),
        _fetchAudio = fetchAudioBundle ?? _noopAudio,
        _audio = pointSayAudio,
        _suggest = suggestClient ?? LexiconSuggestClient(),
        _collection = collectionService ?? LensCollectionService();

  final ObjectSetMapper _mapper;
  final LexiconLabelResolver _labelResolver;
  final FetchVerifiedLexeme _fetchLexeme;
  final WordCardBuilder _wordCards;
  final FetchLexiconAudioBundle _fetchAudio;
  final PointSayAudio? _audio;
  final LexiconSuggestClient _suggest;
  final LensCollectionService _collection;

  static Future<LexiconAudioBundle?> _noopAudio(String _) async => null;

  Future<PointSayDictionaryEntry?> resolveEntry({
    required String mlKitLabel,
    required String learnerLanguageCode,
  }) async {
    final mapping = _mapper.mapLabel(mlKitLabel);
    if (mapping.kind != LensLabelMappingKind.mapped ||
        mapping.objectSetId == null ||
        mapping.livingDictionaryLexemeId == null) {
      return null;
    }

    final label = await _labelResolver.resolveForMappedObject(
      objectSetId: mapping.objectSetId!,
      livingDictionaryLexemeId: mapping.livingDictionaryLexemeId!,
      learnerLanguageCode: learnerLanguageCode,
    );

    if (label.kind == LensLexiconLabelKind.missingLexeme) {
      return null;
    }

    final lexeme = await _fetchLexeme(mapping.livingDictionaryLexemeId!);
    if (lexeme == null) {
      return null;
    }

    final bundle = await _fetchAudio(lexeme.lexemeId);
    final card = _wordCards.build(
      label: label,
      lexeme: lexeme,
      audioBundle: bundle,
    );

    final humanUri = card.audio.kind == LensWordCardAudioKind.nativeHuman
        ? card.audio.playUri
        : null;

    return PointSayDictionaryEntry(
      card: card,
      mlKitLabel: mapping.rawMlKitLabel,
      playbackHit: PointSayDictionaryHit(
        word: card.word,
        language: card.language,
        humanAudioUrl: humanUri,
      ),
    );
  }

  PointSayDictionaryMiss describeMiss(String mlKitLabel) {
    final mapping = _mapper.mapLabel(mlKitLabel);
    return PointSayDictionaryMiss(
      mlKitLabel: mapping.rawMlKitLabel,
      objectSetId: mapping.objectSetId,
      lexemeId: mapping.livingDictionaryLexemeId,
      mappedObject: mapping.kind == LensLabelMappingKind.mapped,
    );
  }

  Future<LexiconSuggestionDto> queueLearnerSuggestion({
    required String languageCode,
    required String lemmaSubmitted,
    required String glossSubmitted,
  }) async {
    return _suggest.submitSuggestion(
      language: lensProfileLanguageToLexiconCode(languageCode),
      lemma: lemmaSubmitted,
      glossEn: glossSubmitted,
    );
  }

  Future<LensCollectionSaveResult> saveToCollection({
    required String userId,
    required LensWordCard card,
    bool attemptServerSync = true,
  }) {
    return _collection.saveWordCard(
      userId: userId,
      card: card,
      attemptServerSync: attemptServerSync,
    );
  }

  Future<PointSayPlaybackPlan?> playEntry(PointSayDictionaryEntry entry) async {
    final audio = _audio;
    if (audio == null) return null;
    return audio.resolve(entry.playbackHit);
  }
}

Future<VerifiedLexeme?> fetchVerifiedLexemeEntry(String lexemeId) async {
  final trimmed = lexemeId.trim();
  if (trimmed.isEmpty) return null;
  await ApiService.initialize();
  final path =
      '$lensVerifiedLexiconEntriesPath${Uri.encodeComponent(trimmed)}';
  try {
    final response = await ApiService.get(path);
    final status = response.statusCode ?? 0;
    if (status == 404) return null;
    if (status != 200) return null;
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return VerifiedLexeme.fromApiJson(body);
    }
    if (body is Map) {
      return VerifiedLexeme.fromApiJson(body.cast<String, dynamic>());
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Production wiring for Point-and-Say dictionary resolution (P7-946).
Future<PointSayDictionaryService> createPointSayDictionaryService({
  TranslationService? translation,
  PointSayAudio? pointSayAudio,
}) async {
  final set = await AfricanObjectSet.loadFromBundle();
  final mapper = ObjectSetMapper(set);
  final t = translation ?? TranslationService();
  final fetch = fetchVerifiedLexemeEntry;
  return PointSayDictionaryService(
    mapper: mapper,
    labelResolver: t.lensLexiconResolver(fetchLexeme: fetch),
    fetchLexeme: fetch,
    pointSayAudio: pointSayAudio,
  );
}

/// Bottom-sheet body for a mapped Point-and-Say label (P7-946).
class PointSayDictionarySheet extends StatefulWidget {
  const PointSayDictionarySheet({
    super.key,
    required this.service,
    required this.mlKitLabel,
    required this.learnerLanguageCode,
    required this.userId,
    this.onSaved,
  });

  final PointSayDictionaryService service;
  final String mlKitLabel;
  final String learnerLanguageCode;
  final String userId;
  final VoidCallback? onSaved;

  @override
  State<PointSayDictionarySheet> createState() => _PointSayDictionarySheetState();
}

class _PointSayDictionarySheetState extends State<PointSayDictionarySheet> {
  PointSayDictionaryPhase _phase = PointSayDictionaryPhase.loading;
  PointSayDictionaryEntry? _entry;
  PointSayDictionaryMiss? _miss;
  final _lemmaController = TextEditingController();
  final _glossController = TextEditingController();
  String? _playStatus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _glossController.text = widget.mlKitLabel;
    _load();
  }

  @override
  void dispose() {
    _lemmaController.dispose();
    _glossController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entry = await widget.service.resolveEntry(
      mlKitLabel: widget.mlKitLabel,
      learnerLanguageCode: widget.learnerLanguageCode,
    );
    if (!mounted) return;
    if (entry != null) {
      setState(() {
        _entry = entry;
        _phase = PointSayDictionaryPhase.entry;
      });
      return;
    }
    setState(() {
      _miss = widget.service.describeMiss(widget.mlKitLabel);
      _phase = PointSayDictionaryPhase.notInDictionary;
    });
  }

  Future<void> _play() async {
    final entry = _entry;
    if (entry == null) return;
    setState(() => _playStatus = null);
    final plan = await widget.service.playEntry(entry);
    if (!mounted) return;
    setState(() {
      _playStatus = plan?.kind.name;
    });
  }

  Future<void> _save() async {
    final entry = _entry;
    if (entry == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.saveToCollection(
        userId: widget.userId,
        card: entry.card,
      );
      if (!mounted) return;
      setState(() => _phase = PointSayDictionaryPhase.saved);
      widget.onSaved?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitSuggestion() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.queueLearnerSuggestion(
        languageCode: widget.learnerLanguageCode,
        lemmaSubmitted: _lemmaController.text,
        glossSubmitted: _glossController.text,
      );
      if (!mounted) return;
      setState(() => _phase = PointSayDictionaryPhase.suggestionSent);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + padding.bottom),
      child: switch (_phase) {
        PointSayDictionaryPhase.loading => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        PointSayDictionaryPhase.entry => _buildEntry(theme),
        PointSayDictionaryPhase.notInDictionary => _buildMiss(theme),
        PointSayDictionaryPhase.suggestionSent => Text(
            lensPointSaySuggestionSent,
            style: theme.textTheme.bodyLarge,
          ),
        PointSayDictionaryPhase.saved => Text(
            lensPointSaySavedLabel,
            style: theme.textTheme.bodyLarge,
          ),
      },
    );
  }

  Widget _buildEntry(ThemeData theme) {
    final entry = _entry!;
    final example = entry.card.exampleSentence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.card.word,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (example != null && example.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(example, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: lensPointSayPlayExample,
          child: FilledButton.tonal(
            onPressed: _play,
            child: const Text(lensPointSayPlayExample),
          ),
        ),
        if (_playStatus != null) ...[
          const SizedBox(height: 8),
          Text(_playStatus!, style: theme.textTheme.labelSmall),
        ],
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: lensPointSaySaveWord,
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text(lensPointSaySaveWord),
          ),
        ),
      ],
    );
  }

  Widget _buildMiss(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: lensPointSayNotInDictionary,
          child: Text(
            lensPointSayNotInDictionary,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lemmaController,
          decoration: const InputDecoration(
            labelText: 'Word in your language',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _glossController,
          decoration: const InputDecoration(
            labelText: 'What you pointed at (English)',
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: lensPointSaySuggestLabel,
          child: FilledButton(
            onPressed: _busy ? null : _submitSuggestion,
            child: const Text(lensPointSaySuggestLabel),
          ),
        ),
      ],
    );
  }
}
