import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/models/offline/local_vocabulary.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/learning/living_dictionary_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/offline/vocabulary_store.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';

/// Where a target-language word was pressed.
enum WordCardHost { lesson, chat, game, persona, dictionary }

/// The word a long-press asked about. The service does not fill gaps.
class WordCardQuery {
  const WordCardQuery({
    required this.word,
    required this.host,
    this.languageCode,
    this.dialect,
  });

  final String word;
  final WordCardHost host;
  final String? languageCode;
  final String? dialect;
}

/// Dialect audio the card may play. Synthetic speech is never a clip.
class WordCardAudio {
  const WordCardAudio._({
    required this.uri,
    required this.dialect,
    required this.synthetic,
    required this.playable,
  });

  const WordCardAudio.missing({this.dialect})
    : uri = null,
      synthetic = false,
      playable = false;

  /// A synthetic clip is dropped. There is no uri to play.
  const WordCardAudio.synthetic({this.dialect})
    : uri = null,
      synthetic = true,
      playable = false;

  factory WordCardAudio.playable({required String uri, String? dialect}) {
    final String trimmed = uri.trim();
    if (trimmed.isEmpty) return WordCardAudio.missing(dialect: dialect);
    return WordCardAudio._(
      uri: trimmed,
      dialect: dialect,
      synthetic: false,
      playable: true,
    );
  }

  final String? uri;
  final String? dialect;
  final bool synthetic;
  final bool playable;
}

/// Contour from the lexicon entry. An unchecked word stays unverified.
class WordCardTone {
  const WordCardTone.checked({
    required this.contours,
    required this.validatedAudio,
  }) : unverified = false;

  const WordCardTone.unverified()
    : contours = const <ToneContourKind>[],
      validatedAudio = false,
      unverified = true;

  final List<ToneContourKind> contours;
  final bool validatedAudio;
  final bool unverified;
}

/// What the card may show. [meaning] is null when the lexicon has no gloss.
class WordCardRecord {
  const WordCardRecord({
    required this.word,
    required this.host,
    required this.meaning,
    required this.audio,
    required this.tone,
    this.languageCode,
    this.lexemeId,
  });

  factory WordCardRecord.unavailable(WordCardQuery query) {
    return WordCardRecord(
      word: query.word,
      host: query.host,
      meaning: null,
      audio: WordCardAudio.missing(dialect: query.dialect),
      tone: const WordCardTone.unverified(),
      languageCode: query.languageCode,
    );
  }

  final String word;
  final WordCardHost host;
  final String? meaning;
  final WordCardAudio audio;
  final WordCardTone tone;
  final String? languageCode;
  final String? lexemeId;

  bool get hasMeaning {
    final String text = meaning?.trim() ?? '';
    return text.isNotEmpty;
  }
}

/// Saved only when both stores accepted the word. Anything else is a failure.
class WordCardSaveResult {
  const WordCardSaveResult.saved()
    : saved = true,
      inMyWords = true,
      inReview = true;

  const WordCardSaveResult.failed()
    : saved = false,
      inMyWords = false,
      inReview = false;

  final bool saved;
  final bool inMyWords;
  final bool inReview;
}

typedef WordCardLookup = Future<WordCardRecord> Function(WordCardQuery query);
typedef WordCardStore = Future<void> Function(WordCardRecord record);
typedef WordCardPlayer = Future<void> Function(String uri);

/// Reads a lexicon gloss and a human dialect clip, then stores a saved word.
///
/// A missing gloss stays missing. A synthetic clip is not returned as audio.
/// [save] adds the word to My Words and Review only when both writes finish.
class WordCardService {
  WordCardService({
    this.lookup,
    this.saveMyWords,
    this.saveReview,
    this.removeReview,
    this.playUri,
    this.lexicon,
    this.dictionary,
    this.vocabulary,
  });

  final WordCardLookup? lookup;
  final WordCardStore? saveMyWords;
  final WordCardStore? saveReview;
  final WordCardStore? removeReview;
  final WordCardPlayer? playUri;
  final LexiconLookupService? lexicon;
  final LivingDictionaryService? dictionary;
  final VocabularyStore? vocabulary;

  final List<WordCardRecord> _myWords = <WordCardRecord>[];
  final List<WordCardRecord> _review = <WordCardRecord>[];

  /// Words both stores accepted. A failed save does not add to either list.
  List<WordCardRecord> get myWords =>
      List<WordCardRecord>.unmodifiable(_myWords);

  /// Review queue entries both stores accepted.
  List<WordCardRecord> get review => List<WordCardRecord>.unmodifiable(_review);

  Future<WordCardRecord> open(WordCardQuery query) async {
    final WordCardLookup? customLookup = lookup;
    if (customLookup != null) return customLookup(query);
    final String word = query.word.trim();
    final String language = query.languageCode?.trim() ?? '';
    if (word.isEmpty || language.isEmpty) {
      return WordCardRecord.unavailable(query);
    }
    try {
      final LexiconLookupService source =
          lexicon ?? LexiconLookupService(languageCode: language);
      final LexiconLookupResult result = await source.lookupSurface(word);
      if (result.kind != LexiconLookupKind.hit || result.lexeme == null) {
        return WordCardRecord.unavailable(query);
      }
      return wordCardFromLexeme(query, result.lexeme);
    } on Object {
      return WordCardRecord.unavailable(query);
    }
  }

