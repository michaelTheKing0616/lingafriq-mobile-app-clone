/// Resolves Lens object labels from the Verified Lexicon (P7-905). No machine translation.
library;

import 'package:lingafriq/models/verified_lexeme.dart';

/// Copy key: [wordcard.ai_draft] (P7-922 honest badge).
const String lensAiDraftHonestLabel = 'AI draft, awaiting native check';

const String lensVerifiedLexiconEntriesPath = '/api/v2/verified-lexicon/entries/';

typedef FetchVerifiedLexeme = Future<VerifiedLexeme?> Function(String lexemeId);

typedef EnqueueLensVerify = Future<bool> Function({
  required String lexemeId,
  required String objectSetId,
  required String learnerLanguageCode,
});

enum LensLexiconLabelKind {
  verified,
  aiDraft,
  missingLexeme,
}

class LensLexiconLabel {
  const LensLexiconLabel({
    required this.kind,
    required this.objectSetId,
    required this.livingDictionaryLexemeId,
    required this.learnerLanguageCode,
    this.displayWord,
    this.verificationStatus,
    this.queuedForVerify = false,
  });

  final LensLexiconLabelKind kind;
  final String objectSetId;
  final String livingDictionaryLexemeId;
  final String learnerLanguageCode;
  final String? displayWord;
  final String? verificationStatus;
  final bool queuedForVerify;

  bool get showsAiDraftBadge =>
      kind == LensLexiconLabelKind.aiDraft ||
      kind == LensLexiconLabelKind.missingLexeme;

  String? get overlayHonestLabel => showsAiDraftBadge ? lensAiDraftHonestLabel : null;
}

bool lensVerificationCountsAsVerified(String status) {
  final s = status.trim().toLowerCase();
  return s == 'expert_reviewed' || s == 'native_verified';
}

/// Maps Lens profile language codes to verified-lexicon ISO ids.
String lensProfileLanguageToLexiconCode(String learnerLanguageCode) {
  final raw = learnerLanguageCode.trim().toLowerCase();
  const names = <String, String>{
    'english': 'en',
    'yoruba': 'yo',
    'hausa': 'ha',
    'igbo': 'ig',
    'swahili': 'sw',
    'zulu': 'zu',
    'xhosa': 'xh',
    'pidgin': 'pcm',
    'twi': 'tw',
    'amharic': 'am',
  };
  if (names.containsKey(raw)) return names[raw]!;
  if (RegExp(r'^[a-z]{2,3}$').hasMatch(raw)) return raw;
  return raw;
}

String? lexemeLanguagePrefix(String lexemeId) {
  final match = RegExp(r'^([a-z]{2,3})\.lex\.').firstMatch(lexemeId.trim());
  return match?.group(1);
}

class LexiconLabelResolver {
  LexiconLabelResolver({
    required FetchVerifiedLexeme fetchLexeme,
    EnqueueLensVerify? enqueueVerify,
  })  : _fetchLexeme = fetchLexeme,
        _enqueueVerify = enqueueVerify ?? _noopEnqueue;

  final FetchVerifiedLexeme _fetchLexeme;
  final EnqueueLensVerify _enqueueVerify;

  static Future<bool> _noopEnqueue({
    required String lexemeId,
    required String objectSetId,
    required String learnerLanguageCode,
  }) async =>
      false;

  Future<LensLexiconLabel> resolveForMappedObject({
    required String objectSetId,
    required String livingDictionaryLexemeId,
    required String learnerLanguageCode,
  }) async {
    final lexemeId = livingDictionaryLexemeId.trim();
    final targetLang = lensProfileLanguageToLexiconCode(learnerLanguageCode);
    final lexLang = lexemeLanguagePrefix(lexemeId);
    if (lexLang != null && lexLang != targetLang) {
      return LensLexiconLabel(
        kind: LensLexiconLabelKind.missingLexeme,
        objectSetId: objectSetId,
        livingDictionaryLexemeId: lexemeId,
        learnerLanguageCode: learnerLanguageCode,
        queuedForVerify: await _enqueueVerify(
          lexemeId: lexemeId,
          objectSetId: objectSetId,
          learnerLanguageCode: learnerLanguageCode,
        ),
      );
    }

    final row = await _fetchLexeme(lexemeId);
    if (row == null) {
      final queued = await _enqueueVerify(
        lexemeId: lexemeId,
        objectSetId: objectSetId,
        learnerLanguageCode: learnerLanguageCode,
      );
      return LensLexiconLabel(
        kind: LensLexiconLabelKind.missingLexeme,
        objectSetId: objectSetId,
        livingDictionaryLexemeId: lexemeId,
        learnerLanguageCode: learnerLanguageCode,
        queuedForVerify: queued,
      );
    }

    if (!lensVerificationCountsAsVerified(row.verificationStatus)) {
      final queued = await _enqueueVerify(
        lexemeId: lexemeId,
        objectSetId: objectSetId,
        learnerLanguageCode: learnerLanguageCode,
      );
      return LensLexiconLabel(
        kind: LensLexiconLabelKind.aiDraft,
        objectSetId: objectSetId,
        livingDictionaryLexemeId: lexemeId,
        learnerLanguageCode: learnerLanguageCode,
        displayWord: row.standardOrthography.isNotEmpty
            ? row.standardOrthography
            : row.lemma,
        verificationStatus: row.verificationStatus,
        queuedForVerify: queued,
      );
    }

    final word = row.standardOrthography.isNotEmpty
        ? row.standardOrthography
        : row.lemma;
    return LensLexiconLabel(
      kind: LensLexiconLabelKind.verified,
      objectSetId: objectSetId,
      livingDictionaryLexemeId: lexemeId,
      learnerLanguageCode: learnerLanguageCode,
      displayWord: word,
      verificationStatus: row.verificationStatus,
    );
  }
}
