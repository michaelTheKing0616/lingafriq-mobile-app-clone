import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';
import 'package:riverpod/legacy.dart';
import '../config/api_contract.dart';
import '../services/connectivity_service.dart';
import '../services/offline/lesson_download_service.dart';
import '../services/offline/local_database_service.dart';
import '../utils/api_service.dart';
import '../utils/structured_logger.dart';

const Object _keep = Object();

final offlineDownloadProvider = StateNotifierProvider<OfflineDownloadNotifier, OfflineDownloadState>((ref) {
  return OfflineDownloadNotifier();
});

class OfflineDownloadState {
  final Set<String> downloadedLessonIds;
  final Map<String, double> downloadProgress; // lessonId -> 0.0 to 1.0
  final bool isDownloading;
  final String? currentDownloadingLessonId;

  /// True after a download attempt failed. Progress for that attempt is cleared.
  final bool downloadFailed;

  /// Bytes in use. Null means the size was not read. Zero is a real empty store.
  final int? storageBytes;
  
  const OfflineDownloadState({
    this.downloadedLessonIds = const {},
    this.downloadProgress = const {},
    this.isDownloading = false,
    this.currentDownloadingLessonId,
    this.downloadFailed = false,
    this.storageBytes,
  });

  bool get storageKnown => storageBytes != null;
  
  OfflineDownloadState copyWith({
    Set<String>? downloadedLessonIds,
    Map<String, double>? downloadProgress,
    bool? isDownloading,
    String? currentDownloadingLessonId,
    bool? downloadFailed,
    Object? storageBytes = _keep,
  }) {
    return OfflineDownloadState(
      downloadedLessonIds: downloadedLessonIds ?? this.downloadedLessonIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      currentDownloadingLessonId: currentDownloadingLessonId ?? this.currentDownloadingLessonId,
      downloadFailed: downloadFailed ?? this.downloadFailed,
      storageBytes: identical(storageBytes, _keep)
          ? this.storageBytes
          : storageBytes as int?,
    );
  }
}

/// Records a failed download and drops that lesson's progress.
/// Previously saved lesson ids stay on the state. The screen hides them
/// while [OfflineDownloadState.downloadFailed] is true.
OfflineDownloadState markDownloadFailed(
  OfflineDownloadState state,
  String lessonId,
) {
  final Map<String, double> progress = Map<String, double>.from(
    state.downloadProgress,
  )..remove(lessonId);
  return OfflineDownloadState(
    downloadedLessonIds: state.downloadedLessonIds,
    downloadProgress: progress,
    isDownloading: false,
    downloadFailed: true,
    storageBytes: state.storageBytes,
  );
}

/// Formats a measured byte count. Callers pass a value the provider read.
String formatStorageUse(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
      downloadFailed: false,
      currentDownloadingLessonId: lessonId,
      downloadProgress: {...state.downloadProgress, lessonId: 0.0},
    );
    
    try {
      await _downloadService.downloadSingleLesson(lessonId);
      final updated = {...state.downloadedLessonIds, lessonId};
      state = state.copyWith(
        downloadedLessonIds: updated,
        isDownloading: false,
        downloadFailed: false,
        currentDownloadingLessonId: null,
        downloadProgress: {...state.downloadProgress}..remove(lessonId),
      );
    } catch (e) {
      logger.error('Failed to download lesson $lessonId', error: e);
      state = markDownloadFailed(state, lessonId);
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
    
    state = state.copyWith(isDownloading: true, downloadFailed: false);
    
    try {
      await _downloadService.downloadLessonPack(language);
      await _loadDownloadedLessons();
      state = state.copyWith(isDownloading: false, downloadFailed: false);
    } catch (e) {
      logger.error('Failed to download all lessons for $language', error: e);
      state = markDownloadFailed(state, language);
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
      state = markDownloadFailed(state, languageId);
    }
  }
  
  /// Sum of the database and download stores.
  /// Null when the size could not be read. Does not substitute zero.
  Future<int?> measureStorageBytes() async {
    try {
      final dbSize = await _db.getDatabaseSizeBytes();
      final downloadSize = await _downloadService.getStorageUsed();
      return dbSize + downloadSize;
    } catch (e) {
      logger.error('Failed to get storage size', error: e);
      return null;
    }
  }

  Future<int> getStorageSizeBytes() async {
    final int? bytes = await measureStorageBytes();
    return bytes ?? 0;
  }

  /// Writes a measured size onto the state. A failed read clears the previous size.
  Future<void> refreshStorageUse() async {
    final int? bytes = await measureStorageBytes();
    state = state.copyWith(storageBytes: bytes);
  }
}

