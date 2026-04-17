import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/offline/local_lesson.dart';
import '../../config/api_contract.dart';
import '../../services/env_config.dart';
import '../../utils/api_service.dart';
import '../../utils/structured_logger.dart';
import '../learning/dialect_preference_service.dart';
import '../learning/heritage_milestone_service.dart';
import 'local_database_service.dart';

/// Download progress information
class DownloadProgress {
  final String language;
  final int totalLessons;
  final int completedLessons;
  final int totalBytes;
  final int downloadedBytes;
  final bool isComplete;
  final String? currentLessonId;
  final String? error;

  DownloadProgress({
    required this.language,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.isComplete,
    this.currentLessonId,
    this.error,
  });

  double get progressPercentage {
    if (totalBytes == 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'totalLessons': totalLessons,
    'completedLessons': completedLessons,
    'totalBytes': totalBytes,
    'downloadedBytes': downloadedBytes,
    'isComplete': isComplete,
    'currentLessonId': currentLessonId,
    'error': error,
  };
}

/// Lesson Download Service
/// Handles downloading lesson content and audio files for offline use
class LessonDownloadService {
  static final LessonDownloadService _instance = LessonDownloadService._internal();
  factory LessonDownloadService() => _instance;
  LessonDownloadService._internal();

  final LocalDatabaseService _db = LocalDatabaseService();
  
  static const int _defaultStorageQuotaMB = 500;
  int _storageQuotaBytes = _defaultStorageQuotaMB * 1024 * 1024;
  
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, ValueNotifier<DownloadProgress>> _progressNotifiers = {};
  
  Directory? _audioDirectory;
  Box<String>? _packStateBox;
  static const String _packStateBoxName = 'lingafriq_offline_pack_state_v1';

  /// Bump when [orderedLessonsForPackDownload] ordering changes (invalidates resume indices).
  static const int _lessonOrderVersion = 2;

  final DialectPreferenceService _dialectPrefs = DialectPreferenceService();

  static bool _lessonMatchesDialect(Map<String, dynamic> m, String? preferredDialectTag) {
    final tag = preferredDialectTag?.trim().toLowerCase();
    if (tag == null || tag.isEmpty) return false;
    final tags = m['dialectTags'];
    if (tags is! List) return false;
    for (final t in tags) {
      if (t.toString().trim().toLowerCase() == tag) return true;
    }
    return false;
  }

  /// Heritage-linked lessons first, then dialect match, then the rest (stable by lesson id).
  static List<Map<String, dynamic>> orderedLessonsForPackDownload(
    List<dynamic> rawLessons,
    String? preferredDialectTag,
  ) {
    final parsed = <Map<String, dynamic>>[];
    for (final e in rawLessons) {
      if (e is Map) parsed.add(Map<String, dynamic>.from(e));
    }
    int tier(Map<String, dynamic> m) {
      final hasHeritage = m['heritageMilestoneId']?.toString().trim().isNotEmpty == true;
      if (hasHeritage) return 0;
      if (_lessonMatchesDialect(m, preferredDialectTag)) return 1;
      return 2;
    }

    parsed.sort((a, b) {
      final ta = tier(a);
      final tb = tier(b);
      if (ta != tb) return ta.compareTo(tb);
      if (ta == 0) {
        final da = _lessonMatchesDialect(a, preferredDialectTag);
        final db = _lessonMatchesDialect(b, preferredDialectTag);
        if (da != db) return da ? -1 : 1;
      }
      final ida = int.tryParse(a['id']?.toString() ?? '') ?? 0;
      final idb = int.tryParse(b['id']?.toString() ?? '') ?? 0;
      return ida.compareTo(idb);
    });
    return parsed;
  }

  Future<String?> _preferredDialectTagForManifest(Map<String, dynamic> manifest, String languageParam) async {
    final fromManifest = manifest['language']?.toString().trim().toLowerCase();
    final p1 = fromManifest != null && fromManifest.isNotEmpty
        ? await _dialectPrefs.readCachedPreferredTag(fromManifest)
        : null;
    if (p1 != null && p1.isNotEmpty) return p1;
    final p2 = await _dialectPrefs.readCachedPreferredTag(languageParam);
    if (p2 != null && p2.isNotEmpty) return p2;
    return null;
  }

