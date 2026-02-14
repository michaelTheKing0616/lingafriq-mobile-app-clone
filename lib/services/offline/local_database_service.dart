import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/offline/local_lesson.dart';
import '../../models/offline/local_vocabulary.dart';
import '../../models/offline/local_progress.dart';
import '../../models/offline/local_media_cache.dart';
import '../../models/offline/hive_adapters.dart';

/// LocalDatabaseService - Manages local Hive database for offline mode
/// Provides CRUD operations, batch operations, and database utilities
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String _lessonsBoxName = 'lessons';
  static const String _vocabularyBoxName = 'vocabulary';
  static const String _progressBoxName = 'progress';
  static const String _mediaCacheBoxName = 'media_cache';
  static const String _metadataBoxName = 'metadata';

  Box<LocalLesson>? _lessonsBox;
  Box<LocalVocabulary>? _vocabularyBox;
  Box<LocalProgress>? _progressBox;
  Box<LocalMediaCache>? _mediaCacheBox;
  Box? _metadataBox;

  bool _isInitialized = false;
  final int _schemaVersion = 1;

  /// Initialize Hive database
  /// Call this from main.dart before runApp()
  /// Example: await LocalDatabaseService().init();
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Initialize Hive with Flutter path
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(localLessonTypeId)) {
        Hive.registerAdapter(LocalLessonAdapter());
      }
      if (!Hive.isAdapterRegistered(localVocabularyTypeId)) {
        Hive.registerAdapter(LocalVocabularyAdapter());
      }
      if (!Hive.isAdapterRegistered(localProgressTypeId)) {
        Hive.registerAdapter(LocalProgressAdapter());
      }
      if (!Hive.isAdapterRegistered(localMediaCacheTypeId)) {
        Hive.registerAdapter(LocalMediaCacheAdapter());
      }

      // Open boxes
      _lessonsBox = await Hive.openBox<LocalLesson>(_lessonsBoxName);
      _vocabularyBox =
          await Hive.openBox<LocalVocabulary>(_vocabularyBoxName);
      _progressBox = await Hive.openBox<LocalProgress>(_progressBoxName);
      _mediaCacheBox =
          await Hive.openBox<LocalMediaCache>(_mediaCacheBoxName);
      _metadataBox = await Hive.openBox(_metadataBoxName);

      // Check and migrate schema if needed
      await _migrateSchemaIfNeeded();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize LocalDatabaseService: $e');
    }
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Get current schema version
  int get schemaVersion => _schemaVersion;

  /// Migrate schema if needed
  Future<void> _migrateSchemaIfNeeded() async {
    final storedVersion = _metadataBox?.get('schemaVersion') as int? ?? 0;
    if (storedVersion < _schemaVersion) {
      await _performMigration(storedVersion, _schemaVersion);
      await _metadataBox?.put('schemaVersion', _schemaVersion);
    }
  }

  /// Perform migration between schema versions
  Future<void> _performMigration(int fromVersion, int toVersion) async {
    // Migration logic here
    // Example: if (fromVersion < 2) { migrateToV2(); }
    // This is a placeholder for future migrations
  }

  // ============================================================================
  // LESSON OPERATIONS
  // ============================================================================

  /// Save a lesson
  Future<void> saveLesson(LocalLesson lesson) async {
    _ensureInitialized();
    await _lessonsBox!.put(lesson.id, lesson);
  }

  /// Get a lesson by ID
  LocalLesson? getLesson(String id) {
    _ensureInitialized();
    return _lessonsBox!.get(id);
  }

  /// Get all lessons
  List<LocalLesson> getAllLessons() {
    _ensureInitialized();
    return _lessonsBox!.values.toList();
  }

  /// Get lessons by language
  List<LocalLesson> getLessonsByLanguage(String language) {
    _ensureInitialized();
    return _lessonsBox!.values
        .where((lesson) => lesson.language == language)
        .toList();
  }

  /// Get lessons by level
  List<LocalLesson> getLessonsByLevel(String level) {
    _ensureInitialized();
    return _lessonsBox!.values
        .where((lesson) => lesson.level == level)
        .toList();
  }

  /// Get lessons by module
  List<LocalLesson> getLessonsByModule(String moduleId) {
    _ensureInitialized();
    return _lessonsBox!.values
        .where((lesson) => lesson.moduleId == moduleId)
        .toList();
  }

  /// Update a lesson
  Future<void> updateLesson(LocalLesson lesson) async {
    _ensureInitialized();
    await _lessonsBox!.put(lesson.id, lesson);
  }

  /// Delete a lesson
  Future<void> deleteLesson(String id) async {
    _ensureInitialized();
    await _lessonsBox!.delete(id);
  }

  /// Check if lesson exists
  bool lessonExists(String id) {
    _ensureInitialized();
    return _lessonsBox!.containsKey(id);
  }

  /// Batch save lessons
  Future<void> saveLessonsBatch(List<LocalLesson> lessons) async {
    _ensureInitialized();
    final Map<String, LocalLesson> map = {
      for (var lesson in lessons) lesson.id: lesson
    };
    await _lessonsBox!.putAll(map);
  }

  /// Batch delete lessons
  Future<void> deleteLessonsBatch(List<String> ids) async {
    _ensureInitialized();
    await _lessonsBox!.deleteAll(ids);
  }

  // ============================================================================
  // VOCABULARY OPERATIONS
  // ============================================================================

  /// Save a vocabulary item
  Future<void> saveVocabulary(LocalVocabulary vocabulary) async {
    _ensureInitialized();
    await _vocabularyBox!.put(vocabulary.id, vocabulary);
  }

  /// Get a vocabulary item by ID
  LocalVocabulary? getVocabulary(String id) {
    _ensureInitialized();
    return _vocabularyBox!.get(id);
  }

  /// Get all vocabulary items
  List<LocalVocabulary> getAllVocabulary() {
    _ensureInitialized();
    return _vocabularyBox!.values.toList();
  }

  /// Get vocabulary by language
  List<LocalVocabulary> getVocabularyByLanguage(String language) {
    _ensureInitialized();
    return _vocabularyBox!.values
        .where((vocab) => vocab.language == language)
        .toList();
  }

  /// Get vocabulary due for review (SM-2 algorithm)
  List<LocalVocabulary> getVocabularyDueForReview() {
    _ensureInitialized();
    final now = DateTime.now();
    return _vocabularyBox!.values
        .where((vocab) =>
            vocab.nextReviewDate != null &&
            vocab.nextReviewDate!.isBefore(now))
        .toList();
  }

  /// Get vocabulary by category
  List<LocalVocabulary> getVocabularyByCategory(String category) {
    _ensureInitialized();
    return _vocabularyBox!.values
        .where((vocab) => vocab.category == category)
        .toList();
  }

  /// Get mastered vocabulary
  List<LocalVocabulary> getMasteredVocabulary() {
    _ensureInitialized();
    return _vocabularyBox!.values
        .where((vocab) => vocab.isMastered)
        .toList();
  }

  /// Update vocabulary
  Future<void> updateVocabulary(LocalVocabulary vocabulary) async {
    _ensureInitialized();
    await _vocabularyBox!.put(vocabulary.id, vocabulary);
  }

  /// Delete vocabulary
  Future<void> deleteVocabulary(String id) async {
    _ensureInitialized();
    await _vocabularyBox!.delete(id);
  }

  /// Check if vocabulary exists
  bool vocabularyExists(String id) {
    _ensureInitialized();
    return _vocabularyBox!.containsKey(id);
  }

  /// Batch save vocabulary
  Future<void> saveVocabularyBatch(List<LocalVocabulary> vocabulary) async {
    _ensureInitialized();
    final Map<String, LocalVocabulary> map = {
      for (var vocab in vocabulary) vocab.id: vocab
    };
    await _vocabularyBox!.putAll(map);
  }

  /// Batch delete vocabulary
  Future<void> deleteVocabularyBatch(List<String> ids) async {
    _ensureInitialized();
    await _vocabularyBox!.deleteAll(ids);
  }

  // ============================================================================
  // PROGRESS OPERATIONS
  // ============================================================================

  /// Save progress
  Future<void> saveProgress(LocalProgress progress) async {
    _ensureInitialized();
    await _progressBox!.put(progress.id, progress);
  }

  /// Get progress by ID
  LocalProgress? getProgress(String id) {
    _ensureInitialized();
    return _progressBox!.get(id);
  }

  /// Get all progress
  List<LocalProgress> getAllProgress() {
    _ensureInitialized();
    return _progressBox!.values.toList();
  }

  /// Get progress by type
  List<LocalProgress> getProgressByType(String type) {
    _ensureInitialized();
    return _progressBox!.values
        .where((progress) => progress.type == type)
        .toList();
  }

  /// Get progress by language
  List<LocalProgress> getProgressByLanguage(String language) {
    _ensureInitialized();
    return _progressBox!.values
        .where((progress) => progress.language == language)
        .toList();
  }

  /// Get unsynced progress
  List<LocalProgress> getUnsyncedProgress() {
    _ensureInitialized();
    return _progressBox!.values
        .where((progress) => !progress.isSynced)
        .toList();
  }

  /// Mark progress as synced
  Future<void> markProgressAsSynced(String id) async {
    _ensureInitialized();
    final progress = _progressBox!.get(id);
    if (progress != null) {
      await _progressBox!.put(
        id,
        progress.copyWith(
          isSynced: true,
          syncedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Update progress
  Future<void> updateProgress(LocalProgress progress) async {
    _ensureInitialized();
    await _progressBox!.put(progress.id, progress);
  }

  /// Delete progress
  Future<void> deleteProgress(String id) async {
    _ensureInitialized();
    await _progressBox!.delete(id);
  }

  /// Check if progress exists
  bool progressExists(String id) {
    _ensureInitialized();
    return _progressBox!.containsKey(id);
  }

  /// Batch save progress
  Future<void> saveProgressBatch(List<LocalProgress> progress) async {
    _ensureInitialized();
    final Map<String, LocalProgress> map = {
      for (var prog in progress) prog.id: prog
    };
    await _progressBox!.putAll(map);
  }

  /// Batch delete progress
  Future<void> deleteProgressBatch(List<String> ids) async {
    _ensureInitialized();
    await _progressBox!.deleteAll(ids);
  }

  // ============================================================================
  // MEDIA CACHE OPERATIONS
  // ============================================================================

  /// Save media cache entry
  Future<void> saveMediaCache(LocalMediaCache cache) async {
    _ensureInitialized();
    await _mediaCacheBox!.put(cache.url, cache);
  }

  /// Get media cache by URL
  LocalMediaCache? getMediaCache(String url) {
    _ensureInitialized();
    return _mediaCacheBox!.get(url);
  }

  /// Get all media cache entries
  List<LocalMediaCache> getAllMediaCache() {
    _ensureInitialized();
    return _mediaCacheBox!.values.toList();
  }

  /// Get expired media cache entries
  List<LocalMediaCache> getExpiredMediaCache() {
    _ensureInitialized();
    final now = DateTime.now();
    return _mediaCacheBox!.values
        .where((cache) =>
            cache.expiresAt != null && cache.expiresAt!.isBefore(now))
        .toList();
  }

  /// Get media cache by language
  List<LocalMediaCache> getMediaCacheByLanguage(String language) {
    _ensureInitialized();
    return _mediaCacheBox!.values
        .where((cache) => cache.language == language)
        .toList();
  }

  /// Get media cache by lesson
  List<LocalMediaCache> getMediaCacheByLesson(String lessonId) {
    _ensureInitialized();
    return _mediaCacheBox!.values
        .where((cache) => cache.lessonId == lessonId)
        .toList();
  }

  /// Update media cache access time
  Future<void> updateMediaCacheAccess(String url) async {
    _ensureInitialized();
    final cache = _mediaCacheBox!.get(url);
    if (cache != null) {
      await _mediaCacheBox!.put(
        url,
        cache.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: cache.accessCount + 1,
        ),
      );
    }
  }

  /// Delete media cache entry
  Future<void> deleteMediaCache(String url) async {
    _ensureInitialized();
    await _mediaCacheBox!.delete(url);
  }

  /// Check if media cache exists
  bool mediaCacheExists(String url) {
    _ensureInitialized();
    return _mediaCacheBox!.containsKey(url);
  }

  /// Batch save media cache
  Future<void> saveMediaCacheBatch(List<LocalMediaCache> cache) async {
    _ensureInitialized();
    final Map<String, LocalMediaCache> map = {
      for (var c in cache) c.url: c
    };
    await _mediaCacheBox!.putAll(map);
  }

  /// Batch delete media cache
  Future<void> deleteMediaCacheBatch(List<String> urls) async {
    _ensureInitialized();
    await _mediaCacheBox!.deleteAll(urls);
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Clear all data from all boxes
  Future<void> clearAll() async {
    _ensureInitialized();
    await _lessonsBox!.clear();
    await _vocabularyBox!.clear();
    await _progressBox!.clear();
    await _mediaCacheBox!.clear();
    await _metadataBox!.clear();
  }

  /// Get total database size in bytes
  Future<int> getDatabaseSizeBytes() async {
    _ensureInitialized();
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');

      if (!await hiveDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in hiveDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get count of items in each box
  Map<String, int> getItemCounts() {
    _ensureInitialized();
    return {
      'lessons': _lessonsBox!.length,
      'vocabulary': _vocabularyBox!.length,
      'progress': _progressBox!.length,
      'mediaCache': _mediaCacheBox!.length,
    };
  }

  /// Compact database (reduces file size)
  Future<void> compactDatabase() async {
    _ensureInitialized();
    await _lessonsBox!.compact();
    await _vocabularyBox!.compact();
    await _progressBox!.compact();
    await _mediaCacheBox!.compact();
    await _metadataBox!.compact();
  }

  /// Close all boxes (call before app termination)
  Future<void> close() async {
    if (!_isInitialized) {
      return;
    }

    await _lessonsBox?.close();
    await _vocabularyBox?.close();
    await _progressBox?.close();
    await _mediaCacheBox?.close();
    await _metadataBox?.close();

    _isInitialized = false;
  }

  /// Ensure database is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'LocalDatabaseService not initialized. Call init() first.',
      );
    }
  }
}
