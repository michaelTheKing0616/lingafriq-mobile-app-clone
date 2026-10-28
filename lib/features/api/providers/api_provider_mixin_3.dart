import 'package:lingafriq/features/api/providers/api_provider_helpers.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/history/models/history_response.dart';
import 'package:lingafriq/history/models/section_history_model.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_lesson_model.dart';
import 'package:lingafriq/mannerisms/models/mannerism_response.dart';
import 'package:lingafriq/mannerisms/models/mannerism_tutorial_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/models/profiles_response.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/random_quiz/models/random_quiz_lesson_model.dart';
import 'package:lingafriq/services/auth_token_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_response.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_lesson_model.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_response.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/models/user.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import 'package:lingafriq/features/api/providers/api_provider_mixin_2.dart';

mixin ApiProviderMixin3 on ApiProviderMixin2 {
  Future<List<SectionHistoryModel>> getSectionHistory(int historyId) async {
    try {
      final res = await ref.read(client).get(Api.sectionHistoryList(historyId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;
      final dataList = <Map<String, dynamic>>[];
      //Flat List Loop
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }

      //LessonType Cast Loop
      final mappedLessonsList = dataList.map((lesson) {
        if (lesson.containsKey("types")) {
          return SectionHistoryModel(
            id: lesson['id'],
            title: lesson.containsKey("title") ? lesson['title'] : lesson['text'],
            score: lesson['score'],
            types: lesson['types'],
            dateTime: lesson['date_time'],
            completed: lesson['completed'],
            completed_by: lesson['completed_by'],
            otherData: lesson,
          );
        }

        final quiz = lesson['quiz'].first;
        late final int quizId;
        if (quiz['quiz_type'] == "Instant Quiz") {
          quizId = lesson['question'].first['question']['quize_history'];
        } else {
          quizId = lesson['word_question'].first.first['quize_history'];
        }
        // quiz.toString().log();
        // // final int quizId;
        // final quizId = lesson['question'].first['question']['quize_history'];
        return SectionHistoryModel(
          id: quizId,
          title: quiz['quiz'],
          score: quiz['score'],
          types: quiz['quiz_type'],
          dateTime: quiz['date_time'],
          completed: quiz['completed'],
          completed_by: quiz['completed_by'],
          otherData: lesson,
        );
        // }
      }).toList();
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * History Section End
  * 
  */

  Future<bool> markAsComplete(String endpointToHit) async {
    logger.debug('Marking content as complete', context: {'endpoint': endpointToHit});
    try {
      state = state.copyWith(isLoading: true);
      final raw = endpointToHit.trim();
      final isAbsolute = raw.startsWith('http://') || raw.startsWith('https://');
      final normalized = raw.startsWith('/') ? raw : '/$raw';
      final noLeading = normalized.replaceFirst(RegExp(r'^/+'), '');
      final candidates = <String>{
        if (isAbsolute) raw,
        if (!isAbsolute) ...{
          normalized,
          noLeading,
          '$normalized/',
          '$noLeading/',
          '/api$normalized',
          '/api/v1$normalized',
          '/v1$normalized',
        },
      }.where((e) => e.isNotEmpty).toList();

      if (isAbsolute) {
        final uri = Uri.tryParse(raw);
        final path = uri?.path;
        if (path != null && path.isNotEmpty) {
          final pathNormalized = path.startsWith('/') ? path : '/$path';
          candidates.addAll([
            pathNormalized,
            pathNormalized.replaceFirst(RegExp(r'^/+'), ''),
            '/api$pathNormalized',
            '/api/v1$pathNormalized',
            '/v1$pathNormalized',
          ]);
        }
      }

      dynamic res;
      Object? lastError;
      for (final candidate in candidates) {
        try {
          final response = await withTransportRetry(
            () => ref.read(client).patch(candidate),
          );
          final code = response.statusCode ?? 0;
          if (code == 200 || code == 204) {
            res = response;
            break;
          }
          lastError = response.data;
        } catch (e) {
          lastError = e;
        }
      }
      if (res == null) throw lastError ?? 'Failed to mark completion';
      
      // CRITICAL FIX: Use async/await instead of chained promises for proper error handling
      try {
        final updateSuccess = await accountUpdate();
        if (updateSuccess) {
          logger.debug('Account update completed after markAsComplete');
          final userId = ref.read(userProvider)?.id;
          if (userId != null) {
            try {
              final user = await getProfileUser(userId);
              ref.read(userProvider.notifier).overrideUser(user);
            } catch (e) {
              // Handle getProfileUser error gracefully - log but don't fail the whole operation
              logger.warn('Failed to fetch updated profile after markAsComplete', error: e);
              // User data might still be valid from previous state
            }
          }
        }
      } catch (e) {
        // Handle accountUpdate error gracefully - log but don't fail the whole operation
        logger.warn('Account update failed after markAsComplete', error: e);
        // Mark as complete succeeded, account update is secondary
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  /*
  * 
  * Random Quiz Section Start
  * 
  */

  Future<List<RandomQuizLessonModel>> getRandomQuizLessons(int languageId) async {
    try {
      final res = await withTransportRetry(
        () => ref.read(client).get(
          Api.randomQuiz(languageId),
          options: Options(receiveTimeout: apiLessonReceiveTimeout),
        ),
      );
      if (res.statusCode != 200) throw res.data;
      final resList = apiExtractListPayload(res.data);
      final dataList = <Map<String, dynamic>>[];
      //Flat List Loop
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            final map = apiCoerceMap(element);
            if (map != null) dataList.add(map);
          }
        } else {
          final map = apiCoerceMap(result);
          if (map != null) dataList.add(map);
        }
      }

      //LessonType Cast Loop
      final mappedLessonsList = dataList
          .map<List<RandomQuizLessonModel>>((randomQuiz) {
            final instantQuestions =
                randomQuiz.containsKey("inst_question") ? randomQuiz["inst_question"] as List : [];
            final wordQuestions =
                randomQuiz.containsKey("word_question") ? randomQuiz["word_question"] as List : [];
            final mappedInstantQuestions = instantQuestions.map((e) {
              final question = apiCoerceMap(apiCoerceMap(e)?['question']);
              if (question == null) return null;
              return RandomQuizLessonModel(
                id: (question['id'] as num?)?.toInt() ?? 0,
                title: (question['title'] ?? 'Untitled question').toString(),
                score: apiCoerceInt(question['score']),
                types: (question['types'] ?? '').toString(),
                dateTime: question['date_time']?.toString() ?? DateTime.now().toIso8601String(),
                completed: apiCoerceNullableBool(question['completed']),
                completed_by: question['completed_by'],
                otherData: apiCoerceMap(e) ?? <String, dynamic>{},
              );
            }).whereType<RandomQuizLessonModel>().toList();
            final mappedWordQuestions = wordQuestions.map((e) {
              final wordQuestion = apiCoerceMap(e);
              if (wordQuestion == null) return null;
              return RandomQuizLessonModel(
                id: (wordQuestion['id'] as num?)?.toInt() ?? 0,
                title: (wordQuestion['title'] ?? 'Untitled question').toString(),
                score: apiCoerceInt(wordQuestion['score']),
                types: (wordQuestion['types'] ?? '').toString(),
                dateTime:
                    wordQuestion['date_time']?.toString() ?? DateTime.now().toIso8601String(),
                completed: apiCoerceNullableBool(wordQuestion['completed']),
                completed_by: wordQuestion['completed_by'],
                otherData: wordQuestion,
              );
            }).whereType<RandomQuizLessonModel>().toList();
            final merged = [...mappedInstantQuestions, ...mappedWordQuestions];
            return merged;
          })
          .toList()
          .expand((e) => e)
          .toList();
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * Random Quiz Section End
  * 
  */

  /*
  * 
  * Language Quiz Section Start
  * 
  */

  Future<LanguageQuizResponse> getLanguageQuiz() async {
    try {
      final res = await ref.read(client).get(Api.languageQuiz);
      if (res.statusCode != 200) throw res.data;
      return LanguageQuizResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LanguageQuizLessonModel>> getLanguageQuizLessons(int sectionId) async {
    try {
      final res = await ref.read(client).get(Api.sectionlanguageQuiz(sectionId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;
      final dataList = <Map<String, dynamic>>[];
      //Flat List Loop
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          // if (result.containsKey('quiz') && result['quiz'].isNotEmpty) {
          dataList.add(result as Map<String, dynamic>);
          // }
        }
      }

      //LessonType Cast Loop
      final mappedLessonsList = dataList.map((lesson) {
        if (lesson.containsKey("types")) {
          return LanguageQuizLessonModel(
            id: lesson['id'],
            title: lesson.containsKey("title") ? lesson['title'] : lesson['text'],
            score: lesson['score'],
            types: lesson['types'],
            dateTime: lesson['date_time'],
            completed: lesson['completed'],
            completed_by: lesson['completed_by'],
            otherData: lesson,
          );
        }
        // if (lesson.containsKey("quiz")) {
        final quiz = lesson['quiz'].first;
        return LanguageQuizLessonModel(
          id: quiz['id'],
          title: quiz['quiz'],
          score: quiz['score'],
          types: quiz['quiz_type'],
          dateTime: quiz['date_time'],
          completed: quiz['completed'],
          completed_by: quiz['completed_by'],
          otherData: lesson,
        );
        // }
      }).toList();
      // final date = DateTime.parse("2022-06-21T02:59:57.623583Z");
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * Language Quiz Section End
  * 
  */

  /*
  * 
  * History Quiz Section Start
  * 
  */

  Future<HistoryQuizResponse> getHistoryQuiz() async {
    try {
      final res = await ref.read(client).get(Api.historyQuiz);
      if (res.statusCode != 200) throw res.data;
      return HistoryQuizResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<HistoryQuizLessonModel>> getHistoryQuizLessons(int sectionId) async {
    try {
      final res = await ref.read(client).get(Api.sectionHistoryQuiz(sectionId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;
      final dataList = <Map<String, dynamic>>[];
      //Flat List Loop
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }

      //LessonType Cast Loop
      final mappedLessonsList = dataList.map((lesson) {
        if (lesson.containsKey("types")) {
          return HistoryQuizLessonModel(
            id: lesson['id'],
            title: lesson.containsKey("title") ? lesson['title'] : lesson['text'],
            score: lesson['score'],
            types: lesson['types'],
            dateTime: lesson['date_time'],
            completed: lesson['completed'],
            completed_by: lesson['completed_by'],
            otherData: lesson,
          );
        }
        // if (lesson.containsKey("quiz")) {
        final quiz = lesson['quiz'].first;
        return HistoryQuizLessonModel(
          id: quiz['id'],
          title: quiz['quiz'],
          score: quiz['score'],
          types: quiz['quiz_type'],
          dateTime: quiz['date_time'],
          completed: quiz['completed'],
          completed_by: quiz['completed_by'],
          otherData: lesson,
        );
        // }
      }).toList();
      // final date = DateTime.parse("2022-06-21T02:59:57.623583Z");
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * History Quiz Section End
  * 
  */
  Future<bool> registerDevice() async {
    try {
      final token = await ref.read(firebaseMessagingProvider).getToken();
      final data = {
        'registration_id': token,
        'type': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
      };
      final res = await ref.read(client).post(Api.registerFcmDevice, data: data);
      logger.debug('Register device completed', context: {'statusCode': res.statusCode});

      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      }
      throw res.data;
    } catch (e) {
      logger.warn('Error registering device');
      return false;
    }
  }

  Future<void> unregisterDevice() async {
    try {
      final token = await ref.read(firebaseMessagingProvider).getToken();
      final res = await ref.read(client).delete(
            Api.unRegisterFcmDevice(token!),
          );
      logger.debug('Unregister device completed', context: {'statusCode': res.statusCode});
      if (res.statusCode != 204) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  getDevices() async {
    try {
      final res = await ref.read(client).get(Api.registerFcmDevice);
      logger.debug('Get devices completed', context: {'statusCode': res.statusCode});
      if (res.statusCode != 200) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get AI-curated loading screen content
  /// Returns a LoadingScreenContent object with fact, image, and cultural information
}
