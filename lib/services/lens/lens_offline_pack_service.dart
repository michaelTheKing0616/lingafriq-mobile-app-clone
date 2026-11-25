/// Offline Lens pack: top object word cards + cached audio (P7-913).
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';

const int lensOfflinePackTargetObjectCount = 300;
const int lensOfflinePackFormatVersion = 1;

enum LensOfflinePackErrorKind {
  incomplete,
  corrupt,
  missingOnDisk,
}

class LensOfflinePackException implements Exception {
  LensOfflinePackException(this.kind, this.message);

  final LensOfflinePackErrorKind kind;
  final String message;

  @override
  String toString() => 'LensOfflinePackException($kind): $message';
}

int lensOfflinePackExpectedObjectCount(int catalogEntryCount) {
  if (catalogEntryCount <= 0) return 0;
  return catalogEntryCount > lensOfflinePackTargetObjectCount
      ? lensOfflinePackTargetObjectCount
      : catalogEntryCount;
}

/// One object row stored inside a downloaded pack manifest.
class LensOfflinePackObjectRow {
  const LensOfflinePackObjectRow({
    required this.objectSetId,
    required this.lexemeId,
    required this.wordCard,
    this.audioRelativePath,
    this.audioSha256,
  });

  final String objectSetId;
  final String lexemeId;
  final Map<String, dynamic> wordCard;
  final String? audioRelativePath;
  final String? audioSha256;

  Map<String, dynamic> toJson() => {
        'object_set_id': objectSetId,
        'lexeme_id': lexemeId,
        'word_card': wordCard,
        if (audioRelativePath != null) 'audio_relative': audioRelativePath,
        if (audioSha256 != null) 'audio_sha256': audioSha256,
      };

  factory LensOfflinePackObjectRow.fromJson(Map<String, dynamic> json) {
    final wc = json['word_card'];
    return LensOfflinePackObjectRow(
      objectSetId: (json['object_set_id'] ?? '').toString(),
      lexemeId: (json['lexeme_id'] ?? '').toString(),
      wordCard: wc is Map
          ? Map<String, dynamic>.from(wc)
          : <String, dynamic>{},
      audioRelativePath: json['audio_relative']?.toString(),
      audioSha256: json['audio_sha256']?.toString(),
    );
  }

  LensWordCard toWordCard() {
    final wc = wordCard;
    final audioMap = (wc['audio'] as Map?)?.cast<String, dynamic>() ?? {};
    final kindRaw = (audioMap['kind'] ?? 'noRecordingYet').toString();
    LensWordCardAudioKind kind;
    switch (kindRaw) {
      case 'nativeHuman':
        kind = LensWordCardAudioKind.nativeHuman;
        break;
      case 'licensedTts':
        kind = LensWordCardAudioKind.licensedTts;
        break;
      default:
        kind = LensWordCardAudioKind.noRecordingYet;
    }
    return LensWordCard(
      lexemeId: (wc['lexeme_id'] ?? lexemeId).toString(),
      language: (wc['language'] ?? '').toString(),
      word: (wc['word'] ?? '').toString(),
      objectSetId: objectSetId,
      exampleSentence: wc['example_sentence']?.toString(),
      audio: LensWordCardAudio(
        kind: kind,
        playUri: audioMap['play_uri']?.toString(),
        honestyLabel: audioMap['honesty_label']?.toString(),
        tonalGatePassed: audioMap['tonal_gate_passed'] != false,
      ),
      showsAiDraftBadge: wc['shows_ai_draft_badge'] == true,
    );
  }
}

class LensOfflinePackManifest {
  LensOfflinePackManifest({
    required this.language,
    required this.formatVersion,
    required this.expectedObjectCount,
    required this.objects,
    required this.integritySha256,
  });

  final String language;
  final int formatVersion;
  final int expectedObjectCount;
  final List<LensOfflinePackObjectRow> objects;
  final String integritySha256;

  Map<String, dynamic> toCanonicalJson() => {
        'format_version': formatVersion,
        'language': language,
        'expected_object_count': expectedObjectCount,
        'objects': objects.map((o) => o.toJson()).toList(),
      };

  Map<String, dynamic> toJson() => {
        ...toCanonicalJson(),
        'integrity_sha256': integritySha256,
      };

  static String computeIntegritySha256(Map<String, dynamic> canonical) {
    final bytes = utf8.encode(jsonEncode(canonical));
    return sha256.convert(bytes).toString();
  }