  /// Plays [audio] only when it is a real dialect clip. Returns false when
  /// the clip is missing, synthetic, or no player is configured. It does not
  /// call a speech synthesizer.
  Future<bool> play(WordCardAudio audio) async {
    if (!audio.playable || audio.synthetic) return false;
    final String uri = audio.uri?.trim() ?? '';
    if (uri.isEmpty) return false;
    final WordCardPlayer? player = playUri;
    if (player == null) return false;
    try {
      await player(uri);
      return true;
    } on Object {
      return false;
    }
  }

  Future<WordCardSaveResult> save(WordCardRecord record) async {
    if (!_canStore(record)) return const WordCardSaveResult.failed();
    var reviewed = false;
    try {
      await _writeReview(record);
      reviewed = true;
      await _writeMyWords(record);
    } on Object {
      if (reviewed) await _undoReview(record);
      return const WordCardSaveResult.failed();
    }
    _review.add(record);
    _myWords.add(record);
    return const WordCardSaveResult.saved();
  }

  bool _canStore(WordCardRecord record) {
    if (!record.hasMeaning) return false;
    if (record.word.trim().isEmpty) return false;
    if ((record.languageCode ?? '').trim().isEmpty) return false;
    return true;
  }

  Future<void> _writeMyWords(WordCardRecord record) {
    final WordCardStore? custom = saveMyWords;
    if (custom != null) return custom(record);
    return _defaultMyWords(record);
  }

  Future<void> _writeReview(WordCardRecord record) {
    final WordCardStore? custom = saveReview;
    if (custom != null) return custom(record);
    return _defaultReview(record);
  }

  Future<void> _undoReview(WordCardRecord record) async {
    final WordCardStore? custom = removeReview;
    if (custom != null) {
      try {
        await custom(record);
      } on Object {
        // The save already failed. A missed undo does not make it a success.
      }
      return;
    }
    if (saveReview != null) return;
    try {
      await _defaultRemoveReview(record);
    } on Object {
      // Same as a custom undo: failure stays a failure.
    }
  }

  Future<void> _defaultMyWords(WordCardRecord record) async {
    final LivingDictionaryService store =
        dictionary ?? LivingDictionaryService();
    final Map<String, dynamic> entry = await store.addEntry(
      language: record.languageCode!.trim(),
      lemma: record.word.trim(),
      translation: record.meaning!.trim(),
      context: 'word-card:${record.host.name}',
      consentAcknowledged: true,
    );
    final String id = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw StateError('My Words entry has no id');
    }
  }

  Future<void> _defaultReview(WordCardRecord record) {
    final VocabularyStore store = vocabulary ?? VocabularyStore();
    return store.addWord(
      LocalVocabulary(
        id: wordCardStorageId(record),
        word: record.word.trim(),
        translation: record.meaning!.trim(),
        language: record.languageCode!.trim(),
      ),
    );
  }

  Future<void> _defaultRemoveReview(WordCardRecord record) {
    final VocabularyStore store = vocabulary ?? VocabularyStore();
    return store.deleteVocabulary(wordCardStorageId(record));
  }
}

/// Stable local id. This is a storage key, not a gloss or a clip.
String wordCardStorageId(WordCardRecord record) {
  final String lexeme = record.lexemeId?.trim() ?? '';
  if (lexeme.isNotEmpty) return 'wordcard:$lexeme';
  final String language = (record.languageCode ?? '').trim();
  return 'wordcard:$language:${record.word.trim()}';
}

/// Maps a lexicon token onto a contour. Unknown tokens are not a contour.
ToneContourKind? toneContourFromToken(String token) {
  switch (token.trim().toLowerCase()) {
    case 'h':
    case 'high':
      return ToneContourKind.high;
    case 'm':
    case 'mid':
    case 'middle':
      return ToneContourKind.mid;
    case 'l':
    case 'low':
      return ToneContourKind.low;
    case 'r':
    case 'rising':
    case 'lh':
      return ToneContourKind.rising;
    case 'f':
    case 'falling':
    case 'hl':
      return ToneContourKind.falling;
    case 'd':
    case 'downstep':
    case 'ds':
      return ToneContourKind.downstep;
    default:
      return null;
  }
}

/// True only for a human recording kind. Empty and synthetic kinds are not.
bool wordCardKindIsHuman(String? kind) {
  final String value = (kind ?? '').trim().toLowerCase().replaceAll('-', '_');
  const Set<String> human = <String>{
    'human',
    'native',
    'native_human',
    'recording',
    'speaker',
  };
  return human.contains(value);
}

