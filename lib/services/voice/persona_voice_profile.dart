// Persona voice profile: TTS parameters derived from HistoricalPersona.

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/services/enhanced_tts_service.dart';

/// TTS parameters derived from a historical persona's voice traits.
class PersonaVoiceProfile {
  final String personaId;
  /// Pitch adjustment: -2 (low) to 2 (high). Maps to TTS 0.5–2.0 via 1.0 + pitch * 0.5.
  final double pitch;
  /// Speech rate: 0.5–1.5 (slow to fast).
  final double speed;
  /// Pause in ms after sentence end (from pace/intonation).
  final int pauseAfterSentenceMs;
  final String emotionProfile;

  const PersonaVoiceProfile({
    required this.personaId,
    this.pitch = 0.0,
    this.speed = 1.0,
    this.pauseAfterSentenceMs = 400,
    this.emotionProfile = 'calm',
  });

  /// Build a voice profile from a [HistoricalPersona].
  factory PersonaVoiceProfile.fromPersona(HistoricalPersona persona) {
    final pace = persona.pace.toLowerCase();
    final speed = pace == 'slow'
        ? 0.85
        : pace == 'fast'
            ? 1.15
            : 1.0;

    final style = persona.voiceStyle.toLowerCase();
    double pitch = 0.0;
    if (style.contains('deep') || style.contains('calm') || style.contains('dignified')) {
      pitch = -1.5;
    } else if (style.contains('commanding') || style.contains('authoritative')) {
      pitch = -0.5;
    } else if (style.contains('warm') || style.contains('musical') || style.contains('expressive')) {
      pitch = 0.3;
    } else if (style.contains('passionate') || style.contains('emphatic')) {
      pitch = 0.5;
    } else if (style.contains('reflective') || style.contains('melodic')) {
      pitch = 0.2;
    }

    final intonation = persona.intonation.toLowerCase();
    int pauseMs = 400;
    if (intonation.contains('measured') || intonation.contains('deliberate') || intonation.contains('steady')) {
      pauseMs = 550;
    } else if (intonation.contains('assertive') || intonation.contains('emphatic') || intonation.contains('commanding')) {
      pauseMs = 280;
    } else if (intonation.contains('calm') || intonation.contains('dignified')) {
      pauseMs = 450;
    }

    final emotionProfile = persona.emotionRange.isNotEmpty
        ? persona.emotionRange.first
        : (persona.tone.isNotEmpty ? persona.tone : 'calm');

    return PersonaVoiceProfile(
      personaId: persona.id,
      pitch: pitch.clamp(-2.0, 2.0),
      speed: speed.clamp(0.5, 1.5),
      pauseAfterSentenceMs: pauseMs.clamp(100, 1200),
      emotionProfile: emotionProfile,
    );
  }

  /// Convert to [TTSConfig] for [EnhancedTTSService]. Pitch -2..2 → 0.5..2.0.
  TTSConfig toTTSConfig({String? language}) {
    final ttsPitch = (1.0 + pitch * 0.5).clamp(0.5, 2.0);
    return TTSConfig(
      speed: speed,
      pitch: ttsPitch,
      language: language,
      enableCache: true,
    );
  }

  PersonaVoiceProfile copyWith({
    String? personaId,
    double? pitch,
    double? speed,
    int? pauseAfterSentenceMs,
    String? emotionProfile,
  }) {
    return PersonaVoiceProfile(
      personaId: personaId ?? this.personaId,
      pitch: pitch ?? this.pitch,
      speed: speed ?? this.speed,
      pauseAfterSentenceMs: pauseAfterSentenceMs ?? this.pauseAfterSentenceMs,
      emotionProfile: emotionProfile ?? this.emotionProfile,
    );
  }
}
