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

import 'package:lingafriq/features/api/providers/api_provider_mixin_1.dart';

mixin ApiProviderMixin2 on ApiProviderMixin1 {
  Future<Map<String, dynamic>?> getLearningPath({
    required String language,
    required String pathType,
  }) async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(
          ApiContract.learningPath.byContext(
            language: language,
            type: pathType,
          ),
        ),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      logger.error('Error fetching learning path', error: e, context: {
        'language': language,
        'pathType': pathType,
      });
      return null;
    }
  }

  /// Create a learning path for the current user.
  Future<Map<String, dynamic>?> createLearningPath({
    required String language,
    required String pathType,
    required String currentLevel,
    required List<Map<String, dynamic>> modules,
  }) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.learningPath.create),
        data: {
          'language': language,
          'type': pathType,
          'currentLevel': currentLevel,
          'modules': modules,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      logger.error('Error creating learning path', error: e, context: {
        'language': language,
        'pathType': pathType,
      });
      return null;
    }
  }

  /// Update learning path fields for language and path type.
  Future<Map<String, dynamic>?> updateLearningPath({
    required String language,
    required String pathType,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final res = await ref.read(client).put(
        ApiContract.url(
          ApiContract.learningPath.updateByContext(
            language: language,
            type: pathType,
          ),
        ),
        data: updates,
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      logger.error('Error updating learning path', error: e, context: {
        'language': language,
        'pathType': pathType,
      });
      return null;
    }
  }

  /// Mark a learning path module as completed.
  Future<Map<String, dynamic>?> completeLearningPathModule({
    required String language,
    required String pathType,
    required String moduleId,
  }) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.learningPath.completeModule),
        data: {
          'language': language,
          'type': pathType,
          'moduleId': moduleId,
        },
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      logger.error('Error completing learning path module', error: e, context: {
        'language': language,
        'pathType': pathType,
        'moduleId': moduleId,
      });
      return null;
    }
  }

  Future<LanguageResponse> getLanguages() async {
    try {
      final res = await ref.read(client).get(Api.language);
      if (res.statusCode != 200) throw res.data;
      return LanguageResponse.fromMap(res.data['result']);
    } catch (e) {
      rethrow;
    }
  }

  // Future<List<ProfileModel>> getProfiles() async {
  //   try {
  //     final res = await ref.read(client).get(Api.profiles);
  //     jsonEncode(res.data).log();
  //     if (res.statusCode != 200) throw res.data;
  //     final profilesRes = res.data as Map;
  //     if (!profilesRes.containsKey("result")) throw res.data;
  //     final result = profilesRes["result"] as Map;
  //     if (!result.containsKey("results")) throw res.data;
  //     final profilesList = result["results"] as List;
  //     final profiles = profilesList.map((e) => ProfileModel.fromMap(e)).toList();
  //     profiles.sort((a, b) => b.completed_point.compareTo(a.completed_point));
  //     return profiles;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  Future<ProfilesResponse> getProfilesResponse([String? url]) async {
    try {
      final res = await ref.read(client).get(url ?? Api.profiles);
      if (res.statusCode != 200) throw res.data;
      final payload = res.data;
      if (payload is Map<String, dynamic> &&
          payload['result'] is Map<String, dynamic>) {
        return ProfilesResponse.fromMap(payload);
      }

      List<dynamic> results = const [];
      String? next;
      String? previous;
      int count = 0;

      if (payload is List) {
        results = payload;
        count = payload.length;
      } else if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        if (map['results'] is List) {
          results = map['results'] as List;
          next = map['next']?.toString();
          previous = map['previous']?.toString();
          count = (map['count'] as num?)?.toInt() ?? results.length;
        } else if (map['data'] is List) {
          results = map['data'] as List;
          count = (map['count'] as num?)?.toInt() ?? results.length;
        } else if (map['data'] is Map &&
            (map['data'] as Map)['results'] is List) {
          final inner = Map<String, dynamic>.from(map['data'] as Map);
          results = inner['results'] as List;
          next = inner['next']?.toString();
          previous = inner['previous']?.toString();
          count = (inner['count'] as num?)?.toInt() ?? results.length;
        }
      }

      return ProfilesResponse.fromMap({
        'result': {
          'count': count,
          'next': next,
          'previous': previous,
          'results': results,
        },
      });
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * Lessons Section Start
  * 
  */

  Future<LessonResponse> getLessons(int? id) async {
    try {
      final params = {"lessons_language": id};
      final res = await ref.read(client).get(
            Api.lessons,
            queryParameters: params,
            options: Options(receiveTimeout: apiLessonReceiveTimeout),
          );
      if (res.statusCode != 200) throw res.data;
      final data = apiCoerceMap(res.data);
      final result =
          apiCoerceMap(data?['result']) ?? (data != null && data['results'] != null ? data : null);
      final totalScore = data?['total_score'];
      if (result == null) throw Exception('Lessons API returned no result');
      return LessonResponse.fromMap(result, totalScore);
    } catch (e) {
      rethrow;
    }
  }

  ///section_lessons_screen
  Future<List<SectionLessonModel>> getSectionLessons(
    int lessonId,
  ) async {
    try {
      final res = await withTransportRetry(
        () => ref.read(client).get(
              Api.sectionLessonsList(lessonId),
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
          .map((lesson) {
            if (lesson.containsKey("types")) {
              return SectionLessonModel(
                id: (lesson['id'] as num?)?.toInt() ?? 0,
                title: (lesson['title'] ?? lesson['text'] ?? 'Untitled lesson').toString(),
                score: apiCoerceInt(lesson['score']),
                types: lesson['types']?.toString() ?? '',
                dateTime: lesson['date_time']?.toString() ?? DateTime.now().toIso8601String(),
                completed: apiCoerceNullableBool(lesson['completed']),
                completed_by: lesson['completed_by'],
                otherData: lesson,
              );
            }
            final quizList = lesson['quiz'];
            if (quizList is! List || quizList.isEmpty) return null;
            final quiz = apiCoerceMap(quizList.first);
            if (quiz == null) return null;
            return SectionLessonModel(
              id: (quiz['id'] as num?)?.toInt() ?? 0,
              title: (quiz['quiz'] ?? lesson['title'] ?? 'Untitled quiz').toString(),
              score: apiCoerceInt(quiz['score']),
              types: (quiz['quiz_type'] ?? 'quiz').toString(),
              dateTime: quiz['date_time']?.toString() ?? DateTime.now().toIso8601String(),
              completed: apiCoerceNullableBool(quiz['completed']),
              completed_by: quiz['completed_by'],
              otherData: lesson,
            );
          })
          .whereType<SectionLessonModel>()
          .toList();
      if (mappedLessonsList.isEmpty) {
        throw Exception('No valid section lessons found');
      }
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
  * Lessons Section End
  * 
  */

  /*
  * 
  * Mannerisms Section Start
  * 
  */

  Future<MannerismResponse> getMannerisms(int? id) async {
    try {
      // final params = {"mannerism_language": id};
      final res = await ref.read(client).get(
            Api.mannerism,
            // queryParameters: params,
          );
      if (res.statusCode != 200) throw res.data;
      return MannerismResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MannerismTutorialModel>> getMannerismTutorials(int mannerismId) async {
    try {
      final res = await ref.read(client).get(Api.mannerismTutorialsList(mannerismId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;

      resList.removeWhere((e) => e is Map && e.containsKey("mannerism"));
      final mannerismLessons =
          resList.map((e) => e['mannerism_lesson']).expand((element) => element).toList();
      final mappedMannerismsList =
          mannerismLessons.map((e) => MannerismTutorialModel.fromMap(e)).toList();

      // final date = DateTime.parse("2022-06-21T02:59:57.623583Z");
      mappedMannerismsList.sort((a, b) {
        if (a.date_time == null || b.date_time == null) return 0;
        return a.date_time!.compareTo(b.date_time!);
      });
      return mappedMannerismsList;
    } catch (e) {
      rethrow;
    }
  }

  /*
  * 
  * Mannerisms Section End
  * 
  */

  /*
  * 
  * History Section Start
  * 
  */

  Future<HistoryResponse> getHistory(int? id) async {
    try {
      // final params = {"lessons_language": id};
      final res = await ref.read(client).get(
            Api.history,
            // queryParameters: params,
          );
      if (res.statusCode != 200) throw res.data;
      return HistoryResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  ///section_lessons_screen
}
