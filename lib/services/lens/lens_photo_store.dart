import 'dart:io';

import 'package:lingafriq/services/lens/lens_privacy_policy.dart';

/// Server-side copy handle — never includes image bytes.
class LensServerPhotoRef {
  const LensServerPhotoRef({required this.opaqueId});

  final String opaqueId;
}

abstract class LensPhotoRetentionClient {
  Future<void> registerServerCopy({
    required String userId,
    required String opaqueId,
  });

  Future<void> deleteServerCopy({
    required String userId,
    required String opaqueId,
  });
}

class LensNoOpRetentionClient implements LensPhotoRetentionClient {
  const LensNoOpRetentionClient();

  @override
  Future<void> registerServerCopy({
    required String userId,
    required String opaqueId,
  }) async {}

  @override
  Future<void> deleteServerCopy({
    required String userId,
    required String opaqueId,
  }) async {}
}

enum LensTempSessionOutcome {
  deleted,
  alreadyGone,
}

class LensPhotoStore {
  LensPhotoStore({
    required Directory root,
    LensPhotoRetentionClient retentionClient = const LensNoOpRetentionClient(),
  })  : _root = root,
        _retention = retentionClient {
    _tempDir = Directory('${root.path}/temp')..createSync(recursive: true);
    _savedDir = Directory('${root.path}/saved')..createSync(recursive: true);
  }

  final Directory _root;
  final LensPhotoRetentionClient _retention;
  late final Directory _tempDir;
  late final Directory _savedDir;

  final Map<String, _LensTempRecord> _temp = {};
  final Map<String, _LensSavedRecord> _saved = {};

  Directory get root => _root;

  Future<File> writeTempCapture({
    required String sessionId,
    required List<int> bytes,
    String? serverOpaqueId,
    required String userId,
  }) async {
    final file = File('${_tempDir.path}/$sessionId.jpg');
    await file.writeAsBytes(bytes, flush: true);
    _temp[sessionId] = _LensTempRecord(
      path: file.path,
      userId: userId,
      serverOpaqueId: serverOpaqueId,
    );
    if (serverOpaqueId != null) {
      await _retention.registerServerCopy(
        userId: userId,
        opaqueId: serverOpaqueId,
      );
    }
    return file;
  }

  /// AC1: discard temp when learner did not save — local + server copy removed.
  Future<LensTempSessionOutcome> endProcessingWithoutSave(
    String sessionId,
  ) async {
    final record = _temp.remove(sessionId);
    if (record == null) return LensTempSessionOutcome.alreadyGone;
    await _deleteFileIfExists(record.path);
    if (record.serverOpaqueId != null) {
      await _retention.deleteServerCopy(
        userId: record.userId,
        opaqueId: record.serverOpaqueId!,
      );
    }
    return LensTempSessionOutcome.deleted;
  }

  Future<bool> verifyTempDeleted(String sessionId) async {
    final record = _temp[sessionId];
    if (record != null) return false;
    final stray = File('${_tempDir.path}/$sessionId.jpg');
    return !await stray.exists();
  }

  Future<String> promoteTempToSaved({
    required String sessionId,
    required String photoId,
  }) async {
    final record = _temp.remove(sessionId);
    if (record == null) {
      throw StateError('LENS_TEMP_MISSING');
    }
    final dest = File('${_savedDir.path}/$photoId.jpg');
    await File(record.path).rename(dest.path);
    _saved[photoId] = _LensSavedRecord(
      path: dest.path,
      userId: record.userId,
      serverOpaqueId: record.serverOpaqueId,
    );
    return dest.path;
  }

  /// AC4: delete saved photo locally and on server.
  Future<void> deleteSavedPhoto(String photoId) async {
    final record = _saved.remove(photoId);
    if (record == null) return;
    await _deleteFileIfExists(record.path);
    if (record.serverOpaqueId != null) {
      await _retention.deleteServerCopy(
        userId: record.userId,
        opaqueId: record.serverOpaqueId!,
      );
    }
  }

  /// Gate before any network upload of photo bytes (AC2–AC3).
  LensServerPhotoBlockReason? blockReasonForUpload(
    LensLearnerPrivacyContext privacy,
  ) {
    return lensServerPhotoBlockReason(privacy);
  }

  Future<void> _deleteFileIfExists(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}

class _LensTempRecord {
  _LensTempRecord({
    required this.path,
    required this.userId,
    this.serverOpaqueId,
  });

  final String path;
  final String userId;
  final String? serverOpaqueId;
}

class _LensSavedRecord {
  _LensSavedRecord({
    required this.path,
    required this.userId,
    this.serverOpaqueId,
  });

  final String path;
  final String userId;
  final String? serverOpaqueId;
}
