import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/voice/voice_api_service.dart';
import '../services/voice/voice_language_utils.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

class TTSProvider extends BaseProvider {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  @override
  BaseProviderState build() {
    // Notifier has no dispose(); register cleanup via ref.onDispose instead.
    ref.onDispose(() {
      // Best-effort cleanup (don't throw during dispose).
      cleanup();
    });

    _playerSub ??= _player.playerStateStream.listen((state) {
      final nowSpeaking =
          state.playing && state.processingState != ProcessingState.completed;
      if (_isSpeaking != nowSpeaking) {
        _isSpeaking = nowSpeaking;
      }
      if (state.processingState == ProcessingState.completed) {
        _isSpeaking = false;
      }
    });
    return super.build();
  }

  /// Speak text using the backend voice service (MMS-TTS routing).
  ///
  /// - **languageName**: e.g. "yoruba", "hausa", "igbo", "swahili", "english"
  Future<void> speak(
    String text, {
    String languageName = 'english',
    String? voice,
    double speed = 1.0,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    try {
      await stop();

      Uint8List? bytes;
      try {
        bytes = await ref.read(voiceApiServiceProvider).synthesizeSpeech(
              text: normalizedText,
              language: languageName.trim().toLowerCase(),
              voice: voice,
              speed: speed,
            );
      } catch (e) {
        logger.error('TTS API error', tag: 'tts', error: e);
      }

      if (bytes != null && bytes.isNotEmpty) {
        await _player.setAudioSource(_BytesAudioSource(bytes));
        await _player.play();
        _isSpeaking = true;
        return;
      }

      logger.warn(
        'TTS: empty or missing audio, using device TTS',
        tag: 'tts',
        context: {'language': languageName},
      );
      await _speakWithDeviceTts(normalizedText, languageName);
    } catch (e) {
      logger.error('TTS speak error', tag: 'tts', error: e);
      await _speakWithDeviceTts(normalizedText, languageName);
    }
  }

  Future<void> _ensureFlutterTts() async {
    if (_flutterTts != null) return;
    final tts = FlutterTts();
    tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts = tts;
  }

  Future<void> _speakWithDeviceTts(String text, String languageHint) async {
    try {
      await _ensureFlutterTts();
      final normalized = normalizeVoiceLanguage(languageHint);
      final locale = systemTtsLocaleForNormalized(normalized);
      await _flutterTts!.stop();
      await _flutterTts!.setLanguage(locale);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setSpeechRate(0.45);
      _isSpeaking = true;
      await _flutterTts!.speak(text);
    } catch (e) {
      _isSpeaking = false;
      logger.error('Device TTS failed', tag: 'tts', error: e);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
      _isSpeaking = false;
    } catch (_) {
      // ignore
    }
  }

  /// Clean up resources
  /// Note: Notifier providers don't have a dispose method in Riverpod 2.0
  /// Resources are cleaned up when the provider is no longer referenced
  /// This method can be called manually if needed
  Future<void> cleanup() async {
    await _playerSub?.cancel();
    _playerSub = null;
    await _player.dispose();
    if (_flutterTts != null) {
      await _flutterTts!.stop();
      _flutterTts = null;
    }
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _data;
  final String _contentType;

  _BytesAudioSource(this._data, {String? contentType})
      : _contentType = contentType ?? _detectContentType(_data);

  static String _detectContentType(Uint8List data) {
    if (data.length >= 3 &&
        data[0] == 0x49 &&
        data[1] == 0x44 &&
        data[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (data.length >= 4 &&
        data[0] == 0xFF &&
        (data[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x41 &&
        data[10] == 0x56 &&
        data[11] == 0x45) {
      return 'audio/wav';
    }
    if (data.length >= 4 &&
        data[0] == 0x4F &&
        data[1] == 0x67 &&
        data[2] == 0x67 &&
        data[3] == 0x53) {
      return 'audio/ogg';
    }
    return 'audio/wav';
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final safeStart = start ?? 0;
    final safeEnd = end ?? _data.length;

    final clippedStart = safeStart.clamp(0, _data.length);
    final clippedEnd = safeEnd.clamp(clippedStart, _data.length);

    return StreamAudioResponse(
      sourceLength: _data.length,
      contentLength: clippedEnd - clippedStart,
      offset: clippedStart,
      stream: Stream.value(_data.sublist(clippedStart, clippedEnd)),
      contentType: _contentType,
    );
  }
}
