import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/extensions.dart';
import 'package:lingafriq/utils/error_handler.dart';

import '../history_quiz/models/history_quiz_response.dart';
import '../language_quiz/models/language_quiz_lesson_model.dart';
import '../language_quiz/models/language_quiz_response.dart';
import '../lessons/models/lesson_response.dart';
import '../lessons/models/section_lesson_model.dart';
import '../models/user.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final apiProvider = NotifierProvider<ApiProvider, BaseProviderState>(() {
  return ApiProvider();
});

class ApiProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  @override
  BaseProviderState build() {
    // Load tokens from SharedPreferences on initialization
    // This ensures tokens are available if the app was previously logged in
    _loadTokensFromStorage();
    return BaseProviderState();
  }

  String? token;
  String? refreshToken;

  /// Load tokens from SharedPreferences on provider initialization
  void _loadTokensFromStorage() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      token = prefs.getAccessToken();
      // Refresh token is async, but we can't await in build()
      // It will be loaded when needed via refreshAccessToken()
    } catch (e) {
      // Silently fail - tokens might not exist yet (user not logged in)
      token = null;
      refreshToken = null;
    }
  }

  /// Refresh access token using refresh token
  Future<String?> refreshAccessToken() async {
    try {
      if (refreshToken == null || (refreshToken?.isEmpty ?? true)) {
        // Try to get from shared preferences
        final prefs = ref.read(sharedPreferencesProvider);
        refreshToken = await prefs.getRefreshToken();
      }
      
      if (refreshToken == null || (refreshToken?.isEmpty ?? true)) {
        return null;
      }

      final res = await ref.read(client).post(
        Api.refreshToken,
        // Django JWT refresh contract: { refresh: token } -> { access }
        data: { 'refresh': refreshToken },
      );

      if (res.statusCode == 200) {
        final data = res.data;
        final access = (data is Map<String, dynamic>)
            ? (data['accessToken'] ?? data['access'])?.toString()
            : null;

        if (access != null && access.isNotEmpty) {
          token = access;

          // Legacy refresh returns {access} only; keep existing refresh token.
          final prefs = ref.read(sharedPreferencesProvider);
          if (refreshToken != null && refreshToken!.isNotEmpty) {
            await prefs.storeAuthTokens(token!, refreshToken!);
          }

          return token;
        }
      }
      return null;
    } catch (e) {
      token = null;
      refreshToken = null;
      return null;
    }
  }

  /// Clear stored tokens
  void clearToken() {
    token = null;
    refreshToken = null;
  }

  Future<void> register(FormData registerData) async {
    try {
      final res = await ref.read(client).post(
            Api.register,
            data: registerData,
            options: Options(contentType: "multipart/form-data"),
          );
      if (res.statusCode != 201) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileModel> login(Map<String, String> data) async {
    try {
      // Log the login attempt with backend URL for debugging
      logger.info('Login API call', context: {
        'endpoint': Api.login,
        'baseUrl': Api.baseurl,
        'fullUrl': '${Api.baseurl}${Api.login}',
      });
      
      final res = await ref.read(client).post(Api.login, data: data);
      if (res.statusCode != 200) {
        // Convert to structured error
        final error = ErrorConverter.toAppError(
          DioException(
            requestOptions: RequestOptions(path: Api.login),
            response: res,
            type: DioExceptionType.badResponse,
          ),
        );
        throw error;
      }
      token = res.data['access'] ?? res.data['token'];
      refreshToken = res.data['refresh'];

      // Store tokens
      if ((token?.isNotEmpty ?? false) && (refreshToken?.isNotEmpty ?? false)) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.storeAuthTokens(token!, refreshToken!);
      }

      final email = data['email'] as String;
      final prefs = ref.read(sharedPreferencesProvider);
      ProfileModel? user = await prefs.getUser(email);

      if (user == null || user.email != email) {
        final userInfo = await getUserInfo();
        user = await getProfileUser(userInfo.id);
        await prefs.storeUser(user, userInfo.email);
      }

      // Update user provider with current user
      ref.read(userProvider.notifier).overrideUser(user);

      logger.info('Login successful', context: {'email': data['email']});
      return user;
    } catch (e) {
      // Log detailed error information for debugging
      logger.error('Login API call failed', error: e, context: {
        'endpoint': Api.login,
        'baseUrl': Api.baseurl,
        'errorType': e.runtimeType.toString(),
        'isDioException': e is DioException,
        'dioErrorType': e is DioException ? e.type.toString() : null,
        'statusCode': e is DioException ? e.response?.statusCode : null,
      });
      rethrow;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true);
      final data = {"email": email};
      final res = await ref.read(client).post(Api.resetPassword, data: data);
      if (res.statusCode != 204) throw res.data;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = ref.read(userProvider)?.id;
      if (userId == null) return false;
      state = state.copyWith(isLoading: true);
      final res = await ref.read(client).put(Api.userInfo, data: data);
      res.statusCode.toString().log();
      if (res.statusCode != 200) throw res.data;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<bool> accountUpdate() async {
    try {
      final res = await ref.read(client).get(Api.accountUpdate);
      res.statusCode.toString().log();
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      "Error Account update $e".log("accountUpdate");
      return false;
    }
  }

  Future<bool> deleteUser(Map<String, dynamic> data) async {
    try {
      final userId = ref.read(userProvider)?.id;
      if (userId == null) return false;
      setBusy();
      final res = await ref.read(client).delete(
            Api.deleteUser(userId),
            data: data,
          );
      res.statusCode.toString().log("statusCode");
      if (res.statusCode != 204) throw res.data;
      setIdle();
      ref.read(authProvider.notifier).signOut();
      return true;
    } catch (e) {
      setIdle();
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<ProfileModel> getProfileUser(int id) async {
    try {
      final res = await ref.read(client).get(Api.userProfile(id));

      if (res.statusCode != 200) throw res.data;
      res.data.toString().log('getProfileUser');
      return ProfileModel.fromMap(res.data.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserInfo() async {
    "getUserInfo".log('getUserInfo');
    try {
      final res = await ref.read(client).get(Api.userInfo);
      if (res.statusCode != 200) throw res.data;
      return User.fromMap(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      setBusy();
      final data = {
        "new_password": newPassword,
        "current_password": currentPassword,
      };
      final res = await ref.read(client).post(Api.changePassword, data: data);
      if (res.statusCode != 204) throw res.data;
      setIdle();
      return true;
    } catch (e) {
      setIdle();
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  /// Update user preferences (privacy, analytics, etc.). Persists to backend when available.
  Future<bool> updateUserPreferences(Map<String, dynamic> prefs) async {
    try {
      final res = await ref.read(client).put(
        '${Api.baseurl}${Api.userPreferences}',
        data: prefs,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // Backend may not implement preferences endpoint yet; fail silently
      return false;
    }
  }

  /// Fetch user preferences from backend.
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final res = await ref.read(client).get(
        '${Api.baseurl}${Api.userPreferences}',
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
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
      jsonEncode(res.data).log();
      if (res.statusCode != 200) throw res.data;
      return ProfilesResponse.fromMap(res.data);
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
          );
      if (res.statusCode != 200) throw res.data;
      return LessonResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  ///section_lessons_screen
  Future<List<SectionLessonModel>> getSectionLessons(
    int lessonId,
  ) async {
    try {
      final res = await ref.read(client).get(Api.sectionLessonsList(lessonId));
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
          return SectionLessonModel(
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
        return SectionLessonModel(
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
    "Marking as complete $endpointToHit".log("endpointToHit");
    try {
      state = state.copyWith(isLoading: true);
      final res = await ref.read(client).patch(endpointToHit);
      if (res.statusCode != 200) throw res.data;
      
      // CRITICAL FIX: Use async/await instead of chained promises for proper error handling
      try {
        final updateSuccess = await accountUpdate();
        if (updateSuccess) {
          "Account updated".log("accountUpdate");
          final userId = ref.read(userProvider)?.id;
          if (userId != null) {
            try {
              final user = await getProfileUser(userId);
              ref.read(userProvider.notifier).overrideUser(user);
            } catch (e) {
              // Handle getProfileUser error gracefully - log but don't fail the whole operation
              "Error getting updated profile $e".log("getProfileUser");
              // User data might still be valid from previous state
            }
          }
        }
      } catch (e) {
        // Handle accountUpdate error gracefully - log but don't fail the whole operation
        "Error Account update $e".log("accountUpdate");
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
      state = state.copyWith(isLoading: true);
      final res = await ref.read(client).get(Api.randomQuiz(languageId));
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
      final mappedLessonsList = dataList
          .map<List<RandomQuizLessonModel>>((randomQuiz) {
            final instantQuestions =
                randomQuiz.containsKey("inst_question") ? randomQuiz["inst_question"] as List : [];
            final wordQuestions =
                randomQuiz.containsKey("word_question") ? randomQuiz["word_question"] as List : [];
            final mappedInstantQuestions = instantQuestions.map((e) {
              final question = e["question"];
              return RandomQuizLessonModel(
                id: question['id'],
                title: question['title'],
                score: question['score'],
                types: question['types'],
                dateTime: question['date_time'],
                completed: question['completed'],
                completed_by: question['completed_by'],
                otherData: e,
              );
            }).toList();
            final mappedWordQuestions = wordQuestions.map((e) {
              return RandomQuizLessonModel(
                id: e['id'],
                title: e['title'],
                score: e['score'] ?? 0,
                types: e['types'],
                dateTime: e['date_time'],
                completed: e['completed'],
                completed_by: e['completed_by'],
                otherData: e,
              );
            }).toList();
            final merged = [...mappedInstantQuestions, ...mappedWordQuestions];
            return merged;
          })
          .toList()
          .expand((e) => e)
          .toList();
      state = state.copyWith(isLoading: false);
      return mappedLessonsList;
    } catch (e) {
      state = state.copyWith(isLoading: true);
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
      res.data.toString().log('getLanguageQuiz');
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
        lesson.toString().log('language quiz');
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
        lesson.toString().log('history quiz');
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
      res.statusCode.log();
      res.data.toString().log();

      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      }
      throw res.data;
    } catch (e) {
      "Error Registering Device".log();
      return false;
    }
  }

  Future<void> unregisterDevice() async {
    try {
      final token = await ref.read(firebaseMessagingProvider).getToken();
      final res = await ref.read(client).delete(
            Api.unRegisterFcmDevice(token!),
          );
      res.statusCode.log();
      res.data.toString().log();
      if (res.statusCode != 204) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  getDevices() async {
    try {
      final res = await ref.read(client).get(Api.registerFcmDevice);
      res.statusCode.log();
      res.data.toString().log();
      if (res.statusCode != 200) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get AI-curated loading screen content
  /// Returns a LoadingScreenContent object with fact, image, and cultural information
  Future<Map<String, dynamic>> getLoadingScreenContent({
    String? country,
    String? language,
    String? lastContentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (country != null) queryParams['country'] = country;
      if (language != null) queryParams['language'] = language;
      if (lastContentId != null) queryParams['lastContentId'] = lastContentId;

      final res = await ref.read(client).get(
        '${Api.baseurl}api/v1/loading-screen/content',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Search users by handle (global_id)
  Future<List<Map<String, dynamic>>> searchUsersByHandle(String handle) async {
    try {
      final res = await ref.read(client).get(
        Api.searchUsersByHandle(handle),
      );
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('result')) {
        final result = data['result'];
        if (result is List) {
          return List<Map<String, dynamic>>.from(result);
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Award XP to a user (server-authoritative)
  /// Returns true if successful, false otherwise
  Future<bool> awardXP({
    required String userId,
    required String source,
    required String sourceId,
    required int amount,
    double difficultyMultiplier = 1.0,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.xpAward,
        data: {
          'user_id': userId,
          'source': source,
          'source_id': sourceId,
          'amount': amount,
          'difficulty_multiplier': difficultyMultiplier,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error awarding XP', error: e);
      return false;
    }
  }

  /// Get user XP and level information
  /// Returns Map with totalXP, level, levelTitle, or null on error
  Future<Map<String, dynamic>?> getUserXP(String userId) async {
    try {
      final res = await ref.read(client).get('${Api.xpTotal}?user_id=$userId');
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      logger.error('Error getting user XP', error: e);
      return null;
    }
  }

  /// Record learner activity for analytics and progress tracking
  Future<bool> recordLearnerActivity({
    required String userId,
    required String language,
    String? activityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}api/learner-activity',
        data: {
          'user_id': userId,
          'language': language,
          if (activityType != null) 'activity_type': activityType,
          if (metadata != null) 'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error recording learner activity', error: e);
      return false;
    }
  }

  /// Get experiments configuration (feature flags and variants)
  Future<Map<String, dynamic>> getExperimentsConfig() async {
    try {
      final res = await ref.read(client).get(
        '${Api.baseurl}api/experiments/config',
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {'flags': {}, 'variants': {}};
    } catch (e) {
      logger.error('Error getting experiments config', error: e);
      // Return default empty config on error
      return {'flags': {}, 'variants': {}};
    }
  }

  /// Get daily goals for the current user
  Future<Map<String, dynamic>> getDailyGoals() async {
    try {
      final res = await ref.read(client).get(Api.dailyChallenges);
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      logger.error('Error getting daily goals', error: e);
      return {};
    }
  }

  /// Sync gamification data with backend
  Future<bool> syncGamification(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}sync',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing gamification', error: e);
      return false;
    }
  }

  /// Save AI chat history
  Future<bool> saveAiChatHistory(Map<String, dynamic> chatData) async {
    try {
      // Canonical backend route: POST /api/ai/chat/history/sync/
      //
      // Backward compatible input: older callers may include `language_code`.
      // Sync controller expects `{ mode, messages, timestamp }`.
      final res = await ref.read(client).post(
        '${Api.baseurl}api/ai/chat/history/sync/',
        data: {
          'mode': chatData['mode'],
          'messages': chatData['messages'],
          if (chatData['timestamp'] != null) 'timestamp': chatData['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error saving AI chat history', error: e);
      return false;
    }
  }

  /// Get AI chat history from backend
  /// Returns list of message maps, or null if not found/error
  Future<List<Map<String, dynamic>>?> getAiChatHistory({
    required String mode,
    required String languageCode,
  }) async {
    try {
      // Canonical backend route: GET /api/ai/chat/history/:mode
      final res = await ref.read(client).get('${Api.baseurl}api/ai/chat/history/$mode');

      if (res.statusCode != 200 || res.data == null) return null;

      // Expected: { success: true, data: { messages: [...] } }
      final root = res.data;
      if (root is Map) {
        final data = root['data'];
        if (data is Map && data['messages'] is List) {
          return (data['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
        }
        // Backward-compatible fallbacks
        if (root['messages'] is List) {
          return (root['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
        }
      }

      return null;
    } catch (e) {
      logger.error('Error getting AI chat history', error: e);
      return null;
    }
  }

  /// Get user gamification data from backend
  /// Returns gamification data map, or null if not found/error
  Future<Map<String, dynamic>?> getGamification(String userId) async {
    try {
      final res = await ref.read(client).get(
        Api.userGamification(userId),
      );
      
      if (res.statusCode == 200 && res.data != null) {
        if (res.data is Map) {
          return res.data as Map<String, dynamic>;
        } else if (res.data is List && (res.data as List).isNotEmpty) {
          // Backend might return a list with single item
          return (res.data as List).first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      logger.error('Error getting gamification', error: e);
      return null;
    }
  }

  /// Update daily goal progress
  Future<bool> updateDailyGoal(String goalId, Map<String, dynamic> progress) async {
    try {
      final res = await ref.read(client).patch(
        '${Api.baseurl}${Api.dailyChallenges}/$goalId',
        data: progress,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      logger.error('Error updating daily goal', error: e);
      return false;
    }
  }

  /// Update user points (legacy method - prefer awardXP)
  Future<bool> updateUserPoints(int points) async {
    try {
      final res = await ref.read(client).post(
        Api.currencyAward,
        data: {'amount': points},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating user points', error: e);
      return false;
    }
  }

  /// Get progress metrics for the current user
  Future<Map<String, dynamic>> getProgressMetrics() async {
    try {
      final res = await ref.read(client).get(
        '${Api.baseurl}${Api.gamificationBase}progress',
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      logger.error('Error getting progress metrics', error: e);
      return {};
    }
  }

  /// Update progress metrics
  Future<bool> updateProgressMetrics(Map<String, dynamic> metrics) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}progress',
        data: metrics,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating progress metrics', error: e);
      return false;
    }
  }

  /// Get all achievements
  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final res = await ref.read(client).get(Api.badges);
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting achievements', error: e);
      return [];
    }
  }

  /// Unlock an achievement
  Future<bool> unlockAchievement(String achievementId) async {
    try {
      final res = await ref.read(client).post(
        '${Api.badges}$achievementId/unlock',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error unlocking achievement', error: e);
      return false;
    }
  }

  /// Update XP (legacy method - prefer awardXP)
  Future<bool> updateXP(int xp) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return false;
      return await awardXP(
        userId: user.id.toString(),
        source: 'manual_update',
        sourceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        amount: xp,
      );
    } catch (e) {
      logger.error('Error updating XP', error: e);
      return false;
    }
  }

  /// Update challenge progress
  Future<bool> updateChallengeProgress(String challengeId, Map<String, dynamic> progress) async {
    try {
      final res = await ref.read(client).patch(
        '${Api.baseurl}${Api.dailyChallenges}/$challengeId',
        data: progress,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      logger.error('Error updating challenge progress', error: e);
      return false;
    }
  }

  /// Update milestone stats
  Future<bool> updateMilestoneStats(String milestoneId, int value) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.milestones}',
        data: {
          'milestoneId': milestoneId,
          'value': value,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating milestone stats', error: e);
      return false;
    }
  }

  /// Add XP to league (for tribe competitions)
  Future<bool> addLeagueXP(int xp) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.league}/xp',
        data: {'xp': xp},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error adding league XP', error: e);
      return false;
    }
  }

  /// Use a heart (lives system)
  Future<bool> useHeart() async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}hearts/use',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error using heart', error: e);
      return false;
    }
  }

  /// Refill hearts (buy or wait)
  Future<bool> refillHearts() async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}hearts/refill',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error refilling hearts', error: e);
      return false;
    }
  }

  /// Toggle challenge mode
  Future<bool> toggleChallengeMode(bool enabled) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}challenge-mode',
        data: {'enabled': enabled},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error toggling challenge mode', error: e);
      return false;
    }
  }

  /// Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({String? category}) async {
    try {
      final url = category != null 
          ? '${Api.baseurl}${Api.leagueLeaderboard}?category=$category'
          : Api.leagueLeaderboard;
      final res = await ref.read(client).get(url);
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        } else if (res.data is Map && res.data['leaderboard'] is List) {
          return List<Map<String, dynamic>>.from(res.data['leaderboard']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting leaderboard', error: e);
      return [];
    }
  }

  /// Send telemetry events
  Future<bool> sendTelemetry(List<Map<String, dynamic>> events) async {
    try {
      if (events.isEmpty) return true;

      // Canonical backend route: POST /api/games/telemetry/
      // Backend accepts ONE event per request, so we batch client-side.
      var ok = true;
      for (final event in events) {
        final res = await ref.read(client).post(
          '${Api.baseurl}api/games/telemetry/',
          data: event,
        );
        ok = ok && (res.statusCode == 200 || res.statusCode == 201);
      }
      return ok;
    } catch (e) {
      logger.error('Error sending telemetry', error: e);
      return false;
    }
  }

  /// Family subscription: aggregated progress dashboard
  /// Backend: GET /api/progress/family/dashboard
  Future<Map<String, dynamic>> getFamilyProgressDashboard() async {
    final res = await ref.read(client).get('/api/progress/family/dashboard');
    if (res.statusCode != 200) {
      throw Exception(res.data);
    }
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// Fetch ancestry graph for the current user.
  ///
  /// Backend: GET /api/ancestry/me
  /// Backward-compatible: requires only auth (user id is derived from JWT server-side).
  Future<Map<String, dynamic>> getAncestryMe() async {
    final res = await ref.read(client).get('/api/ancestry/me');
    if (res.statusCode != 200) {
      throw Exception(res.data);
    }
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// Generic POST helper method for flexibility
  Future<Response?> post(String path, {dynamic data}) async {
    try {
      return await ref.read(client).post(path, data: data);
    } catch (e) {
      logger.error('Error in POST request', error: e, context: {'path': path});
      return null;
    }
  }

  /// Sync game session to backend
  Future<bool> syncGameSession(Map<String, dynamic> data) async {
    try {
      // Canonical backend route: POST /api/games/session/start/
      // Backend upserts by `session.session_id` and is tolerant to being called
      // for start/turn/complete via the same handler.
      final res = await ref.read(client).post(
        '${Api.baseurl}api/games/session/start/',
        data: {
          'session': data['session'],
          if (data['timestamp'] != null) 'timestamp': data['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing game session', error: e);
      return false;
    }
  }

  /// Sync game SRS (Spaced Repetition System) data to backend
  Future<bool> syncGameSRS(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id']?.toString();
      if (userId == null || userId.trim().isEmpty) {
        throw Exception('syncGameSRS requires user_id');
      }

      // Canonical backend route: PUT /api/games/srs/user/:userId
      final res = await ref.read(client).put(
        '${Api.baseurl}api/games/srs/user/$userId',
        data: {
          'srs': data['srs'],
          if (data['timestamp'] != null) 'timestamp': data['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing game SRS', error: e);
      return false;
    }
  }

  /// Create user-generated lesson
  Future<Map<String, dynamic>> createUgcLesson(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.userContent}lessons',
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create lesson: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC lesson', error: e);
      rethrow;
    }
  }

  /// Create user-generated quiz
  Future<Map<String, dynamic>> createUgcQuiz(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.userContent}quizzes',
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create quiz: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC quiz', error: e);
      rethrow;
    }
  }

  /// Create user-generated story
  Future<Map<String, dynamic>> createUgcStory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.userContent}stories',
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create story: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC story', error: e);
      rethrow;
    }
  }

  /// Share user-generated content
  Future<bool> shareUgcContent({
    required String contentId,
    required String contentType,
    List<String>? userIds,
  }) async {
    try {
      final data = {
        'content_id': contentId,
        'content_type': contentType,
        if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
      };
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.userContent}share',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error sharing UGC content', error: e);
      return false;
    }
  }

  /// Get user-generated content
  Future<List<Map<String, dynamic>>> getUserContent({
    String? language,
    String? contentType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (language != null) queryParams['language'] = language;
      if (contentType != null) queryParams['type'] = contentType;
      
      final queryString = queryParams.isEmpty 
          ? '' 
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      
      final res = await ref.read(client).get(
        '${Api.baseurl}${Api.userContent}content$queryString',
      );
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        } else if (res.data is Map && res.data['content'] is List) {
          return List<Map<String, dynamic>>.from(res.data['content']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting user content', error: e);
      return [];
    }
  }

  /// Rate user-generated content
  Future<bool> rateUgcContent({
    required String contentId,
    required int rating,
    String? review,
  }) async {
    try {
      final data = {
        'content_id': contentId,
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      };
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.userContent}rate',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error rating UGC content', error: e);
      return false;
    }
  }

  /// Sync AI chat history to backend
  Future<bool> syncAIChatHistory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}api/ai/chat/history/sync/',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing AI chat history', error: e);
      return false;
    }
  }

  /// Sync AI chat SRS data to backend
  Future<bool> syncAIChatSRS(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}api/ai/chat/srs/sync/',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing AI chat SRS', error: e);
      return false;
    }
  }

  /// Sync progress metrics to backend
  Future<bool> syncProgress(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.gamificationBase}progress/sync',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing progress', error: e);
      return false;
    }
  }

  /// Sync onboarding data to backend
  /// Backend expects: { onboarding_data: {...}, timestamp: "..." }
  Future<bool> syncOnboarding(Map<String, dynamic> data) async {
    try {
      // Backend expects the data wrapped in 'onboarding_data' field
      final requestBody = {
        'onboarding_data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final res = await ref.read(client).post(
        '${Api.baseurl}api/onboarding/save/',
        data: requestBody,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing onboarding', error: e);
      return false;
    }
  }

  /// Sync telemetry events to backend
  Future<bool> syncTelemetry(Map<String, dynamic> data) async {
    try {
      // Canonical backend route: POST /api/games/telemetry/
      // Support both single event and `{ events: [...] }` payloads.
      if (data['events'] is List) {
        final events = (data['events'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return await sendTelemetry(events);
      }

      final res = await ref.read(client).post(
        '${Api.baseurl}api/games/telemetry/',
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing telemetry', error: e);
      return false;
    }
  }

  /// Check if username is available
  /// Queries backend to check against all registered usernames (case-insensitive)
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final res = await ref.read(client).get(
        '${Api.baseurl}onboarding/check-username',
        queryParameters: {'username': username.trim()},
      );
      
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map ? res.data : (res.data['data'] ?? {});
        // Backend returns: { success: true, data: { username: "...", available: true/false } }
        return data['available'] ?? false;
      }
      // If endpoint doesn't exist or fails, assume available (allow user to continue)
      logger.warn('Username check endpoint returned unexpected response', context: {
        'statusCode': res.statusCode,
        'data': res.data,
      });
      return true; // Default to available if check fails
    } catch (e) {
      // If check fails, allow user to continue (they can change it later if needed)
      logger.warn('Error checking username availability', error: e);
      return true; // Default to available if check fails
    }
  }

  /// Search chat messages
  Future<List<Map<String, dynamic>>> searchChatMessages({
    required String query,
    String? room,
    String type = 'all',
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'type': type,
        'limit': limit,
      };
      if (room != null) {
        queryParams['room'] = room;
      }
      
      final res = await ref.read(client).get(
        '${Api.baseurl}api/chat/search',
        queryParameters: queryParams,
      );
      
      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      } else if (res.statusCode == 200 && res.data is Map && res.data['results'] is List) {
        return List<Map<String, dynamic>>.from(res.data['results']);
      }
      return [];
    } catch (e) {
      logger.error('Error searching chat messages', error: e);
      return [];
    }
  }

  /// Submit voice contribution
  Future<bool> submitVoiceContribution({
    required String userId,
    required String promptId,
    required String language,
    required String category,
    required String promptText,
    required String audioPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'prompt_id': promptId,
        'language': language,
        'category': category,
        'prompt_text': promptText,
        'audio': await MultipartFile.fromFile(audioPath),
      });
      
      final res = await ref.read(client).post(
        '${Api.baseurl}api/voice/contributions',
        data: formData,
      );
      
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error submitting voice contribution', error: e);
      return false;
    }
  }

  // ========== SOCIAL AUDIO API METHODS ==========

  /// Get social audio rooms
  Future<Response?> getSocialAudioRooms({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await ref.read(client).get(
        '${Api.baseurl}${Api.socialAudioRooms}',
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio rooms', error: e);
      return null;
    }
  }

  /// Get social audio room by ID
  Future<Response?> getSocialAudioRoom(String roomId) async {
    try {
      return await ref.read(client).get(
        '${Api.baseurl}${Api.socialAudioRoom(roomId)}',
      );
    } catch (e) {
      logger.error('Error getting social audio room', error: e);
      return null;
    }
  }

  /// Create social audio room
  Future<Response?> createSocialAudioRoom(Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        '${Api.baseurl}${Api.socialAudioRooms}',
        data: data,
      );
    } catch (e) {
      logger.error('Error creating social audio room', error: e);
      return null;
    }
  }

  /// Join social audio room
  Future<Response?> joinSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        '${Api.baseurl}${Api.socialAudioRoomJoin(roomId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error joining social audio room', error: e);
      return null;
    }
  }

  /// Leave social audio room
  Future<Response?> leaveSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        '${Api.baseurl}${Api.socialAudioRoomLeave(roomId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error leaving social audio room', error: e);
      return null;
    }
  }

  /// Update social audio room status
  Future<Response?> updateSocialAudioRoomStatus(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).patch(
        '${Api.baseurl}${Api.socialAudioRoomStatus(roomId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error updating social audio room status', error: e);
      return null;
    }
  }

  /// Get social audio room participants
  Future<Response?> getSocialAudioRoomParticipants(String roomId) async {
    try {
      return await ref.read(client).get(
        '${Api.baseurl}${Api.socialAudioRoomParticipants(roomId)}',
      );
    } catch (e) {
      logger.error('Error getting social audio room participants', error: e);
      return null;
    }
  }

  /// Moderate social audio room
  Future<Response?> moderateSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        '${Api.baseurl}${Api.socialAudioRoomModerate(roomId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error moderating social audio room', error: e);
      return null;
    }
  }

  /// Follow user for social audio
  Future<Response?> followSocialAudioUser(String userId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        '${Api.baseurl}${Api.socialAudioFollowUser(userId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error following social audio user', error: e);
      return null;
    }
  }

  /// Unfollow user for social audio
  Future<Response?> unfollowSocialAudioUser(String userId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).delete(
        '${Api.baseurl}${Api.socialAudioUnfollowUser(userId)}',
        data: data,
      );
    } catch (e) {
      logger.error('Error unfollowing social audio user', error: e);
      return null;
    }
  }

  /// Get following list for social audio
  Future<Response?> getSocialAudioFollowingList(Map<String, dynamic>? queryParameters) async {
    try {
      return await ref.read(client).get(
        '${Api.baseurl}${Api.socialAudioFollowingList}',
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio following list', error: e);
      return null;
    }
  }

  /// Get followers list for social audio
  Future<Response?> getSocialAudioFollowersList(Map<String, dynamic>? queryParameters) async {
    try {
      return await ref.read(client).get(
        '${Api.baseurl}${Api.socialAudioFollowers}',
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio followers list', error: e);
      return null;
    }
  }

  /// Upload media file
  Future<Map<String, dynamic>?> uploadMedia(File file, {String? type, Map<String, dynamic>? metadata}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        if (type != null) 'type': type,
        if (metadata != null) ...metadata,
      });
      
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.mediaUpload()}',
        data: formData,
      );
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data.toString()};
      }
      return null;
    } catch (e) {
      logger.error('Error uploading media', error: e);
      return null;
    }
  }

  /// Report a chat message
  Future<bool> reportChatMessage({required String messageId, String? reason, String? description}) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}chat/report',
        data: {
          'messageId': messageId,
          if (reason != null) 'reason': reason,
          if (description != null) 'description': description,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error reporting chat message', error: e);
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.connectionBlock()}',
        data: {'userId': userId},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error blocking user', error: e);
      return false;
    }
  }

  /// Quick pronunciation check
  Future<Map<String, dynamic>?> pronunciationQuick({
    required String text,
    required String language,
    String? audioUrl,
  }) async {
    try {
      final data = {
        'text': text,
        'language': language,
        if (audioUrl != null) 'audioUrl': audioUrl,
      };
      
      final res = await ref.read(client).post(
        '${Api.baseurl}pronunciation/quick',
        data: data,
      );
      
      if (res.statusCode == 200) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
      }
      return null;
    } catch (e) {
      logger.error('Error checking pronunciation', error: e);
      return null;
    }
  }

  /// Submit game completion
  Future<bool> submitGameCompletion({
    required String gameType,
    required int languageId,
    required int points,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}${Api.games}/complete',
        data: {
          'gameType': gameType,
          'languageId': languageId,
          'points': points,
          'score': score,
          if (metadata != null) ...metadata,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error submitting game completion', error: e);
      return false;
    }
  }
}
