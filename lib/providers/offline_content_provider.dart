import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/services/offline/lesson_download_service.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/providers/dio_provider.dart' show client;
import 'package:lingafriq/config/api_contract.dart';
import 'package:dio/dio.dart';

/// Provider for managing offline content downloads
class OfflineContentNotifier extends Notifier<OfflineContentState> {
  static const _prefsDownloadedLanguages = 'downloaded_languages_v2';

  @override
  OfflineContentState build() {
    _loadDownloadedContent();
    return OfflineContentState(
      downloadedLanguages: [],
      downloadedGames: [],
      totalSize: 0,
      isDownloading: false,
      downloadProgress: 0.0,
    );
  }

  Future<void> _loadDownloadedContent() async {
    final prefs = await SharedPreferences.getInstance();
    final languages = prefs.getStringList(_prefsDownloadedLanguages) ?? [];
    final games = prefs.getStringList('downloaded_games') ?? [];
    int totalSize = prefs.getInt('offline_content_size') ?? 0;
    try {
      totalSize = await LessonDownloadService().getStorageUsed();
      await prefs.setInt('offline_content_size', totalSize);
    } catch (_) {}

    state = state.copyWith(
      downloadedLanguages: languages,
      downloadedGames: games,
      totalSize: totalSize,
    );
  }

  /// Download a language pack using v2 content packs.
  /// [language] may be an ISO code (e.g. "yo") or a canonical language key (e.g. "yoruba").
  Future<void> downloadLanguage(String language) async {
    final key = SupportedLanguages.getKeyFromCode(language) ?? language.toLowerCase();
    if (state.downloadedLanguages.contains(key)) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      final downloadService = LessonDownloadService();
      await downloadService.init();

      final progress = downloadService.getDownloadProgress(key);
      void onProgress() {
        final p = progress?.value;
        if (p == null) return;
        state = state.copyWith(
          isDownloading: true,
          downloadProgress: p.progressPercentage,
        );
      }

      progress?.addListener(onProgress);
      try {
        await downloadService.downloadLessonPack(key);
      } finally {
        progress?.removeListener(onProgress);
      }

      // Save downloaded language
      final prefs = await SharedPreferences.getInstance();
      final languages = List<String>.from(state.downloadedLanguages)..add(key);
      await prefs.setStringList(_prefsDownloadedLanguages, languages);
      final newSize = await downloadService.getStorageUsed();
      await prefs.setInt('offline_content_size', newSize);

      state = state.copyWith(
        downloadedLanguages: languages,
        totalSize: newSize,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      logger.error('Error downloading language', tag: 'offline-content', error: e, context: {'language': language});
      state = state.copyWith(isDownloading: false);
      // Don't rethrow - allow user to retry
      throw Exception('Failed to download language pack. Please check your connection and try again.');
    }
  }

  Future<void> downloadGame(String gameId) async {
    if (state.downloadedGames.contains(gameId)) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final gameDir = Directory('${appDir.path}/offline/games/$gameId');
      await gameDir.create(recursive: true);

      // Get game download manifest from backend
      final dioClient = ref.read(client);
      final manifestResponse = await dioClient.get<Map<String, dynamic>>(
        ApiContract.url(ApiContract.offline.gameManifest(gameId)),
      );

      if (manifestResponse.statusCode != 200) {
        throw Exception('Failed to get game download manifest');
      }

      final manifest = manifestResponse.data as Map<String, dynamic>;
      final files = List<Map<String, dynamic>>.from(manifest['files'] ?? []);
      final totalSize = (manifest['totalSize'] as num?)?.toInt() ?? 5 * 1024 * 1024; // Default 5MB

      int downloadedBytes = 0;

      // Download each file
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final url = file['url'] as String;
        final path = file['path'] as String;
        final size = (file['size'] as num?)?.toInt() ?? 0;

        // Create subdirectories if needed
        final filePath = '${gameDir.path}/$path';
        final fileDir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
        if (!fileDir.existsSync()) {
          await fileDir.create(recursive: true);
        }

        // Download file using Dio client
        final fileResponse = await dioClient.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (fileResponse.statusCode != 200) {
          logger.warn('Failed to download game file', tag: 'offline-content', context: {'url': url});
          continue; // Skip failed files but continue with others
        }

        // Save file
        final fileFile = File(filePath);
        await fileFile.writeAsBytes(fileResponse.data as List<int>);

        downloadedBytes += size;
        final progress = totalSize > 0 ? downloadedBytes / totalSize : (i + 1) / files.length;
        state = state.copyWith(downloadProgress: progress.clamp(0.0, 1.0));
      }

      final prefs = await SharedPreferences.getInstance();
      final games = List<String>.from(state.downloadedGames)..add(gameId);
      await prefs.setStringList('downloaded_games', games);

      // Update size
      final newSize = state.totalSize + totalSize;
      await prefs.setInt('offline_content_size', newSize);

      state = state.copyWith(
        downloadedGames: games,
        totalSize: newSize,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      logger.error('Error downloading game', tag: 'offline-content', error: e, context: {'gameId': gameId});
      state = state.copyWith(isDownloading: false);
      // Don't rethrow - allow user to retry
      throw Exception('Failed to download game. Please check your connection and try again.');
    }
  }

  Future<void> deleteLanguage(String language) async {
    final key = SupportedLanguages.getKeyFromCode(language) ?? language.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final languages = List<String>.from(state.downloadedLanguages)..remove(key);
    await prefs.setStringList(_prefsDownloadedLanguages, languages);

    // Delete lessons from local DB
    final db = LocalDatabaseService();
    final lessons = db.getAllLessons().where((l) => (l.language).toLowerCase() == key).toList();
    for (final l in lessons) {
      await db.deleteLesson(l.id);
    }

    // Delete downloaded media for that language (offline_audio/<languageKey>/...)
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/offline_audio/$key');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }

    // Update size (recompute)
    int newSize = 0;
    try {
      newSize = await LessonDownloadService().getStorageUsed();
    } catch (_) {
      newSize = 0;
    }
    await prefs.setInt('offline_content_size', newSize);

    state = state.copyWith(
      downloadedLanguages: languages,
      totalSize: newSize,
    );
  }

  bool isLanguageDownloaded(String language) {
    final key = SupportedLanguages.getKeyFromCode(language) ?? language.toLowerCase();
    return state.downloadedLanguages.contains(key);
  }

  bool isGameDownloaded(String gameId) {
    return state.downloadedGames.contains(gameId);
  }

  String getFormattedSize() {
    if (state.totalSize < 1024 * 1024) {
      return '${(state.totalSize / 1024).toStringAsFixed(1)} KB';
    } else if (state.totalSize < 1024 * 1024 * 1024) {
      return '${(state.totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(state.totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

final offlineContentProvider = NotifierProvider<OfflineContentNotifier, OfflineContentState>(() {
  return OfflineContentNotifier();
});

class OfflineContentState {
  final List<String> downloadedLanguages;
  final List<String> downloadedGames;
  final int totalSize; // in bytes
  final bool isDownloading;
  final double downloadProgress;

  OfflineContentState({
    required this.downloadedLanguages,
    required this.downloadedGames,
    required this.totalSize,
    required this.isDownloading,
    required this.downloadProgress,
  });

  OfflineContentState copyWith({
    List<String>? downloadedLanguages,
    List<String>? downloadedGames,
    int? totalSize,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    return OfflineContentState(
      downloadedLanguages: downloadedLanguages ?? this.downloadedLanguages,
      downloadedGames: downloadedGames ?? this.downloadedGames,
      totalSize: totalSize ?? this.totalSize,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

