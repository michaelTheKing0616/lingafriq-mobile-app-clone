import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/services/chat/mls_session_service.dart';

void main() {
  group('MlsSessionService', () {
    late Map<String, String> vault;

    setUp(() {
      vault = {};
    });

    MlsSessionService service({
      required Future<Map<String, dynamic>> Function(
        String path, {
        Map<String, Object?>? data,
      }) post,
      bool minor = false,
    }) {
      return MlsSessionService(
        capabilities: CapabilityGate(
          get: (_) async => {
            'ok': true,
            'capabilities': {
              'is_minor': minor,
              'direct_messages_open': true,
              'snaps': !minor,
              'ads': !minor,
              'purchases': !minor,
            },
          },
        ),
        post: post,
        secureRead: (k) async => vault[k],
        secureWrite: (k, v) async {
          vault[k] = v;
        },
      );
    }

    test('adult bootstrap requests E2EE by default', () async {
      Map<String, Object?>? captured;
      final svc = service(
        post: (path, {data}) async {
          if (path.contains('dm-thread')) {
            captured = data;
            return {
              'ok': true,
              'e2ee_enabled': true,
              'requires_moderation': false,
            };
          }
          fail('unexpected path $path');
        },
      );
      final snap = await svc.bootstrapDirectMessage(
        peerUserId: 42,
        myNumericUserId: 7,
      );
      expect(captured?['e2ee_requested'], isTrue);
      expect(snap.uiState, MlsEncryptionUiState.encrypted);
      expect(snap.e2eeActive, isTrue);
    });

    test('minor bootstrap does not request E2EE', () async {
      Map<String, Object?>? captured;
      final svc = service(
        minor: true,
        post: (path, {data}) async {
          captured = data;
          return {
            'ok': true,
            'e2ee_enabled': false,
            'requires_moderation': true,
          };
        },
      );
      final snap = await svc.bootstrapDirectMessage(
        peerUserId: 42,
        myNumericUserId: 7,
      );
      expect(captured?['e2ee_requested'], isFalse);
      expect(snap.uiState, MlsEncryptionUiState.notEncryptedMinor);
      expect(snap.e2eeActive, isFalse);
    });

    test('detects key change on new device fingerprint', () async {
      final threadKey = MlsSessionService.threadKeyForUsers(7, 42);
      vault['mls_device_key_v1'] = 'device-a';
      vault['mls_thread_fp_$threadKey'] = 'device-b';

      final svc = service(
        post: (path, {data}) async => {
          'ok': true,
          'e2ee_enabled': true,
          'requires_moderation': false,
        },
      );
      final snap = await svc.bootstrapDirectMessage(
        peerUserId: 42,
        myNumericUserId: 7,
      );
      expect(snap.uiState, MlsEncryptionUiState.keyChanged);
    });

    test('recovery fails honestly without backup secret', () async {
      final svc = service(post: (_, {data}) async => {'ok': true});
      final outcome = await svc.recoverFromBackup(
        threadKey: 'private_1_2',
        backupSecret: '',
      );
      expect(outcome.ok, isFalse);
      expect(outcome.honestMessage, kE2eeRecoveryLost);
    });

    test('messageReadableOnDevice hides history until key ack', () {
      final svc = service(post: (_, {data}) async => {'ok': true});
      const snap = MlsSessionSnapshot(
        uiState: MlsEncryptionUiState.keyChanged,
        e2eeActive: true,
        requiresModeration: false,
        keyChangeAcknowledged: false,
        historyReadableFromMs: 1000,
      );
      expect(
        svc.messageReadableOnDevice(snapshot: snap, messageSortMs: 500),
        isFalse,
      );
      expect(
        svc.messageReadableOnDevice(snapshot: snap, messageSortMs: 1500),
        isFalse,
      );
    });
  });
}