  /// Optional: ask the server to re-hash `/media/*` assets (same rules as pack generation).
  /// Returns the `results` list from `POST /api/v2/content-packs/:language/verify`.
  Future<List<Map<String, dynamic>>> verifyAssetsWithServer({
    required String language,
    required List<Map<String, String>> assets,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.contentPacks.verify(language),
      data: <String, dynamic>{'assets': assets},
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('verify failed (${res.statusCode})');
    }
    final root = (res.data as Map).cast<String, dynamic>();
    final raw = root['results'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// Initialize the service
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _audioDirectory = Directory('${appDir.path}/offline_audio');
    if (!await _audioDirectory!.exists()) {
      await _audioDirectory!.create(recursive: true);
    }
    _packStateBox ??= await Hive.openBox<String>(_packStateBoxName);
  }

  Map<String, dynamic>? _getPackState(String language) {
    final raw = _packStateBox?.get(language);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  Future<void> _savePackState(String language, Map<String, dynamic> state) async {
    await _packStateBox?.put(language, jsonEncode(state));
  }

  Future<void> _clearPackState(String language) async {
    await _packStateBox?.delete(language);
  }

  /// True if there is persisted pack state indicating an interrupted download.
  /// Used by UI to show "Resume" vs "Download".
  Future<bool> hasResumablePackDownload(String language) async {
    await init();
    final s = _getPackState(language);
    if (s == null) return false;
    final nextIdx = (s['nextLessonIndex'] is num) ? (s['nextLessonIndex'] as num).toInt() : 0;
    final totalLessons = (s['totalLessons'] is num) ? (s['totalLessons'] as num).toInt() : 0;
    final orderVer = (s['lessonOrderVersion'] is num) ? (s['lessonOrderVersion'] as num).toInt() : 0;
    if (totalLessons <= 0) return false;
    if (orderVer != _lessonOrderVersion) return false;
    return nextIdx > 0 && nextIdx < totalLessons;
  }

  /// Set storage quota in MB
  void setStorageQuota(int quotaMB) {
    _storageQuotaBytes = quotaMB * 1024 * 1024;
  }

  /// Get storage quota in MB
  int getStorageQuotaMB() => _storageQuotaBytes ~/ (1024 * 1024);

  /// Download all lessons for a language
  Future<void> downloadLessonPack(String language) async {
    if (_activeDownloads.containsKey(language)) {
      throw Exception('Download already in progress for $language');
    }

    await init();
    
    final cancelToken = CancelToken();
    _activeDownloads[language] = cancelToken;

    final progressNotifier = ValueNotifier<DownloadProgress>(
      DownloadProgress(
        language: language,
        totalLessons: 0,
        completedLessons: 0,
        totalBytes: 0,
        downloadedBytes: 0,
        isComplete: false,
      ),
    );
    _progressNotifiers[language] = progressNotifier;

    try {
      await ApiService.initialize();
      
      final manifestResponse = await ApiService.get(
        ApiContract.contentPacks.manifest(language),
      );

      if (manifestResponse.statusCode != 200) {
        throw Exception('Failed to fetch manifest: ${manifestResponse.statusCode}');
      }

      final root = manifestResponse.data as Map<String, dynamic>;
      final manifest = (root['manifest'] as Map?)?.cast<String, dynamic>() ?? {};
      final rawLessons = (manifest['lessons'] as List<dynamic>?) ?? [];
      final preferredTag = await _preferredDialectTagForManifest(manifest, language);
      final lessons = orderedLessonsForPackDownload(rawLessons, preferredTag);
      final totalLessons = lessons.length;
      final totalBytesManifest = (manifest['totalBytes'] is num) ? (manifest['totalBytes'] as num).toInt() : 0;
      final checksum = manifest['checksumSha256']?.toString() ?? '';

      final hm = manifest['heritageMilestones'];
      if (hm is List && hm.isNotEmpty) {
        await HeritageMilestoneService.cacheMilestonesFromPackManifest(hm);
      }

      if (totalLessons == 0) {
        progressNotifier.value = DownloadProgress(
          language: language,
          totalLessons: 0,
          completedLessons: 0,
          totalBytes: 0,
          downloadedBytes: 0,
          isComplete: true,
        );
        _activeDownloads.remove(language);
        await _clearPackState(language);
        return;
      }

      int totalBytes = totalBytesManifest;
      int downloadedBytes = 0;
      int completedLessons = 0;
      int resumeIndex = 0;

      final existingState = _getPackState(language);
      if (existingState != null &&
          (existingState['schemaVersion'] == 1) &&
          (existingState['lessonOrderVersion'] == _lessonOrderVersion) &&
          (existingState['checksumSha256']?.toString() ?? '') == checksum) {
        resumeIndex = (existingState['nextLessonIndex'] is num) ? (existingState['nextLessonIndex'] as num).toInt() : 0;
        completedLessons = (existingState['completedLessons'] is num) ? (existingState['completedLessons'] as num).toInt() : 0;
        downloadedBytes = (existingState['downloadedBytes'] is num) ? (existingState['downloadedBytes'] as num).toInt() : 0;

        if (resumeIndex < 0 || resumeIndex > totalLessons) resumeIndex = 0;
        if (completedLessons < 0 || completedLessons > totalLessons) completedLessons = 0;
        if (downloadedBytes < 0) downloadedBytes = 0;
      } else {
        await _savePackState(language, {
          'schemaVersion': 1,
          'lessonOrderVersion': _lessonOrderVersion,
          'checksumSha256': checksum,
          'totalLessons': totalLessons,
          'totalBytes': totalBytes,
          'completedLessons': 0,
          'downloadedBytes': 0,
          'nextLessonIndex': 0,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      }

      for (var i = resumeIndex; i < lessons.length; i++) {
        if (cancelToken.isCancelled) {
          throw Exception('Download cancelled');
        }

        final lessonData = lessons[i];
        if (lessonData is! Map) {
          continue;
        }
        final lessonMap = Map<String, dynamic>.from(lessonData);
        final lessonId = (lessonMap['id']).toString();
        progressNotifier.value = DownloadProgress(
          language: language,
          totalLessons: totalLessons,
          completedLessons: completedLessons,
          totalBytes: totalBytes,
          downloadedBytes: downloadedBytes,
          isComplete: false,
          currentLessonId: lessonId,
        );

        try {
          final lessonSize = await _downloadSingleLesson(
            lessonId: lessonId,
            lessonData: lessonMap,
            language: language,
            cancelToken: cancelToken,
            onProgress: (bytesDownloaded) {
              // bytesDownloaded is an incremental delta from the underlying HTTP stream.
              downloadedBytes += bytesDownloaded;
              progressNotifier.value = DownloadProgress(
                language: language,
                totalLessons: totalLessons,
                completedLessons: completedLessons,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                isComplete: false,
                currentLessonId: lessonId,
              );
            },
          );
          
          completedLessons++;
          await _savePackState(language, {
            'schemaVersion': 1,
            'lessonOrderVersion': _lessonOrderVersion,
            'checksumSha256': checksum,
            'totalLessons': totalLessons,
            'totalBytes': totalBytes,
            'completedLessons': completedLessons,
            'downloadedBytes': downloadedBytes,
            'nextLessonIndex': i + 1,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          logger.error('Failed to download lesson $lessonId', error: e);
          progressNotifier.value = DownloadProgress(
            language: language,
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            isComplete: false,
            currentLessonId: lessonId,
            error: e.toString(),
          );
          rethrow;
        }
      }

      progressNotifier.value = DownloadProgress(
        language: language,
        totalLessons: totalLessons,
        completedLessons: completedLessons,
        totalBytes: totalBytes,
        downloadedBytes: downloadedBytes,
        isComplete: true,
      );
      await _clearPackState(language);
    } catch (e) {
      logger.error('Failed to download lesson pack for $language', error: e);
      progressNotifier.value = DownloadProgress(
        language: language,
        totalLessons: progressNotifier.value.totalLessons,
        completedLessons: progressNotifier.value.completedLessons,
        totalBytes: progressNotifier.value.totalBytes,
        downloadedBytes: progressNotifier.value.downloadedBytes,
        isComplete: false,
        error: e.toString(),
      );
      rethrow;
    } finally {
      _activeDownloads.remove(language);
    }
  }

  /// Resume a previously interrupted pack download, if state exists.
  /// If no persisted state exists, this behaves like [downloadLessonPack].
  Future<void> resumeLessonPack(String language) => downloadLessonPack(language);

  /// Download a single lesson
  Future<void> downloadSingleLesson(String lessonId) async {
    await init();
    
    final cancelToken = CancelToken();
    _activeDownloads[lessonId] = cancelToken;

    try {
      await ApiService.initialize();
      
      // Single-lesson offline download:
      // 1) Fetch the canonical lesson to discover its language_id
      // 2) Fetch the content-pack manifest for that language_id
      // 3) Download the matching lesson in pack format (assets + raw lesson JSON)
      final lessonRes = await ApiService.get(ApiContract.url('/lessons/$lessonId'));
      if (lessonRes.statusCode != 200 || lessonRes.data is! Map) {
        throw Exception('Failed to fetch lesson metadata (${lessonRes.statusCode})');
      }
      final lessonObj = (lessonRes.data as Map).cast<String, dynamic>();
      final languageId = lessonObj['language_id'];
      final languageKey = (languageId is num) ? '${languageId.toInt()}' : (languageId?.toString() ?? '');
      if (languageKey.isEmpty) {
        throw Exception('Lesson metadata missing language_id');
      }

      final manifestRes = await ApiService.get(ApiContract.contentPacks.manifest(languageKey));
      if (manifestRes.statusCode != 200 || manifestRes.data is! Map) {
        throw Exception('Failed to fetch pack manifest (${manifestRes.statusCode})');
      }

      final root = (manifestRes.data as Map).cast<String, dynamic>();
      final manifest = (root['manifest'] as Map?)?.cast<String, dynamic>() ?? {};
      final lessons = (manifest['lessons'] as List<dynamic>?) ?? [];
      final match = lessons.whereType<Map>().firstWhere(
        (e) => e['id']?.toString() == lessonId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isEmpty) throw Exception('Lesson $lessonId not found in pack manifest');
      final language = (manifest['language']?.toString().isNotEmpty == true) ? manifest['language'].toString() : languageKey;

      await _downloadSingleLesson(
        lessonId: lessonId,
        lessonData: match.cast<String, dynamic>(),
        language: language,
        cancelToken: cancelToken,
        onProgress: (_) {},
      );
    } finally {
      _activeDownloads.remove(lessonId);
    }
  }

  /// Internal method to download a single lesson
  Future<int> _downloadSingleLesson({
    required String lessonId,
    required Map<String, dynamic> lessonData,
    required String language,
    required void Function(int) onProgress,
    CancelToken? cancelToken,
  }) async {
    final assets = (lessonData['assets'] as List<dynamic>?) ?? [];
    final audioAssets = assets.where((a) => a is Map && a['kind'] == 'audio').cast<Map>();
    final imageAssets = assets.where((a) => a is Map && a['kind'] == 'image').cast<Map>();
    final videoAssets = assets.where((a) => a is Map && a['kind'] == 'video').cast<Map>();
    
    final List<String> audioPaths = [];
    int totalSize = 0;

    for (final a in audioAssets) {
      final audioUrl = a['url']?.toString() ?? '';
      final expectedSha = a['sha256']?.toString() ?? '';
      if (audioUrl.isEmpty || expectedSha.isEmpty) continue;
      
      final fileName = _getFileNameFromUrl(audioUrl);
      final localPath = '${_audioDirectory!.path}/$language/$lessonId/$fileName';
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        final ok = await _verifySha256(localFile, expectedSha);
        if (ok) {
          totalSize += await localFile.length();
          audioPaths.add(localPath);
          continue;
        }
        await localFile.delete();
      }

      await localFile.parent.create(recursive: true);
      
      final fileSize = await _downloadFileWithIntegrity(
        url: audioUrl,
        localPath: localPath,
        expectedSha256Hex: expectedSha,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          onProgress(received);
        },
      );
      
      totalSize += fileSize;
      audioPaths.add(localPath);
    }

    final List<String> imagePaths = [];
    for (final a in imageAssets) {
      final imageUrl = a['url']?.toString() ?? '';
      final expectedSha = a['sha256']?.toString() ?? '';
      if (imageUrl.isEmpty || expectedSha.isEmpty) continue;
      
      final fileName = _getFileNameFromUrl(imageUrl);
      final localPath = '${_audioDirectory!.path}/$language/$lessonId/images/$fileName';
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        final ok = await _verifySha256(localFile, expectedSha);
        if (ok) {
          totalSize += await localFile.length();
          imagePaths.add(localPath);
          continue;
        }
        await localFile.delete();
      }

      await localFile.parent.create(recursive: true);
      
      final fileSize = await _downloadFileWithIntegrity(
        url: imageUrl,
        localPath: localPath,
        expectedSha256Hex: expectedSha,
        cancelToken: cancelToken,
        onProgress: (received, total) {},
      );
      
      totalSize += fileSize;
      imagePaths.add(localPath);
    }

    final List<String> videoPaths = [];
    for (final a in videoAssets) {
      final videoUrl = a['url']?.toString() ?? '';
      final expectedSha = a['sha256']?.toString() ?? '';
      if (videoUrl.isEmpty || expectedSha.isEmpty) continue;

      final fileName = _getFileNameFromUrl(videoUrl);
      final localPath = '${_audioDirectory!.path}/$language/$lessonId/videos/$fileName';
      final localFile = File(localPath);

      if (await localFile.exists()) {
        final ok = await _verifySha256(localFile, expectedSha);
        if (ok) {
          totalSize += await localFile.length();
          videoPaths.add(localPath);
          continue;
        }
        await localFile.delete();
      }

      await localFile.parent.create(recursive: true);

      final fileSize = await _downloadFileWithIntegrity(
        url: videoUrl,
        localPath: localPath,
        expectedSha256Hex: expectedSha,
        cancelToken: cancelToken,
        onProgress: (received, total) {},
      );

      totalSize += fileSize;
      videoPaths.add(localPath);
    }

    final lessonJson = jsonEncode(lessonData['lesson'] ?? lessonData);
    final meta = <String, dynamic>{};
    if (videoPaths.isNotEmpty) {
      meta['videoPaths'] = videoPaths;
    }
    final localLesson = LocalLesson(
      id: lessonId,
      title: lessonData['name'] as String? ?? '',
      content: lessonJson,
      language: language,
      level: 'beginner',
      audioPaths: audioPaths,
      imagePaths: imagePaths,
      downloadedAt: DateTime.now(),
      sizeBytes: totalSize,
      metadata: meta,
      isComplete: true,
      orderIndex: int.tryParse(lessonId) ?? 0,
      exercises: const [],
    );

    await _db.saveLesson(localLesson);
    
    return totalSize;
  }

  /// Download a file with progress tracking
  Future<int> _downloadFileWithIntegrity({
    required String url,
    required String localPath,
    required String expectedSha256Hex,
    required void Function(int, int?) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _downloadResumableHttp(
        url: url,
        localPath: localPath,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      final file = File(localPath);
      final ok = await _verifySha256(file, expectedSha256Hex);
      if (!ok) {
        await file.delete();
        throw Exception('Integrity check failed (sha256 mismatch)');
      }
      return await file.length();
    } catch (e) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<bool> _verifySha256(File file, String expectedHex) async {
    final bytes = await file.readAsBytes();
    final got = sha256.convert(bytes).toString();
    return got.toLowerCase() == expectedHex.toLowerCase();
  }

  /// Resumable download using HTTP Range where supported.
  Future<void> _downloadResumableHttp({
    required String url,
    required String localPath,
    required void Function(int, int?) onProgress,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.parse(url);
    final file = File(localPath);
    int existing = 0;
    if (await file.exists()) {
      existing = await file.length();
    }

    final client = HttpClient();
    try {
      while (true) {
        final req = await client.getUrl(uri);
        await _addAuthHeaderIfApplicable(req, uri);
        if (existing > 0) {
          req.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
        }
        final resp = await req.close();

        if (existing > 0 && resp.statusCode == 200) {
          // Server ignored Range; restart full download so we do not append duplicate bytes.
          await resp.drain<void>();
          if (await file.exists()) {
            await file.delete();
          }
          existing = 0;
          continue;
        }

        if (resp.statusCode == 416) {
          await resp.drain<void>();
          if (await file.exists()) {
            await file.delete();
          }
          existing = 0;
          continue;
        }

        if (resp.statusCode != 200 && resp.statusCode != 206) {
          throw Exception('HTTP ${resp.statusCode}');
        }

        final append = existing > 0 && resp.statusCode == 206;
        final total = resp.contentLength >= 0
            ? (append ? resp.contentLength + existing : resp.contentLength)
            : null;
        final sink = file.openWrite(mode: append ? FileMode.append : FileMode.write);

        try {
          await for (final chunk in resp) {
            if (cancelToken?.isCancelled == true) {
              throw Exception('Download cancelled');
            }
            sink.add(chunk);
            onProgress(chunk.length, total);
          }
        } finally {
          await sink.close();
        }
        break;
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Attach JWT for same-origin pack media when the API is not fully public.
  Future<void> _addAuthHeaderIfApplicable(HttpClientRequest req, Uri requestUri) async {
    final base = Uri.parse(EnvConfig.backendBaseUrl);
    if (requestUri.host.isEmpty || base.host.isEmpty) return;
    if (requestUri.scheme != base.scheme ||
        requestUri.host != base.host ||
        requestUri.port != base.port) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  /// Get download progress for a language
  ValueNotifier<DownloadProgress>? getDownloadProgress(String language) {
    return _progressNotifiers[language];
  }

  /// Cancel active download
  void cancelDownload(String language) {
    final cancelToken = _activeDownloads[language];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel();
      _activeDownloads.remove(language);
    }
  }

  /// Get storage used in bytes
  Future<int> getStorageUsed() async {
    await init();
    
    int totalSize = 0;
    
    final lessons = _db.getAllLessons();
    for (final lesson in lessons) {
      totalSize += lesson.sizeBytes;
    }
    
    if (await _audioDirectory!.exists()) {
      await for (final entity in _audioDirectory!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }

  /// Delete downloaded lessons for a language
  Future<void> deleteDownloadedLessons(String language) async {
    await init();
    
    final lessons = _db.getLessonsByLanguage(language);
    final lessonIds = lessons.map((l) => l.id).toList();
    
    await _db.deleteLessonsBatch(lessonIds);
    
    final languageDir = Directory('${_audioDirectory!.path}/$language');
    if (await languageDir.exists()) {
      await languageDir.delete(recursive: true);
    }
    
    _progressNotifiers.remove(language);
  }

  /// Check if storage quota is exceeded
  Future<bool> isStorageQuotaExceeded() async {
    final used = await getStorageUsed();
    return used >= _storageQuotaBytes;
  }

  /// Get available storage space
  Future<int> getAvailableStorage() async {
    final used = await getStorageUsed();
    return (_storageQuotaBytes - used).clamp(0, _storageQuotaBytes);
  }

  /// Extract filename from URL
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return 'file_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
