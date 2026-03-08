import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Pronunciation Score from voice analysis
class PronunciationScore {
  final double overall;
  final double phonemeAccuracy;
  final double toneAccuracy;
  final double fluency;
  final double confidence;
  final String feedbackText;
  final List<String> improvementTips;
  final List<Map<String, dynamic>> problemSegments;

  PronunciationScore({
    required this.overall,
    required this.phonemeAccuracy,
    required this.toneAccuracy,
    required this.fluency,
    required this.confidence,
    required this.feedbackText,
    required this.improvementTips,
    required this.problemSegments,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> json) {
    return PronunciationScore(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      phonemeAccuracy: (json['phoneme_accuracy'] as num?)?.toDouble() ?? 0.0,
      toneAccuracy: (json['tone_accuracy'] as num?)?.toDouble() ?? 0.0,
      fluency: (json['fluency'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      feedbackText: json['feedback_text'] as String? ?? '',
      improvementTips: List<String>.from(json['improvement_tips'] ?? []),
      problemSegments: List<Map<String, dynamic>>.from(json['problem_segments'] ?? []),
    );
  }

  bool get passed => overall >= 0.6;
  
  String get grade {
    if (overall >= 0.9) return 'A+';
    if (overall >= 0.8) return 'A';
    if (overall >= 0.7) return 'B';
    if (overall >= 0.6) return 'C';
    if (overall >= 0.5) return 'D';
    return 'F';
  }
}

/// Voice Lesson model
class VoiceLesson {
  final String id;
  final int number;
  final int phase;
  final String title;
  final String description;
  final String goal;
  final int durationMinutes;
  final Map<String, dynamic> content;

  VoiceLesson({
    required this.id,
    required this.number,
    required this.phase,
    required this.title,
    required this.description,
    required this.goal,
    required this.durationMinutes,
    required this.content,
  });

  factory VoiceLesson.fromJson(Map<String, dynamic> json) {
    return VoiceLesson(
      id: json['id'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      phase: json['phase'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 5,
      content: json['content'] as Map<String, dynamic>? ?? {},
    );
  }

  String get phaseTitle {
    switch (phase) {
      case 1:
        return 'Foundations';
      case 2:
        return 'Controlled Speaking';
      case 3:
        return 'Real Speech';
      default:
        return 'Phase $phase';
    }
  }
}

/// Difficulty Recommendation
class DifficultyRecommendation {
  final int recommendedLevel;
  final double confidence;
  final String reasoning;
  final List<String> focusAreas;
  final String suggestedContentType;

  DifficultyRecommendation({
    required this.recommendedLevel,
    required this.confidence,
    required this.reasoning,
    required this.focusAreas,
    required this.suggestedContentType,
  });

  factory DifficultyRecommendation.fromJson(Map<String, dynamic> json) {
    return DifficultyRecommendation(
      recommendedLevel: json['recommended_level'] as int? ?? 1,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reasoning: json['reasoning'] as String? ?? '',
      focusAreas: List<String>.from(json['focus_areas'] ?? []),
      suggestedContentType: json['suggested_content_type'] as String? ?? 'word',
    );
  }
}

/// Voice API Service Provider
final voiceApiServiceProvider = Provider<VoiceApiService>((ref) {
  return VoiceApiService(ref);
});

/// Voice API Service
/// 
/// Handles all voice-related API calls:
/// - Speech-to-Text transcription
/// - Text-to-Speech synthesis
/// - Pronunciation analysis
/// - Voice lesson management
class VoiceApiService {
  final Ref _ref;

  VoiceApiService(this._ref);

  Dio get _dio => _ref.read(client);

  // ============================================
  // SPEECH-TO-TEXT
  // ============================================

  /// Transcribe audio file to text
  Future<Map<String, dynamic>?> transcribeAudio({
    required String audioPath,
    String? language,
    String task = 'transcribe',
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $audioPath');
        return null;
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'audio.wav',
        ),
        if (language != null) 'language': language,
        'task': task,
      });

    final response = await _dio.post(
      ApiContract.url(ApiContract.voice.sttTranscribe),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
    }
    return null;
  }

  /// Transcribe audio bytes to text
  Future<Map<String, dynamic>?> transcribeAudioBytes({
    required Uint8List audioBytes,
    String? language,
    String task = 'transcribe',
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audioBytes,
          filename: 'audio.wav',
        ),
        if (language != null) 'language': language,
        'task': task,
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.sttTranscribe),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
    }
    return null;
  }

  /// Get supported STT languages
  Future<List<String>> getSupportedSTTLanguages() async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.voice.sttLanguages));
      if (response.statusCode == 200) {
        return List<String>.from(response.data['languages'] ?? []);
      }
    } catch (e) {
      debugPrint('Error getting STT languages: $e');
    }
    return ['yoruba', 'swahili', 'hausa', 'igbo', 'english'];
  }

  // ============================================
  // TEXT-TO-SPEECH
  // ============================================

  /// Synthesize text to speech
  Future<Uint8List?> synthesizeSpeech({
    required String text,
    required String language,
    String? voice,
    double speed = 1.0,
  }) async {
    try {
      final normalizedLanguage = _normalizeLanguage(language);
      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.ttsSynthesize),
        data: {
          'text': text,
          'language': normalizedLanguage,
          if (voice != null) 'voice': voice,
          'speed': speed,
          'provider_priority': _providerPriorityFor(normalizedLanguage),
          'accent_profile': _accentProfileFor(normalizedLanguage),
          'model_tier': 'free_best',
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      debugPrint('TTS error: $e');
    }
    return null;
  }

  /// Get supported TTS languages
  Future<List<String>> getSupportedTTSLanguages() async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.voice.ttsLanguages));
      if (response.statusCode == 200) {
        return List<String>.from(response.data['languages'] ?? []);
      }
    } catch (e) {
      debugPrint('Error getting TTS languages: $e');
    }
    return ['yoruba', 'swahili', 'hausa', 'english'];
  }

  // ============================================
  // PRONUNCIATION ANALYSIS
  // ============================================

  /// Analyze pronunciation of recorded audio
  Future<PronunciationScore?> analyzePronunciation({
    required String audioPath,
    required String expectedText,
    required String language,
    String? referenceAudioPath,
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $audioPath');
        return null;
      }

      final formData = FormData.fromMap({
        'learner_audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'learner.wav',
        ),
        'expected_text': expectedText,
        'language': language,
      });

      if (referenceAudioPath != null) {
        final refFile = File(referenceAudioPath);
        if (await refFile.exists()) {
          formData.files.add(MapEntry(
            'reference_audio',
            await MultipartFile.fromFile(
              referenceAudioPath,
              filename: 'reference.wav',
            ),
          ));
        }
      }

      final response = await _dio.post(
        ApiContract.url(ApiContract.pronunciation.analyze),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return PronunciationScore.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Pronunciation analysis error: $e');
    }
    return null;
  }

  /// Quick pronunciation check
  Future<Map<String, dynamic>?> quickPronunciationCheck({
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final formData = FormData.fromMap({
        'learner_audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'audio.wav',
        ),
        'expected_text': expectedText,
        'language': language,
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.pronunciation.quick),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Quick pronunciation check error: $e');
    }
    return null;
  }

  /// Analyze tone patterns
  Future<Map<String, dynamic>?> analyzeTones({
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'audio.wav',
        ),
        'expected_text': expectedText,
        'language': language,
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.pronunciation.tone),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Tone analysis error: $e');
    }
    return null;
  }

  /// Get difficulty recommendation for user
  Future<DifficultyRecommendation?> getDifficultyRecommendation({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.pronunciation.difficulty(userId, language),
        ),
      );

      if (response.statusCode == 200) {
        return DifficultyRecommendation.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Difficulty recommendation error: $e');
    }
    return null;
  }

  /// Get learner pronunciation profile
  Future<Map<String, dynamic>?> getLearnerProfile({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.pronunciation.profile(userId, language),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Learner profile error: $e');
    }
    return null;
  }

  // ============================================
  // VOICE LESSONS
  // ============================================

  /// Get voice lessons for a language
  Future<List<VoiceLesson>> getVoiceLessons({
    required String language,
    int? phase,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        if (phase != null) 'phase': phase,
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.voice.lessons),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final lessons = response.data['lessons'] as List?;
        if (lessons != null) {
          return lessons
              .map((l) => VoiceLesson.fromJson(l as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Get voice lessons error: $e');
    }
    return [];
  }

  /// Get specific lesson
  Future<VoiceLesson?> getVoiceLesson({
    required String lessonId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.voice.lesson(lessonId)),
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        return VoiceLesson.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Get voice lesson error: $e');
    }
    return null;
  }

  /// Get user's lesson progress
  Future<Map<String, dynamic>?> getLessonProgress({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.voice.lessonsProgress(userId, language),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Get lesson progress error: $e');
    }
    return null;
  }

  /// Update lesson progress
  Future<bool> updateLessonProgress({
    required String userId,
    required String lessonId,
    required bool completed,
    required double score,
    int attempts = 1,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.lessonsProgressUpdate),
        data: {
          'user_id': userId,
          'lesson_id': lessonId,
          'completed': completed,
          'score': score,
          'attempts': attempts,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update lesson progress error: $e');
    }
    return false;
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  /// Check voice service health
  Future<bool> checkVoiceServiceHealth() async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.voice.health),
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200 && 
             response.data['status'] == 'healthy';
    } catch (e) {
      debugPrint('Voice service health check failed: $e');
    }
    return false;
  }

  String _normalizeLanguage(String language) {
    final key = language.trim().toLowerCase().replaceAll('-', '_');
    const aliases = {
      'yo': 'yoruba',
      'ha': 'hausa',
      'ig': 'igbo',
      'sw': 'swahili',
      'zu': 'zulu',
      'xh': 'xhosa',
      'am': 'amharic',
      'so': 'somali',
      'af': 'afrikaans',
      'wo': 'wolof',
      'tw': 'twi',
      'pcm': 'pidgin',
      'en': 'english',
      'en_us': 'english',
      'en_gb': 'english',
    };
    return aliases[key] ?? key;
  }

  List<String> _providerPriorityFor(String language) {
    if (language == 'english') {
      return const ['xtts_v2', 'piper', 'mms_tts'];
    }
    return const ['xtts_v2', 'mms_tts', 'piper'];
  }

  String _accentProfileFor(String language) {
    const accents = {
      'yoruba': 'yo-NG',
      'hausa': 'ha-NG',
      'igbo': 'ig-NG',
      'swahili': 'sw-KE',
      'zulu': 'zu-ZA',
      'xhosa': 'xh-ZA',
      'amharic': 'am-ET',
      'somali': 'so-SO',
      'afrikaans': 'af-ZA',
      'wolof': 'wo-SN',
      'twi': 'tw-GH',
      'pidgin': 'pcm-NG',
      'english': 'en-AF',
    };
    return accents[language] ?? language;
  }
}

