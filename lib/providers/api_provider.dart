import 'dart:async';
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
      if (res.statusCode != 200) throw res.data;
      token = res.data['access'];

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
      debugPrint('Calling accountUpdate endpoint');
      final res = await ref.read(client).get(
        Api.accountUpdate,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      res.statusCode.toString().log();
      debugPrint('Account update response status: ${res.statusCode}');
      
      if (res.statusCode != 200) {
        debugPrint('Account update failed with status: ${res.statusCode}');
        throw res.data ?? 'Account update failed';
      }
      
      if (res.data is Map) {
        final data = res.data as Map;
        debugPrint('Account update response data keys: ${data.keys.toList()}');
      }
      
      return true;
    } catch (e) {
      debugPrint("Error Account update: $e");
      "Error Account update $e".log("accountUpdate");
      return false;
    }
  }
  
  Future<bool> submitGameCompletion({
    required String gameType,
    required int languageId,
    required int points,
    required int score,
  }) async {
    try {
      debugPrint('Submitting game completion: $gameType, language: $languageId, points: $points, score: $score');
      final pointsSuccess = await updateUserPoints(points);
      if (pointsSuccess) {
        debugPrint('Points updated successfully: $points');
      }
      await accountUpdate();
      return pointsSuccess;
    } catch (e) {
      debugPrint('Error submitting game completion: $e');
      return false;
    }
  }

  Future<bool> updateUserPoints(int points) async {
    try {
      final res = await ref.read(client).post(
        Api.updateUserPoints,
        data: {'points': points},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating user points: $e');
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

  Future<Map<String, dynamic>> getLoadingScreenContent() async {
    try {
      final res = await ref.read(client).get(Api.loadingScreen);
      if (res.statusCode != 200) throw res.data;
      return res.data['result'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

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

  // Lessons Section
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

  Future<List<SectionLessonModel>> getSectionLessons(int lessonId) async {
    try {
      final res = await ref.read(client).get(Api.sectionLessonsList(lessonId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;
      final dataList = <Map<String, dynamic>>[];
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }
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
      }).toList();
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  // Mannerisms Section
  Future<MannerismResponse> getMannerisms(int? id) async {
    try {
      final res = await ref.read(client).get(Api.mannerism);
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
      mappedMannerismsList.sort((a, b) {
        if (a.date_time == null || b.date_time == null) return 0;
        return a.date_time!.compareTo(b.date_time!);
      });
      return mappedMannerismsList;
    } catch (e) {
      rethrow;
    }
  }

  // History Section
  Future<HistoryResponse> getHistory(int? id) async {
    try {
      final res = await ref.read(client).get(Api.history);
      if (res.statusCode != 200) throw res.data;
      return HistoryResponse.fromMap(res.data['result'], res.data['total_score']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SectionHistoryModel>> getSectionHistory(int historyId) async {
    try {
      final res = await ref.read(client).get(Api.sectionHistoryList(historyId));
      if (res.statusCode != 200) throw res.data;
      final resList = res.data as List;
      final dataList = <Map<String, dynamic>>[];
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }
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
      }).toList();
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> markAsComplete(String endpointToHit, {int maxRetries = 2}) async {
    "Marking as complete $endpointToHit".log("endpointToHit");
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
        if (attempt > 0) {
          debugPrint('Retrying markAsComplete (attempt ${attempt + 1}/${maxRetries + 1})');
          await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
        }
        
      state = state.copyWith(isLoading: true);
        
        // Add timeout to prevent infinite loading
        final res = await ref.read(client).patch(
          endpointToHit,
          options: Options(
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Request timed out after 15 seconds');
          },
        );
        
      if (res.statusCode != 200) throw res.data;
        
        // Update account in background (don't wait for it)
      accountUpdate().then((value) {
        "Account updated".log("accountUpdate");
        final userId = ref.read(userProvider)?.id;
        if (userId != null) {
          getProfileUser(userId).then((user) {
            ref.read(userProvider.notifier).overrideUser(user);
            }).catchError((e) {
              "Error getting profile user $e".log("accountUpdate");
          });
        }
      }).catchError((e) {
        "Error Account update $e".log("accountUpdate");
      });
        
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
        
        // If it's the last attempt or a non-retryable error, handle it
        if (attempt == maxRetries || e is TimeoutException) {
          debugPrint('markAsComplete failed after ${attempt + 1} attempts: $e');
          // Don't show dialog for timeout - let the caller handle it
          if (e is! TimeoutException) {
      ref.read(dialogProvider(e)).showExceptionDialog();
          }
      return false;
    }
        
        // Otherwise, retry
        debugPrint('markAsComplete attempt ${attempt + 1} failed, retrying...');
      }
    }
    
    return false;
  }

  // Random Quiz Section
  Future<List<RandomQuizLessonModel>> getRandomQuizLessons(int languageId) async {
    try {
      state = state.copyWith(isLoading: true);
      debugPrint('Fetching random quiz for language ID: $languageId');
      debugPrint('API endpoint: ${Api.randomQuiz(languageId)}');
      debugPrint('Full URL: ${Api.baseurl}${Api.randomQuiz(languageId)}');
      
      // Ensure we have a valid token
      final token = this.token;
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false);
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('Using token: ${token.substring(0, 20)}...');
      
      final res = await ref.read(client).get(
        Api.randomQuiz(languageId),
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx
        ),
      );
      
      debugPrint('Quiz API response status: ${res.statusCode}');
      debugPrint('Quiz API response data type: ${res.data.runtimeType}');
      
      if (res.statusCode == 401 || res.statusCode == 403) {
        state = state.copyWith(isLoading: false);
        throw Exception('Authentication failed. Please log in again.');
      }
      
      if (res.statusCode != 200) {
        state = state.copyWith(isLoading: false);
        final errorMsg = res.data?.toString() ?? 'Failed to fetch quiz lessons';
        debugPrint('Quiz API error: $errorMsg');
        throw Exception('Failed to load quizzes. ${res.statusCode == 404 ? "No quizzes available for this language." : errorMsg}');
      }
      
      List<dynamic> resList;
      if (res.data is List) {
        resList = res.data as List;
      } else if (res.data is Map) {
        final mapData = res.data as Map;
        if (mapData.containsKey('results')) {
          resList = mapData['results'] as List? ?? [];
        } else if (mapData.containsKey('data')) {
          resList = mapData['data'] as List? ?? [];
        } else {
          resList = [res.data];
        }
      } else {
        resList = [];
      }
      
      debugPrint('Quiz API returned ${resList.length} items');
      final dataList = <Map<String, dynamic>>[];
      
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            if (element is Map) {
              dataList.add(element as Map<String, dynamic>);
            }
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }
      
      debugPrint('Processed ${dataList.length} quiz items');
      final mappedLessonsList = dataList
          .map<List<RandomQuizLessonModel>>((randomQuiz) {
            try {
              final instantQuestions =
                  randomQuiz.containsKey("inst_question") ? randomQuiz["inst_question"] as List : [];
              final wordQuestions =
                  randomQuiz.containsKey("word_question") ? randomQuiz["word_question"] as List : [];
              
              final mappedInstantQuestions = instantQuestions.map((e) {
                if (e is! Map) {
                  return null;
                }
                Map questionData;
                if (e.containsKey("question") && e["question"] is Map) {
                  questionData = e["question"] as Map;
                } else {
                  questionData = e;
                }
                
                return RandomQuizLessonModel(
                  id: questionData['id'] ?? e['id'] ?? 0,
                  title: questionData['title'] ?? e['title'] ?? '',
                  score: questionData['score'] ?? e['score'] ?? 0,
                  types: questionData['types'] ?? e['types'] ?? '',
                  dateTime: questionData['date_time'] ?? e['date_time'] ?? '',
                  completed: questionData['completed'] ?? e['completed'] ?? false,
                  completed_by: questionData['completed_by'] ?? e['completed_by'],
                  otherData: e,
                );
              }).whereType<RandomQuizLessonModel>().toList();
              
              final mappedWordQuestions = wordQuestions.map((e) {
                if (e is! Map) {
                  throw Exception("Invalid word question format");
                }
                return RandomQuizLessonModel(
                  id: e['id'],
                  title: e['title'] ?? '',
                  score: e['score'] ?? 0,
                  types: e['types'] ?? '',
                  dateTime: e['date_time'] ?? '',
                  completed: e['completed'] ?? false,
                  completed_by: e['completed_by'],
                  otherData: e,
                );
              }).toList();
              
              final merged = [...mappedInstantQuestions, ...mappedWordQuestions];
              return merged;
            } catch (e) {
              "Error parsing quiz data: $e".log("getRandomQuizLessons");
              return <RandomQuizLessonModel>[];
            }
          })
          .toList()
          .expand((e) => e)
          .toList();
      
      state = state.copyWith(isLoading: false);
      return mappedLessonsList;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      "Error in getRandomQuizLessons: $e".log("getRandomQuizLessons");
      rethrow;
    }
  }

  // Language Quiz Section
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
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }
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
      }).toList();
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

  // History Quiz Section
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
      for (var result in resList) {
        if (result is List) {
          for (var element in result) {
            dataList.add(element);
          }
        } else if (result is Map) {
          dataList.add(result as Map<String, dynamic>);
        }
      }
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
      }).toList();
      mappedLessonsList.sort((a, b) {
        return a.date.compareTo(b.date);
      });
      return mappedLessonsList;
    } catch (e) {
      rethrow;
    }
  }

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

  // Progress Tracking & Daily Goals API Methods
  Future<Map<String, dynamic>> getDailyGoals() async {
    try {
      final res = await ref.read(client).get(Api.dailyGoals);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateDailyGoal(String type, int increment) async {
    try {
      final res = await ref.read(client).post(
        Api.updateDailyGoal,
        data: {'type': type, 'increment': increment},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating daily goal: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getProgressMetrics() async {
    try {
      final res = await ref.read(client).get(Api.progressMetrics);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProgressMetrics(Map<String, dynamic> metrics) async {
    try {
      final res = await ref.read(client).post(
        Api.updateProgressMetrics,
        data: metrics,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating progress metrics: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final res = await ref.read(client).get(Api.achievements);
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> unlockAchievement(String achievementId) async {
    try {
      final res = await ref.read(client).post(
        Api.unlockAchievement,
        data: {'achievement_id': achievementId},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      return false;
    }
  }

  Future<bool> updateXP(int totalXP, int level) async {
    try {
      final res = await ref.read(client).post(
        Api.updateXP,
        data: {'total_xp': totalXP, 'level': level},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating XP: $e');
      return false;
    }
  }

  Future<bool> updateDailyStreak(int streak) async {
    try {
      final res = await ref.read(client).post(
        Api.updateDailyStreak,
        data: {'streak': streak},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating daily streak: $e');
      return false;
    }
  }

  Future<bool> syncAiChatHistory(String mode, List<Map<String, dynamic>> messages) async {
    try {
      final res = await ref.read(client).post(
        Api.syncAiChatHistory,
        data: {
          'mode': mode,
          'messages': messages,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error syncing AI chat history: $e');
      return false;
    }
  }


  /// Award XP via server-authoritative XP service
  /// POST /api/gamification/xp/award
  Future<bool> awardXP({
    required String userId,
    required String source, // 'quiz', 'story', 'chat', 'game', 'event', 'tribe', 'lesson', 'review'
    required String sourceId, // Unique ID for this specific event
    required int amount,
    double difficultyMultiplier = 1.0,
    double repetitionFactor = 1.0,
  }) async {
    try {
      final res = await ref.read(client).post(
        '/api/gamification/xp/award',
        data: {
          'source': source,
          'sourceId': sourceId,
          'baseXP': amount,
          'metadata': {
            'difficultyMultiplier': difficultyMultiplier,
            'repetitionFactor': repetitionFactor,
          },
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      return false;
    }
  }

  /// Get user's current XP and level
  /// GET /api/gamification/xp/total
  Future<Map<String, dynamic>?> getUserXP(String userId) async {
    try {
      final res = await ref.read(client).get('/api/gamification/xp/total');
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      return null;
    }
  }

  Future<bool> trackArticleView(String articleId) async {
    try {
      final res = await ref.read(client).post(Api.cultureMagazineTrackView(articleId));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error tracking article view: $e');
      return false;
    }
  }

  Future<bool> toggleArticleFavorite(String articleId, bool isFavorite) async {
    try {
      final res = await ref.read(client).post(
        Api.cultureMagazineToggleFavorite(articleId),
        data: {'favorite': isFavorite},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error toggling article favorite: $e');
      return false;
    }
  }

  // Global Rankings & Statistics API Methods
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final res = await ref.read(client).get(Api.globalStats);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({int limit = 100}) async {
    try {
      final res = await ref.read(client).get('${Api.globalLeaderboard}?limit=$limit');
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopLanguages() async {
    try {
      final res = await ref.read(client).get(Api.topLanguages);
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  // Culture Content API Methods
  Future<List<Map<String, dynamic>>> getCultureContent({String? type}) async {
    try {
      String url = Api.cultureMagazineArticles;
      if (type != null) {
        url = Api.cultureMagazineArticlesByCategory(type);
      }
      final res = await ref.read(client).get(url);
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is Map && data.containsKey('data') && data['data'] is Map && data['data'].containsKey('docs')) {
        return List<Map<String, dynamic>>.from(data['data']['docs']);
      }
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCultureContentById(String id) async {
    try {
      final res = await ref.read(client).get(Api.cultureMagazineArticleBySlug(id));
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is Map && data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Chat & Social API Methods
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      final res = await ref.read(client).get(Api.chatRooms);
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String room, {int limit = 50}) async {
    try {
      final res = await ref.read(client).get('${Api.chatMessages(room)}?limit=$limit');
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    try {
      final res = await ref.read(client).get(Api.onlineUsers);
      if (res.statusCode != 200) throw res.data;
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      rethrow;
    }
  }

  // Backend Sync Endpoints
  Future<bool> syncGamification(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.syncGamification, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing gamification: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getGamification(String userId) async {
    try {
      final res = await ref.read(client).get(Api.getGamification(userId));
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting gamification: $e');
      return null;
    }
  }

  Future<bool> syncGameSession(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.gameSessionStart, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing game session: $e');
      rethrow;
    }
  }

  Future<bool> syncAIChatHistory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.aiChatHistorySync, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing AI chat history: $e');
      rethrow;
    }
  }

  /// Save AI chat history scoped by mode × language
  /// POST /api/ai-chat-history
  Future<bool> saveAiChatHistory({
    required String mode,
    required String languageCode,
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return false;
      
      final res = await ref.read(client).post(
        Api.aiChatHistorySync,
        data: {
          'mode': mode,
          'languageCode': languageCode,
          'messages': messages,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving AI chat history: $e');
      return false;
    }
  }

  /// Get AI chat history scoped by mode × language
  /// GET /api/ai-chat-history?mode=translation&languageCode=yoruba
  Future<List<Map<String, dynamic>>?> getAiChatHistory({
    required String mode,
    required String languageCode,
  }) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return null;
      
      final res = await ref.read(client).get(
        Api.getAIChatHistory(mode, languageCode),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data.containsKey('messages')) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        return List<Map<String, dynamic>>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting AI chat history: $e');
      return null;
    }
  }

  Future<bool> syncAIChatSRS(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.aiChatSRSSync, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing AI chat SRS: $e');
      rethrow;
    }
  }

  Future<bool> syncProgress(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.progressActivity, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing progress: $e');
      rethrow;
    }
  }

  Future<bool> syncOnboarding(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.onboardingSave, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing onboarding: $e');
      rethrow;
    }
  }

  Future<bool> syncTelemetry(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.gameTelemetry, data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error syncing telemetry: $e');
      rethrow;
    }
  }

  // NEW API METHODS - Personalization, Subscription, Offline Content, Learning Path, Grammar, Notifications

  // Personalization
  Future<Map<String, dynamic>?> getPersonalization() async {
    try {
      final res = await ref.read(client).get(Api.getPersonalization);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting personalization: $e');
      return null;
    }
  }

  Future<bool> updatePersonalization(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).put(Api.updatePersonalization, data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error updating personalization: $e');
      return false;
    }
  }

  // Subscription
  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      final res = await ref.read(client).get(Api.getSubscription);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting subscription: $e');
      return null;
    }
  }

  Future<bool> updateSubscription(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).put(Api.updateSubscription, data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final res = await ref.read(client).post(Api.cancelSubscription);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      return false;
    }
  }

  // Offline Content
  Future<Map<String, dynamic>?> getOfflineContent() async {
    try {
      final res = await ref.read(client).get(Api.getOfflineContent);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting offline content: $e');
      return null;
    }
  }

  Future<bool> updateOfflineContent(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).put(Api.updateOfflineContent, data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error updating offline content: $e');
      return false;
    }
  }

  // Learning Path
  Future<Map<String, dynamic>?> getLearningPath(String language, String type) async {
    try {
      final res = await ref.read(client).get(Api.getLearningPath(language, type));
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting learning path: $e');
      return null;
    }
  }

  Future<bool> createLearningPath(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.createLearningPath, data: data);
      if (res.statusCode != 201) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error creating learning path: $e');
      return false;
    }
  }

  Future<bool> updateLearningPath(String language, String type, Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).put(Api.updateLearningPath(language, type), data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error updating learning path: $e');
      return false;
    }
  }

  Future<bool> completeModule(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.completeModule, data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error completing module: $e');
      return false;
    }
  }

  // Grammar
  Future<Map<String, dynamic>?> getGrammarExplanation(String language, String grammarPoint) async {
    try {
      final res = await ref.read(client).get(Api.getGrammarExplanation(language, grammarPoint));
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting grammar explanation: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getGrammarByLanguage(String language, {String? difficulty}) async {
    try {
      final res = await ref.read(client).get(Api.getGrammarByLanguage(language, difficulty));
      if (res.statusCode != 200) throw res.data;
      return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting grammar by language: $e');
      return [];
    }
  }

  // Notifications
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final res = await ref.read(client).get(Api.getNotificationSettings);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return null;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).put(Api.updateNotificationSettings, data: data);
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      return false;
    }
  }

  // Telemetry
  Future<bool> sendTelemetry(dynamic data) async {
    try {
      // Accept both single event and batch of events
      final payload = data is List ? {'events': data} : data;
      final res = await ref.read(client).post(Api.sendTelemetry, data: payload);
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error sending telemetry: $e');
      return false;
    }
  }

  // Sync Game SRS
  Future<bool> syncGameSRS(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.syncGameSRS, data: data);
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error syncing game SRS: $e');
      return false;
    }
  }

  // User-Generated Content APIs
  Future<Map<String, dynamic>?> createUgcLesson(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.createUgcLesson, data: data);
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating UGC lesson: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createUgcQuiz(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.createUgcQuiz, data: data);
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating UGC quiz: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createUgcStory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(Api.createUgcStory, data: data);
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating UGC story: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserContent({
    String? language,
    String? contentType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (language != null) queryParams['language'] = language;
      if (contentType != null) queryParams['content_type'] = contentType;
      
      final res = await ref.read(client).get(
        Api.getUserContent,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      if (res.statusCode != 200) throw res.data;
      return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting user content: $e');
      return [];
    }
  }

  Future<bool> shareUgcContent({
    required String contentId,
    required String contentType,
    List<String>? userIds,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.shareUgcContent,
        data: {
          'content_id': contentId,
          'content_type': contentType,
          'shared_with': userIds,
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error sharing UGC content: $e');
      return false;
    }
  }

  Future<bool> rateUgcContent({
    required String contentId,
    required int rating,
    String? review,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.rateUgcContent,
        data: {
          'content_id': contentId,
          'rating': rating,
          'review': review,
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error rating UGC content: $e');
      return false;
    }
  }

  // ============================================
  // ADVANCED GAMIFICATION APIs
  // ============================================

  // --- Daily Challenges ---
  Future<Map<String, dynamic>?> getDailyChallenges() async {
    try {
      final res = await ref.read(client).get(Api.dailyChallenges);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting daily challenges: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateChallengeProgress({
    required String type,
    required int amount,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.dailyChallengesProgress,
        data: {'type': type, 'amount': amount},
      );
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> claimChallengeReward(String challengeId) async {
    try {
      final res = await ref.read(client).post(
        Api.dailyChallengesClaim,
        data: {'challengeId': challengeId},
      );
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error claiming challenge reward: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> claimAllChallengeRewards() async {
    try {
      final res = await ref.read(client).post(Api.dailyChallengesClaimAll);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error claiming all rewards: $e');
      return null;
    }
  }

  // --- League System ---
  Future<Map<String, dynamic>?> getLeagueStanding() async {
    try {
      final res = await ref.read(client).get(Api.leagueStanding);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting league standing: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLeaderboard({
    String tier = 'bronze',
    String type = 'weekly',
    int limit = 30,
  }) async {
    try {
      final res = await ref.read(client).get(
        Api.leagueLeaderboard,
        queryParameters: {'tier': tier, 'type': type, 'limit': limit},
      );
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return null;
    }
  }

  Future<bool> addLeagueXP(int amount) async {
    try {
      final res = await ref.read(client).post(
        Api.leagueAddXP,
        data: {'amount': amount},
      );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error adding league XP: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLeagueHistory() async {
    try {
      final res = await ref.read(client).get(Api.leagueHistory);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting league history: $e');
      return null;
    }
  }

  // --- Milestones ---
  Future<Map<String, dynamic>?> getUserMilestones() async {
    try {
      final res = await ref.read(client).get(Api.milestones);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting milestones: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateMilestoneStats(Map<String, dynamic> stats) async {
    try {
      final res = await ref.read(client).post(
        Api.milestonesUpdate,
        data: {'stats': stats},
      );
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating milestone stats: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMilestoneDefinitions() async {
    try {
      final res = await ref.read(client).get(Api.milestonesDefinitions);
      if (res.statusCode != 200) throw res.data;
      final data = res.data as Map<String, dynamic>;
      return (data['definitions'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting milestone definitions: $e');
      return [];
    }
  }

  // --- Hearts System ---
  Future<Map<String, dynamic>?> getHeartsStatus() async {
    try {
      final res = await ref.read(client).get(Api.hearts);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting hearts status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> useHeart() async {
    try {
      final res = await ref.read(client).post(Api.heartsUse);
      if (res.statusCode != 200 && res.statusCode != 400) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error using heart: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> refillHearts() async {
    try {
      final res = await ref.read(client).post(Api.heartsRefill);
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error refilling hearts: $e');
      return null;
    }
  }

  Future<bool> toggleChallengeMode({bool? enabled}) async {
    try {
      final res = await ref.read(client).post(
        Api.heartsToggleChallengeMode,
        data: enabled != null ? {'enabled': enabled} : null,
      );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error toggling challenge mode: $e');
      return false;
    }
  }

  Future<bool> addBonusHearts(int count) async {
    try {
      final res = await ref.read(client).post(
        Api.heartsBonus,
        data: {'count': count},
      );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error adding bonus hearts: $e');
      return false;
    }
  }

  // --- Voice Contributions ---
  Future<Map<String, dynamic>?> submitVoiceContribution({
    required String language,
    required String text,
    required String category,
    required List<int> audioBytes,
    required double duration,
    required int sampleRate,
    required int numChannels,
    required bool consentGiven,
  }) async {
    try {
      final formData = FormData.fromMap({
        'language': language,
        'text': text,
        'category': category,
        'duration': duration,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'consentGiven': consentGiven.toString(),
        'audio': MultipartFile.fromBytes(audioBytes, filename: 'recording.wav'),
      });
      
      final res = await ref.read(client).post(
        Api.voiceContributions,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error submitting voice contribution: $e');
      return null;
    }
  }

  Future<List<String>> getVoiceContributionPrompts({
    required String language,
    String? category,
    int count = 5,
  }) async {
    try {
      final res = await ref.read(client).get(
        Api.voiceContributionPrompts,
        queryParameters: {
          'language': language,
          'category': category,
          'count': count,
        },
      );
      if (res.statusCode != 200) throw res.data;
      final data = res.data as Map<String, dynamic>;
      return (data['prompts'] as List).cast<String>();
    } catch (e) {
      debugPrint('Error getting contribution prompts: $e');
      return [];
    }
  }

  // --- Vocabulary System ---
  Future<Map<String, dynamic>?> addVocabularyWord({
    required String word,
    required String language,
    required String translation,
    String? meaning,
    String? exampleSentence,
    List<String>? tags,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.vocabularyWords,
        data: {
          'word': word,
          'language': language,
          'translation': translation,
          'meaning': meaning,
          'exampleSentence': exampleSentence,
          'tags': tags,
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error adding vocabulary word: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVocabularyWords({
    String? language,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (language != null) params['language'] = language;
      if (tags != null) params['tags'] = tags.join(',');
      if (isFavorite != null) params['isFavorite'] = isFavorite.toString();
      
      final res = await ref.read(client).get(
        Api.vocabularyWords,
        queryParameters: params.isEmpty ? null : params,
      );
      if (res.statusCode != 200) throw res.data;
      final data = res.data as Map<String, dynamic>;
      return (data['words'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting vocabulary words: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWordsDueForReview({String? language}) async {
    try {
      final res = await ref.read(client).get(
        Api.vocabularyDueForReview,
        queryParameters: language != null ? {'language': language} : null,
      );
      if (res.statusCode != 200) throw res.data;
      final data = res.data as Map<String, dynamic>;
      return (data['words'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting words due for review: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> submitVocabularyReview({
    required String wordId,
    required int quality, // 0-5
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.vocabularyReview(wordId),
        data: {'quality': quality},
      );
      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error submitting vocabulary review: $e');
      return null;
    }
  }

  // --- Learner Progress ---
  Future<Map<String, dynamic>?> getLearnerProgress({
    required String userId,
    required String language,
  }) async {
    try {
      final res = await ref.read(client).get(Api.learnerProgressGet(userId, language));
      if (res.statusCode != 200 && res.statusCode != 201) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting learner progress: $e');
      return null;
    }
  }

  Future<bool> recordLearnerActivity({
    required String userId,
    required String language,
  }) async {
    try {
      final res = await ref.read(client).post(Api.learnerProgressActivity(userId, language));
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error recording activity: $e');
      return false;
    }
  }

  Future<String?> getAICoachingRecommendation({
    required String userId,
    required String language,
  }) async {
    try {
      final res = await ref.read(client).post(Api.learnerProgressCoach(userId, language));
      if (res.statusCode != 200) throw res.data;
      final data = res.data as Map<String, dynamic>;
      return data['recommendation'] as String?;
    } catch (e) {
      debugPrint('Error getting AI coaching: $e');
      return null;
    }
  }

}
