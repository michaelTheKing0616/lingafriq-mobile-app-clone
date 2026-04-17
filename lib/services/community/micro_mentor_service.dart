import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/utils/api_service.dart';

final microMentorServiceProvider = Provider<MicroMentorService>((ref) {
  return MicroMentorService();
});

class MicroMentorService {
  Future<List<Map<String, dynamic>>> listMentors({String? language, int limit = 30}) async {
    await ApiService.initialize();
    final uri = Uri.parse(ApiContract.url(ApiContract.microMentorsV2.mentors)).replace(
      queryParameters: {
        'limit': '$limit',
        if (language != null && language.trim().isNotEmpty) 'language': language.trim().toLowerCase(),
      },
    );
    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200) throw Exception('Failed to load mentors');
    final data = res.data;
    if (data is! Map) return [];
    final rows = data['data'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> upsertMyProfile(Map<String, dynamic> body) async {
    await ApiService.initialize();
    final res = await ApiService.put(
      ApiContract.url(ApiContract.microMentorsV2.mentorsMe),
      data: body,
    );
    if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to save mentor profile');
    final m = res.data as Map;
    return m.cast<String, dynamic>();
  }

  Future<String> requestSession({
    required String mentorUserId,
    required String language,
    DateTime? scheduledStartTime,
    int durationMinutes = 10,
    String? dialectTag,
  }) async {
    await ApiService.initialize();
    final payload = {
      'mentorUserId': mentorUserId,
      'language': language.trim().toLowerCase(),
      'scheduledStartTime': (scheduledStartTime ?? DateTime.now().add(const Duration(minutes: 30))).toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      if (dialectTag != null && dialectTag.trim().isNotEmpty) 'dialectTag': dialectTag.trim(),
    };

    try {
      final res = await ApiService.post(
        ApiContract.url(ApiContract.microMentorsV2.sessions),
        data: payload,
      );
      if (res.statusCode == 201 && res.data is Map) {
        final data = (res.data as Map)['data'];
        if (data is Map && data['id'] != null) return data['id'].toString();
      }
      throw Exception('Request failed');
    } catch (_) {
      await PersistedOutboxService.instance.enqueue(
        type: 'micro_mentor_session_request',
        payload: payload.cast<String, dynamic>(),
      );
      return 'queued';
    }
  }

  Future<List<Map<String, dynamic>>> listSessions({String role = 'any', int limit = 50}) async {
    await ApiService.initialize();
    final uri = Uri.parse(ApiContract.url(ApiContract.microMentorsV2.sessions)).replace(
      queryParameters: {
        'role': role,
        'limit': '$limit',
      },
    );
    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200) throw Exception('Failed to load sessions');
    final data = res.data;
    if (data is! Map) return [];
    final rows = data['data'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    await ApiService.initialize();
    final res = await ApiService.get(ApiContract.url(ApiContract.microMentorsV2.session(sessionId)));
    if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to load session');
    final data = (res.data as Map)['data'];
    if (data is! Map) throw Exception('Invalid session payload');
    return data.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> mentorRespond({required String sessionId, required String action}) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.url(ApiContract.microMentorsV2.sessionRespond(sessionId)),
      data: {'action': action},
    );
    if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to respond');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> joinSession(String sessionId) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.url(ApiContract.microMentorsV2.sessionJoin(sessionId)),
      data: const {},
    );
    if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to join');
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Submits a safety report for this session (participant-only). [category] must match backend enums.
  Future<Map<String, dynamic>> reportSession({
    required String sessionId,
    required String category,
    required String details,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.url(ApiContract.microMentorsV2.sessionReport(sessionId)),
      data: {
        'category': category,
        'details': details,
      },
    );
    if (res.statusCode != 201 || res.data is! Map) throw Exception('Failed to submit report');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> setConsent({required String sessionId, required bool consent}) async {
    await ApiService.initialize();
    final res = await ApiService.put(
      ApiContract.url(ApiContract.microMentorsV2.sessionConsent(sessionId)),
      data: {'consent': consent},
    );
    if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to update consent');
    final data = (res.data as Map)['data'];
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }

  Future<Map<String, dynamic>> submitRubric({
    required String sessionId,
    required Map<String, dynamic> rubric,
    bool generateSummary = true,
  }) async {
    await ApiService.initialize();
    final payload = {
      'rubric': rubric,
      'generateSummary': generateSummary,
    };

    try {
      final res = await ApiService.post(
        ApiContract.url(ApiContract.microMentorsV2.sessionRubric(sessionId)),
        data: payload,
      );
      if (res.statusCode != 200 || res.data is! Map) throw Exception('Failed to submit rubric');
      return (res.data as Map).cast<String, dynamic>();
    } catch (_) {
      await PersistedOutboxService.instance.enqueue(
        type: 'micro_mentor_rubric_submit',
        payload: {
          'sessionId': sessionId,
          ...payload,
        }.cast<String, dynamic>(),
      );
      return {'success': true, 'queued': true};
    }
  }
}