bool wordCardKindIsSynthetic(String? kind) {
  final String value = (kind ?? '').trim().toLowerCase().replaceAll('-', '_');
  if (value.isEmpty) return false;
  if (value == dynamicSpeechAudioKind) return true;
  const Set<String> blocked = <String>{
    'tts',
    'tts_synthetic',
    'licensed_tts',
    'licensedtts',
    'synthetic',
  };
  return blocked.contains(value);
}

/// Gloss from the entry. An example sentence is not used as the meaning.
String? wordCardMeaningFromEntry(Map<String, dynamic> entry) {
  final Object? senses = entry['senses'];
  if (senses is! List) return null;
  for (final Object? sense in senses) {
    if (sense is! Map) continue;
    final Map<String, dynamic> map = sense.cast<String, dynamic>();
    final String text =
        (map['gloss_en'] ?? map['gloss'])?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return null;
}

WordCardTone wordCardToneFromEntry(Map<String, dynamic> entry) {
  final Object? rawPattern = entry['tone_pattern'];
  if (rawPattern is! List || rawPattern.isEmpty) {
    return const WordCardTone.unverified();
  }
  final List<ToneContourKind> contours = <ToneContourKind>[];
  for (final Object? token in rawPattern) {
    final ToneContourKind? kind = toneContourFromToken(token.toString());
    if (kind == null) return const WordCardTone.unverified();
    contours.add(kind);
  }
  final Object? review = entry['review'];
  if (review is Map && review['tone_checked'] == false) {
    return const WordCardTone.unverified();
  }
  final String source =
      entry['tone_source']?.toString().trim().toLowerCase() ?? '';
  final bool validated =
      source == 'validated_audio' || source == 'validatedaudio';
  return WordCardTone.checked(
    contours: List<ToneContourKind>.unmodifiable(contours),
    validatedAudio: validated,
  );
}

WordCardAudio wordCardAudioFromEntry(
  Map<String, dynamic> entry, {
  String? dialect,
}) {
  final List<_Clip> clips = _clips(entry);
  final String requested = dialect?.trim() ?? '';
  if (requested.isNotEmpty) {
    final Iterable<_Clip> tagged = clips.where(
      (_Clip clip) => clip.dialect?.toLowerCase() == requested.toLowerCase(),
    );
    final Iterable<_Clip> human = tagged.where((_Clip clip) => clip.human);
    if (human.isEmpty) return WordCardAudio.missing(dialect: requested);
    final _Clip clip = human.first;
    return WordCardAudio.playable(uri: clip.uri, dialect: clip.dialect);
  }
  final Iterable<_Clip> human = clips.where((_Clip clip) => clip.human);
  if (human.isNotEmpty) {
    final _Clip clip = human.first;
    return WordCardAudio.playable(uri: clip.uri, dialect: clip.dialect);
  }
  if (clips.any((_Clip clip) => clip.synthetic)) {
    return const WordCardAudio.synthetic();
  }
  return const WordCardAudio.missing();
}

/// Builds a card from a lexicon row. A null row has no meaning and no audio.
WordCardRecord wordCardFromLexeme(WordCardQuery query, VerifiedLexeme? lexeme) {
  if (lexeme == null) return WordCardRecord.unavailable(query);
  final String? language = query.languageCode?.trim();
  return WordCardRecord(
    word: query.word,
    host: query.host,
    meaning: wordCardMeaningFromEntry(lexeme.raw),
    audio: wordCardAudioFromEntry(lexeme.raw, dialect: query.dialect),
    tone: wordCardToneFromEntry(lexeme.raw),
    languageCode: (language == null || language.isEmpty)
        ? lexeme.language
        : language,
    lexemeId: lexeme.lexemeId,
  );
}

class _Clip {
  const _Clip({
    required this.uri,
    required this.dialect,
    required this.human,
    required this.synthetic,
  });

  final String uri;
  final String? dialect;
  final bool human;
  final bool synthetic;
}

List<_Clip> _clips(Map<String, dynamic> entry) {
  final Object? audio = entry['audio'];
  if (audio is! List) return const <_Clip>[];
  final List<_Clip> out = <_Clip>[];
  for (final Object? clip in audio) {
    if (clip is! Map) continue;
    final Map<String, dynamic> map = clip.cast<String, dynamic>();
    final String uri = (map['uri'] ?? map['play_uri'] ?? '').toString().trim();
    if (uri.isEmpty) continue;
    final String? tag = _dialectTag(map);
    final String? kind = map['kind']?.toString();
    out.add(
      _Clip(
        uri: uri,
        dialect: tag,
        human: wordCardKindIsHuman(kind),
        synthetic: wordCardKindIsSynthetic(kind),
      ),
    );
  }
  return out;
}

String? _dialectTag(Map<String, dynamic> map) {
  final String tag = (map['dialect_tag'] ?? map['dialect'] ?? map['tag'] ?? '')
      .toString()
      .trim();
  if (tag.isEmpty || tag.toLowerCase() == 'standard') return null;
  return tag;
}
