import 'package:hive/hive.dart';
import 'local_lesson.dart';
import 'local_vocabulary.dart';
import 'local_progress.dart';
import 'local_media_cache.dart';

// Type IDs
const int localLessonTypeId = 0;
const int localVocabularyTypeId = 1;
const int localProgressTypeId = 2;
const int localMediaCacheTypeId = 3;

/// TypeAdapter for LocalLesson
class LocalLessonAdapter extends TypeAdapter<LocalLesson> {
  @override
  final int typeId = localLessonTypeId;

  @override
  LocalLesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalLesson(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      language: fields[3] as String,
      level: fields[4] as String,
      audioPaths: (fields[5] as List?)?.cast<String>() ?? [],
      imagePaths: (fields[6] as List?)?.cast<String>() ?? [],
      downloadedAt: fields[7] as DateTime,
      lastAccessedAt: fields[8] as DateTime?,
      sizeBytes: fields[9] as int? ?? 0,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>() ?? {},
      isComplete: fields[11] as bool? ?? false,
      orderIndex: fields[12] as int? ?? 0,
      moduleId: fields[13] as String?,
      unitId: fields[14] as String?,
      exercises: (fields[15] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  @override
  void write(BinaryWriter writer, LocalLesson obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.audioPaths)
      ..writeByte(6)
      ..write(obj.imagePaths)
      ..writeByte(7)
      ..write(obj.downloadedAt)
      ..writeByte(8)
      ..write(obj.lastAccessedAt)
      ..writeByte(9)
      ..write(obj.sizeBytes)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.isComplete)
      ..writeByte(12)
      ..write(obj.orderIndex)
      ..writeByte(13)
      ..write(obj.moduleId)
      ..writeByte(14)
      ..write(obj.unitId)
      ..writeByte(15)
      ..write(obj.exercises);
  }
}

/// TypeAdapter for LocalVocabulary
class LocalVocabularyAdapter extends TypeAdapter<LocalVocabulary> {
  @override
  final int typeId = localVocabularyTypeId;

  @override
  LocalVocabulary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalVocabulary(
      id: fields[0] as String,
      word: fields[1] as String,
      translation: fields[2] as String,
      language: fields[3] as String,
      pronunciation: fields[4] as String?,
      audioPath: fields[5] as String?,
      exampleSentence: fields[6] as String?,
      exampleTranslation: fields[7] as String?,
      sourceMediaId: fields[19] as String?,
      sourceStartMs: fields[20] as int?,
      sourceEndMs: fields[21] as int?,
      easeFactor: (fields[8] as num?)?.toDouble() ?? 2.5,
      interval: fields[9] as int? ?? 0,
      repetitions: fields[10] as int? ?? 0,
      nextReviewDate: fields[11] as DateTime?,
      lastReviewedAt: fields[12] as DateTime?,
      quality: fields[13] as int? ?? 0,
      totalReviews: fields[14] as int? ?? 0,
      correctReviews: fields[15] as int? ?? 0,
      category: fields[16] as String?,
      addedAt: fields[17] as DateTime? ?? DateTime.now(),
      isMastered: fields[18] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, LocalVocabulary obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.translation)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.pronunciation)
      ..writeByte(5)
      ..write(obj.audioPath)
      ..writeByte(6)
      ..write(obj.exampleSentence)
      ..writeByte(7)
      ..write(obj.exampleTranslation)
      ..writeByte(8)
      ..write(obj.easeFactor)
      ..writeByte(9)
      ..write(obj.interval)
      ..writeByte(10)
      ..write(obj.repetitions)
      ..writeByte(11)
      ..write(obj.nextReviewDate)
      ..writeByte(12)
      ..write(obj.lastReviewedAt)
      ..writeByte(13)
      ..write(obj.quality)
      ..writeByte(14)
      ..write(obj.totalReviews)
      ..writeByte(15)
      ..write(obj.correctReviews)
      ..writeByte(16)
      ..write(obj.category)
      ..writeByte(17)
      ..write(obj.addedAt)
      ..writeByte(18)
      ..write(obj.isMastered)
      ..writeByte(19)
      ..write(obj.sourceMediaId)
      ..writeByte(20)
      ..write(obj.sourceStartMs)
      ..writeByte(21)
      ..write(obj.sourceEndMs);
  }
}

/// TypeAdapter for LocalProgress
class LocalProgressAdapter extends TypeAdapter<LocalProgress> {
  @override
  final int typeId = localProgressTypeId;

  @override
  LocalProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalProgress(
      id: fields[0] as String,
      type: fields[1] as String,
      language: fields[2] as String,
      xpEarned: fields[3] as int? ?? 0,
      completionPercentage: (fields[4] as num?)?.toDouble() ?? 0.0,
      score: fields[5] as int? ?? 0,
      timeSpentSeconds: fields[6] as int? ?? 0,
      completedAt: fields[7] as DateTime,
      isSynced: fields[8] as bool? ?? false,
      syncedAt: fields[9] as DateTime?,
      details: (fields[10] as Map?)?.cast<String, dynamic>() ?? {},
      attempts: fields[11] as int? ?? 1,
      sessionId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalProgress obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.language)
      ..writeByte(3)
      ..write(obj.xpEarned)
      ..writeByte(4)
      ..write(obj.completionPercentage)
      ..writeByte(5)
      ..write(obj.score)
      ..writeByte(6)
      ..write(obj.timeSpentSeconds)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.syncedAt)
      ..writeByte(10)
      ..write(obj.details)
      ..writeByte(11)
      ..write(obj.attempts)
      ..writeByte(12)
      ..write(obj.sessionId);
  }
}

/// TypeAdapter for LocalMediaCache
class LocalMediaCacheAdapter extends TypeAdapter<LocalMediaCache> {
  @override
  final int typeId = localMediaCacheTypeId;

  @override
  LocalMediaCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalMediaCache(
      url: fields[0] as String,
      localPath: fields[1] as String,
      mimeType: fields[2] as String,
      sizeBytes: fields[3] as int? ?? 0,
      cachedAt: fields[4] as DateTime,
      lastAccessedAt: fields[5] as DateTime? ?? DateTime.now(),
      accessCount: fields[6] as int? ?? 0,
      expiresAt: fields[7] as DateTime?,
      checksum: fields[8] as String?,
      language: fields[9] as String?,
      lessonId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalMediaCache obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.mimeType)
      ..writeByte(3)
      ..write(obj.sizeBytes)
      ..writeByte(4)
      ..write(obj.cachedAt)
      ..writeByte(5)
      ..write(obj.lastAccessedAt)
      ..writeByte(6)
      ..write(obj.accessCount)
      ..writeByte(7)
      ..write(obj.expiresAt)
      ..writeByte(8)
      ..write(obj.checksum)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.lessonId);
  }
}
