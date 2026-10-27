/// Builds Lens Word Cards from verified lexeme rows and native audio bundles (P7-906).
library;

import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_audio_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';
import 'package:lingafriq/services/tts/yo_tts.dart';

const lensNoRecordingYetLabel = 'No recording yet';

bool lensTonalTtsGateAllows(String language, String text) {
  final lang = language.trim().toLowerCase();
  if (lang != 'yo' && lang != 'ig' && lang != 'ha') {
    return true;
  }
  try {
    if (lang == 'yo' || lang == 'ha') {
      assertYoFullyToneMarked(text);
    } else {
      assertIgTtsInput(text);
    }
    return true;
  } catch (_) {
    return false;
  }
}

LensNounClassInfo? lensParseNounClass(Map<String, dynamic> entry, String language) {
  final lang = language.trim().toLowerCase();
  if (lang != 'sw' && lang != 'zu') {
    return null;
  }
  final raw = entry['noun_class'];
  if (raw is! Map) {
    return null;
  }
  final map = raw.cast<String, dynamic>();
  final sg = map['sg']?.toString();
  final pl = map['pl']?.toString();
  final pluralForm = map['plural_form']?.toString();
  if ((sg == null || sg.isEmpty) && (pl == null || pl.isEmpty)) {
    return null;
  }
  return LensNounClassInfo(
    singularClass: sg,
    pluralClass: pl,
    pluralForm: pluralForm?.isNotEmpty == true ? pluralForm : null,
  );
}

List<LensDialectVariant> lensParseDialectVariants(Map<String, dynamic> entry) {
  final out = <LensDialectVariant>[];
  final variants = entry['dialect_variants'];
  if (variants is List) {
    for (final row in variants) {
      if (row is! Map) continue;
      final map = row.cast<String, dynamic>();
      final text = (map['text'] ?? map['form'] ?? '').toString().trim();
      final tag = (map['dialect_tag'] ?? map['tag'] ?? '').toString().trim();
      if (text.isNotEmpty && tag.isNotEmpty && tag != 'standard') {
        out.add(LensDialectVariant(text: text, dialectTag: tag));
      }
    }
  }
  final audio = entry['audio'];
  if (audio is List) {
    for (final clip in audio) {
      if (clip is! Map) continue;
      final map = clip.cast<String, dynamic>();
      if (map['kind']?.toString() == 'tts_synthetic') continue;
      final tag = (map['dialect_tag'] ?? '').toString().trim();
      final take = (map['take_kind'] ?? 'standard').toString();
      if (tag.isEmpty || tag == 'standard' || take != 'regional') continue;
      final orth = (entry['orthography'] as Map?)?.cast<String, dynamic>();
      final text = (orth?['standard'] ?? entry['lemma'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      if (out.any((v) => v.dialectTag == tag)) continue;
      out.add(LensDialectVariant(text: text, dialectTag: tag));
    }
  }
  return out;
}

String? lensExampleFromEntry(Map<String, dynamic> entry) {
  final senses = entry['senses'];
  if (senses is List) {
    for (final sense in senses) {
      if (sense is! Map) continue;
      final map = sense.cast<String, dynamic>();
      final example = map['example_target'] as String?;
      if (example != null && example.trim().isNotEmpty) {
        return example.trim();
      }
    }
  }
  return null;
}

String? _firstHumanUri({
  required VerifiedLexeme lexeme,
  LexiconAudioBundle? audioBundle,
}) {
  if (audioBundle != null) {
    for (final uri in audioBundle.playableUris) {
      if (uri.trim().isNotEmpty) return uri.trim();
    }
  }
  for (final uri in lexeme.audioUris) {
    if (uri.trim().isNotEmpty) return uri.trim();
  }
  final audio = lexeme.raw['audio'];
  if (audio is List) {
    for (final clip in audio) {
      if (clip is! Map) continue;
      final map = clip.cast<String, dynamic>();
      if (map['kind']?.toString() == 'tts_synthetic') continue;
      final uri = map['uri']?.toString().trim();
      if (uri != null && uri.isNotEmpty) return uri;
    }
  }
  return null;
}

LensWordCardAudio lensResolveWordCardAudio({
  required VerifiedLexeme lexeme,
  LexiconAudioBundle? audioBundle,
  bool allowLicensedTtsFallback = true,
}) {
  final human = _firstHumanUri(lexeme: lexeme, audioBundle: audioBundle);
  if (human != null) {
    return LensWordCardAudio(
      kind: LensWordCardAudioKind.nativeHuman,
      playUri: human,
    );
  }

  final surface = lexeme.standardOrthography.isNotEmpty
      ? lexeme.standardOrthography
      : lexeme.lemma;
  final gateOk = lensTonalTtsGateAllows(lexeme.language, surface);
  if (allowLicensedTtsFallback && gateOk) {
    return const LensWordCardAudio(
      kind: LensWordCardAudioKind.licensedTts,
      honestyLabel: dynamicSpeechSyntheticVoiceTag,
      tonalGatePassed: true,
    );
  }

  return LensWordCardAudio(
    kind: LensWordCardAudioKind.noRecordingYet,
    honestyLabel: lensNoRecordingYetLabel,
    tonalGatePassed: gateOk,
  );
}

class WordCardBuilder {
  LensWordCard build({
    required LensLexiconLabel label,
    required VerifiedLexeme lexeme,
    LexiconAudioBundle? audioBundle,
    bool allowLicensedTtsFallback = true,
  }) {
    final word = lexeme.standardOrthography.isNotEmpty
        ? lexeme.standardOrthography
        : lexeme.lemma;
    final example =
        lexeme.exampleSentence ?? lensExampleFromEntry(lexeme.raw);
    final audio = lensResolveWordCardAudio(
      lexeme: lexeme,
      audioBundle: audioBundle,
      allowLicensedTtsFallback: allowLicensedTtsFallback,
    );

    return LensWordCard(
      lexemeId: lexeme.lexemeId,
      language: lexeme.language,
      word: word,
      objectSetId: label.objectSetId,
      exampleSentence: example,
      dialectVariants: lensParseDialectVariants(lexeme.raw),
      nounClass: lensParseNounClass(lexeme.raw, lexeme.language),
      audio: audio,
      showsAiDraftBadge: label.showsAiDraftBadge,
    );
  }
}
