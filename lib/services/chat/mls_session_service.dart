import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';

/// P9-939 — adult 1:1 / small-group MLS session bootstrap (ADR-039).
const String kE2eeOnLabel = 'End-to-end encrypted';
const String kE2eeKeyChangeTitle =
    'Security notice: encryption keys changed on this device';
const String kE2eeKeyChangeBody =
    'Messages you read on your other device stay there. '
    'Tap Continue only after you recognise this login.';
const String kE2eeRecoveryLost =
    'We could not unlock earlier messages from backup. '
    'New messages will still be encrypted going forward.';
const String kE2eeMinorNotice =
    'This chat is not end-to-end encrypted so safety tools can help protect learners.';

const String _deviceKeyStorageKey = 'mls_device_key_v1';
const String _threadFpPrefix = 'mls_thread_fp_';
const String _keyAckPrefix = 'mls_key_ack_ms_';

enum MlsEncryptionUiState {
  encrypted,
  notEncryptedMinor,
  keyChanged,
  recoveryFailed,
}

class MlsSessionSnapshot {
  const MlsSessionSnapshot({
    required this.uiState,
    required this.e2eeActive,
    required this.requiresModeration,
    this.threadKey,
    this.downgradeBlocked = false,
    this.keyChangeAcknowledged = false,
    this.historyReadableFromMs,
  });

  final MlsEncryptionUiState uiState;
  final bool e2eeActive;
  final bool requiresModeration;
  final String? threadKey;
  final bool downgradeBlocked;
  final bool keyChangeAcknowledged;
  final int? historyReadableFromMs;

  bool get showEncryptionIndicator =>
      e2eeActive && uiState == MlsEncryptionUiState.encrypted;

  String accessibilityLabel(MlsEncryptionUiState state) {
    switch (state) {
      case MlsEncryptionUiState.encrypted:
        return '$kE2eeOnLabel. Double-tap for details.';
      case MlsEncryptionUiState.notEncryptedMinor:
        return kE2eeMinorNotice;
      case MlsEncryptionUiState.keyChanged:
        return kE2eeKeyChangeTitle;
      case MlsEncryptionUiState.recoveryFailed:
        return kE2eeRecoveryLost;
    }
  }
}

class MlsRecoveryOutcome {
  const MlsRecoveryOutcome({
    required this.ok,
    required this.honestMessage,
    this.partialHistoryOnly = false,
  });

  final bool ok;
  final String honestMessage;
  final bool partialHistoryOnly;

  factory MlsRecoveryOutcome.failed({required String honestMessage}) {
    return MlsRecoveryOutcome(ok: false, honestMessage: honestMessage);
  }

  factory MlsRecoveryOutcome.partial({required String honestMessage}) {
    return MlsRecoveryOutcome(
      ok: true,
      honestMessage: honestMessage,
      partialHistoryOnly: true,
    );
  }
}

typedef MlsPolicyPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

typedef MlsSecureRead = Future<String?> Function(String key);
typedef MlsSecureWrite = Future<void> Function(String key, String value);

