// Modulates TTS parameters based on emotional content for persona voice.

import 'package:lingafriq/services/voice/persona_voice_profile.dart';

enum VoiceEmotion {
  calm,
  reflective,
  passionate,
  firm,
  joyful,
  solemn,
  urgent,
}

/// TTS parameter adjustments for a detected emotion (additive/multiplicative to base).
class EmotionVoiceParams {
  final double pitchAdjust;
  final double speedAdjust;
  final int pauseAdjustMs;
  final double volumeAdjust;

  const EmotionVoiceParams({
    this.pitchAdjust = 0.0,
    this.speedAdjust = 0.0,
    this.pauseAdjustMs = 0,
    this.volumeAdjust = 1.0,
  });
}

/// Detects emotion from text and persona tone, and applies emotion-based TTS adjustments.
class EmotionVoiceModulator {
  EmotionVoiceModulator._();

  static final _struggle = RegExp(
    r'\b(struggle|fight|resist|resist|defy|rebel)\b',
    caseSensitive: false,
  );
  static final _reflect = RegExp(
    r'\b(remember|reflect|once|long ago|back then)\b',
    caseSensitive: false,
  );
  static final _peace = RegExp(
    r'\b(peace|hope|together|unity|ubuntu)\b',
    caseSensitive: false,
  );
  static final _demand = RegExp(
    r'\b(must|demand|never|always|justice)\b',
    caseSensitive: false,
  );
  static final _sorrow = RegExp(
    r'\b(lost|sacrifice|fallen|mourn|honor)\b',
    caseSensitive: false,
  );
  static final _urgent = RegExp(
    r'\b(now|urgent|quick|immediately|hurry)\b',
    caseSensitive: false,
  );
  static final _joy = RegExp(
    r'\b(joy|celebrate|freedom|victory|proud)\b',
    caseSensitive: false,
  );

  /// Detect emotion from [text] with [personaTone] as baseline when no strong signal.
  static VoiceEmotion detectEmotion(String text, String personaTone) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty) return _toneToEmotion(personaTone);

    if (_struggle.hasMatch(lower) || _demand.hasMatch(lower)) {
      if (_urgent.hasMatch(lower)) return VoiceEmotion.urgent;
      return VoiceEmotion.passionate;
    }
    if (_reflect.hasMatch(lower)) return VoiceEmotion.reflective;
    if (_peace.hasMatch(lower) || _joy.hasMatch(lower)) return VoiceEmotion.joyful;
    if (_sorrow.hasMatch(lower)) return VoiceEmotion.solemn;
    if (_demand.hasMatch(lower)) return VoiceEmotion.firm;
    if (_urgent.hasMatch(lower)) return VoiceEmotion.urgent;

    return _toneToEmotion(personaTone);
  }

  static VoiceEmotion _toneToEmotion(String tone) {
    final t = tone.toLowerCase();
    if (t.contains('passionate') || t.contains('emphatic')) return VoiceEmotion.passionate;
    if (t.contains('authoritative') || t.contains('firm')) return VoiceEmotion.firm;
    if (t.contains('reflective') || t.contains('calm')) return VoiceEmotion.reflective;
    if (t.contains('solemn') || t.contains('dignified')) return VoiceEmotion.solemn;
    if (t.contains('warm') || t.contains('joyful')) return VoiceEmotion.joyful;
    return VoiceEmotion.calm;
  }

  /// TTS parameter adjustments for [emotion].
  static EmotionVoiceParams getParams(VoiceEmotion emotion) {
    switch (emotion) {
      case VoiceEmotion.calm:
        return const EmotionVoiceParams();
      case VoiceEmotion.reflective:
        return const EmotionVoiceParams(
          pitchAdjust: 0.0,
          speedAdjust: -0.10,
          pauseAdjustMs: 80,
          volumeAdjust: 1.0,
        );
      case VoiceEmotion.passionate:
        return const EmotionVoiceParams(
          pitchAdjust: 0.3,
          speedAdjust: 0.10,
          pauseAdjustMs: -30,
          volumeAdjust: 1.0,
        );
      case VoiceEmotion.firm:
        return const EmotionVoiceParams(
          pitchAdjust: -0.2,
          speedAdjust: -0.05,
          pauseAdjustMs: -40,
          volumeAdjust: 1.0,
        );
      case VoiceEmotion.joyful:
        return const EmotionVoiceParams(
          pitchAdjust: 0.2,
          speedAdjust: 0.05,
          pauseAdjustMs: 0,
          volumeAdjust: 1.0,
        );
      case VoiceEmotion.solemn:
        return const EmotionVoiceParams(
          pitchAdjust: -0.5,
          speedAdjust: -0.15,
          pauseAdjustMs: 120,
          volumeAdjust: 1.0,
        );
      case VoiceEmotion.urgent:
        return const EmotionVoiceParams(
          pitchAdjust: 0.5,
          speedAdjust: 0.15,
          pauseAdjustMs: -60,
          volumeAdjust: 1.0,
        );
    }
  }

  /// Apply [emotion] adjustments to [base] and return a new [PersonaVoiceProfile].
  static PersonaVoiceProfile applyEmotion(PersonaVoiceProfile base, VoiceEmotion emotion) {
    final p = getParams(emotion);
    final newPitch = (base.pitch + p.pitchAdjust).clamp(-2.0, 2.0);
    final newSpeed = (base.speed + p.speedAdjust).clamp(0.5, 1.5);
    final newPause = (base.pauseAfterSentenceMs + p.pauseAdjustMs).clamp(100, 1200);
    return base.copyWith(
      pitch: newPitch,
      speed: newSpeed,
      pauseAfterSentenceMs: newPause,
    );
  }
}
