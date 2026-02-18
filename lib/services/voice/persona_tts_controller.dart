// Persona-aware TTS controller: wraps TTS with historical persona voice constraints and streaming.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/services/enhanced_tts_service.dart';
import 'package:lingafriq/services/voice/persona_voice_profile.dart';
import 'package:lingafriq/services/voice/phrase_chunker.dart';
import 'package:lingafriq/services/voice/emotion_voice_modulator.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Persona-aware TTS: applies persona voice profile and supports streaming + interrupt.
class PersonaTtsController {
  PersonaTtsController({EnhancedTTSService? enhancedTts})
      : _enhancedTts = enhancedTts;

  final EnhancedTTSService? _enhancedTts;
  PersonaVoiceProfile? _activeProfile;
  bool _isInterrupted = false;
  final List<String> _speechQueue = [];
  StreamSubscription<String>? _streamSub;
  bool _isDisposed = false;

  PersonaVoiceProfile? get activeProfile => _activeProfile;
  bool get isInterrupted => _isInterrupted;

  /// Set active persona by id; loads profile from registry.
  Future<void> setPersona(String personaId) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona != null) {
      _activeProfile = PersonaVoiceProfile.fromPersona(persona);
      if (kDebugMode) {
        logger.debug('Persona TTS profile set', context: {'personaId': personaId});
      }
    } else {
      _activeProfile = null;
    }
  }

  /// Speak a complete text with persona voice (or default if no persona).
  Future<void> speak(String text) async {
    if (_isDisposed || _enhancedTts == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isInterrupted = false;
    final profile = _activeProfile;
    final config = profile?.toTTSConfig() ?? TTSConfig(speed: 1.0, pitch: 1.0);
    try {
      await _enhancedTts!.speak(trimmed, config);
    } catch (e) {
      logger.error('Persona TTS speak failed', error: e);
    }
  }

  /// Stream speech from text chunks (e.g. streaming AI response).
  /// Chunks are split into phrases via [PhraseChunker], then spoken sequentially.
  /// Respects [interrupt] between chunks.
  Future<void> speakStreaming(Stream<String> textStream) async {
    if (_isDisposed || _enhancedTts == null) return;

    _isInterrupted = false;
    _speechQueue.clear();
    final chunker = PhraseChunker();
    final profile = _activeProfile;
    final baseConfig = profile?.toTTSConfig() ?? TTSConfig(speed: 1.0, pitch: 1.0);
    final pauseAfterSentenceMs = profile?.pauseAfterSentenceMs ?? 400;

    await _streamSub?.cancel();
    _streamSub = textStream.listen(
      (String newText) async {
        if (_isInterrupted || _isDisposed) return;
        final chunks = chunker.addText(newText);
        for (final c in chunks) {
          if (_isInterrupted || _isDisposed) break;
          final emotion = EmotionVoiceModulator.detectEmotion(c.text, profile?.emotionProfile ?? 'calm');
          final adjustedProfile = profile != null
              ? EmotionVoiceModulator.applyEmotion(profile, emotion)
              : null;
          final config = adjustedProfile?.toTTSConfig() ?? baseConfig;
          final phrase = c.text.trim();
          if (phrase.isEmpty) continue;
          try {
            await _enhancedTts!.speak(phrase, config);
            if (_isInterrupted || _isDisposed) break;
            if (c.isSentenceEnd && pauseAfterSentenceMs > 0) {
              await Future<void>.delayed(Duration(milliseconds: pauseAfterSentenceMs));
            }
          } catch (e) {
            logger.error('Persona TTS streaming chunk failed', error: e);
          }
        }
      },
      onError: (e) => logger.error('Persona TTS stream error', error: e),
      onDone: () async {
        final remaining = chunker.flush();
        if (remaining != null && remaining.text.trim().isNotEmpty && !_isInterrupted && !_isDisposed) {
          try {
            await _enhancedTts!.speak(remaining.text.trim(), baseConfig);
          } catch (e) {
            logger.error('Persona TTS flush speak failed', error: e);
          }
        }
        await _streamSub?.cancel();
        _streamSub = null;
      },
      cancelOnError: false,
    );
  }

  /// Interrupt current and queued speech; clear queue and stop audio.
  void interrupt() {
    _isInterrupted = true;
    _speechQueue.clear();
    _enhancedTts?.stop();
  }

  /// Clear interrupt flag so next speak/speakStreaming can run.
  void resume() {
    _isInterrupted = false;
  }

  void dispose() {
    _isDisposed = true;
    _isInterrupted = true;
    _speechQueue.clear();
    _streamSub?.cancel();
    _streamSub = null;
  }
}
