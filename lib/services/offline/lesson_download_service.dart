import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/offline/local_lesson.dart';
import '../../config/api_contract.dart';
import '../../utils/api_service.dart';
import '../../utils/structured_logger.dart';
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
  final Dio _dio = Dio();
  
  static const int _defaultStorageQuotaMB = 500;
  int _storageQuotaBytes = _defaultStorageQuotaMB * 1024 * 1024;
  
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, ValueNotifier<DownloadProgress>> _progressNotifiers = {};
  
  Directory? _audioDirectory;

  /// Initialize the service
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _audioDirectory = Directory('${appDir.path}/offline_audio');
    if (!await _audioDirectory!.exists()) {
      await _audioDirectory!.create(recursive: true);
    }
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
        ApiContract.offline.contentManifest(language),
      );

      if (manifestResponse.statusCode != 200) {
        throw Exception('Failed to fetch manifest: ${manifestResponse.statusCode}');
      }

      final manifest = manifestResponse.data as Map<String, dynamic>;
      final lessons = manifest['lessons'] as List<dynamic>? ?? [];
      final totalLessons = lessons.length;

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
        return;
      }

      int totalBytes = 0;
      int downloadedBytes = 0;
      int completedLessons = 0;

      for (final lessonData in lessons) {
        if (cancelToken.isCancelled) {
          throw Exception('Download cancelled');
        }

        final lessonId = lessonData['id'] as String;
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
            lessonData: lessonData as Map<String, dynamic>,
            language: language,
            cancelToken: cancelToken,
            onProgress: (bytesDownloaded) {
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
          
          totalBytes += lessonSize;
          completedLessons++;
          downloadedBytes += lessonSize;
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

  /// Download a single lesson
  Future<void> downloadSingleLesson(String lessonId) async {
    await init();
    
    final cancelToken = CancelToken();
    _activeDownloads[lessonId] = cancelToken;

    try {
      await ApiService.initialize();
      
      final response = await ApiService.get('/lessons/$lessonId/');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch lesson: ${response.statusCode}');
      }

      final lessonData = response.data as Map<String, dynamic>;
      final language = lessonData['language'] as String? ?? 'unknown';

      await _downloadSingleLesson(
        lessonId: lessonId,
        lessonData: lessonData,
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
    final audioUrls = (lessonData['audio_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final imageUrls = (lessonData['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    
    final List<String> audioPaths = [];
    int totalSize = 0;

    for (final audioUrl in audioUrls) {
      if (audioUrl == null || audioUrl.isEmpty) continue;
      
      final fileName = _getFileNameFromUrl(audioUrl);
      final localPath = '${_audioDirectory!.path}/$language/$lessonId/$fileName';
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        totalSize += await localFile.length();
        audioPaths.add(localPath);
        continue;
      }

      await localFile.parent.create(recursive: true);
      
      final fileSize = await _downloadFile(
        url: audioUrl,
        localPath: localPath,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          onProgress(received);
        },
      );
      
      totalSize += fileSize;
      audioPaths.add(localPath);
    }

    final List<String> imagePaths = [];
    for (final imageUrl in imageUrls) {
      if (imageUrl == null || imageUrl.isEmpty) continue;
      
      final fileName = _getFileNameFromUrl(imageUrl);
      final localPath = '${_audioDirectory!.path}/$language/$lessonId/images/$fileName';
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        totalSize += await localFile.length();
        imagePaths.add(localPath);
        continue;
      }

      await localFile.parent.create(recursive: true);
      
      final fileSize = await _downloadFile(
        url: imageUrl,
        localPath: localPath,
        cancelToken: cancelToken,
        onProgress: (received, total) {},
      );
      
      totalSize += fileSize;
      imagePaths.add(localPath);
    }

    final localLesson = LocalLesson(
      id: lessonId,
      title: lessonData['title'] as String? ?? '',
      content: lessonData['content'] as String? ?? '',
      language: language,
      level: lessonData['level'] as String? ?? 'beginner',
      audioPaths: audioPaths,
      imagePaths: imagePaths,
      downloadedAt: DateTime.now(),
      sizeBytes: totalSize,
      metadata: lessonData['metadata'] as Map<String, dynamic>? ?? {},
      isComplete: true,
      orderIndex: lessonData['order_index'] as int? ?? 0,
      moduleId: lessonData['module_id'] as String?,
      unitId: lessonData['unit_id'] as String?,
      exercises: (lessonData['exercises'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );

    await _db.saveLesson(localLesson);
    
    return totalSize;
  }

  /// Download a file with progress tracking
  Future<int> _downloadFile({
    required String url,
    required String localPath,
    required void Function(int, int?) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          onProgress(received, total ?? 0);
        },
      );
      
      final file = File(localPath);
      return await file.length();
    } catch (e) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
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
