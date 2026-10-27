/// Lens signs/menus OCR: ML Kit + lexicon restore + gateway translate (P7-912).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lingafriq/services/lens/diacritic_restorer.dart';
import 'package:lingafriq/services/lens/point_say_audio.dart';
import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Copy key: lens.ocr.read_aloud
const String lensOcrReadAloudCopyKey = 'lens.ocr.read_aloud';

const String lensOcrErrorCopy =
    'Could not read this sign. Try another photo or better light.';

const String kLensOcrRestorePath = '/api/ai/lens/ocr/restore';

enum LensOcrPhase { scanning, result, unsure, error }

class LensOcrPhrase {
  const LensOcrPhrase({
    required this.sourceText,
    required this.translationEn,
    required this.unsure,
    required this.restoredSpans,
  });

  final String sourceText;
  final String translationEn;
  final bool unsure;
  final List<RestoredCharacterSpan> restoredSpans;
}

class LensOcrScanOutcome {
  const LensOcrScanOutcome({
    required this.phase,
    this.phrases = const [],
    this.errorMessage,
    this.pipelineId,
    this.modelDisclosure,
  });

  final LensOcrPhase phase;
  final List<LensOcrPhrase> phrases;
  final String? errorMessage;
  final String? pipelineId;
  final String? modelDisclosure;
}

typedef LensOcrMlKitScan = Future<String?> Function(File image);
typedef LensOcrRestorePost = Future<Map<String, dynamic>> Function(
  String path,
  Map<String, dynamic> body,
);
typedef LensOcrTranslatePhrase = Future<String?> Function({
  required String sourceLang,
  required String text,
});
typedef LensOcrLexiconLookup = List<String> Function(
  String languageCode,
  String foldedToken,
);

class LensOcrPipelineConfig {
  const LensOcrPipelineConfig({
    required this.primaryRecognizer,
    required this.requiresServerDiacriticPass,
    required this.captureTier,
  });

  final String primaryRecognizer;
  final bool requiresServerDiacriticPass;
  final String captureTier;

  String get pipelineId => requiresServerDiacriticPass
      ? '$primaryRecognizer+gemini_vision_restore'
      : primaryRecognizer;
}

Future<LensOcrPipelineConfig> loadLensOcrPipelineFromLedger() async {
  final raw = await rootBundle
      .loadString('assets/data/lens/ml_kit_latin_ocr_ledger.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final recognizer =
      (json['recognizer'] as String?) ?? 'google_mlkit_text_recognition/latin';
  final tier = (json['capture_tier'] as String?) ?? 'fixture_until_device_rerun';
  return LensOcrPipelineConfig(
    primaryRecognizer: recognizer,
    requiresServerDiacriticPass: true,
    captureTier: tier,
  );
}

List<String> splitOcrPhrases(String text) {
  final lines = text.split(RegExp(r'[\n\r]+'));
  final phrases = <String>[];
  for (final line in lines) {
    final parts = line.split(RegExp(r'[•|;,]+'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        phrases.add(trimmed);
      }
    }
  }
  if (phrases.isEmpty && text.trim().isNotEmpty) {
    phrases.add(text.trim());
  }
  return phrases;
}

class LensOcrModeService {
  LensOcrModeService({
    TextRecognizer? recognizer,
    this.restorePost,
    this.translatePhrase,
    this.lexiconLookup,
  }) : _recognizer = recognizer;

  TextRecognizer? _recognizer;
  final LensOcrRestorePost? restorePost;
  final LensOcrTranslatePhrase? translatePhrase;
  final LensOcrLexiconLookup? lexiconLookup;

  void _ensureRecognizer() {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }

  Future<String?> scanWithMlKit(File image) async {
    _ensureRecognizer();
    try {
      final input = InputImage.fromFile(image);
      final recognized = await _recognizer!.processImage(input);
      final text = recognized.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  Future<LensOcrScanOutcome> scanSignPhoto({
    required File image,
    required String languageCode,
    LensOcrMlKitScan? mlKitScan,
    String? imageBase64,
  }) async {
    final pipeline = await loadLensOcrPipelineFromLedger();
    final lang = languageCode.trim().toLowerCase();
    final needsServer = pipeline.requiresServerDiacriticPass &&
        lensLanguageRequiresServerDiacriticPass(lang);

    final rawOcr = await (mlKitScan ?? scanWithMlKit)(image);
    if (rawOcr == null || rawOcr.trim().isEmpty) {
      return LensOcrScanOutcome(
        phase: LensOcrPhase.error,
        errorMessage: lensOcrErrorCopy,
        pipelineId: pipeline.pipelineId,
      );
    }

    final lookup = lexiconLookup ?? (_, __) => <String>[];
    final phraseChunks = splitOcrPhrases(rawOcr);
    final built = <LensOcrPhrase>[];
    var anyUnsure = false;

    for (final chunk in phraseChunks) {
      var restore = restoreDiacriticsFromLexicon(
        ocrText: chunk,
        languageCode: lang,
        lookupForms: lookup,
      );

      if (needsServer && restorePost != null && imageBase64 != null) {
        try {
          final response = await restorePost(
            kLensOcrRestorePath,
            {
              'imageOptIn': true,
              'imageBase64': imageBase64,
              'language': lang,
              'ocrText': chunk,
              'localText': restore.text,
            },
          );
          if (response['ok'] == true) {
            final result = response['result'];
            if (result is Map) {
              final map = Map<String, dynamic>.from(result);
              restore = applyServerDiacriticPass(
                local: restore,
                serverText: map['restored_text'] as String?,
                serverUnsure: map['unsure'] == true,
              );
              if (map['model'] is Map) {
                final model = Map<String, dynamic>.from(map['model'] as Map);
                // surfaced on outcome below
              }
            }
          }
        } catch (_) {
          restore = DiacriticRestoreOutcome(
            text: restore.text,
            unsure: true,
            restoredSpans: restore.restoredSpans,
            perMarkErrorRate: restore.perMarkErrorRate,
          );
        }
      } else if (needsServer && restore.text == chunk) {
        restore = DiacriticRestoreOutcome(
          text: restore.text,
          unsure: true,
          restoredSpans: restore.restoredSpans,
          perMarkErrorRate: 1.0,
        );
      }

      anyUnsure = anyUnsure || restore.unsure;

      String translationEn = '';
      if (translatePhrase != null) {
        translationEn =
            await translatePhrase(sourceLang: lang, text: restore.text) ?? '';
      }

      built.add(
        LensOcrPhrase(
          sourceText: restore.text,
          translationEn: translationEn,
          unsure: restore.unsure,
          restoredSpans: restore.restoredSpans,
        ),
      );
    }

    return LensOcrScanOutcome(
      phase: anyUnsure ? LensOcrPhase.unsure : LensOcrPhase.result,
      phrases: built,
      pipelineId: pipeline.pipelineId,
      modelDisclosure: needsServer
          ? 'Google Cloud Vision + Gemini vision restore (EXT-01 §3.13)'
          : pipeline.primaryRecognizer,
    );
  }

  Future<PointSayPlaybackPlan> readPhraseAloud({
    required PointSayAudio audio,
    required String languageCode,
    required String phrase,
    String? humanAudioUrl,
  }) {
    return audio.resolve(
      PointSayDictionaryHit(
        word: nfc(phrase),
        language: languageCode,
        humanAudioUrl: humanAudioUrl,
      ),
    );
  }
}
