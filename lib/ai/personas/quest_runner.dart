// P11-016 — Persona narrative quest structure loader and replay progress.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const String kYaaAsantewaaQuestAssetPath =
    'lib/ai/personas/quests/yaa_asantewaa/quest.json';

/// Parsed persona quest definition (§8.2 narrative + language + history layers).
@immutable
class PersonaQuestDefinition {
  const PersonaQuestDefinition({
    required this.questId,
    required this.personaId,
    required this.title,
    required this.languageCode,
    required this.cefrMin,
    required this.cefrMax,
    required this.runtimeMinutes,
    required this.replayable,
    required this.experienceLayers,
    required this.chapters,
    required this.vocabularyDeckId,
    this.historianReviewGate,
    this.twiSurfacePolicy,
  });

  final String questId;
  final String personaId;
  final String title;
  final String languageCode;
  final String cefrMin;
  final String cefrMax;
  final int runtimeMinutes;
  final bool replayable;
  final List<String> experienceLayers;
  final List<PersonaQuestChapter> chapters;
  final String vocabularyDeckId;
  final String? historianReviewGate;
  final String? twiSurfacePolicy;

  static PersonaQuestDefinition fromJson(Map<String, dynamic> json) {
    final chaptersJson = json['chapters'] as List<dynamic>;
    return PersonaQuestDefinition(
      questId: json['quest_id'] as String,
      personaId: json['persona_id'] as String,
      title: json['title'] as String,
      languageCode: json['language_code'] as String,
      cefrMin: json['cefr_min'] as String,
      cefrMax: json['cefr_max'] as String,
      runtimeMinutes: json['runtime_minutes'] as int,
      replayable: json['replayable'] as bool,
      experienceLayers: (json['experience_layers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      chapters: chaptersJson
          .map((c) => PersonaQuestChapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      vocabularyDeckId: json['vocabulary_deck_id'] as String,
      historianReviewGate: json['historian_review_gate'] as String?,
      twiSurfacePolicy: json['twi_surface_policy'] as String?,
    );
  }

  void validateStructure() {
    if (chapters.length != 4) {
      throw PersonaQuestStructureException(
        'expected_4_chapters',
        'Quest must have exactly 4 chapters (§8.2).',
      );
    }
    if (languageCode != 'tw') {
      throw PersonaQuestStructureException(
        'language_not_twi',
        'Yaa Asantewaa quest must be Twi (tw).',
      );
    }
    const allowedCefr = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
    if (!allowedCefr.contains(cefrMin) || !allowedCefr.contains(cefrMax)) {
      throw PersonaQuestStructureException(
        'cefr_invalid',
        'CEFR bounds must be valid levels.',
      );
    }
    if (_cefrRank(cefrMin) > _cefrRank(cefrMax)) {
      throw PersonaQuestStructureException(
        'cefr_range_inverted',
        'cefr_min must not exceed cefr_max.',
      );
    }
    if (_cefrRank(cefrMin) < _cefrRank('A2') ||
        _cefrRank(cefrMax) > _cefrRank('B1')) {
      throw PersonaQuestStructureException(
        'cefr_out_of_band',
        'Quest CEFR band must stay within A2–B1.',
      );
    }
    if (runtimeMinutes != 25) {
      throw PersonaQuestStructureException(
        'runtime_mismatch',
        'Runtime estimate must be 25 minutes.',
      );
    }
    if (!replayable) {
      throw PersonaQuestStructureException(
        'not_replayable',
        'Persona quests must be replayable.',
      );
    }
    final layerSet = experienceLayers.toSet();
    for (final layer in ['narrative', 'language', 'history']) {
      if (!layerSet.contains(layer)) {
        throw PersonaQuestStructureException(
          'missing_layer',
          'Quest must combine narrative, language, and history layers.',
        );
      }
    }
    final sumMinutes =
        chapters.fold<int>(0, (sum, c) => sum + c.estimatedMinutes);
    if (sumMinutes != runtimeMinutes) {
      throw PersonaQuestStructureException(
        'chapter_minutes_mismatch',
        'Chapter minute estimates must sum to runtime_minutes.',
      );
    }
    final ch1 = chapters.firstWhere((c) => c.index == 1);
    if (ch1.learnerRole != 'young_messenger' ||
        !ch1.objectiveEn.toLowerCase().contains('queen mother') ||
        !ch1.objectiveEn.toLowerCase().contains('honorific')) {
      throw PersonaQuestStructureException(
        'chapter1_objective',
        'Chapter 1 must be young messenger greeting Queen Mother with honorifics.',
      );
    }
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].index != i + 1) {
        throw PersonaQuestStructureException(
          'chapter_index',
          'Chapters must be indexed 1..4 in order.',
        );
      }
      if (chapters[i].twiContentStatus != 'native_review_required') {
        throw PersonaQuestStructureException(
          'twi_surface_ungated',
          'Twi surfaces stay gated until native review (no invented copy).',
        );
      }
    }
  }

