import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio/african_tts_service.dart';
import '../services/audio/african_tts_bootstrap.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

/// Unified African-accented TTS for the entire app (games, tutor, vocab, Polie).
///
/// Resolves audio via [AfricanTtsService] (Gold → Silver → Bronze) and plays
/// through [AudioPlayer] so existing widgets keep a single playback stream.
class TTSProvider extends BaseProvider {
  final AfricanTtsService _african = AfricanTtsService();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  BaseProviderState build() {
    ref.onDispose(() {
      cleanup();
    });

    _playerSub ??= _player.playerStateStream.listen((state) {
      final nowSpeaking =
          state.playing && state.processingState != ProcessingState.completed;
      _isSpeaking = nowSpeaking;
      if (state.processingState == ProcessingState.completed) {
        _isSpeaking = false;
      }
    });

    unawaited(AfricanTtsBootstrap.ensureManifestLoaded());
    return super.build();
  }

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
      await AfricanTtsBootstrap.ensureManifestLoaded();

      final resolution = await _african.resolve(
        language: languageName.trim(),
        text: normalizedText,
        speed: speed,
        voice: voice,
      );

      if (resolution.tier == TtsEngineTier.unavailable) {
        logger.error(
          'TTS unavailable',
          tag: 'tts',
          context: {
            'language': languageName,
            'reason': resolution.errorReason,
          },
        );
        return false;
      }

      if (resolution.tier == TtsEngineTier.deviceFallback) {
        await _african.speak(
          language: languageName,
          text: normalizedText,
          speed: speed,
          voice: voice,
        );
        _isSpeaking = true;
        return true;
      }

      if (resolution.localFile != null) {
        await _player.setFilePath(resolution.localFile!.path);
      } else if (resolution.cdnUrl != null) {
        await _player.setUrl(resolution.cdnUrl!);
      } else {
        return false;
      }

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
      await _african.stop();
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