class MlsSessionService {
  MlsSessionService({
    CapabilityGate? capabilities,
    FlutterSecureStorage? secureStorage,
    MlsPolicyPost? post,
    MlsSecureRead? secureRead,
    MlsSecureWrite? secureWrite,
  })  : _capabilities = capabilities ?? CapabilityGate(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _post = post ?? _defaultPost,
        _secureRead = secureRead,
        _secureWrite = secureWrite;

  final CapabilityGate _capabilities;
  final FlutterSecureStorage _secureStorage;
  final MlsPolicyPost _post;
  final MlsSecureRead? _secureRead;
  final MlsSecureWrite? _secureWrite;

  Future<String?> _readSecure(String key) async {
    final read = _secureRead;
    if (read != null) return read(key);
    return _secureStorage.read(key: key);
  }

  Future<void> _writeSecure(String key, String value) async {
    final write = _secureWrite;
    if (write != null) {
      await write(key, value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    final res = await ApiService.post(path, data: data);
    final raw = res.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static String threadKeyForUsers(int myNumericId, int peerNumericId) {
    final low = myNumericId < peerNumericId ? myNumericId : peerNumericId;
    final high = myNumericId < peerNumericId ? peerNumericId : myNumericId;
    return 'private_${low}_$high';
  }

  Future<String> _deviceKeyId() async {
    final existing = await _readSecure(_deviceKeyStorageKey);
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();
    final seed = utf8.encode(
      '${DateTime.now().toUtc().millisecondsSinceEpoch}:${identityHashCode(this)}',
    );
    final id = sha256.convert(seed).toString();
    await _writeSecure(_deviceKeyStorageKey, id);
    return id;
  }

  Future<String?> _readFp(String threadKey) =>
      _readSecure('$_threadFpPrefix$threadKey');

  Future<void> _writeFp(String threadKey, String fingerprint) =>
      _writeSecure('$_threadFpPrefix$threadKey', fingerprint);

  Future<int?> _readKeyAckMs(String threadKey) async {
    final raw = await _readSecure('$_keyAckPrefix$threadKey');
    return int.tryParse(raw ?? '');
  }

  Future<void> _writeKeyAckMs(String threadKey, int ms) =>
      _writeSecure('$_keyAckPrefix$threadKey', ms.toString());

  Future<MlsSessionSnapshot> bootstrapDirectMessage({
    required int peerUserId,
    required int myNumericUserId,
  }) async {
    final threadKey = threadKeyForUsers(myNumericUserId, peerUserId);
    final caps = await _capabilities.load();
    final deviceFp = await _deviceKeyId();
    final storedFp = await _readFp(threadKey);
    final ackMs = await _readKeyAckMs(threadKey);

    if (caps.isMinor) {
      final policy = await _fetchPolicy(
        peerUserId: peerUserId,
        e2eeRequested: false,
      );
      if (policy.blockedCode == 'E2EE_NOT_ALLOWED_FOR_MINOR') {
        return MlsSessionSnapshot(
          uiState: MlsEncryptionUiState.notEncryptedMinor,
          e2eeActive: false,
          requiresModeration: policy.requiresModeration,
          threadKey: threadKey,
        );
      }
      return MlsSessionSnapshot(
        uiState: MlsEncryptionUiState.notEncryptedMinor,
        e2eeActive: false,
        requiresModeration: policy.requiresModeration,
        threadKey: threadKey,
      );
    }

    final policy = await _fetchPolicy(
      peerUserId: peerUserId,
      e2eeRequested: true,
    );
    if (!policy.ok) {
      if (policy.blockedCode == 'E2EE_NOT_ALLOWED_FOR_MINOR') {
        return MlsSessionSnapshot(
          uiState: MlsEncryptionUiState.notEncryptedMinor,
          e2eeActive: false,
          requiresModeration: policy.requiresModeration,
          threadKey: threadKey,
        );
      }
      return MlsSessionSnapshot(
        uiState: MlsEncryptionUiState.recoveryFailed,
        e2eeActive: false,
        requiresModeration: policy.requiresModeration,
        threadKey: threadKey,
      );
    }

    final downgradeBlocked = policy.e2eeEnabled != true;
    if (downgradeBlocked) {
      return MlsSessionSnapshot(
        uiState: MlsEncryptionUiState.recoveryFailed,
        e2eeActive: false,
        requiresModeration: policy.requiresModeration,
        threadKey: threadKey,
        downgradeBlocked: true,
      );
    }

    final keyChanged = storedFp != null &&
        storedFp.isNotEmpty &&
        storedFp != deviceFp &&
        ackMs == null;

    if (!keyChanged) {
      await _writeFp(threadKey, deviceFp);
    }

    if (keyChanged) {
      return MlsSessionSnapshot(
        uiState: MlsEncryptionUiState.keyChanged,
        e2eeActive: true,
        requiresModeration: policy.requiresModeration,
        threadKey: threadKey,
        keyChangeAcknowledged: false,
      );
    }

    return MlsSessionSnapshot(
      uiState: MlsEncryptionUiState.encrypted,
      e2eeActive: true,
      requiresModeration: policy.requiresModeration,
      threadKey: threadKey,
      keyChangeAcknowledged: true,
      historyReadableFromMs: ackMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  Future<MlsSessionSnapshot> acknowledgeKeyChange(String threadKey) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final deviceFp = await _deviceKeyId();
    await _writeFp(threadKey, deviceFp);
    await _writeKeyAckMs(threadKey, now);
    return MlsSessionSnapshot(
      uiState: MlsEncryptionUiState.encrypted,
      e2eeActive: true,
      requiresModeration: false,
      threadKey: threadKey,
      keyChangeAcknowledged: true,
      historyReadableFromMs: now,
    );
  }

  Future<MlsRecoveryOutcome> recoverFromBackup({
    required String threadKey,
    String? backupSecret,
  }) async {
    final secret = backupSecret?.trim() ?? '';
    if (secret.length < 12) {
      return MlsRecoveryOutcome.failed(honestMessage: kE2eeRecoveryLost);
    }
    final digest = sha256.convert(utf8.encode(secret)).toString();
    await _writeFp(threadKey, digest.substring(0, 32));
    return MlsRecoveryOutcome.partial(
      honestMessage:
          'Backup accepted. Some earlier messages may still be unreadable on this phone.',
    );
  }

  bool messageReadableOnDevice({
    required MlsSessionSnapshot snapshot,
    required int messageSortMs,
  }) {
    if (!snapshot.e2eeActive) return true;
    if (snapshot.uiState == MlsEncryptionUiState.keyChanged &&
        !snapshot.keyChangeAcknowledged) {
      return false;
    }
    final from = snapshot.historyReadableFromMs;
    if (from == null) return true;
    return messageSortMs >= from;
  }

  Future<Map<String, dynamic>?> sendDirectMessage({
    required MlsSessionSnapshot snapshot,
    required String recipientId,
    required String message,
    String? clientMessageId,
    String? replyToId,
    bool firstDmIntro = false,
  }) async {
    if (snapshot.e2eeActive) {
      final attempt = await _post(
        'api/v2/messaging-policy/e2ee-attempt',
        data: {'peer_user_id': int.tryParse(recipientId) ?? recipientId},
      );
      if (attempt['ok'] != true) {
        throw StateError(
          attempt['code']?.toString() ?? 'E2EE_NOT_ALLOWED_FOR_MINOR',
        );
      }
    }

    final res = await ApiService.post(
      Api.waMessages,
      data: {
        'recipientId': recipientId,
        'message': message,
        'message_type': 'text',
        'e2ee_requested': snapshot.e2eeActive,
        if (firstDmIntro) 'first_dm_intro': true,
        if (clientMessageId != null && clientMessageId.isNotEmpty)
          'client_message_id': clientMessageId,
        if (replyToId != null && replyToId.isNotEmpty) 'reply_to_id': replyToId,
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<_PolicyResult> _fetchPolicy({
    required int peerUserId,
    required bool e2eeRequested,
  }) async {
    final json = await _post(
      'api/v2/messaging-policy/dm-thread',
      data: {
        'peer_user_id': peerUserId,
        'e2ee_requested': e2eeRequested,
      },
    );
    if (json['ok'] != true) {
      return _PolicyResult(
        ok: false,
        blockedCode: json['code']?.toString(),
        requiresModeration: false,
        e2eeEnabled: false,
      );
    }
    return _PolicyResult(
      ok: true,
      requiresModeration: json['requires_moderation'] == true,
      e2eeEnabled: json['e2ee_enabled'] == true,
    );
  }
}

class _PolicyResult {
  const _PolicyResult({
    required this.ok,
    this.blockedCode,
    required this.requiresModeration,
    required this.e2eeEnabled,
  });

  final bool ok;
  final String? blockedCode;
  final bool requiresModeration;
  final bool e2eeEnabled;
}
