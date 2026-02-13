import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/providers/dio_provider.dart' show client;
import 'package:lingafriq/config/api_contract.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Provider for managing offline content downloads
class OfflineContentNotifier extends Notifier<OfflineContentState> {
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
    final languages = prefs.getStringList('downloaded_languages') ?? [];
    final games = prefs.getStringList('downloaded_games') ?? [];
    final totalSize = prefs.getInt('offline_content_size') ?? 0;

    state = state.copyWith(
      downloadedLanguages: languages,
      downloadedGames: games,
      totalSize: totalSize,
    );
  }

  Future<void> downloadLanguage(String language) async {
    if (state.downloadedLanguages.contains(language)) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final languageDir = Directory('${appDir.path}/offline/$language');
      await languageDir.create(recursive: true);

      // Get download manifest from backend
      final dioClient = ref.read(client);
      final manifestResponse = await dioClient.get<Map<String, dynamic>>(
        ApiContract.url(ApiContract.offline.contentManifest(language)),
      );

      if (manifestResponse.statusCode != 200) {
        throw Exception('Failed to get download manifest');
      }

      final manifest = manifestResponse.data as Map<String, dynamic>;
      final files = List<Map<String, dynamic>>.from(manifest['files'] ?? []);
      final totalSize = (manifest['totalSize'] as num?)?.toInt() ?? 0;

      int downloadedBytes = 0;

      // Download each file
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final url = file['url'] as String;
        final path = file['path'] as String;
        final size = (file['size'] as num?)?.toInt() ?? 0;

        // Create subdirectories if needed
        final filePath = '${languageDir.path}/$path';
        final fileDir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
        if (!fileDir.existsSync()) {
          await fileDir.create(recursive: true);
        }

        // Download file using Dio client for better error handling
        try {
          final fileResponse = await dioClient.get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
            ),
          );

          if (fileResponse.statusCode != 200) {
            logger.warn('Failed to download file', tag: 'offline-content', context: {'url': url, 'statusCode': fileResponse.statusCode});
            continue; // Skip failed files but continue with others
          }

          // Save file
          final fileFile = File(filePath);
          await fileFile.writeAsBytes(fileResponse.data as List<int>);
        } catch (e) {
          logger.error('Error downloading file', tag: 'offline-content', error: e, context: {'url': url});
          continue; // Skip failed files but continue with others
        }

        downloadedBytes += size;
        final progress = totalSize > 0 ? downloadedBytes / totalSize : (i + 1) / files.length;
        state = state.copyWith(downloadProgress: progress.clamp(0.0, 1.0));
      }

      // Save downloaded language
      final prefs = await SharedPreferences.getInstance();
      final languages = List<String>.from(state.downloadedLanguages)..add(language);
      await prefs.setStringList('downloaded_languages', languages);

      // Update size
      final newSize = state.totalSize + totalSize;
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
    final prefs = await SharedPreferences.getInstance();
    final languages = List<String>.from(state.downloadedLanguages)..remove(language);
    await prefs.setStringList('downloaded_languages', languages);

    // Delete files
    final appDir = await getApplicationDocumentsDirectory();
    final languageDir = Directory('${appDir.path}/offline/$language');
    if (await languageDir.exists()) {
      await languageDir.delete(recursive: true);
    }

    // Update size
    final newSize = state.totalSize - 50 * 1024 * 1024;
    await prefs.setInt('offline_content_size', newSize);

    state = state.copyWith(
      downloadedLanguages: languages,
      totalSize: newSize,
    );
  }

  bool isLanguageDownloaded(String language) {
    return state.downloadedLanguages.contains(language);
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

