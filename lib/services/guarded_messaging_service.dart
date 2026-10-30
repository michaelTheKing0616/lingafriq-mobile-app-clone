import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Guarded adult <-> learner messaging: guardian thread view, teacher student requests,
/// and joining a class by code. Backend: node-backend `guardedMessaging.service.ts`.
typedef GuardedRequest =
    Future<GuardedResponse> Function(
      String method,
      String path, {
      Map<String, Object?>? data,
    });

class GuardedResponse {
  const GuardedResponse(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;
  bool get ok => status >= 200 && status < 300;
}

DateTime? _date(Object? raw) =>
    raw == null ? null : DateTime.tryParse(raw.toString());
int _int(Object? raw) => raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

enum PeerRole { teacher, classmate, contact }

class ChildDmThread {
  const ChildDmThread({
    required this.peerUserId,
    required this.peerName,
    required this.role,
    required this.lastActivityAt,
    required this.messageCount,
    required this.reportCount,
    required this.blockedMessageCount,
    required this.revoked,
  });

  factory ChildDmThread.fromJson(Map<String, dynamic> j) => ChildDmThread(
    peerUserId: j['peer_user_id'] == null ? null : _int(j['peer_user_id']),
    peerName: j['peer_name']?.toString(),
    role: switch (j['role']) {
      'teacher' => PeerRole.teacher,
      'classmate' => PeerRole.classmate,
      _ => PeerRole.contact,
    },
    lastActivityAt: _date(j['last_activity_at']),
    messageCount: _int(j['message_count']),
    reportCount: _int(j['report_count']),
    blockedMessageCount: _int(j['blocked_message_count']),
    revoked: j['revoked'] == true,
  );

  final int? peerUserId;
  final String? peerName;
  final PeerRole role;
  final DateTime? lastActivityAt;
  final int messageCount;
  final int reportCount;
  final int blockedMessageCount;
  final bool revoked;

  ChildDmThread copyWith({bool? revoked}) => ChildDmThread(
    peerUserId: peerUserId,
    peerName: peerName,
    role: role,
    lastActivityAt: lastActivityAt,
    messageCount: messageCount,
    reportCount: reportCount,
    blockedMessageCount: blockedMessageCount,
    revoked: revoked ?? this.revoked,
  );
}

class PendingStudent {
  const PendingStudent({
    required this.studentUserId,
    this.name,
    this.submittedAt,
  });
  final int studentUserId;
  final String? name;
  final DateTime? submittedAt;
}

class SchoolStudent {
  const SchoolStudent({
    required this.studentUserId,
    this.name,
    required this.accountActive,
    required this.teacherDmApproved,
  });
  final int studentUserId;
  final String? name;
  final bool accountActive;
  final bool teacherDmApproved;
}

class ClassroomStudentRequests {
  const ClassroomStudentRequests({required this.waiting, required this.school});
  final List<PendingStudent> waiting;
  final List<SchoolStudent> school;
}

enum ClassJoinOutcome {
  joined,
  waitingForGuardian,
  needsGuardianLink,
  needsAgeCheck,
  notFound,
  alreadyMember,
  error,
}

class GuardedLoadException implements Exception {
  const GuardedLoadException(this.status);
  final int status;
}

class GuardedMessagingService {
  GuardedMessagingService({GuardedRequest? request})
    : _request = request ?? _defaultRequest;

  final GuardedRequest _request;

  static Future<GuardedResponse> _defaultRequest(
    String method,
    String path, {
    Map<String, Object?>? data,
  }) async {
    try {
      final r = method == 'GET'
          ? await ApiService.get(path)
          : await ApiService.post(path, data: data);
      final body = r.data;
      return GuardedResponse(
        r.statusCode ?? 200,
        body is Map<String, dynamic> ? body : <String, dynamic>{},
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      return GuardedResponse(
        e.response?.statusCode ?? 0,
        body is Map<String, dynamic> ? body : <String, dynamic>{},
      );
    }
  }

  Future<List<ChildDmThread>> childThreads(int childUserId) async {
    final r = await _request(
      'GET',
      '/api/v2/guardian/children/$childUserId/dm-threads',
    );
    if (!r.ok || r.body['threads'] is! List) {
      throw GuardedLoadException(r.status);
    }
    return (r.body['threads'] as List)
        .whereType<Map>()
        .map((e) => ChildDmThread.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> setPeerStopped(
    int childUserId,
    int peerUserId, {
    required bool stopped,
  }) async {
    final action = stopped ? 'revoke-peer' : 'restore-peer';
    final r = await _request(
      'POST',
      '/api/v2/guardian/children/$childUserId/$action',
      data: {'peer_user_id': peerUserId},
    );
    return r.ok;
  }

  Future<ClassroomStudentRequests> studentRequests(String tribeId) async {
    final r = await _request(
      'GET',
      '/api/v2/classroom/guarded/$tribeId/pending-students',
    );
    if (!r.ok) throw GuardedLoadException(r.status);
    final waiting = (r.body['waiting_for_guardian'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => PendingStudent(
            studentUserId: _int(e['student_user_id']),
            name: e['student_name']?.toString(),
            submittedAt: _date(e['submitted_at']),
          ),
        )
        .toList();
    final school = (r.body['school_students'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => SchoolStudent(
            studentUserId: _int(e['student_user_id']),
            name: e['student_name']?.toString(),
            accountActive: e['account_status'] == 'active',
            teacherDmApproved: e['teacher_dm_approved'] == true,
          ),
        )
        .toList();
    return ClassroomStudentRequests(waiting: waiting, school: school);
  }

  Future<bool> setTeacherDm(
    String tribeId,
    int studentUserId, {
    required bool approved,
  }) async {
    final action = approved ? 'approve-teacher-dm' : 'revoke-teacher-dm';
    final r = await _request(
      'POST',
      '/api/v2/classroom/guarded/$tribeId/students/$studentUserId/$action',
    );
    return r.ok;
  }

  Future<ClassJoinOutcome> joinClassByCode(String code) async {
    final r = await _request(
      'POST',
      '/api/tribes/classrooms/join',
      data: {'code': code.trim()},
    );
    if (r.status == 201 || r.status == 200) return ClassJoinOutcome.joined;
    if (r.status == 202) return ClassJoinOutcome.waitingForGuardian;
    if (r.status == 404) return ClassJoinOutcome.notFound;
    if (r.status == 409) return ClassJoinOutcome.alreadyMember;
    return switch (r.body['code']) {
      'guardian_link_required' => ClassJoinOutcome.needsGuardianLink,
      'age_verification_required' => ClassJoinOutcome.needsAgeCheck,
      'classroom_code_required' => ClassJoinOutcome.notFound,
      _ => ClassJoinOutcome.error,
    };
  }
}
