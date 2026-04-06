import 'dart:async';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/voice/voice_api_service.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

/// Server-only African TTS (MMS via Node → Python). **No** on-device `flutter_tts`.
class TTSProvider extends BaseProvider {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// For UI (e.g. [TtsPlayButton]) to show stop while audio is active.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  BaseProviderState build() {
    ref.onDispose(() {
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

  /// Speak text using the backend MMS-TTS pipeline only (no device fallback).
  /// Returns `true` if playback started, `false` on failure.
  ///
  /// - **languageName**: e.g. "yoruba", "hausa", "igbo", "swahili", "english"
  Future<bool> speak(
    String text, {
    String languageName = 'english',
    String? voice,
    double speed = 1.0,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return false;

    try {
      await stop();

      final bytes = await ref.read(voiceApiServiceProvider).synthesizeSpeech(
            text: normalizedText,
            language: languageName.trim().toLowerCase(),
            voice: voice,
            speed: speed,
          );

      if (bytes == null || bytes.isEmpty) {
        logger.error(
          'TTS: empty audio from server (no device fallback)',
          tag: 'tts',
          context: {'language': languageName},
        );
        return false;
      }

      await _player.setAudioSource(_BytesAudioSource(bytes));
      await _player.play();
      _isSpeaking = true;
      return true;
    } catch (e, st) {
      logger.error('TTS speak error', tag: 'tts', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _isSpeaking = false;
    } catch (_) {
      // ignore
    }
  }

  Future<void> cleanup() async {
    await _playerSub?.cancel();
    await _player.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _data;
  final String _contentType;

  _BytesAudioSource(this._data, {String contentType = 'audio/wav'})
      : _contentType = contentType;

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
