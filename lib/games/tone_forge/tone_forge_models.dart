/// ToneForge game models + GameKit per-language tone inventories (P8-913).
library;

import '../../learning/pronunciation/tone_models.dart';
import '../../models/game/game_content_models.dart';
import '../../models/verified_lexeme.dart';
import '../../services/lexicon_lookup_service.dart';
import '../../utils/api_service.dart';
import '../../widgets/tone_contour_line.dart';
import '../gamekit/batch_game_factory.dart';

/// One selectable tone level for a tone-trainer turn (from [ToneLanguageModel.levels]).
class ToneInventoryOption {
  const ToneInventoryOption({
    required this.code,
    required this.label,
    required this.symbol,
    required this.inventoryIndex,
  });

  final String code;
  final String label;
  final String symbol;
  final int inventoryIndex;
}

/// Lexeme row eligible for tone games (verified + resolved tone pattern).
class ToneGameLexeme {
  const ToneGameLexeme({
    required this.lexemeId,
    required this.language,
    required this.toneMarkedForm,
    required this.tonePattern,
    required this.syllables,
    this.englishGloss,
    this.audioUri,
  });

  final String lexemeId;
  final String language;
  final String toneMarkedForm;
  final List<String> tonePattern;
  final List<String> syllables;
  final String? englishGloss;
  final String? audioUri;
}

class ToneGamePoolDiagnostics {
  const ToneGamePoolDiagnostics({
    required this.included,
    required this.excludedUnverified,
    required this.excludedMissingTone,
    required this.excludedNonTonalLanguage,
  });

  final int included;
  final int excludedUnverified;
  final int excludedMissingTone;
  final int excludedNonTonalLanguage;

  String formatLine() =>
      'tone_pool: included=$included '
      'excluded_unverified=$excludedUnverified '
      'excluded_missing_tone=$excludedMissingTone '
      'excluded_non_tonal=$excludedNonTonalLanguage';
}

class ToneGamePoolBuildResult {
  const ToneGamePoolBuildResult({
    required this.lexemes,
    required this.inventory,
    required this.diagnostics,
    required this.options,
  });

  final List<ToneGameLexeme> lexemes;
  final ToneLanguageModel? inventory;
  final ToneGamePoolDiagnostics diagnostics;
  final List<ToneInventoryOption> options;
}

/// Raised when tone games would fall back to a single global H/M/L set (CI guard).
class ToneGameHardcodedInventoryForbidden implements Exception {
  const ToneGameHardcodedInventoryForbidden(this.detail);
  final String detail;

  @override
  String toString() => 'ToneGameHardcodedInventoryForbidden: $detail';
}

const Set<String> _toneGameBlockedVerificationStatuses = {
  'beta',
  'unverified',
  'draft',
  'auto_beta',
  'machine_beta',
};

/// Guards AC3: only publishable verification labels enter tone pools.
bool isLexemeEligibleForToneGame(VerifiedLexeme lexeme) {
  final status = lexeme.verificationStatus.trim().toLowerCase();
  if (status.isEmpty) return false;
  if (_toneGameBlockedVerificationStatuses.contains(status)) return false;
  return true;
}

List<ToneInventoryOption> toneInventoryOptions(ToneLanguageModel model) {
  final options = <ToneInventoryOption>[];
  for (var i = 0; i < model.levels.length; i++) {
    final code = model.levels[i];
    options.add(
      ToneInventoryOption(
        code: code,
        label: _toneLevelLabel(code, model),
        symbol: _toneLevelSymbol(code),
        inventoryIndex: i,
      ),
    );
  }
  return options;
}

String _toneLevelLabel(String code, ToneLanguageModel model) {
  switch (code) {
    case 'H':
      return 'High';
    case 'M':
      return 'Mid';
    case 'L':
      return 'Low';
    case 'F':
      return 'Falling';
    default:
      return code;
  }
}

