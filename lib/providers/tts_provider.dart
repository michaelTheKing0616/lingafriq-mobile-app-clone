import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/voice/voice_api_service.dart';
import 'base_provider.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

class TTSProvider extends BaseProvider {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  @override
  BaseProviderState build() {
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

      final bytes = await ref.read(voiceApiServiceProvider).synthesizeSpeech(
            text: normalizedText,
            language: languageName.trim().toLowerCase(),
            voice: voice,
            speed: speed,
          );

      if (bytes == null || bytes.isEmpty) {
        debugPrint('TTS: empty audio for language=$languageName');
        return;
      }

      await _player.setAudioSource(_BytesAudioSource(bytes));
      await _player.play();
      _isSpeaking = true;
    } catch (e) {
      debugPrint('TTS speak error: $e');
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

  @override
  void dispose() {
    unawaited(_playerSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
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
