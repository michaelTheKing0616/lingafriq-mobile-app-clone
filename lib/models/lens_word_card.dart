/// Lens Word Card payload (P7-906): verified lexeme surface + honest audio metadata.
library;

import 'package:lingafriq/services/tts/dynamic_tts_label.dart';

enum LensWordCardAudioKind {
  nativeHuman,
  licensedTts,
  noRecordingYet,
}

class LensDialectVariant {
  const LensDialectVariant({
    required this.text,
    required this.dialectTag,
  });

  final String text;
  final String dialectTag;
}

class LensNounClassInfo {
  const LensNounClassInfo({
    this.singularClass,
    this.pluralClass,
    this.pluralForm,
  });

  final String? singularClass;
  final String? pluralClass;
  final String? pluralForm;

  bool get hasContent =>
      (singularClass != null && singularClass!.isNotEmpty) ||
      (pluralClass != null && pluralClass!.isNotEmpty) ||
      (pluralForm != null && pluralForm!.isNotEmpty);
}

class LensWordCardAudio {
  const LensWordCardAudio({
    required this.kind,
    this.playUri,
    this.honestyLabel,
    this.tonalGatePassed = true,
  });

  final LensWordCardAudioKind kind;
  final String? playUri;
  final String? honestyLabel;
  final bool tonalGatePassed;

  bool get presentsAsNative => kind == LensWordCardAudioKind.nativeHuman;

  bool get showsSyntheticLabel =>
      kind == LensWordCardAudioKind.licensedTts &&
      honestyLabel == dynamicSpeechSyntheticVoiceTag;
}

class LensWordCard {
  const LensWordCard({
    required this.lexemeId,
    required this.language,
    required this.word,
    required this.objectSetId,
    this.exampleSentence,
    this.dialectVariants = const [],
    this.nounClass,
    required this.audio,
    this.showsAiDraftBadge = false,
  });

  final String lexemeId;
  final String language;
  final String word;
  final String objectSetId;
  final String? exampleSentence;
  final List<LensDialectVariant> dialectVariants;
  final LensNounClassInfo? nounClass;
  final LensWordCardAudio audio;
  final bool showsAiDraftBadge;
}