String _toneLevelSymbol(String code) {
  switch (code) {
    case 'H':
      return 'á';
    case 'M':
      return 'ā';
    case 'L':
      return 'à';
    case 'F':
      return 'â';
    default:
      return code;
  }
}

/// Maps contour / pattern codes onto the language inventory level index.
int? inventoryIndexForToneCode(ToneLanguageModel model, String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized == 'D' && model.hasDownstep) {
    final low = model.levels.indexOf('L');
    return low >= 0 ? low : null;
  }
  if (normalized == 'R' || normalized == 'F') {
    if (model.levels.contains(normalized)) {
      return model.levels.indexOf(normalized);
    }
    if (normalized == 'F' && model.levels.contains('F')) {
      return model.levels.indexOf('F');
    }
    return null;
  }
  final idx = model.levels.indexOf(normalized);
  return idx >= 0 ? idx : null;
}

List<String> resolveTonePatternForLexeme(
  VerifiedLexeme lexeme,
  ToneLanguageModel model,
) {
  final fromEntry = lensLemmaToneFromEntry(lexeme.raw);
  if (fromEntry.tonePattern.isNotEmpty) {
    return _normalizePatternToInventory(fromEntry.tonePattern, model);
  }
  return parseTonePatternFromMarkedForm(
    lexeme.standardOrthography.trim().isNotEmpty
        ? lexeme.standardOrthography.trim()
        : lexeme.lemma.trim(),
    model,
  );
}

List<String> _normalizePatternToInventory(
  List<String> raw,
  ToneLanguageModel model,
) {
  final out = <String>[];
  for (final token in raw) {
    final idx = inventoryIndexForToneCode(model, token);
    if (idx == null) return const [];
    out.add(model.levels[idx]);
  }
  return out;
}

/// Derives H/M/L (or H/L/F) per vowel from tone-marked orthography (AC1).
List<String> parseTonePatternFromMarkedForm(
  String form,
  ToneLanguageModel model,
) {
  if (form.trim().isEmpty) return const [];
  final pattern = <String>[];
  final clusterRe = RegExp(
    r'[\u0041-\u024F\u1E00-\u1EFF](?:[\u0300-\u036F\u0323-\u0331])*',
    unicode: true,
  );
  for (final match in clusterRe.allMatches(form)) {
    final cluster = match.group(0);
    if (cluster == null || !_clusterHasVowel(cluster)) continue;
    final level = _toneLevelFromCluster(cluster, model);
    if (level == null) return const [];
    pattern.add(level);
  }
  return _collapseOrthographyPattern(pattern, model);
}

List<String> _collapseOrthographyPattern(
  List<String> pattern,
  ToneLanguageModel model,
) {
  if (pattern.isEmpty) return pattern;
  if (pattern.every((t) => t == pattern.first)) {
    return [pattern.first];
  }
  if (pattern.length <= 1) return pattern;
  final nonMid = pattern.where((t) => t != 'M').toList();
  if (nonMid.length == 1 && model.levels.contains('M')) {
    return nonMid;
  }
  return pattern;
}

bool _clusterHasVowel(String cluster) {
  for (var i = 0; i < cluster.length; i++) {
    if (_isVowelBase(cluster[i])) return true;
  }
  return false;
}

bool _isVowelBase(String ch) {
  const latinVowels = 'aeiouAEIOU';
  if (latinVowels.contains(ch)) return true;
  const extended = 'àáèéìíòóùúāăąǎǝǟǡǣǫǭǖǘǚǜẹịọụẹ́ọ̀';
  return extended.contains(ch);
}

