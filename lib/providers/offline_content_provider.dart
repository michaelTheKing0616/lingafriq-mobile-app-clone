import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(downloadProgress: i / 100);
      }

      // Download language pack (audio, images, text)
      final appDir = await getApplicationDocumentsDirectory();
      final languageDir = Directory('${appDir.path}/offline/$language');
      await languageDir.create(recursive: true);

      // Save downloaded language
      final prefs = await SharedPreferences.getInstance();
      final languages = List<String>.from(state.downloadedLanguages)..add(language);
      await prefs.setStringList('downloaded_languages', languages);

      // Update size (estimate: ~50MB per language)
      final newSize = state.totalSize + 50 * 1024 * 1024;
      await prefs.setInt('offline_content_size', newSize);

      state = state.copyWith(
        downloadedLanguages: languages,
        totalSize: newSize,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(isDownloading: false);
      rethrow;
    }
  }

  Future<void> downloadGame(String gameId) async {
    if (state.downloadedGames.contains(gameId)) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      // Simulate download
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(downloadProgress: i / 100);
      }

      final prefs = await SharedPreferences.getInstance();
      final games = List<String>.from(state.downloadedGames)..add(gameId);
      await prefs.setStringList('downloaded_games', games);

      // Update size (estimate: ~5MB per game)
      final newSize = state.totalSize + 5 * 1024 * 1024;
      await prefs.setInt('offline_content_size', newSize);

      state = state.copyWith(
        downloadedGames: games,
        totalSize: newSize,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(isDownloading: false);
      rethrow;
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

