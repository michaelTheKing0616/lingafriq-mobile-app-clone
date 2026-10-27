import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// P7-928 offline lexicon pack: top-ranked entries with audio metadata.
class LexiconPackCorruptException implements Exception {
  LexiconPackCorruptException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'LexiconPackCorruptException($code${detail == null ? '' : ': $detail'})';
}

class LexiconPackLowStorageWarning implements Exception {
  LexiconPackLowStorageWarning(this.requiredBytes, this.availableBytes);

  final int requiredBytes;
  final int availableBytes;

  @override
  String toString() =>
      'LexiconPackLowStorageWarning(need $requiredBytes B, have $availableBytes B)';
}

class LexiconPackEntry {
  LexiconPackEntry({
    required this.lexemeId,
    required this.lemma,
    required this.standard,
    required this.adjustedRank,
    required this.audioUris,
    this.verificationStatus = 'pack_ranked',
  });

  final String lexemeId;
  final String lemma;
  final String standard;
  final int adjustedRank;
  final List<String> audioUris;
  final String verificationStatus;

  Map<String, dynamic> toJson() => {
        'lexeme_id': lexemeId,
        'lemma': lemma,
        'standard': standard,
        'adjusted_rank': adjustedRank,
        'audio_uris': audioUris,
        'verification_status': verificationStatus,
      };

  factory LexiconPackEntry.fromJson(Map<String, dynamic> json) {
    final audio = json['audio_uris'];
    return LexiconPackEntry(
      lexemeId: (json['lexeme_id'] ?? '').toString(),
      lemma: (json['lemma'] ?? '').toString(),
      standard: (json['standard'] ?? json['lemma'] ?? '').toString(),
      adjustedRank: (json['adjusted_rank'] as num?)?.toInt() ?? 0,
      audioUris: audio is List
          ? audio.map((e) => e.toString()).where((u) => u.isNotEmpty).toList()
          : const [],
      verificationStatus: (json['verification_status'] ?? 'pack_ranked').toString(),
    );
  }
}

class LexiconPackManifest {
  LexiconPackManifest({
    required this.language,
    required this.version,
    required this.entryCount,
    required this.entriesSha256,
    required this.audioBytesEstimate,
    this.baseVersion,
  });

  final String language;
  final String version;
  final int entryCount;
  final String entriesSha256;
  final int audioBytesEstimate;
  final String? baseVersion;

  Map<String, dynamic> toJson() => {
        'card': 'P7-928',
        'language': language,
        'version': version,
        'entry_count': entryCount,
        'entries_sha256': entriesSha256,
        'audio_bytes_estimate': audioBytesEstimate,
        'base_version': baseVersion,
      };

  factory LexiconPackManifest.fromJson(Map<String, dynamic> json) {
    return LexiconPackManifest(
      language: (json['language'] ?? '').toString(),
      version: (json['version'] ?? '').toString(),
      entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
      entriesSha256: (json['entries_sha256'] ?? '').toString(),
      audioBytesEstimate: (json['audio_bytes_estimate'] as num?)?.toInt() ?? 0,
      baseVersion: json['base_version']?.toString(),
    );
  }
}

class InstalledLexiconPack {
  InstalledLexiconPack({
    required this.manifest,
    required this.entries,
    required this.verifiedAt,
  });

  final LexiconPackManifest manifest;
  final List<LexiconPackEntry> entries;
  final DateTime verifiedAt;
}

String lexiconPackEntriesDigest(List<LexiconPackEntry> entries) {
  final payload = jsonEncode(entries.map((e) => e.toJson()).toList());
  return sha256.convert(utf8.encode(payload)).toString();
}

bool verifyLexiconPackIntegrity(LexiconPackManifest manifest, List<LexiconPackEntry> entries) {
  if (manifest.entryCount != entries.length) return false;
  return lexiconPackEntriesDigest(entries) == manifest.entriesSha256;
}