/// Offline Downloads. Progress, failure, and storage come from [state].
/// A null [storageBytes] is shown as unknown. No byte count is filled in.
class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({super.key, this.state});

  /// App route `/learn/downloads`. The map key drops the leading slash.
  static const String routePath = '/learn/downloads';

  static const String routeKey = 'learn/downloads';

  static const Key emptyKey = ValueKey<String>('learn-downloads-empty');

  static const Key errorKey = ValueKey<String>('learn-downloads-error');

  static const Key progressKey = ValueKey<String>('learn-downloads-progress');

  static const Key storageKey = ValueKey<String>('learn-downloads-storage');

  /// When set, the screen paints this state and does not read the provider.
  final OfflineDownloadState? state;

  @override
  Widget build(BuildContext context) {
    if (state != null) {
      return OfflineDownloadsView(state: state!);
    }
    if (!_hasProviderScope(context)) {
      return const OfflineDownloadsView(state: OfflineDownloadState());
    }
    return const _LiveOfflineDownloads();
  }
}

bool _hasProviderScope(BuildContext context) {
  try {
    ProviderScope.containerOf(context, listen: false);
    return true;
  } catch (_) {
    return false;
  }
}

class _LiveOfflineDownloads extends ConsumerStatefulWidget {
  const _LiveOfflineDownloads();

  @override
  ConsumerState<_LiveOfflineDownloads> createState() =>
      _LiveOfflineDownloadsState();
}

class _LiveOfflineDownloadsState extends ConsumerState<_LiveOfflineDownloads> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(offlineDownloadProvider.notifier).refreshStorageUse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final OfflineDownloadState state = ref.watch(offlineDownloadProvider);
    return OfflineDownloadsView(state: state);
  }
}

class OfflineDownloadsView extends StatelessWidget {
  const OfflineDownloadsView({required this.state, super.key});

  final OfflineDownloadState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool failed = state.downloadFailed;
    final bool inProgress =
        !failed && (state.isDownloading || state.downloadProgress.isNotEmpty);
    final bool hasSaved = !failed && state.downloadedLessonIds.isNotEmpty;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.hubLearnDownloads,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _storageLine(l10n, palette),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(context, l10n, palette, failed: failed, inProgress: inProgress, hasSaved: hasSaved),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubLearnBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () {
                final NavigatorState? navigator = Navigator.maybeOf(context);
                if (navigator != null && navigator.canPop()) navigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette, {
    required bool failed,
    required bool inProgress,
    required bool hasSaved,
  }) {
    if (failed) {
      return LingErrorState(
        key: OfflineDownloadsScreen.errorKey,
        whatHappened: l10n.revRvLearnDownloadsFailWhat,
        why: l10n.revRvLearnDownloadsFailWhy,
        whatToDo: l10n.revRvLearnDownloadsFailNext,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: () {},
      );
    }
    if (inProgress) return _progress(l10n, palette);
    if (!hasSaved) {
      return LingEmptyState(
        key: OfflineDownloadsScreen.emptyKey,
        title: l10n.revRvLearnDownloadsEmptyTitle,
        whatHappened: l10n.revRvLearnDownloadsEmptyWhat,
        why: l10n.revRvLearnDownloadsEmptyWhy,
        whatToDo: l10n.revRvLearnDownloadsEmptyNext,
        actionLabel: l10n.hubLearnOpenPath,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: () {
          Navigator.of(context).pushNamed(LearnRoutes.path);
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final String id in state.downloadedLessonIds)
          Text(
            id,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: lingBody(palette.onSurface),
          ),
      ],
    );
  }

  Widget _storageLine(AppLocalizations l10n, LingPalette palette) {
    final int? bytes = state.storageBytes;
    final String label = bytes == null
        ? l10n.revRvLearnDownloadsStorageUnknown
        : l10n.revRvLearnDownloadsStorage(formatStorageUse(bytes));
    return Text(
      label,
      key: OfflineDownloadsScreen.storageKey,
      style: lingBody(palette.onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _progress(AppLocalizations l10n, LingPalette palette) {
    final List<MapEntry<String, double>> entries = state.downloadProgress
        .entries
        .toList();
    return Column(
      key: OfflineDownloadsScreen.progressKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.revRvLearnDownloadsInProgress,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        for (final MapEntry<String, double> entry in entries) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            entry.key,
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
          LinearProgressIndicator(
            value: entry.value.clamp(0.0, 1.0),
          ),
        ],
      ],
    );
  }
}
