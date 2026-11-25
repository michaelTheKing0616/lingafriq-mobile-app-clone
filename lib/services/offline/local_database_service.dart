import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../db/app_database.dart';
import '../../db/schema_version_policy.dart';
import '../../models/offline/local_lesson.dart';
import '../../models/offline/local_vocabulary.dart';
import '../../models/offline/local_progress.dart';
import '../../models/offline/local_media_cache.dart';
import '../../models/offline/hive_adapters.dart';
import '../local_schema_migrator.dart';

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
  LingAfriqDatabase? _drift;
  Box<String>? _pointAndSayBox;
  final Map<String, LocalLesson> _lessons = {};
  final Map<String, LocalVocabulary> _vocabulary = {};
  final Map<String, LocalProgress> _progress = {};
  final Map<String, LocalMediaCache> _media = {};
  final Map<String, Map<String, dynamic>> _pointAndSay = {};

  bool _isInitialized = false;
  final int _schemaVersion = 2;

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
      await _openDrift();

      _isInitialized = true;
    } on SchemaMigrationFailure {
      rethrow;
    } on DriftMigrationFailure catch (error) {
      throw SchemaMigrationFailure(
        code: 'schema_migration_failed',
        fromVersion: error.fromVersion,
        toVersion: error.toVersion,
        cause: error.cause,
      );
    } catch (e) {
      throw Exception('Failed to initialize LocalDatabaseService: $e');
    }
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// The open Drift database. Call [init] first.
  LingAfriqDatabase get database {
    _ensureInitialized();
    return _drift!;
  }

  /// Get current schema version
  int get schemaVersion => _schemaVersion;

  Future<void> _openDrift() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'lingafriq.sqlite'));
    final db = LingAfriqDatabase(NativeDatabase(file));
    if (db.clearsSessionOnUpgrade) {
      throw StateError('a version change must not clear the session');
    }
    try {
      await db.customSelect('SELECT 1').get();
    } on SchemaNewerThanAppException catch (error) {
      await db.close();
      throw SchemaMigrationFailure(
        code: 'schema_newer_than_app',
        fromVersion: error.storedVersion,
        toVersion: error.appVersion,
        cause: error,
      );
    } on DriftMigrationFailure catch (error) {
      await db.close();
      throw SchemaMigrationFailure(
        code: 'schema_migration_failed',
        fromVersion: error.fromVersion,
        toVersion: error.toVersion,
        cause: error.cause,
      );
    }
    _drift = db;
    await _loadOrImportLessons(db);
    await _loadOrImportVocabulary(db);
    await _loadOrImportProgress(db);
    await _loadOrImportMedia(db);
    await _loadOrImportPointAndSay(db);
  }

  Future<void> _loadOrImportLessons(LingAfriqDatabase db) async {
    final stored = await readPayloads(db, 'lessons');
    if (stored.isEmpty) {
      for (final item in _lessonsBox?.values ?? const <LocalLesson>[]) {
        await storeLessonPayload(db, item.toJson());
        _lessons[item.id] = item;
      }
      return;
    }
    _lessons
      ..clear()
      ..addEntries(stored.map((row) => MapEntry(
            '${row['id']}',
            LocalLesson.fromJson(Map<String, dynamic>.from(row)),
          )));
  }

  Future<void> _loadOrImportVocabulary(LingAfriqDatabase db) async {
    final stored = await readPayloads(db, 'vocabulary');
    if (stored.isEmpty) {
      for (final item in _vocabularyBox?.values ?? const <LocalVocabulary>[]) {
        await storeVocabularyPayload(db, item.toJson());
        _vocabulary[item.id] = item;
      }
      return;
    }
    _vocabulary
      ..clear()
      ..addEntries(stored.map((row) => MapEntry(
            '${row['id']}',
            LocalVocabulary.fromJson(Map<String, dynamic>.from(row)),
          )));
  }

  Future<void> _loadOrImportProgress(LingAfriqDatabase db) async {
    final stored = await readPayloads(db, 'progress');
    if (stored.isEmpty) {
      for (final item in _progressBox?.values ?? const <LocalProgress>[]) {
        await storeProgressPayload(db, item.toJson());
        _progress[item.id] = item;
      }
      return;
    }
    _progress
      ..clear()
      ..addEntries(stored.map((row) => MapEntry(
            '${row['id']}',
            LocalProgress.fromJson(Map<String, dynamic>.from(row)),
          )));
  }

  Future<void> _loadOrImportMedia(LingAfriqDatabase db) async {
    final stored = await readPayloads(db, 'media_cache');
    if (stored.isEmpty) {
      for (final item in _mediaCacheBox?.values ?? const <LocalMediaCache>[]) {
        await storeMediaPayload(db, item.toJson());
        _media[item.url] = item;
      }
      return;
    }
    _media
      ..clear()
      ..addEntries(stored.map((row) => MapEntry(
            '${row['url']}',
            LocalMediaCache.fromJson(Map<String, dynamic>.from(row)),
          )));
  }

  Future<void> _loadOrImportPointAndSay(LingAfriqDatabase db) async {
    const boxName = 'lingafriq_point_and_say_queue_v1';
    _pointAndSayBox = Hive.isBoxOpen(boxName)
        ? Hive.box<String>(boxName)
        : await Hive.openBox<String>(boxName);
    final stored = await readPayloads(db, 'point_and_say');
    if (stored.isEmpty) {
      for (final key in _pointAndSayBox!.keys) {
        final raw = _pointAndSayBox!.get(key);
        if (raw == null) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final row = Map<String, dynamic>.from(decoded);
        await storePointAndSayPayload(db, row);
        _pointAndSay['${row['id']}'] = row;
      }
      return;
    }
    _pointAndSay
      ..clear()
      ..addEntries(stored.map((row) => MapEntry(
            '${row['id']}',
            Map<String, dynamic>.from(row),
          )));
  }

  Future<void> _migrateSchemaIfNeeded() async {
    final metadata = _metadataBox;
    if (metadata == null) return;
    final stored = metadata.get('schemaVersion') as int? ?? 0;
    if (stored > _schemaVersion) {
      throw SchemaMigrationFailure(
        code: 'schema_newer_than_app',
        fromVersion: stored,
        toVersion: _schemaVersion,
        cause: StateError(
          'local Hive metadata was written by a newer app ($stored > $_schemaVersion)',
        ),
      );
    }
    final store = _HiveSchemaStore(metadata, _vocabularyBox);
    await LocalSchemaMigrator(
      targetVersion: _schemaVersion,
      steps: {
        1: (_) async {},
        2: (store) => (store as _HiveSchemaStore).rewriteVocabularyPointers(),
      },
    ).migrate(store);
  }

  // ============================================================================
  // LESSON OPERATIONS
  // ============================================================================

  /// Save a lesson
  Future<void> saveLesson(LocalLesson lesson) async {
    _ensureInitialized();
    await _writeLesson(lesson);
  }

  /// Get a lesson by ID
  LocalLesson? getLesson(String id) {
    _ensureInitialized();
    return _lessons[id];
  }

  /// Get all lessons
  List<LocalLesson> getAllLessons() {
    _ensureInitialized();
    return _lessons.values.toList();
  }

  /// Get lessons by language
  List<LocalLesson> getLessonsByLanguage(String language) {
    _ensureInitialized();
    return _lessons.values
        .where((lesson) => lesson.language == language)
        .toList();
  }

  /// Get lessons by level
  List<LocalLesson> getLessonsByLevel(String level) {
    _ensureInitialized();
    return _lessons.values
        .where((lesson) => lesson.level == level)
        .toList();
  }

  /// Get lessons by module
  List<LocalLesson> getLessonsByModule(String moduleId) {
    _ensureInitialized();
    return _lessons.values
        .where((lesson) => lesson.moduleId == moduleId)
        .toList();
  }

  /// Update a lesson
  Future<void> updateLesson(LocalLesson lesson) async {
    _ensureInitialized();
    await _writeLesson(lesson);
  }

  /// Delete a lesson
  Future<void> deleteLesson(String id) async {
    _ensureInitialized();
    _lessons.remove(id);
    await deleteLocalRow(_drift!, 'lessons', 'id', id);
    await _lessonsBox?.delete(id);
  }

  /// Check if lesson exists
  bool lessonExists(String id) {
    _ensureInitialized();
    return _lessons.containsKey(id);
  }

  /// Batch save lessons
  Future<void> saveLessonsBatch(List<LocalLesson> lessons) async {
    _ensureInitialized();
    await _drift!.transaction(() async {
      for (final lesson in lessons) {
        await _writeLesson(lesson);
      }
    });
  }

  /// Batch delete lessons
  Future<void> deleteLessonsBatch(List<String> ids) async {
    _ensureInitialized();
    for (final id in ids) {
      await deleteLesson(id);
    }
  }

  Future<void> _writeLesson(LocalLesson lesson) async {
    await storeLessonPayload(_drift!, lesson.toJson());
    _lessons[lesson.id] = lesson;
    await _lessonsBox?.put(lesson.id, lesson);
  }

  // ============================================================================
  // VOCABULARY OPERATIONS
  // ============================================================================

  /// Save a vocabulary item
  Future<void> saveVocabulary(LocalVocabulary vocabulary) async {
    _ensureInitialized();
    await _writeVocabulary(vocabulary);
  }

  /// Get a vocabulary item by ID
  LocalVocabulary? getVocabulary(String id) {
    _ensureInitialized();
    return _vocabulary[id];
  }

  /// Get all vocabulary items
  List<LocalVocabulary> getAllVocabulary() {
    _ensureInitialized();
    return _vocabulary.values.toList();
  }

  /// Get vocabulary by language
  List<LocalVocabulary> getVocabularyByLanguage(String language) {
    _ensureInitialized();
    return _vocabulary.values
        .where((vocab) => vocab.language == language)
        .toList();
  }

  /// Get vocabulary due for review (SM-2 algorithm)
  List<LocalVocabulary> getVocabularyDueForReview() {
    _ensureInitialized();
    final now = DateTime.now();
    return _vocabulary.values
        .where((vocab) =>
            vocab.nextReviewDate != null &&
            vocab.nextReviewDate!.isBefore(now))
        .toList();
  }

  /// Get vocabulary by category
  List<LocalVocabulary> getVocabularyByCategory(String category) {
    _ensureInitialized();
    return _vocabulary.values
        .where((vocab) => vocab.category == category)
        .toList();
  }

  /// Get mastered vocabulary
  List<LocalVocabulary> getMasteredVocabulary() {
    _ensureInitialized();
    return _vocabulary.values
        .where((vocab) => vocab.isMastered)
        .toList();
  }

  /// Update vocabulary
  Future<void> updateVocabulary(LocalVocabulary vocabulary) async {
    _ensureInitialized();
    await _writeVocabulary(vocabulary);
  }

  /// Delete vocabulary
  Future<void> deleteVocabulary(String id) async {
    _ensureInitialized();
    _vocabulary.remove(id);
    await deleteLocalRow(_drift!, 'vocabulary', 'id', id);
    await _vocabularyBox?.delete(id);
  }

  /// Check if vocabulary exists
  bool vocabularyExists(String id) {
    _ensureInitialized();
    return _vocabulary.containsKey(id);
  }

  /// Batch save vocabulary
  Future<void> saveVocabularyBatch(List<LocalVocabulary> vocabulary) async {
    _ensureInitialized();
    await _drift!.transaction(() async {
      for (final item in vocabulary) {
        await _writeVocabulary(item);
      }
    });
  }

  /// Batch delete vocabulary
  Future<void> deleteVocabularyBatch(List<String> ids) async {
    _ensureInitialized();
    for (final id in ids) {
      await deleteVocabulary(id);
    }
  }

  Future<void> _writeVocabulary(LocalVocabulary vocabulary) async {
    await storeVocabularyPayload(_drift!, vocabulary.toJson());
    _vocabulary[vocabulary.id] = vocabulary;
    await _vocabularyBox?.put(vocabulary.id, vocabulary);
  }

  // ============================================================================
  // PROGRESS OPERATIONS
  // ============================================================================

  /// Save progress
  Future<void> saveProgress(LocalProgress progress) async {
    _ensureInitialized();
    await _writeProgress(progress);
  }

  /// Get progress by ID
  LocalProgress? getProgress(String id) {
    _ensureInitialized();
    return _progress[id];
  }

  /// Get all progress
  List<LocalProgress> getAllProgress() {
    _ensureInitialized();
    return _progress.values.toList();
  }

  /// Get progress by type
  List<LocalProgress> getProgressByType(String type) {
    _ensureInitialized();
    return _progress.values
        .where((progress) => progress.type == type)
        .toList();
  }

  /// Get progress by language
  List<LocalProgress> getProgressByLanguage(String language) {
    _ensureInitialized();
    return _progress.values
        .where((progress) => progress.language == language)
        .toList();
  }

  /// Get unsynced progress
  List<LocalProgress> getUnsyncedProgress() {
    _ensureInitialized();
    return _progress.values
        .where((progress) => !progress.isSynced)
        .toList();
  }

  /// Mark progress as synced
  Future<void> markProgressAsSynced(String id) async {
    _ensureInitialized();
    final progress = _progress[id];
    if (progress != null) {
      await _writeProgress(
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
    await _writeProgress(progress);
  }

  /// Delete progress
  Future<void> deleteProgress(String id) async {
    _ensureInitialized();
    _progress.remove(id);
    await deleteLocalRow(_drift!, 'progress', 'id', id);
    await _progressBox?.delete(id);
  }

  /// Check if progress exists
  bool progressExists(String id) {
    _ensureInitialized();
    return _progress.containsKey(id);
  }

  /// Batch save progress
  Future<void> saveProgressBatch(List<LocalProgress> progress) async {
    _ensureInitialized();
    await _drift!.transaction(() async {
      for (final item in progress) {
        await _writeProgress(item);
      }
    });
  }

  /// Batch delete progress
  Future<void> deleteProgressBatch(List<String> ids) async {
    _ensureInitialized();
    for (final id in ids) {
      await deleteProgress(id);
    }
  }

  Future<void> _writeProgress(LocalProgress progress) async {
    await storeProgressPayload(_drift!, progress.toJson());
    _progress[progress.id] = progress;
    await _progressBox?.put(progress.id, progress);
  }

  // ============================================================================
  // MEDIA CACHE OPERATIONS
  // ============================================================================

  /// Save media cache entry
  Future<void> saveMediaCache(LocalMediaCache cache) async {
    _ensureInitialized();
    await _writeMedia(cache);
  }

  /// Get media cache by URL
  LocalMediaCache? getMediaCache(String url) {
    _ensureInitialized();
    return _media[url];
  }

  /// Get all media cache entries
  List<LocalMediaCache> getAllMediaCache() {
    _ensureInitialized();
    return _media.values.toList();
  }

  /// Get expired media cache entries
  List<LocalMediaCache> getExpiredMediaCache() {
    _ensureInitialized();
    final now = DateTime.now();
    return _media.values
        .where((cache) =>
            cache.expiresAt != null && cache.expiresAt!.isBefore(now))
        .toList();
  }

  /// Get media cache by language
  List<LocalMediaCache> getMediaCacheByLanguage(String language) {
    _ensureInitialized();
    return _media.values
        .where((cache) => cache.language == language)
        .toList();
  }

  /// Get media cache by lesson
  List<LocalMediaCache> getMediaCacheByLesson(String lessonId) {
    _ensureInitialized();
    return _media.values
        .where((cache) => cache.lessonId == lessonId)
        .toList();
  }

  /// Update media cache access time
  Future<void> updateMediaCacheAccess(String url) async {
    _ensureInitialized();
    final cache = _media[url];
    if (cache != null) {
      await _writeMedia(
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
    _media.remove(url);
    await deleteLocalRow(_drift!, 'media_cache', 'url', url);
    await _mediaCacheBox?.delete(url);
  }

  /// Check if media cache exists
  bool mediaCacheExists(String url) {
    _ensureInitialized();
    return _media.containsKey(url);
  }

  /// Batch save media cache
  Future<void> saveMediaCacheBatch(List<LocalMediaCache> cache) async {
    _ensureInitialized();
    await _drift!.transaction(() async {
      for (final item in cache) {
        await _writeMedia(item);
      }
    });
  }

  /// Batch delete media cache
  Future<void> deleteMediaCacheBatch(List<String> urls) async {
    _ensureInitialized();
    for (final url in urls) {
      await deleteMediaCache(url);
    }
  }

  Future<void> _writeMedia(LocalMediaCache cache) async {
    await storeMediaPayload(_drift!, cache.toJson());
    _media[cache.url] = cache;
    await _mediaCacheBox?.put(cache.url, cache);
  }

  int get pointAndSayCount {
    if (!_isInitialized) return 0;
    return _pointAndSay.length;
  }

  List<Map<String, dynamic>> pointAndSayRecords() {
    _ensureInitialized();
    final rows = _pointAndSay.values
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    rows.sort((a, b) =>
        (a['createdAt']?.toString() ?? '').compareTo(b['createdAt']?.toString() ?? ''));
    return rows;
  }

  Future<void> savePointAndSay(Map<String, dynamic> row) async {
    _ensureInitialized();
    final id = '${row['id']}';
    await storePointAndSayPayload(_drift!, row);
    _pointAndSay[id] = Map<String, dynamic>.from(row);
    await _pointAndSayBox?.put(id, jsonEncode(row));
  }

  Future<void> deletePointAndSay(String id) async {
    _ensureInitialized();
    _pointAndSay.remove(id);
    await deleteLocalRow(_drift!, 'point_and_say', 'id', id);
    await _pointAndSayBox?.delete(id);
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Clear all data from all boxes
  Future<void> clearAll() async {
    _ensureInitialized();
    final db = _drift!;
    await db.customStatement('DELETE FROM lessons');
    await db.customStatement('DELETE FROM vocabulary');
    await db.customStatement('DELETE FROM progress');
    await db.customStatement('DELETE FROM media_cache');
    await db.customStatement('DELETE FROM point_and_say');
    await db.customStatement('DELETE FROM outbox');
    _lessons.clear();
    _vocabulary.clear();
    _progress.clear();
    _media.clear();
    _pointAndSay.clear();
    await _lessonsBox?.clear();
    await _vocabularyBox?.clear();
    await _progressBox?.clear();
    await _mediaCacheBox?.clear();
    await _pointAndSayBox?.clear();
    await _metadataBox?.clear();
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
      'lessons': _lessons.length,
      'vocabulary': _vocabulary.length,
      'progress': _progress.length,
      'mediaCache': _media.length,
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
    await _pointAndSayBox?.close();
    await _metadataBox?.close();
    await _drift?.close();
    _drift = null;
    _lessons.clear();
    _vocabulary.clear();
    _progress.clear();
    _media.clear();
    _pointAndSay.clear();

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

class _HiveSchemaStore implements SchemaStore {
  _HiveSchemaStore(this._metadata, this._vocabulary);

  final Box _metadata;
  final Box<LocalVocabulary>? _vocabulary;
  Map<dynamic, LocalVocabulary> _backup = {};

  @override
  int get schemaVersion => _metadata.get('schemaVersion') as int? ?? 0;

  @override
  Future<void> setSchemaVersion(int version) async {
    await _metadata.put('schemaVersion', version);
  }

  @override
  Map<String, Object?> snapshot() {
    final box = _vocabulary;
    _backup = {
      for (final key in box?.keys ?? const <dynamic>[])
        if (box!.get(key) != null) key: box.get(key)!,
    };
    return {'schemaVersion': schemaVersion};
  }

  @override
  Future<void> restore(Map<String, Object?> snapshot) async {
    final box = _vocabulary;
    if (box != null && box.isOpen) {
      await box.clear();
      for (final entry in _backup.entries) {
        await box.put(entry.key, entry.value);
      }
    }
    await setSchemaVersion(snapshot['schemaVersion'] as int? ?? 0);
  }

  Future<void> rewriteVocabularyPointers() async {
    final box = _vocabulary;
    if (box == null || !box.isOpen) return;
    for (final key in box.keys.toList()) {
      final value = box.get(key);
      if (value == null) continue;
      await box.put(
        key,
        value.copyWith(
          sourceMediaId: value.sourceMediaId,
          sourceStartMs: value.sourceStartMs,
          sourceEndMs: value.sourceEndMs,
        ),
      );
    }
  }
}
