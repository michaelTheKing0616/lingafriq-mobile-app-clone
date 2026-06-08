// TTS Audio Cache
//
// SHA256-keyed on-disk cache for synthesized + downloaded audio bytes. Keeps
// the AI Chat, Authentic Path, and Games experiences instant on repeat use,
// and resilient when offline.
//
// Layout:
//   {appDocuments}/tts_cache/{prefix}/{key}.{ext}
//
// We bucket by the first 2 hex chars of the key to avoid filesystem dirent
// blowups on Android when the cache grows past tens of thousands of entries.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TtsCacheEntry {
  final File file;
  final int sizeBytes;
  const TtsCacheEntry({required this.file, required this.sizeBytes});
}

class TtsAudioCache {
  TtsAudioCache._();
  static final TtsAudioCache _i = TtsAudioCache._();
  factory TtsAudioCache() => _i;

  Directory? _root;
  Completer<Directory>? _initCompleter;

  /// Lazily resolves the cache directory and ensures it exists.
  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    if (_initCompleter != null) return _initCompleter!.future;
    final completer = Completer<Directory>();
    _initCompleter = completer;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/tts_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _root = dir;
      completer.complete(dir);
      return dir;
    } catch (e, st) {
      debugPrint('[TtsAudioCache] init failed: $e');
      completer.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Stable key for (language, text, engine, voice, speed) tuple. Two callers
  /// requesting the same audio always hit the same cache file.
  String makeKey({
    required String language,
    required String text,
    required String engine,
    String voice = '',
    double speed = 1.0,
  }) {
    final raw =
        '${language.toLowerCase()}|$engine|$voice|${speed.toStringAsFixed(2)}|$text';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Future<File> _pathFor(String key, String ext) async {
    final root = await _ensureRoot();
    final bucket = key.substring(0, 2);
    final bucketDir = Directory('${root.path}/$bucket');
    if (!await bucketDir.exists()) {
      await bucketDir.create(recursive: true);
    }
    return File('${bucketDir.path}/$key.$ext');
  }

  /// Lookup. Tries the requested [ext] first, then falls back to the other
  /// common audio extension so callers don't need to know whether MMS returned
  /// WAV or MP3.
  Future<TtsCacheEntry?> get(String key, {String ext = 'mp3'}) async {
    try {
      final f = await _pathFor(key, ext);
      if (await f.exists()) {
        final stat = await f.stat();
        return TtsCacheEntry(file: f, sizeBytes: stat.size);
      }
      final alt = ext == 'mp3' ? 'wav' : 'mp3';
      final f2 = await _pathFor(key, alt);
      if (await f2.exists()) {
        final stat = await f2.stat();
        return TtsCacheEntry(file: f2, sizeBytes: stat.size);
      }
    } catch (e) {
      debugPrint('[TtsAudioCache] get failed: $e');
    }
    return null;
  }

  Future<File?> put(String key, List<int> bytes, {String ext = 'mp3'}) async {
    try {
      final f = await _pathFor(key, ext);
      await f.writeAsBytes(bytes, flush: true);
      return f;
    } catch (e) {
      debugPrint('[TtsAudioCache] put failed: $e');
      return null;
    }
  }

  Future<int> sizeBytes() async {
    try {
      final root = await _ensureRoot();
      int total = 0;
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += (await entity.stat()).size;
          } catch (_) {}
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Evicts oldest files until disk usage falls below [maxBytes]. Returns the
  /// number of files evicted. Call periodically (e.g. on app start).
  Future<int> evictLru(int maxBytes) async {
    try {
      final root = await _ensureRoot();
      final entries = <_FileWithAccess>[];
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            entries.add(_FileWithAccess(entity, stat.accessed, stat.size));
          } catch (_) {}
        }
      }
      var total = entries.fold<int>(0, (a, e) => a + e.size);
      if (total <= maxBytes) return 0;
      entries.sort((a, b) => a.accessed.compareTo(b.accessed));
      var evicted = 0;
      for (final entry in entries) {
        if (total <= maxBytes) break;
        try {
          await entry.file.delete();
          total -= entry.size;
          evicted++;
        } catch (_) {}
      }
      return evicted;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clear() async {
    try {
      final root = await _ensureRoot();
      if (await root.exists()) {
        await root.delete(recursive: true);
        await root.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[TtsAudioCache] clear failed: $e');
    }
  }
}

class _FileWithAccess {
  final File file;
  final DateTime accessed;
  final int size;
  _FileWithAccess(this.file, this.accessed, this.size);
}