  static LensOfflinePackManifest parse(Map<String, dynamic> json) {
    final objectsRaw = json['objects'] as List? ?? const [];
    final objects = <LensOfflinePackObjectRow>[];
    for (final row in objectsRaw) {
      if (row is Map) {
        objects.add(LensOfflinePackObjectRow.fromJson(row.cast<String, dynamic>()));
      }
    }
    final canonical = <String, dynamic>{
      'format_version': (json['format_version'] as num?)?.toInt() ??
          lensOfflinePackFormatVersion,
      'language': (json['language'] ?? '').toString(),
      'expected_object_count': (json['expected_object_count'] as num?)?.toInt() ?? 0,
      'objects': objects.map((o) => o.toJson()).toList(),
    };
    final expectedHash = computeIntegritySha256(canonical);
    final onDisk = (json['integrity_sha256'] ?? '').toString();
    if (onDisk.isEmpty || onDisk != expectedHash) {
      throw LensOfflinePackException(
        LensOfflinePackErrorKind.corrupt,
        'integrity_mismatch',
      );
    }
    return LensOfflinePackManifest(
      language: canonical['language'] as String,
      formatVersion: canonical['format_version'] as int,
      expectedObjectCount: canonical['expected_object_count'] as int,
      objects: objects,
      integritySha256: onDisk,
    );
  }

  void validateCompleteness() {
    if (objects.length != expectedObjectCount) {
      throw LensOfflinePackException(
        LensOfflinePackErrorKind.incomplete,
        'object_count_mismatch:${objects.length}/$expectedObjectCount',
      );
    }
    for (final o in objects) {
      if (o.objectSetId.trim().isEmpty || o.lexemeId.trim().isEmpty) {
        throw LensOfflinePackException(
          LensOfflinePackErrorKind.incomplete,
          'missing_ids',
        );
      }
    }
  }
}

Map<String, dynamic> lensWordCardToPackJson(LensWordCard card) => {
      'lexeme_id': card.lexemeId,
      'language': card.language,
      'word': card.word,
      'object_set_id': card.objectSetId,
      if (card.exampleSentence != null) 'example_sentence': card.exampleSentence,
      'shows_ai_draft_badge': card.showsAiDraftBadge,
      'audio': {
        'kind': switch (card.audio.kind) {
          LensWordCardAudioKind.nativeHuman => 'nativeHuman',
          LensWordCardAudioKind.licensedTts => 'licensedTts',
          LensWordCardAudioKind.noRecordingYet => 'noRecordingYet',
        },
        if (card.audio.playUri != null) 'play_uri': card.audio.playUri,
        if (card.audio.honestyLabel != null) 'honesty_label': card.audio.honestyLabel,
        'tonal_gate_passed': card.audio.tonalGatePassed,
      },
    };

/// Validates on-disk audio for each cached native clip.
void validatePackFilesOnDisk({
  required Directory packRoot,
  required LensOfflinePackManifest manifest,
}) {
  for (final row in manifest.objects) {
    final rel = row.audioRelativePath?.trim();
    final hash = row.audioSha256?.trim();
    if (rel == null || rel.isEmpty) continue;
    final file = File('${packRoot.path}/$rel');
    if (!file.existsSync()) {
      throw LensOfflinePackException(
        LensOfflinePackErrorKind.missingOnDisk,
        'audio_missing:$rel',
      );
    }
    if (hash != null && hash.isNotEmpty) {
      final digest = sha256.convert(file.readAsBytesSync()).toString();
      if (digest != hash) {
        throw LensOfflinePackException(
          LensOfflinePackErrorKind.corrupt,
          'audio_hash_mismatch:$rel',
        );
      }
    }
  }
}

typedef LensPackAudioFetcher = Future<List<int>?> Function(String remoteUri);

class LensOfflinePackService {
  LensOfflinePackService({
    required this.packRoot,
    this.audioFetcher,
  });

  final Directory packRoot;
  final LensPackAudioFetcher? audioFetcher;

  Directory languageDir(String language) =>
      Directory('${packRoot.path}/${language.trim().toLowerCase()}');

  File manifestFile(String language) =>
      File('${languageDir(language).path}/manifest.json');

  /// Builds manifest rows from the curated object set (cap [lensOfflinePackTargetObjectCount]).
  static List<AfricanObjectSetEntry> selectPackObjects(AfricanObjectSet set) {
    final n = lensOfflinePackExpectedObjectCount(set.entries.length);
    return set.entries.take(n).toList();
  }

