import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Live classroom: personal notes + speaker queue (Mongo-backed, `/api/classroom/*`).
class ClassroomService {
  ClassroomService(this._dio);

  final Dio _dio;

  Future<({Map<String, dynamic>? meta, List<Map<String, dynamic>> notes})> listNotes(
    String tribeId,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.notes(tribeId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to load notes',
      );
    }
    final raw = data['data'];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) list.add(e);
      }
    }
    Map<String, dynamic>? meta;
    final m = data['meta'];
    if (m is Map<String, dynamic>) meta = m;
    return (meta: meta, notes: list);
  }

  Future<Map<String, dynamic>> createNote(
    String tribeId, {
    required String title,
    required String body,
    List<String>? tags,
    bool pinned = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.notes(tribeId)),
      data: {
        'title': title,
        'body': body,
        if (tags != null) 'tags': tags,
        'pinned': pinned,
      },
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to create note',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid create note response',
    );
  }

  Future<Map<String, dynamic>> updateNote(
    String tribeId,
    String noteId, {
    String? title,
    String? body,
    List<String>? tags,
    bool? pinned,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.note(tribeId, noteId)),
      data: {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (tags != null) 'tags': tags,
        if (pinned != null) 'pinned': pinned,
      },
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to update note',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid update note response',
    );
  }

  Future<void> deleteNote(String tribeId, String noteId) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.note(tribeId, noteId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to delete note',
      );
    }
  }

  Future<Map<String, dynamic>> getSpeakerQueue(String tribeId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueue(tribeId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to load speaker queue',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid speaker queue response',
    );
  }

  Future<Map<String, dynamic>> joinSpeakerQueue(String tribeId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueueJoin(tribeId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to join queue',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid join queue response',
    );
  }

  Future<Map<String, dynamic>> leaveSpeakerQueue(String tribeId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueueLeave(tribeId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to leave queue',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid leave queue response',
    );
  }

  Future<Map<String, dynamic>> nextSpeaker(String tribeId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueueNext(tribeId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to advance queue',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid next speaker response',
    );
  }

  Future<Map<String, dynamic>> removeQueueEntry(
    String tribeId,
    String entryId,
  ) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueueEntry(tribeId, entryId)),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to remove entry',
      );
    }
    final d = data['data'];
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid remove entry response',
    );
  }

  Future<Map<String, dynamic>> clearWaiting(String tribeId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiContract.url(ApiContract.classroom.speakerQueueClearWaiting(tribeId)),
    );
    final data = res.data;
    final d = data?['data'];
    if (data == null || data['success'] != true || d is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Failed to clear waiting',
      );
    }
    return d;
  }
}
