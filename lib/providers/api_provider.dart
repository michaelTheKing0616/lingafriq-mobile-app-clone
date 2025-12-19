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
      final res = await ref.read(client).get(Api.accountUpdate);
      res.statusCode.toString().log();
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      "Error Account update $e".log("accountUpdate");
      return false;
    }
  }

  /// Search users by handle (global_id) so learners can discover each other
  /// for chats and communities. Requires authentication.
  Future<List<Map<String, dynamic>>> searchUsersByHandle(String handle) async {
    try {
      final res = await ref.read(client).get(
            'accounts/auth/users/search',
            queryParameters: {'handle': handle},
          );
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of blocked users for the current learner
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final res = await ref.read(client).get('user-connections/blocked');
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  /// Report a chat message for moderation
  Future<bool> reportChatMessage({
    required String messageId,
    String? reason,
  }) async {
    try {
      final res = await ref.read(client).post(
            '/chat/messages/$messageId/report',
            data: {
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            },
          );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
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

  /*
   * Subscription API helpers
   */

  Future<Map<String, dynamic>> getSubscription() async {
    try {
      final res = await ref.read(client).get('/subscription');
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSubscription(String tier) async {
    try {
      final res = await ref.read(client).put(
            '/subscription',
            data: {
              'tier': tier.toString().split('.').last,
            },
          );
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final res = await ref.read(client).post('/subscription/cancel');
      if (res.statusCode != 200) throw res.data;
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

  /*
   * User Generated Content (UGC)
   * These helpers wire the mobile app to the backend UGC endpoints:
   *   POST /api/user-content/lessons
   *   POST /api/user-content/quizzes
   *   POST /api/user-content/stories
   *   GET  /api/user-content
   *   POST /api/user-content/share
   *   POST /api/user-content/rate
   */

  Future<Map<String, dynamic>> createUgcLesson(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
            '/api/user-content/lessons',
            data: data,
          );
      if (res.statusCode != 201 && res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUgcQuiz(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
            '/api/user-content/quizzes',
            data: data,
          );
      if (res.statusCode != 201 && res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUgcStory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
            '/api/user-content/stories',
            data: data,
          );
      if (res.statusCode != 201 && res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
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
            '/api/user-content',
            queryParameters: queryParams.isEmpty ? null : queryParams,
          );
      if (res.statusCode != 200) throw res.data;

      final data = res.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }

      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> shareUgcContent({
    required String contentId,
    required String contentType,
    List<String>? userIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'content_id': contentId,
        'content_type': contentType,
      };
      if (userIds != null) {
        payload['shared_with'] = userIds;
      }

      final res = await ref.read(client).post(
            '/api/user-content/share',
            data: payload,
          );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rateUgcContent({
    required String contentId,
    required int rating,
    String? review,
  }) async {
    try {
      final payload = <String, dynamic>{
        'content_id': contentId,
        'rating': rating,
      };
      if (review != null) {
        payload['review'] = review;
      }

      final res = await ref.read(client).post(
            '/api/user-content/rate',
            data: payload,
          );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search chat messages (global or private) using the backend search endpoint.
  Future<List<Map<String, dynamic>>> searchChatMessages({
    required String query,
    String? room,
    String type = 'all', // 'global' | 'private' | 'all'
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'type': type,
        'limit': limit,
      };
      if (room != null && room.isNotEmpty) {
        params['room'] = room;
      }
      final res = await ref.read(client).get(
            '/chat/messages/search',
            queryParameters: params,
          );
      if (res.statusCode != 200) throw res.data;
      final data = res.data['data'] ?? res.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  /// Family subscription: get family progress dashboard
  Future<Map<String, dynamic>> getFamilyProgressDashboard() async {
    try {
      final res = await ref.read(client).get('/api/progress/family/dashboard');
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /*
   * Experiments & feature flags
   * Lightweight configuration returned by /api/experiments/config.
   */

  Future<Map<String, dynamic>> getExperimentsConfig() async {
    try {
      final res = await ref.read(client).get('/api/experiments/config');
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /*
   * Language villages & voice rooms
   */

  /// Get (or lazily create) a language village for the given language.
  Future<Map<String, dynamic>> getVillage(String language) async {
    try {
      final res = await ref.read(client).get('/api/villages/$language');
      if (res.statusCode != 200) throw res.data;
      if (res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// List all villages, optionally filtered by language.
  Future<List<Map<String, dynamic>>> getVillages({String? language}) async {
    try {
      final params = <String, dynamic>{};
      if (language != null && language.isNotEmpty) {
        params['lang'] = language;
      }
      final res = await ref.read(client).get(
            '/api/villages',
            queryParameters: params.isEmpty ? null : params,
          );
      if (res.statusCode != 200) throw res.data;
      final body = res.data;
      final data = body is Map && body['data'] != null ? body['data'] : body;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  /// List recent village voice messages for a language.
  Future<List<Map<String, dynamic>>> getVillageVoiceMessages({
    required String language,
    int limit = 50,
  }) async {
    try {
      final res = await ref.read(client).get(
            '/api/villages/$language/voice-messages',
            queryParameters: {'limit': limit},
          );
      if (res.statusCode != 200) throw res.data;
      final body = res.data;
      final data = body is Map && body['data'] != null ? body['data'] : body;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      rethrow;
    }
  }

  /// Link an uploaded audio media item to a village as a voice message.
  Future<bool> createVillageVoiceMessage({
    required String language,
    required String mediaId,
  }) async {
    try {
      final res = await ref.read(client).post(
            '/api/villages/$language/voice-message',
            data: {'mediaId': mediaId},
          );
      if (res.statusCode != 201 && res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      debugPrint('Error creating village voice message: $e');
      return false;
    }
  }

  /// Request an STT-based summary of recent village voice messages.
  Future<Map<String, dynamic>> summarizeVillageAudio({
    required String language,
    int limit = 10,
  }) async {
    try {
      final res = await ref.read(client).post(
            '/api/voice/stt/summarize-village',
            data: {
              'language': language,
              'limit': limit,
            },
          );
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// Request a summarized transcript of recent village voice messages.
  Future<Map<String, dynamic>> summarizeVillageVoice({
    required String language,
    int limit = 10,
  }) async {
    try {
      final res = await ref.read(client).post(
            '/api/voice/stt/summarize-village',
            data: {
              'language': language,
              'limit': limit,
            },
          );
      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      debugPrint('Error summarizing village voice: $e');
      rethrow;
    }
  }

  /// Record an Ubuntu streak donation when the user would otherwise break their streak.
  Future<bool> donateUbuntuStreak({
    required int streakBefore,
    required int donatedLessons,
    int? donatedXp,
    String? language,
  }) async {
    try {
      final payload = <String, dynamic>{
        'streakBefore': streakBefore,
        'donatedLessons': donatedLessons,
      };
      if (donatedXp != null && donatedXp > 0) {
        payload['donatedXp'] = donatedXp;
      }
      if (language != null && language.isNotEmpty) {
        payload['language'] = language;
      }

      final res = await ref.read(client).post(
            '/api/gamification/ubuntu/donate',
            data: payload,
          );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      // Donation failure should not break streak logic; log and continue.
      debugPrint('Error donating Ubuntu streak: $e');
      return false;
    }
  }

  /*
   * Media import & voice integration helpers
   */

  Future<Map<String, dynamic>> uploadMedia({
    required String filePath,
    required String fileName,
    String? title,
    String? description,
    String? language,
  }) async {
    try {
      final file = await MultipartFile.fromFile(filePath, filename: fileName);
      final formData = FormData.fromMap({
        'file': file,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (language != null) 'language': language,
      });

      final res = await ref.read(client).post(
            '/media/upload',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );

      if (res.statusCode != 201 && res.statusCode != 200) throw res.data;
      final body = res.data;
      if (body is Map && body['data'] != null) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return Map<String, dynamic>.from(body ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> transcribeAudioFile({
    required String filePath,
    required String fileName,
    String? language,
    String task = 'transcribe',
  }) async {
    try {
      final file = await MultipartFile.fromFile(filePath, filename: fileName);
      final formData = FormData.fromMap({
        'audio': file,
        if (language != null) 'language': language,
        'task': task,
      });

      final res = await ref.read(client).post(
            '/api/voice/stt/transcribe',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );

      if (res.statusCode != 200) throw res.data;
      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// Quick pronunciation scoring via voice-service proxy.
  /// Proxies to: POST /api/voice/pronunciation/quick
  Future<Map<String, dynamic>> pronunciationQuick({
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    try {
      final file = File(audioPath);
      final fileName = audioPath.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'learner_audio': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'expected_text': expectedText,
        'language': language,
      });

      final res = await ref.read(client).post(
            '/voice/pronunciation/quick',
            data: formData,
          );

      if (res.statusCode != 200) {
        throw res.data;
      }

      return Map<String, dynamic>.from(res.data ?? {});
    } catch (e) {
      debugPrint('Error calling pronunciationQuick: $e');
      rethrow;
    }
  }

  Future<bool> linkMediaToLesson({
    required String mediaId,
    required String lessonId,
    String? summary,
    List<String>? keyPhrases,
    String? cefrLevel,
  }) async {
    try {
      final payload = <String, dynamic>{
        'lesson_id': lessonId,
      };
      if (summary != null && summary.isNotEmpty) {
        payload['summary'] = summary;
      }
      if (keyPhrases != null && keyPhrases.isNotEmpty) {
        payload['key_phrases'] = keyPhrases;
      }
      if (cefrLevel != null && cefrLevel.isNotEmpty) {
        payload['cefr_level'] = cefrLevel;
      }

      final res = await ref.read(client).post(
            '/media/$mediaId/link-lesson',
            data: payload,
          );
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      return false;
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
}
