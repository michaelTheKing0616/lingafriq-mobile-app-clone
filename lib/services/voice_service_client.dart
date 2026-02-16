import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/api.dart';

/// Voice Service Client - Handles TTS, STT, and pronunciation analysis
/// Uses intelligent language-based routing for authentic African language pronunciation
class VoiceServiceClient {
  final Dio _dio;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _voiceServiceBaseUrl;

  VoiceServiceClient({Dio? dio, String? voiceServiceBaseUrl})
      : _dio = dio ?? Dio(),
        _voiceServiceBaseUrl = voiceServiceBaseUrl {
    // Default to backend API which proxies to voice service
    _voiceServiceBaseUrl ??= Api.baseurl;
  }

  /// Synthesize speech with intelligent language routing
  /// Automatically routes to appropriate MMS-TTS model based on language
  /// 
  /// Example:
  /// ```dart
  /// await voiceClient.synthesize(
  ///   text: "Ẹ káàbọ̀",  // Yoruba greeting
  ///   language: "yoruba",
  /// );
  /// ```
  Future<void> synthesize({
    required String text,
    required String language,
    Function()? onComplete,
    Function(Object error)? onError,
  }) async {
    if (text.isEmpty) return;

    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Use backend API which proxies to voice service
      // The backend will route to appropriate MMS-TTS model based on language
      final response = await _dio.post(
        '${_voiceServiceBaseUrl}api/voice/tts/synthesize',
        data: FormData.fromMap({
          'text': text,
          'language': language.toLowerCase(),
        }),
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TTS synthesis failed: ${response.statusCode}');
      }

      // Get audio bytes from response
      final audioBytes = response.data as List<int>;
      
      // Play audio
      await _audioPlayer.setAudioSource(
        LockCachingAudioSource(Uri.dataFromBytes(
          Uint8List.fromList(audioBytes),
          mimeType: 'audio/wav',
        )),
      );
      
      await _audioPlayer.play();
      
      // Wait for playback to complete
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          onComplete?.call();
        }
      }).onError((error) {
        onError?.call(error);
      });
      
    } catch (e) {
      debugPrint('Error synthesizing speech: $e');
      onError?.call(e);
      rethrow;
    }
  }

  /// Stop current speech playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