List<LexiconPackEntry> mergeIncrementalLexiconPack({
  required List<LexiconPackEntry> installedEntries,
  required List<LexiconPackEntry> deltaEntries,
  required LexiconPackManifest incomingManifest,
  required String installedVersion,
  int maxEntries = 5000,
}) {
  if (incomingManifest.baseVersion != installedVersion) {
    throw LexiconPackCorruptException('incremental_base_mismatch');
  }
  final merged = <String, LexiconPackEntry>{};
  for (final row in installedEntries) {
    merged[row.lexemeId] = row;
  }
  for (final row in deltaEntries) {
    merged[row.lexemeId] = row;
  }
  final combined = merged.values.toList()
    ..sort((a, b) => a.adjustedRank.compareTo(b.adjustedRank));
  if (combined.length > maxEntries) {
    return combined.sublist(0, maxEntries);
  }
  return combined;
}

/// In-memory store for tests and offline lookup after a verified install.
class LexiconPackService {
  LexiconPackService({
    this.lowStorageThresholdBytes = 50 * 1024 * 1024,
    this.availableBytesProvider,
  });

  final int lowStorageThresholdBytes;
  final Future<int> Function()? availableBytesProvider;

  InstalledLexiconPack? _active;
  InstalledLexiconPack? _staging;

  InstalledLexiconPack? get activePack => _active;

  Future<void> assertStorageForDownload(LexiconPackManifest manifest) async {
    final available = availableBytesProvider != null
        ? await availableBytesProvider!()
        : lowStorageThresholdBytes + 1;
    final need = manifest.audioBytesEstimate + 2 * 1024 * 1024;
    if (available < need || available < lowStorageThresholdBytes) {
      throw LexiconPackLowStorageWarning(need, available);
    }
  }

  Future<InstalledLexiconPack> installVerifiedPack({
    required LexiconPackManifest manifest,
    required List<LexiconPackEntry> entries,
  }) async {
    if (!verifyLexiconPackIntegrity(manifest, entries)) {
      throw LexiconPackCorruptException('integrity_failed');
    }
    final installed = InstalledLexiconPack(
      manifest: manifest,
      entries: entries,
      verifiedAt: DateTime.now().toUtc(),
    );
    _staging = installed;
    _active = installed;
    _staging = null;
    return installed;
  }

  Future<InstalledLexiconPack> syncIncrementalPack({
    required LexiconPackManifest manifest,
    required List<LexiconPackEntry> deltaEntries,
  }) async {
    final current = _active;
    if (current == null) {
      return installVerifiedPack(manifest: manifest, entries: deltaEntries);
    }
    final merged = mergeIncrementalLexiconPack(
      installedEntries: current.entries,
      deltaEntries: deltaEntries,
      incomingManifest: manifest,
      installedVersion: current.manifest.version,
    );
    if (!verifyLexiconPackIntegrity(manifest, merged)) {
      throw LexiconPackCorruptException('integrity_failed');
    }
    _staging = InstalledLexiconPack(
      manifest: manifest,
      entries: merged,
      verifiedAt: DateTime.now().toUtc(),
    );
    _active = _staging;
    _staging = null;
    return _active!;
  }

  LexiconPackEntry? lookupLemma(String lemma) {
    final needle = lemma.trim().toLowerCase();
    if (needle.isEmpty || _active == null) return null;
    for (final row in _active!.entries) {
      if (row.lemma.toLowerCase() == needle || row.standard.toLowerCase() == needle) {
        return row;
      }
    }
    return null;
  }

  LexiconPackEntry? lookupLexemeId(String lexemeId) {
    final id = lexemeId.trim();
    if (id.isEmpty || _active == null) return null;
    for (final row in _active!.entries) {
      if (row.lexemeId == id) return row;
    }
    return null;
  }

  List<LexiconPackEntry> searchPrefix(String query, {int limit = 25}) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty || _active == null) return const [];
    final hits = <LexiconPackEntry>[];
    for (final row in _active!.entries) {
      if (row.lemma.toLowerCase().startsWith(needle) ||
          row.standard.toLowerCase().startsWith(needle)) {
        hits.add(row);
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }

  void openActivePack() {
    if (_active == null) {
      throw LexiconPackCorruptException('pack_missing');
    }
    if (!verifyLexiconPackIntegrity(_active!.manifest, _active!.entries)) {
      throw LexiconPackCorruptException('integrity_failed');
    }
  }

  @visibleForTesting
  void resetForTests() {
    _active = null;
    _staging = null;
  }
}
