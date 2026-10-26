/// CP-§7-08 / P5-075: Polie and persona speech keeps server TTS permanently, labelled.
library;

import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/content_label_badge.dart';

/// Sources whose audio is always synthesized (never replaced by native recordings).
enum DynamicSpeechSource {
  polie,
  persona,
}

/// Matches publish gate and [audioKindShowsSyntheticTag] (P5-058 / P5-010).
const dynamicSpeechAudioKind = 'tts_synthetic';

/// Visible copy on item audio; kept in sync with backend [SYNTHETIC_VOICE_TAG].
const dynamicSpeechSyntheticVoiceTag = 'Synthetic voice';

/// Whether [source] is Polie or a historical persona turn (dynamic, not curriculum items).
bool isDynamicSpeechSource(DynamicSpeechSource? source) => source != null;

/// Curriculum native-replacement (CP-§7-07) never applies to dynamic speech (AC1).
bool dynamicSpeechEligibleForNativeReplacement(DynamicSpeechSource source) =>
    false;

/// Dynamic clips always route through licensed server TTS — no bundled human lookup (AC1).
bool dynamicSpeechUsesPermanentServerTts(DynamicSpeechSource? source) =>
    isDynamicSpeechSource(source);

/// Audio metadata kind for honesty surfaces and gates.
String? dynamicSpeechAudioKindFor(DynamicSpeechSource? source) {
  if (!isDynamicSpeechSource(source)) {
    return null;
  }
  return dynamicSpeechAudioKind;
}

/// Synthetic tag is always required when dynamic speech is shown (AC2).
bool dynamicSpeechShowsSyntheticTag(DynamicSpeechSource? source) =>
    isDynamicSpeechSource(source);

bool dynamicSpeechSyntheticTagMatchesGate(String tag) =>
    tag.trim() == dynamicSpeechSyntheticVoiceTag;

/// Label chip for Polie / persona playback surfaces (AC2).
class DynamicTtsHonestyLabel extends StatelessWidget {
  const DynamicTtsHonestyLabel({
    super.key,
    required this.source,
  });

  final DynamicSpeechSource source;

  @override
  Widget build(BuildContext context) {
    if (!dynamicSpeechShowsSyntheticTag(source)) {
      return const SizedBox.shrink();
    }
    return const SyntheticVoiceTag();
  }
}
