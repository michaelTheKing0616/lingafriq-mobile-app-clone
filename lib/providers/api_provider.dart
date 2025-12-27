import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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

final apiProvider = NotifierProvider<ApiProvider, BaseProviderState>(() {
  return ApiProvider();
});

class ApiProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  String? token;
  String? refreshToken;

  /// Refresh access token using refresh token
  Future<String?> refreshAccessToken() async {
    try {
      if (refreshToken == null || refreshToken.isEmpty) {
        // Try to get from shared preferences
        final prefs = await ref.read(sharedPreferencesProvider);
        refreshToken = await prefs.getRefreshToken();
      }
      
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final res = await ref.read(client).post(
        Api.refreshToken,
        data: { 'refreshToken': refreshToken },
      );

      if (res.statusCode == 200 && (res.data['accessToken'] || res.data['access'])) {
        // Handle both formats: backend returns 'accessToken' and 'refreshToken'
        token = res.data['accessToken'] ?? res.data['access'];
        refreshToken = res.data['refreshToken'] ?? res.data['refresh'] ?? refreshToken;
        
        // Store tokens
        final prefs = await ref.read(sharedPreferencesProvider);
        await prefs.storeAuthTokens(token!, refreshToken!);
        
        return token;
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
      if (token != null && token.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
        final prefs = await ref.read(sharedPreferencesProvider);
        await prefs.storeAuthTokens(token!, refreshToken!);
      }

      final email = data['email'] as String;
      ProfileModel? user = await ref.read(sharedPreferencesProvider).getUser(email);

      if (user == null || user.email != email) {
        final userInfo = await getUserInfo();
        user = await getProfileUser(userInfo.id);

        await ref.read(sharedPreferencesProvider).storeUser(user, userInfo.email);
      }

      getUserInfo().then((userInfo) async {
        user = await getProfileUser(userInfo.id);
        ref.read(userProvider.notifier).overrideUser(user);
        await ref.read(sharedPreferencesProvider).storeUser(user!, userInfo.email);
      });

      return user!;
    } catch (e) {
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
      accountUpdate().then((value) {
        "Account updated".log("accountUpdate");
        final userId = ref.read(userProvider)?.id;
        if (userId != null) {
          getProfileUser(userId).then((user) {
            ref.read(userProvider.notifier).overrideUser(user);
          });
        }
      }).catchError((e) {
        "Error Account update $e".log("accountUpdate");
      });

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
  Future<bool> regiserDevice() async {
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
      debugPrint('Error awarding XP: $e');
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
      debugPrint('Error getting user XP: $e');
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
      debugPrint('Error recording learner activity: $e');
      return false;
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
      debugPrint('Error getting daily goals: $e');
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
      debugPrint('Error syncing gamification: $e');
      return false;
    }
  }

  /// Save AI chat history
  Future<bool> saveAiChatHistory(Map<String, dynamic> chatData) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}api/ai-chat/history',
        data: chatData,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving AI chat history: $e');
      return false;
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
      debugPrint('Error updating daily goal: $e');
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
      debugPrint('Error updating user points: $e');
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
      debugPrint('Error getting progress metrics: $e');
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
      debugPrint('Error updating progress metrics: $e');
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
      debugPrint('Error getting achievements: $e');
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
      debugPrint('Error unlocking achievement: $e');
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
      debugPrint('Error updating XP: $e');
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
      debugPrint('Error updating challenge progress: $e');
      return false;
    }
  }

  /// Update milestone stats
  Future<bool> updateMilestoneStats(Map<String, dynamic> stats) async {
    try {
      final res = await ref.read(client).post(
        Api.milestones,
        data: stats,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error updating milestone stats: $e');
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
      debugPrint('Error adding league XP: $e');
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
      debugPrint('Error using heart: $e');
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
      debugPrint('Error refilling hearts: $e');
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
      debugPrint('Error toggling challenge mode: $e');
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
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Send telemetry events
  Future<bool> sendTelemetry(List<Map<String, dynamic>> events) async {
    try {
      final res = await ref.read(client).post(
        '${Api.baseurl}api/telemetry',
        data: {'events': events},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending telemetry: $e');
      return false;
    }
  }

  /// Generic POST helper method for flexibility
  Future<Response?> post(String path, {dynamic data}) async {
    try {
      return await ref.read(client).post(path, data: data);
    } catch (e) {
      debugPrint('Error in POST $path: $e');
      return null;
    }
  }
}
