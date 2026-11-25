import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/lens_photo_store.dart';
import 'package:lingafriq/services/lens/lens_privacy_policy.dart';

void main() {
  group('lensPrivacyContextFromPrefs', () {
    test('minor without guardian consent blocks server', () {
      final ctx = lensPrivacyContextFromPrefs(
        ageCategory: 'child',
        guardianPhotoConsentRecorded: false,
      );
      expect(lensServerPhotoPolicy(ctx), LensPhotoServerPolicy.onDeviceOnly);
      expect(
        lensServerPhotoBlockReason(ctx),
        LensServerPhotoBlockReason.minorNoGuardianConsent,
      );
    });

    test('teen with guardian consent allows server', () {
      final ctx = lensPrivacyContextFromPrefs(
        ageCategory: 'teen',
        guardianPhotoConsentRecorded: true,
      );
      expect(lensServerPhotoPolicy(ctx), LensPhotoServerPolicy.allowed);
      expect(lensServerPhotoBlockReason(ctx), isNull);
    });

    test('adult allows server without guardian consent', () {
      final ctx = lensPrivacyContextFromPrefs(ageCategory: 'adult');
      expect(lensServerPhotoPolicy(ctx), LensPhotoServerPolicy.allowed);
    });
  });

  group('lensLogPayloadContainsImageBytes', () {
    test('flags base64 image fields', () {
      expect(
        lensLogPayloadContainsImageBytes({
          'imageBase64': 'a' * 100,
        }),
        isTrue,
      );
      expect(
        lensLogPayloadContainsImageBytes({
          'lens_session_id': 'sess-1',
        }),
        isFalse,
      );
    });
  });

  group('LensPhotoStore retention', () {
    late Directory root;
    late _RecordingRetention retention;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('lens_photo_914_');
      retention = _RecordingRetention();
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('endProcessingWithoutSave deletes temp and server copy', () async {
      final store = LensPhotoStore(root: root, retentionClient: retention);
      await store.writeTempCapture(
        sessionId: 's1',
        bytes: [1, 2, 3],
        serverOpaqueId: 'srv-1',
        userId: 'u1',
      );
      final outcome = await store.endProcessingWithoutSave('s1');
      expect(outcome, LensTempSessionOutcome.deleted);
      expect(await store.verifyTempDeleted('s1'), isTrue);
      expect(retention.deleted, ['srv-1']);
    });

    test('deleteSavedPhoto removes local and server', () async {
      final store = LensPhotoStore(root: root, retentionClient: retention);
      await store.writeTempCapture(
        sessionId: 's2',
        bytes: [4, 5],
        serverOpaqueId: 'srv-2',
        userId: 'u1',
      );
      await store.promoteTempToSaved(sessionId: 's2', photoId: 'p2');
      await store.deleteSavedPhoto('p2');
      expect(File('${root.path}/saved/p2.jpg').existsSync(), isFalse);
      expect(retention.deleted, contains('srv-2'));
    });

    test('blockReasonForUpload surfaces minor gate', () {
      final store = LensPhotoStore(root: root);
      final reason = store.blockReasonForUpload(
        lensPrivacyContextFromPrefs(ageCategory: 'teen'),
      );
      expect(reason, LensServerPhotoBlockReason.minorNoGuardianConsent);
    });
  });
}

class _RecordingRetention implements LensPhotoRetentionClient {
  final List<String> registered = [];
  final List<String> deleted = [];

  @override
  Future<void> registerServerCopy({
    required String userId,
    required String opaqueId,
  }) async {
    registered.add(opaqueId);
  }

  @override
  Future<void> deleteServerCopy({
    required String userId,
    required String opaqueId,
  }) async {
    deleted.add(opaqueId);
  }
}