String? _toneLevelFromCluster(String cluster, ToneLanguageModel model) {
  var hasAcute = false;
  var hasGrave = false;
  var hasCircumflex = false;
  var hasMacron = false;
  for (var k = 0; k < cluster.length; k++) {
    final cp = cluster.codeUnitAt(k);
    if (cp == 0x0301 || cp == 0x00B4) hasAcute = true;
    if (cp == 0x0300) hasGrave = true;
    if (cp == 0x0302) hasCircumflex = true;
    if (cp == 0x0304) hasMacron = true;
  }
  if (hasCircumflex && model.levels.contains('F')) return 'F';
  if (hasAcute) return model.levels.contains('H') ? 'H' : null;
  if (hasGrave) return model.levels.contains('L') ? 'L' : null;
  if (hasMacron && model.levels.contains('M')) return 'M';
  if (model.levels.contains('M') && model.isThreeLevelHml) return 'M';
  return null;
}

ToneGamePoolBuildResult buildToneGamePoolFromLexemes({
  required List<VerifiedLexeme> lexemes,
  required ToneModelsCatalog catalog,
  required String languageCode,
  int maxItems = 32,
}) {
  final lang = languageCode.trim().toLowerCase();
  if (!isToneTrainerAvailable(catalog, lang)) {
    return ToneGamePoolBuildResult(
      lexemes: const [],
      inventory: null,
      diagnostics: ToneGamePoolDiagnostics(
        included: 0,
        excludedUnverified: 0,
        excludedMissingTone: 0,
        excludedNonTonalLanguage: lexemes.length,
      ),
      options: const [],
    );
  }

  final model = resolveToneModel(catalog, lang);
  final options = toneInventoryOptions(model);
  var excludedUnverified = 0;
  var excludedMissingTone = 0;
  final included = <ToneGameLexeme>[];

  for (final lexeme in lexemes) {
    if (lexeme.language.trim().toLowerCase() != lang) continue;
    if (!isLexemeEligibleForToneGame(lexeme)) {
      excludedUnverified++;
      continue;
    }
    final pattern = resolveTonePatternForLexeme(lexeme, model);
    if (pattern.isEmpty) {
      excludedMissingTone++;
      continue;
    }
    final toneData = lensLemmaToneFromEntry(lexeme.raw);
    final poolItem = verifiedLexemeToPoolItem(lexeme);
    included.add(
      ToneGameLexeme(
        lexemeId: lexeme.lexemeId,
        language: lang,
        toneMarkedForm: poolItem.toneMarkedForm,
        tonePattern: pattern,
        syllables: toneData.syllables,
        englishGloss: poolItem.englishGloss,
        audioUri: poolItem.audioUri,
      ),
    );
    if (included.length >= maxItems) break;
  }

  return ToneGamePoolBuildResult(
    lexemes: included,
    inventory: model,
    options: options,
    diagnostics: ToneGamePoolDiagnostics(
      included: included.length,
      excludedUnverified: excludedUnverified,
      excludedMissingTone: excludedMissingTone,
      excludedNonTonalLanguage: 0,
    ),
  );
}

/// Builds pool via verified lexicon fetch (P8-912) + inventory gates (P8-913).
Future<ToneGamePoolBuildResult> buildToneGamePool({
  required ToneModelsCatalog catalog,
  required String languageCode,
  required int fetchLimit,
  GameLexiconPoolFetch? fetch,
}) async {
  final lang = languageCode.trim().toLowerCase();
  if (!isToneTrainerAvailable(catalog, lang)) {
    return ToneGamePoolBuildResult(
      lexemes: const [],
      inventory: null,
      diagnostics: const ToneGamePoolDiagnostics(
        included: 0,
        excludedUnverified: 0,
        excludedMissingTone: 0,
        excludedNonTonalLanguage: 1,
      ),
      options: const [],
    );
  }

  final fetcher = fetch ?? _defaultToneGameLexemeFetch;
  final rows = await fetcher(lang, limit: fetchLimit.clamp(1, 100));

  return buildToneGamePoolFromLexemes(
    lexemes: rows,
    catalog: catalog,
    languageCode: lang,
    maxItems: fetchLimit,
  );
}

