import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

typedef ManifestSignatureVerifier = bool Function(
  Map<String, dynamic> manifest,
  String signatureB64,
  String publicKeyB64,
);

typedef PackDiffFetcher = Future<PackDiffDownload> Function(
  String languageCode,
  String fromVersion,
  String toVersion,
);

class PackUpdateError implements Exception {
  PackUpdateError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PackUpdateError($code): $message';
}

enum PackUpdaterPhase { idle, checking, downloading, applying, ready, error }

class PackUpdaterState {
  const PackUpdaterState({
    required this.phase,
    this.installedVersion,
    this.error,
  });

  final PackUpdaterPhase phase;
  final String? installedVersion;
  final PackUpdateError? error;
}

class PackDiffDownload {
  PackDiffDownload({
    required this.fromVersion,
    required this.toVersion,
    required this.diff,
    required this.blobs,
    required this.manifest,
    required this.signatureB64,
    required this.publicKeyB64,
  });

  final String fromVersion;
  final String toVersion;
  final PackDiffHashes diff;
  final List<PackDiffBlob> blobs;
  final Map<String, dynamic> manifest;
  final String signatureB64;
  final String publicKeyB64;

  factory PackDiffDownload.fromJson(Map<String, dynamic> json) {
    final diffJson = json['diff'] as Map<String, dynamic>? ?? {};
    return PackDiffDownload(
      fromVersion: json['from_version'] as String? ?? '',
      toVersion: json['to_version'] as String? ?? '',
      diff: PackDiffHashes.fromJson(diffJson),
      blobs: (json['blobs'] as List<dynamic>? ?? [])
          .map((row) => PackDiffBlob.fromJson(row as Map<String, dynamic>))
          .toList(),
      manifest: json['manifest'] as Map<String, dynamic>? ?? {},
      signatureB64: json['signature_b64'] as String? ?? '',
      publicKeyB64: json['public_key_b64'] as String? ?? '',
    );
  }
}

class PackDiffHashes {
  PackDiffHashes({
    required this.added,
    required this.removed,
    required this.changed,
  });

  final List<String> added;
  final List<String> removed;
  final List<String> changed;

  factory PackDiffHashes.fromJson(Map<String, dynamic> json) {
    return PackDiffHashes(
      added: _stringList(json['added']),
      removed: _stringList(json['removed']),
      changed: _stringList(json['changed']),
    );
  }
}

class PackDiffBlob {
  PackDiffBlob({
    required this.path,
    required this.sha256,
    required this.data,
  });

  final String path;
  final String sha256;
  final Uint8List data;

  factory PackDiffBlob.fromJson(Map<String, dynamic> json) {
    final b64 = json['data_base64'] as String? ?? '';
    return PackDiffBlob(
      path: json['path'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      data: Uint8List.fromList(base64.decode(b64)),
    );
  }
}

class InstalledContentPack {
  InstalledContentPack({
    required this.languageCode,
    required this.version,
    required this.files,
    required this.manifest,
    required this.signatureB64,
    required this.publicKeyB64,
  });

