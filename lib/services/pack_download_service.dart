import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lingafriq/content/language_pack_catalog.dart';

const _catalogAsset = 'assets/data/cms_manifests/pack_catalog.json';
const _bundledManifestRoot = 'assets/data/cms_manifests';

/// Typed failure for pack download / verify (P12-003 AC2–AC3).
class PackDownloadError implements Exception {
  PackDownloadError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PackDownloadError($code): $message';
}

enum LanguagePackAvailability {
  bundled,
  notDownloaded,
  downloading,
  installed,
  checksumFailed,
}

/// Result of one ranged chunk fetch.
class PackChunkResponse {
  PackChunkResponse({
    required this.bytes,
    required this.totalSize,
  });

  final List<int> bytes;
  final int totalSize;
}

typedef PackChunkFetcher = Future<PackChunkResponse> Function(
  String url,
  int offset,
  int length,
);

typedef CatalogLoader = Future<LanguagePackCatalog> Function();

String sha256HexOfBytes(List<int> bytes) {
  return sha256.convert(bytes).toString();
}

Map<String, dynamic>? manifestBodyFromJson(Map<String, dynamic> decoded) {
  final inner = decoded['manifest'];
  if (inner is Map) return Map<String, dynamic>.from(inner);
  return decoded;
}

class PackDownloadService {
  PackDownloadService({
    Directory? packRoot,
    this.maxRetries = 3,
    PackChunkFetcher? chunkFetcher,
    CatalogLoader? catalogLoader,
    AssetBundle? bundle,
  })  : _packRoot = packRoot,
        _chunkFetcher = chunkFetcher ?? _defaultChunkFetcher,
        _catalogLoader = catalogLoader ?? _loadBundledCatalog,
        _bundle = bundle ?? rootBundle;

  final Directory? _packRoot;
  final int maxRetries;
  final PackChunkFetcher _chunkFetcher;
  final CatalogLoader _catalogLoader;
  final AssetBundle _bundle;

  LanguagePackCatalog? _cachedCatalog;

  Future<Directory> _root() async {
    if (_packRoot != null) return _packRoot!;
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/language_packs');
  }

  Future<LanguagePackCatalog> catalog() async {
    _cachedCatalog ??= await _catalogLoader();
    return _cachedCatalog!;
  }

  Future<LanguagePackEntry?> entryForLanguage(String languageKey) async {
    final cat = await catalog();
    return cat.entryForKey(languageKey);
  }

  Directory _languageDir(Directory root, String id) =>
      Directory('${root.path}/$id');

  File _manifestFile(Directory root, String id) =>
      File('${_languageDir(root, id).path}/manifest.json');

  File _partFile(Directory root, String id) =>
      File('${_languageDir(root, id).path}/manifest.json.part');

  File _resumeFile(Directory root, String id) =>
      File('${_languageDir(root, id).path}/resume.json');

  Future<LanguagePackAvailability> availabilityFor(String languageKey) async {
    final entry = await entryForLanguage(languageKey);
    if (entry == null) {
      throw PackDownloadError('PACK_UNKNOWN_LANGUAGE', languageKey);
    }
    if (entry.bundled) return LanguagePackAvailability.bundled;

    final root = await _root();
    final manifest = _manifestFile(root, entry.id);
    if (await manifest.exists()) {
      final ok = await _verifyInstalledManifest(root, entry);
      return ok
          ? LanguagePackAvailability.installed
          : LanguagePackAvailability.checksumFailed;
    }
    final part = _partFile(root, entry.id);
    if (await part.exists()) {
      return LanguagePackAvailability.downloading;
    }
    final resume = _resumeFile(root, entry.id);
    if (await resume.exists()) {
      return LanguagePackAvailability.downloading;
    }
    return LanguagePackAvailability.notDownloaded;
  }

  Future<Map<String, dynamic>?> loadInstalledOrBundledManifest(
    String languageKey,
  ) async {
    final entry = await entryForLanguage(languageKey);
    if (entry == null) return null;
    if (entry.bundled) {
      return _loadBundledManifestById(entry.id);
    }
    final root = await _root();
    final manifest = _manifestFile(root, entry.id);
    if (!await manifest.exists()) return null;
    final ok = await _verifyInstalledManifest(root, entry);
    if (!ok) return null;
    final decoded =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    return manifestBodyFromJson(decoded);
  }