  Future<LensOfflinePackManifest> openPack(String language) async {
    final file = manifestFile(language);
    if (!file.existsSync()) {
      throw LensOfflinePackException(
        LensOfflinePackErrorKind.missingOnDisk,
        'manifest_missing',
      );
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw LensOfflinePackException(
        LensOfflinePackErrorKind.corrupt,
        'manifest_not_object',
      );
    }
    final manifest =
        LensOfflinePackManifest.parse(Map<String, dynamic>.from(decoded));
    manifest.validateCompleteness();
    validatePackFilesOnDisk(packRoot: languageDir(language), manifest: manifest);
    return manifest;
  }

  LensWordCard? wordCardFromOpenPack(
    LensOfflinePackManifest manifest,
    String objectSetId,
  ) {
    final id = objectSetId.trim();
    for (final row in manifest.objects) {
      if (row.objectSetId == id) return row.toWordCard();
    }
    return null;
  }

  String? localAudioPath(
    LensOfflinePackManifest manifest,
    String objectSetId,
  ) {
    final id = objectSetId.trim();
    for (final row in manifest.objects) {
      if (row.objectSetId != id) continue;
      final rel = row.audioRelativePath?.trim();
      if (rel == null || rel.isEmpty) return null;
      final file = File('${languageDir(manifest.language).path}/$rel');
      return file.existsSync() ? file.path : null;
    }
    return null;
  }

  /// Persists a pack from pre-built rows (download orchestration / tests).
  Future<LensOfflinePackManifest> writePack({
    required String language,
    required List<LensOfflinePackObjectRow> objects,
  }) async {
    final lang = language.trim().toLowerCase();
    final dir = languageDir(lang);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final expected = objects.length;
    final canonical = <String, dynamic>{
      'format_version': lensOfflinePackFormatVersion,
      'language': lang,
      'expected_object_count': expected,
      'objects': objects.map((o) => o.toJson()).toList(),
    };
    final integrity = LensOfflinePackManifest.computeIntegritySha256(canonical);
    final manifest = LensOfflinePackManifest(
      language: lang,
      formatVersion: lensOfflinePackFormatVersion,
      expectedObjectCount: expected,
      objects: objects,
      integritySha256: integrity,
    );
    await manifestFile(lang).writeAsString(
      jsonEncode(manifest.toJson()),
      flush: true,
    );
    return manifest;
  }

  /// Downloads remote audio into the pack when [audioFetcher] is set.
  Future<LensOfflinePackObjectRow> cacheAudioForRow({
    required String language,
    required LensOfflinePackObjectRow row,
    required String remoteUri,
  }) async {
    final fetcher = audioFetcher;
    if (fetcher == null) return row;
    final bytes = await fetcher(remoteUri);
    if (bytes == null || bytes.isEmpty) return row;
    final langDir = languageDir(language);
    final audioDir = Directory('${langDir.path}/audio');
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
    final safeId = row.objectSetId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final rel = 'audio/$safeId.m4a';
    final file = File('${langDir.path}/$rel');
    await file.writeAsBytes(bytes, flush: true);
    final digest = sha256.convert(bytes).toString();
    final wc = Map<String, dynamic>.from(row.wordCard);
    final audio = Map<String, dynamic>.from(
      (wc['audio'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    audio['kind'] = 'nativeHuman';
    audio['play_uri'] = file.path;
    audio.remove('honesty_label');
    wc['audio'] = audio;
    return LensOfflinePackObjectRow(
      objectSetId: row.objectSetId,
      lexemeId: row.lexemeId,
      wordCard: wc,
      audioRelativePath: rel,
      audioSha256: digest,
    );
  }
}

LensOfflinePackObjectRow lensPackRowFromWordCard({
  required LensWordCard card,
  String? audioRelativePath,
  String? audioSha256,
}) {
  return LensOfflinePackObjectRow(
    objectSetId: card.objectSetId,
    lexemeId: card.lexemeId,
    wordCard: lensWordCardToPackJson(card),
    audioRelativePath: audioRelativePath,
    audioSha256: audioSha256,
  );
}

/// Placeholder row when only licensed TTS is available (no bytes cached).
LensOfflinePackObjectRow lensPackRowLicensedTts({
  required String objectSetId,
  required String lexemeId,
  required String language,
  required String word,
}) {
  final card = LensWordCard(
    lexemeId: lexemeId,
    language: language,
    word: word,
    objectSetId: objectSetId,
    audio: const LensWordCardAudio(
      kind: LensWordCardAudioKind.licensedTts,
      honestyLabel: dynamicSpeechSyntheticVoiceTag,
    ),
  );
  return lensPackRowFromWordCard(card: card);
}