  final String languageCode;
  final String version;
  final Map<String, Uint8List> files;
  final Map<String, dynamic> manifest;
  final String signatureB64;
  final String publicKeyB64;
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((entry) => entry.toString()).toList();
}

String stableStringify(dynamic value) {
  if (value == null || value is! Map && value is! List) {
    return jsonEncode(value);
  }
  if (value is List) {
    return '[${value.map(stableStringify).join(',')}]';
  }
  final record = value as Map<String, dynamic>;
  final keys = record.keys.toList()..sort();
  final body = keys
      .map((key) => '${jsonEncode(key)}:${stableStringify(record[key])}')
      .join(',');
  return '{$body}';
}

String sha256Hex(Uint8List data) {
  return sha256.convert(data).toString();
}

String objectContentHash(Map<String, dynamic> payload) {
  return sha256Hex(Uint8List.fromList(utf8.encode(stableStringify(payload))));
}

String fileContentHash(String path, Uint8List data) {
  if (path.startsWith('objects/') && path.endsWith('.json')) {
    final payload = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    return objectContentHash(payload);
  }
  return sha256Hex(data);
}

Map<String, Uint8List> applyPackDiff(
  Map<String, Uint8List> baseFiles,
  PackDiffHashes diff,
  Map<String, Uint8List> additions,
) {
  final result = Map<String, Uint8List>.from(baseFiles);
  const protectedPaths = {'manifest.json', 'public_key.txt', 'signature.txt'};

  for (final digest in diff.removed) {
    final toDelete = result.keys
        .where(
          (path) =>
              !protectedPaths.contains(path) &&
              fileContentHash(path, result[path]!) == digest,
        )
        .toList();
    for (final path in toDelete) {
      result.remove(path);
    }
  }

  final wanted = {...diff.added, ...diff.changed};
  for (final digest in wanted) {
    final matches = additions.entries
        .where((entry) => fileContentHash(entry.key, entry.value) == digest)
        .map((entry) => entry.key)
        .toList();
    if (matches.isEmpty) {
      throw PackUpdateError(
        'PACK_DIFF_APPLY_FAILED',
        'missing bytes for hash $digest',
      );
    }
    for (final path in matches) {
      result[path] = additions[path]!;
    }
  }
  return result;
}

InstalledContentPack mergeDiffIntoPack(
  InstalledContentPack installed,
  PackDiffDownload download, {
  required ManifestSignatureVerifier verifySignature,
}) {
  if (!verifySignature(
    download.manifest,
    download.signatureB64,
    download.publicKeyB64,
  )) {
    throw PackUpdateError(
      'PACK_SIGNATURE_INVALID',
      'diff manifest signature invalid',
    );
  }

  final additions = <String, Uint8List>{};
  for (final blob in download.blobs) {
    final digest = fileContentHash(blob.path, blob.data);
    if (digest != blob.sha256) {
      throw PackUpdateError(
        'PACK_DIFF_HASH_MISMATCH',
        'blob hash mismatch for ${blob.path}',
      );
    }
    additions[blob.path] = blob.data;
  }

  final merged = applyPackDiff(installed.files, download.diff, additions);
  merged['manifest.json'] = Uint8List.fromList(
    utf8.encode(jsonEncode(download.manifest)),
  );
  merged['signature.txt'] = Uint8List.fromList(utf8.encode(download.signatureB64));
  merged['public_key.txt'] = Uint8List.fromList(utf8.encode(download.publicKeyB64));

  return InstalledContentPack(
    languageCode: installed.languageCode,
    version: download.toVersion,
    files: merged,
    manifest: download.manifest,
    signatureB64: download.signatureB64,
    publicKeyB64: download.publicKeyB64,
  );
}

class PackUpdater {
  PackUpdater({
    required this.languageCode,
    required ManifestSignatureVerifier verifySignature,
    PackDiffFetcher? fetchDiff,
  })  : _verifySignature = verifySignature,
        _fetchDiff = fetchDiff;

  final String languageCode;
  final ManifestSignatureVerifier _verifySignature;
  final PackDiffFetcher? _fetchDiff;

  PackUpdaterState _state = const PackUpdaterState(phase: PackUpdaterPhase.idle);
  InstalledContentPack? _installed;

  PackUpdaterState get state => _state;
  InstalledContentPack? get installed => _installed;

  void installPack(InstalledContentPack pack) {
    _installed = pack;
    _state = PackUpdaterState(
      phase: PackUpdaterPhase.ready,
      installedVersion: pack.version,
    );
  }

  Future<InstalledContentPack?> applyDiffDownload(PackDiffDownload download) async {
    final current = _installed;
    if (current == null) {
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.error,
        error: PackUpdateError('PACK_NOT_INSTALLED', 'no installed pack'),
      );
      return null;
    }
    _state = PackUpdaterState(
      phase: PackUpdaterPhase.applying,
      installedVersion: current.version,
    );
    try {
      final updated = mergeDiffIntoPack(
        current,
        download,
        verifySignature: _verifySignature,
      );
      _installed = updated;
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.ready,
        installedVersion: updated.version,
      );
      return updated;
    } on PackUpdateError catch (err) {
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.error,
        installedVersion: current.version,
        error: err,
      );
      return null;
    }
  }

  Future<InstalledContentPack?> updateToVersion(String targetVersion) async {
    final current = _installed;
    final fetch = _fetchDiff;
    if (current == null || fetch == null) {
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.error,
        error: PackUpdateError('PACK_UPDATE_UNAVAILABLE', 'fetch not configured'),
      );
      return null;
    }
    _state = PackUpdaterState(
      phase: PackUpdaterPhase.downloading,
      installedVersion: current.version,
    );
    try {
      final download = await fetch(languageCode, current.version, targetVersion);
      return applyDiffDownload(download);
    } on PackUpdateError catch (err) {
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.error,
        installedVersion: current.version,
        error: err,
      );
      return null;
    } catch (err) {
      _state = PackUpdaterState(
        phase: PackUpdaterPhase.error,
        installedVersion: current.version,
        error: PackUpdateError('PACK_DOWNLOAD_FAILED', err.toString()),
      );
      return null;
    }
  }
}
