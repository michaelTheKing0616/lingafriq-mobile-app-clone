import 'dart:convert';

import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P9-913 — guardian hub, invites, and consent (server-owned records).
const String guardianApiBasePath = '/api/v2/guardian';

const String guardianPendingOpsPrefsKey = 'guardian_link_pending_ops_v1';

enum GuardianLinkUiState { loading, empty, loaded, error, offline }

enum GuardianSubmitState { idle, submitting, sent, queuedOffline, error }

class GuardianHubLink {
  GuardianHubLink({
    required this.childUserId,
    required this.status,
    this.regime,
    this.policyVersion,
    this.consentedAt,
    this.withdrawnAt,
    this.childName,
  });

  final int childUserId;

  /// Learner's first name (or username) for the guardian's own live link.
  final String? childName;
  final String status;
  final String? regime;
  final String? policyVersion;
  final DateTime? consentedAt;
  final DateTime? withdrawnAt;

  factory GuardianHubLink.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return GuardianHubLink(
      childUserId: (json['child_user_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      regime: json['regime'] as String?,
      policyVersion: json['policy_version'] as String?,
      consentedAt: parse(json['consented_at'] as String?),
      withdrawnAt: parse(json['withdrawn_at'] as String?),
      childName: (json['child_name']?.toString().trim().isNotEmpty ?? false)
          ? json['child_name'].toString().trim()
          : null,
    );
  }
}

typedef GuardianPost =
    Future<Map<String, dynamic>> Function(
      String path, {
      Map<String, Object?>? data,
    });

typedef GuardianGet = Future<Map<String, dynamic>> Function(String path);

typedef GuardianPendingLoad = Future<List<Map<String, dynamic>>> Function();
typedef GuardianPendingSave =
    Future<void> Function(List<Map<String, dynamic>> pending);

class GuardianLinkService {
  GuardianLinkService({
    GuardianPost? post,
    GuardianGet? get,
    Future<bool> Function()? isOnline,
    GuardianPendingLoad? loadPending,
    GuardianPendingSave? savePending,
  }) : _post = post ?? _defaultPost,
       _get = get ?? _defaultGet,
       _isOnline = isOnline ?? (() async => true),
       _loadPendingFn = loadPending ?? _defaultLoadPending,
       _savePendingFn = savePending ?? _defaultSavePending;

  final GuardianPost _post;
  final GuardianGet _get;
  final Future<bool> Function() _isOnline;
  final GuardianPendingLoad _loadPendingFn;
  final GuardianPendingSave _savePendingFn;

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.post(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<List<GuardianHubLink>> fetchHubLinks() async {
    if (!await _isOnline()) {
      throw const GuardianOfflineException();
    }
    final json = await _get('$guardianApiBasePath/hub');
    if (json['ok'] != true) {
      throw GuardianApiException(
        code: json['code']?.toString(),
        message: json['message']?.toString(),
      );
    }
    final links = json['links'];
    if (links is! List) return [];
    return links
        .whereType<Map>()
        .map((e) => GuardianHubLink.fromJson(Map<String, dynamic>.from(e)))
        .where((l) => l.childUserId > 0)
        .toList();
  }

  Future<GuardianSubmitState> createChildInvite({
    required void Function(String token, DateTime expiresAt) onSuccess,
  }) async {
    const path = '$guardianApiBasePath/invite';
    if (!await _isOnline()) {
      return GuardianSubmitState.error;
    }
    try {
      final json = await _post(path);
      if (json['ok'] == true && json['invite_token'] is String) {
        final expires =
            DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 7));
        onSuccess(json['invite_token'] as String, expires);
        return GuardianSubmitState.sent;
      }
      return GuardianSubmitState.error;
    } catch (_) {
      return GuardianSubmitState.error;
    }
  }

  Future<GuardianSubmitState> acceptInvite({
    required String inviteToken,
    required String guardianDisplayName,
  }) async {
    final body = <String, Object?>{
      'invite_token': inviteToken.trim(),
      'guardian_display_name': guardianDisplayName.trim(),
    };
    return _submitWithOfflineQueue(
      path: '$guardianApiBasePath/accept-invite',
      body: body,
      opType: 'accept_invite',
    );
  }

  Future<GuardianSubmitState> submitConsent({
    required int childUserId,
    required bool attestationConfirmed,
  }) async {
    final body = <String, Object?>{
      'child_user_id': childUserId,
      'attestation_confirmed': attestationConfirmed,
    };
    return _submitWithOfflineQueue(
      path: '$guardianApiBasePath/consent',
      body: body,
      opType: 'consent',
    );
  }

  Future<GuardianSubmitState> withdrawConsent({
    required int childUserId,
  }) async {
    final body = <String, Object?>{'child_user_id': childUserId};
    return _submitWithOfflineQueue(
      path: '$guardianApiBasePath/withdraw',
      body: body,
      opType: 'withdraw',
    );
  }

  Future<GuardianSubmitState> _submitWithOfflineQueue({
    required String path,
    required Map<String, Object?> body,
    required String opType,
  }) async {
    if (!await _isOnline()) {
      await _enqueuePending(path: path, body: body, opType: opType);
      return GuardianSubmitState.queuedOffline;
    }
    try {
      final json = await _post(path, data: body);
      if (json['ok'] == true) {
        return GuardianSubmitState.sent;
      }
      return GuardianSubmitState.error;
    } catch (_) {
      await _enqueuePending(path: path, body: body, opType: opType);
      return GuardianSubmitState.queuedOffline;
    }
  }

  Future<void> flushPending() async {
    if (!await _isOnline()) return;
    final pending = await _loadPendingFn();
    if (pending.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final row in pending) {
      final path = row['path']?.toString() ?? '';
      final body = row['body'];
      if (path.isEmpty || body is! Map) {
        continue;
      }
      try {
        final json = await _post(path, data: Map<String, Object?>.from(body));
        if (json['ok'] != true) {
          remaining.add(row);
        }
      } catch (_) {
        remaining.add(row);
      }
    }
    await _savePendingFn(remaining);
  }

  Future<void> _enqueuePending({
    required String path,
    required Map<String, Object?> body,
    required String opType,
  }) async {
    final pending = await _loadPendingFn();
    pending.add(<String, dynamic>{
      'path': path,
      'body': body,
      'op_type': opType,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await _savePendingFn(pending);
  }

  static Future<List<Map<String, dynamic>>> _defaultLoadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(guardianPendingOpsPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> _defaultSavePending(
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(guardianPendingOpsPrefsKey, jsonEncode(rows));
  }
}

class GuardianApiException implements Exception {
  GuardianApiException({this.code, this.message});

  final String? code;
  final String? message;
}

class GuardianOfflineException implements Exception {
  const GuardianOfflineException();
}