  static int _cefrRank(String level) {
    const order = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return order.indexOf(level);
  }
}

@immutable
class PersonaQuestChapter {
  const PersonaQuestChapter({
    required this.index,
    required this.id,
    required this.title,
    required this.learnerRole,
    required this.objectiveEn,
    required this.beatTypes,
    required this.estimatedMinutes,
    required this.twiContentStatus,
    this.settingSummary,
    this.interactionModes = const [],
    this.languageSkillTargets = const [],
  });

  final int index;
  final String id;
  final String title;
  final String? settingSummary;
  final String learnerRole;
  final String objectiveEn;
  final List<String> beatTypes;
  final List<String> interactionModes;
  final List<String> languageSkillTargets;
  final int estimatedMinutes;
  final String twiContentStatus;

  static PersonaQuestChapter fromJson(Map<String, dynamic> json) {
    return PersonaQuestChapter(
      index: json['index'] as int,
      id: json['id'] as String,
      title: json['title'] as String,
      settingSummary: json['setting_summary'] as String?,
      learnerRole: json['learner_role'] as String,
      objectiveEn: json['objective_en'] as String,
      beatTypes: (json['beat_types'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      interactionModes: (json['interaction_modes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      languageSkillTargets:
          (json['language_skill_targets'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      estimatedMinutes: json['estimated_minutes'] as int,
      twiContentStatus: json['twi_content_status'] as String,
    );
  }
}

/// In-memory progress; chapter state resets on replay, vocabulary ids persist.
@immutable
class PersonaQuestProgress {
  const PersonaQuestProgress({
    required this.questId,
    required this.currentChapterIndex,
    required this.completedChapterIndices,
    required this.earnedVocabularyIds,
  });

  final String questId;
  final int currentChapterIndex;
  final Set<int> completedChapterIndices;
  final Set<String> earnedVocabularyIds;

  factory PersonaQuestProgress.initial(String questId) {
    return PersonaQuestProgress(
      questId: questId,
      currentChapterIndex: 1,
      completedChapterIndices: {},
      earnedVocabularyIds: {},
    );
  }

  PersonaQuestProgress completeChapter(int chapterIndex) {
    final next = Set<int>.from(completedChapterIndices)..add(chapterIndex);
    final nextChapter = chapterIndex < 4 ? chapterIndex + 1 : chapterIndex;
    return PersonaQuestProgress(
      questId: questId,
      currentChapterIndex: nextChapter,
      completedChapterIndices: next,
      earnedVocabularyIds: earnedVocabularyIds,
    );
  }

  PersonaQuestProgress recordVocabulary(Iterable<String> lexemeIds) {
    final merged = Set<String>.from(earnedVocabularyIds)..addAll(lexemeIds);
    return PersonaQuestProgress(
      questId: questId,
      currentChapterIndex: currentChapterIndex,
      completedChapterIndices: completedChapterIndices,
      earnedVocabularyIds: merged,
    );
  }

  /// Replay clears chapter progress but keeps earned vocabulary (AC3).
  PersonaQuestProgress startReplay() {
    return PersonaQuestProgress(
      questId: questId,
      currentChapterIndex: 1,
      completedChapterIndices: {},
      earnedVocabularyIds: earnedVocabularyIds,
    );
  }
}

class PersonaQuestStructureException implements Exception {
  PersonaQuestStructureException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'PersonaQuestStructureException($code): $message';
}

class PersonaQuestRunner {
  PersonaQuestRunner._();

  static PersonaQuestDefinition? _cachedYaa;

  /// Loads the Yaa Asantewaa quest from the authored JSON beside this library.
  static Future<PersonaQuestDefinition> loadYaaAsantewaaQuest() async {
    if (_cachedYaa != null) return _cachedYaa!;
    final jsonText = await _readQuestJsonFile();
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final def = PersonaQuestDefinition.fromJson(decoded);
    def.validateStructure();
    _cachedYaa = def;
    return def;
  }

  static PersonaQuestDefinition parseQuestJson(String jsonText) {
    final def =
        PersonaQuestDefinition.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
    def.validateStructure();
    return def;
  }

  static Future<String> _readQuestJsonFile() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Bundled persona quests are not registered for web in P11-016.',
      );
    }
    final file = File(kYaaAsantewaaQuestAssetPath);
    if (!file.existsSync()) {
      throw StateError(
        'Missing quest JSON at $kYaaAsantewaaQuestAssetPath (run from package root).',
      );
    }
    return file.readAsStringSync();
  }
}
