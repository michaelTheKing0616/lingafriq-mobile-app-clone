import 'package:riverpod/legacy.dart';
import '../config/api_contract.dart';
import '../services/connectivity_service.dart';
import '../services/offline/lesson_download_service.dart';
import '../services/offline/local_database_service.dart';
import '../utils/api_service.dart';
import '../utils/structured_logger.dart';

final offlineDownloadProvider = StateNotifierProvider<OfflineDownloadNotifier, OfflineDownloadState>((ref) {
  return OfflineDownloadNotifier();
});

class OfflineDownloadState {
  final Set<String> downloadedLessonIds;
  final Map<String, double> downloadProgress; // lessonId -> 0.0 to 1.0
  final bool isDownloading;
  final String? currentDownloadingLessonId;
  
  const OfflineDownloadState({
    this.downloadedLessonIds = const {},
    this.downloadProgress = const {},
    this.isDownloading = false,
    this.currentDownloadingLessonId,
  });
  
  OfflineDownloadState copyWith({
    Set<String>? downloadedLessonIds,
    Map<String, double>? downloadProgress,
    bool? isDownloading,
    String? currentDownloadingLessonId,
  }) {
    return OfflineDownloadState(
      downloadedLessonIds: downloadedLessonIds ?? this.downloadedLessonIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      currentDownloadingLessonId: currentDownloadingLessonId ?? this.currentDownloadingLessonId,
    );
  }
}

class OfflineDownloadNotifier extends StateNotifier<OfflineDownloadState> {
  final _db = LocalDatabaseService();
  final _downloadService = LessonDownloadService();
  
  OfflineDownloadNotifier() : super(const OfflineDownloadState()) {
    _loadDownloadedLessons();
  }
  
  Future<void> _loadDownloadedLessons() async {
    try {
      final lessons = _db.getAllLessons();
      state = state.copyWith(
        downloadedLessonIds: lessons.map((l) => l.id).toSet(),
      );
    } catch (e) {
      logger.error('Failed to load downloaded lessons', error: e);
    }
  }
  
  bool isDownloaded(String lessonId) => state.downloadedLessonIds.contains(lessonId);
  
  double? getDownloadProgress(String lessonId) => state.downloadProgress[lessonId];
  
  Future<void> downloadLesson(String lessonId) async {
    if (state.isDownloading && state.currentDownloadingLessonId == lessonId) {
      return; // Already downloading
    }
    
    state = state.copyWith(
      isDownloading: true,
      currentDownloadingLessonId: lessonId,
      downloadProgress: {...state.downloadProgress, lessonId: 0.0},
    );
    
    try {
      await _downloadService.downloadSingleLesson(lessonId);
      final updated = {...state.downloadedLessonIds, lessonId};
      state = state.copyWith(
        downloadedLessonIds: updated,
        isDownloading: false,
        currentDownloadingLessonId: null,
        downloadProgress: {...state.downloadProgress}..remove(lessonId),
      );
    } catch (e) {
      logger.error('Failed to download lesson $lessonId', error: e);
      state = state.copyWith(
        isDownloading: false,
        currentDownloadingLessonId: null,
        downloadProgress: {...state.downloadProgress}..remove(lessonId),
      );
      rethrow;
    }
  }
  
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _db.deleteLesson(lessonId);
      final updated = {...state.downloadedLessonIds}..remove(lessonId);
      state = state.copyWith(downloadedLessonIds: updated);
    } catch (e) {
      logger.error('Failed to delete lesson $lessonId', error: e);
      rethrow;
    }
  }
  
  Future<void> downloadAllLessonsForLanguage(String language) async {
    if (state.isDownloading) {
      return; // Already downloading
    }
    
    state = state.copyWith(isDownloading: true);
    
    try {
      await _downloadService.downloadLessonPack(language);
      await _loadDownloadedLessons();
      state = state.copyWith(isDownloading: false);
    } catch (e) {
      logger.error('Failed to download all lessons for $language', error: e);
      state = state.copyWith(isDownloading: false);
      rethrow;
    }
  }
  
  int getDownloadedCount() => state.downloadedLessonIds.length;

  /// Downloads the next [count] undownloaded lessons for [languageId].
  /// Uses ConnectivityService to run only when online (caller should check WiFi/connectivity).
  /// Default [count] is 3. Gets lesson order from offline content manifest.
  Future<void> autoDownloadNextLessons(String languageId, [int count = 3]) async {
    if (state.isDownloading) return;
    final hasConnection = await ConnectivityService.hasInternet();
    if (!hasConnection) {
      logger.info('Skipping auto-download: no connectivity', tag: 'offline');
      return;
    }
    try {
      await ApiService.initialize();
      final response = await ApiService.get(ApiContract.contentPacks.manifest(languageId));
      if (response.statusCode != 200 || response.data == null) return;
      final root = response.data as Map<String, dynamic>;
      final manifest = (root['manifest'] as Map?)?.cast<String, dynamic>() ?? {};
      final lessons = manifest['lessons'] as List<dynamic>? ?? [];
      final orderedIds = <String>[];
      for (final l in lessons) {
        if (l is Map) {
          final id = l['id']?.toString();
          if (id != null && id.isNotEmpty) orderedIds.add(id);
        }
      }
      final toDownload = orderedIds
          .where((id) => !state.downloadedLessonIds.contains(id))
          .take(count)
          .toList();
      for (final lessonId in toDownload) {
        if (!(await ConnectivityService.hasInternet())) break;
        await _downloadService.downloadSingleLesson(lessonId);
        await _loadDownloadedLessons();
      }
    } catch (e) {
      logger.error('Auto-download next lessons failed', error: e, context: {'languageId': languageId});
    }
  }
  
  Future<int> getStorageSizeBytes() async {
    try {
      final dbSize = await _db.getDatabaseSizeBytes();
      final downloadSize = await _downloadService.getStorageUsed();
      return dbSize + downloadSize;
    } catch (e) {
      logger.error('Failed to get storage size', error: e);
      return 0;
    }
  }
}
