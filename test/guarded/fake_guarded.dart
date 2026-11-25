import 'package:lingafriq/services/guarded_messaging_service.dart';

class Call {
  Call(this.method, this.path, this.data);
  final String method;
  final String path;
  final Map<String, Object?>? data;
}

/// Records calls; answers from [routes] keyed by "METHOD path".
class FakeGuarded {
  FakeGuarded(this.routes);
  final Map<String, GuardedResponse> routes;
  final calls = <Call>[];

  GuardedMessagingService get service => GuardedMessagingService(
    request: (method, path, {data}) async {
      calls.add(Call(method, path, data));
      return routes['$method $path'] ?? const GuardedResponse(500, {});
    },
  );
}

const threadsJson = {
  'ok': true,
  'threads': [
    {
      'peer_user_id': 11,
      'peer_name': 'Mrs Adebayo',
      'role': 'teacher',
      'last_activity_at': '2026-10-28T09:00:00Z',
      'message_count': 14,
      'report_count': 0,
      'blocked_message_count': 0,
      'revoked': false,
    },
    {
      'peer_user_id': 12,
      'peer_name': 'Kwame',
      'role': 'classmate',
      'last_activity_at': '2026-10-27T15:30:00Z',
      'message_count': 3,
      'report_count': 1,
      'blocked_message_count': 2,
      'held_media_count': 1,
      'revoked': false,
      'first_message_at': '2026-10-26T08:00:00Z',
    },
    {
      'peer_user_id': 13,
      'peer_name': null,
      'role': 'contact',
      'last_activity_at': '2026-10-20T10:00:00Z',
      'message_count': 1,
      'report_count': 0,
      'blocked_message_count': 0,
      'revoked': true,
    },
  ],
};

const requestsJson = {
  'ok': true,
  'waiting_for_guardian': [
    {
      'request_id': 'r1',
      'student_user_id': 21,
      'student_name': 'Amara',
      'status': 'pending',
      'submitted_at': '2026-10-29T08:00:00Z',
    },
  ],
  'school_students': [
    {
      'student_user_id': 31,
      'student_name': 'Tunde',
      'account_status': 'active',
      'teacher_dm_approved': false,
    },
    {
      'student_user_id': 32,
      'student_name': 'Zainab',
      'account_status': 'active',
      'teacher_dm_approved': true,
      'teacher_dm_expires_at': '2027-06-30T00:00:00.000Z',
    },
    {
      'student_user_id': 33,
      'student_name': 'Femi',
      'account_status': 'pending_consent',
      'teacher_dm_approved': false,
    },
  ],
};