Future<List<VerifiedLexeme>> _defaultToneGameLexemeFetch(
  String languageCode, {
  required int limit,
}) async {
  await ApiService.initialize();
  try {
    final response = await ApiService.get(
      verifiedLexiconSearchPath,
      queryParameters: {
        'language': languageCode.trim().toLowerCase(),
        'q': '',
        'limit': limit.clamp(1, 100).toString(),
      },
    );
    if (response.statusCode != 200) return const [];
    final body = response.data;
    if (body is! Map) return const [];
    final entries = body['entries'];
    if (entries is! List) return const [];
    final out = <VerifiedLexeme>[];
    for (final row in entries) {
      if (row is Map<String, dynamic>) {
        out.add(VerifiedLexeme.fromApiJson(row));
      } else if (row is Map) {
        out.add(VerifiedLexeme.fromApiJson(row.cast<String, dynamic>()));
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Question for legacy Tone Trainer UI (one target syllable per turn).
class ToneTrainerQuestionSpec {
  const ToneTrainerQuestionSpec({
    required this.lexeme,
    required this.syllableIndex,
    required this.correctInventoryIndex,
    required this.options,
  });

  final ToneGameLexeme lexeme;
  final int syllableIndex;
  final int correctInventoryIndex;
  final List<ToneInventoryOption> options;
}

ToneTrainerQuestionSpec? toneTrainerQuestionFromLexeme({
  required ToneGameLexeme lexeme,
  required List<ToneInventoryOption> options,
  required ToneLanguageModel inventory,
  int? syllableIndex,
}) {
  if (lexeme.tonePattern.isEmpty || options.isEmpty) return null;
  final idx = syllableIndex ?? 0;
  if (idx < 0 || idx >= lexeme.tonePattern.length) return null;
  final code = lexeme.tonePattern[idx];
  final correct = inventory.levels.indexOf(code);
  if (correct < 0) return null;
  return ToneTrainerQuestionSpec(
    lexeme: lexeme,
    syllableIndex: idx,
    correctInventoryIndex: correct,
    options: options,
  );
}

/// ToneForge pitch content (production games).
class ToneForgeContent {
  final String text;
  final List<double> targetPitchContour;
  final String? audioUrl;
  final String? ipa;
  final double pitchTolerance;
  final double timingTolerance;
  final String? culturalContext;
  final String contentId;
  final List<String> tonePattern;
  final String? languageCode;

  ToneForgeContent({
    required this.text,
    required this.targetPitchContour,
    this.audioUrl,
    this.ipa,
    required this.pitchTolerance,
    required this.timingTolerance,
    this.culturalContext,
    required this.contentId,
    this.tonePattern = const [],
    this.languageCode,
  });

  factory ToneForgeContent.fromPolieContent(Map<String, dynamic> polieData) {
    final rawTones = polieData['tones'];
    final pattern = rawTones is List
        ? rawTones.map((e) => e.toString()).toList()
        : <String>[];
    return ToneForgeContent(
      text: polieData['text'] as String? ?? '',
      targetPitchContour: polieData['tones'] != null && polieData['tones'] is List
          ? List<double>.from(
              (polieData['tones'] as List).whereType<num>().map((n) => n.toDouble()),
            )
          : [],
      audioUrl: polieData['audio_url'] as String?,
      ipa: polieData['ipa'] as String?,
      pitchTolerance:
          (polieData['scoring_rules']?['pitch_tolerance'] as num?)?.toDouble() ??
              0.15,
      timingTolerance:
          (polieData['scoring_rules']?['timing_tolerance'] as num?)?.toDouble() ??
              0.2,
      culturalContext: polieData['cultural_context'] as String?,
      contentId: polieData['content_id'] as String? ?? '',
      tonePattern: pattern,
      languageCode: polieData['language'] as String?,
    );
  }
}

class ToneForgeInput {
  final List<double> userPitchContour;
  final List<double>? audioSamples;
  final int durationMs;

  ToneForgeInput({
    required this.userPitchContour,
    this.audioSamples,
    required this.durationMs,
  });
}