  Future<void> downloadPack(String languageKey) async {
    final entry = await entryForLanguage(languageKey);
    if (entry == null) {
      throw PackDownloadError('PACK_UNKNOWN_LANGUAGE', languageKey);
    }
    if (entry.bundled) return;
    if (entry.packUrl == null ||
        entry.sha256 == null ||
        entry.sizeBytes == null) {
      throw PackDownloadError('PACK_CATALOG_INCOMPLETE', entry.languageKey);
    }

    final root = await _root();
    final langDir = _languageDir(root, entry.id);
    await langDir.create(recursive: true);

    var attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        await _downloadWithResume(
          entry: entry,
          root: root,
        );
        final verified = await _verifyInstalledManifest(root, entry);
        if (!verified) {
          await _purgeInstalledPack(root, entry.id);
          throw PackDownloadError(
            'PACK_CHECKSUM_MISMATCH',
            entry.languageKey,
          );
        }
        try {
          await _partFile(root, entry.id).delete();
        } catch (_) {}
        try {
          await _resumeFile(root, entry.id).delete();
        } catch (_) {}
        return;
      } on PackDownloadError catch (e) {
        if (e.code == 'PACK_CHECKSUM_MISMATCH') {
          await _purgeInstalledPack(root, entry.id);
          throw e;
        }
        if (attempt >= maxRetries) {
          throw PackDownloadError(
            'PACK_RETRIES_EXHAUSTED',
            '${entry.languageKey}: ${e.message}',
          );
        }
      } on IOException catch (e) {
        if (attempt >= maxRetries) {
          throw PackDownloadError(
            'PACK_RETRIES_EXHAUSTED',
            '${entry.languageKey}: $e',
          );
        }
      }
    }
    throw PackDownloadError('PACK_RETRIES_EXHAUSTED', entry.languageKey);
  }

  Future<void> discardFailedPack(String languageKey) async {
    final entry = await entryForLanguage(languageKey);
    if (entry == null || entry.bundled) return;
    final root = await _root();
    await _purgeInstalledPack(root, entry.id);
  }

  Future<void> _downloadWithResume({
    required LanguagePackEntry entry,
    required Directory root,
  }) async {
    final part = _partFile(root, entry.id);
    final resume = _resumeFile(root, entry.id);
    var offset = 0;
    if (await part.exists()) {
      offset = await part.length();
    } else if (await resume.exists()) {
      final map =
          jsonDecode(await resume.readAsString()) as Map<String, dynamic>;
      offset = (map['offset'] as num?)?.round() ?? 0;
    }

    final cat = await catalog();
    final chunkSize = cat.chunkBytes;
    final total = entry.sizeBytes!;
    final url = entry.packUrl!;

    if (offset > total) offset = 0;

    final sink = part.openWrite(mode: offset > 0 ? FileMode.append : FileMode.write);
    try {
      while (offset < total) {
        final remaining = total - offset;
        final requestLen =
            remaining < chunkSize ? remaining : chunkSize;
        final chunk = await _chunkFetcher(url, offset, requestLen);
        if (chunk.bytes.isEmpty) {
          throw PackDownloadError('PACK_EMPTY_CHUNK', url);
        }
        sink.add(chunk.bytes);
        await sink.flush();
        offset += chunk.bytes.length;
        await resume.writeAsString(jsonEncode({
          'offset': offset,
          'url': url,
          'expectedSha256': entry.sha256,
          'sizeBytes': total,
        }));
      }
    } finally {
      await sink.close();
    }

    final bytes = await part.readAsBytes();
    final digest = sha256HexOfBytes(bytes);
    if (digest != entry.sha256) {
      try {
        await part.delete();
      } catch (_) {}
      try {
        await resume.delete();
      } catch (_) {}
      throw PackDownloadError('PACK_CHECKSUM_MISMATCH', entry.languageKey);
    }

    final manifest = _manifestFile(root, entry.id);
    await part.rename(manifest.path);
  }

  Future<bool> _verifyInstalledManifest(
    Directory root,
    LanguagePackEntry entry,
  ) async {
    if (entry.sha256 == null) return true;
    final manifest = _manifestFile(root, entry.id);
    if (!await manifest.exists()) return false;
    final bytes = await manifest.readAsBytes();
    return sha256HexOfBytes(bytes) == entry.sha256;
  }

  Future<void> _purgeInstalledPack(Directory root, String id) async {
    final dir = _languageDir(root, id);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<Map<String, dynamic>?> _loadBundledManifestById(String id) async {
    try {
      final raw =
          await _bundle.loadString('$_bundledManifestRoot/$id/manifest.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return manifestBodyFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<LanguagePackCatalog> _loadBundledCatalog() async {
    final raw = await rootBundle.loadString(_catalogAsset);
    return LanguagePackCatalog.parse(raw);
  }

  static Future<PackChunkResponse> _defaultChunkFetcher(
    String url,
    int offset,
    int length,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(
        HttpHeaders.rangeHeader,
        'bytes=$offset-${offset + length - 1}',
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.partialContent &&
          response.statusCode != HttpStatus.ok) {
        throw PackDownloadError(
          'PACK_HTTP_ERROR',
          '${response.statusCode} for $url',
        );
      }
      final bytes = await response.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      final totalHeader = response.contentLength;
      var total = totalHeader > 0 ? totalHeader : offset + bytes.length;
      final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
      if (contentRange != null) {
        final slash = contentRange.lastIndexOf('/');
        if (slash >= 0) {
          final parsed = int.tryParse(contentRange.substring(slash + 1));
          if (parsed != null) total = parsed;
        }
      }
      return PackChunkResponse(bytes: bytes, totalSize: total);
    } finally {
      client.close(force: true);
    }
  }
}
