import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/curriculum_languages.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/utils/supported_languages.dart';

/// Provider for structured learning paths
class LearningPathNotifier extends Notifier<LearningPath> {
  String? _lastHydrationKey;

  @override
  LearningPath build() {
    final onboarding = ref.watch(onboardingProvider);
    final localPath = _buildPathFromOnboarding(onboarding);
    _scheduleBackendHydration(onboarding, localPath);
    return localPath;
  }

  void _scheduleBackendHydration(OnboardingData onboarding, LearningPath localPath) {
    final language = onboarding.selectedLanguage?.trim();
    if (language == null || language.isEmpty) return;

    final pathType = _resolvePathType(onboarding.selectedPath);
    final hydrationKey = '$language|$pathType';
    if (_lastHydrationKey == hydrationKey) return;

    _lastHydrationKey = hydrationKey;
    Future.microtask(() async {
      final api = ref.read(apiProvider.notifier);
      final backendPath = await api.getLearningPath(
        language: language,
        pathType: pathType,
      );

      if (backendPath != null) {
        state = _pathFromBackend(backendPath, fallback: localPath);
        return;
      }

      final created = await api.createLearningPath(
        language: language,
        pathType: pathType,
        currentLevel: localPath.currentLevel,
        modules: _modulesToBackend(localPath.modules),
      );
      if (created != null) {
        state = _pathFromBackend(created, fallback: localPath);
      }
    });
  }

  String _resolvePathType(String? selectedPath) {
    if (selectedPath == 'career') return 'career';
    if (selectedPath == 'academic') return 'academic';
    if (selectedPath == 'dialect') return 'dialect';
    return 'explore';
  }

  LearningPath _buildPathFromOnboarding(OnboardingData data) {
    final pathType = _resolvePathType(data.selectedPath);

    // Build structured path
    final path = LearningPath(
      type: pathType,
      currentLevel: data.proficiencyLevel ?? 'beginner',
      modules: _getModulesForPath(pathType, data.proficiencyLevel ?? 'beginner'),
      currentModuleIndex: 0,
      progress: 0.0,
    );

    return path;
  }

  LearningPath _pathFromBackend(
    Map<String, dynamic> backend, {
    required LearningPath fallback,
  }) {
    final backendModules = _modulesFromBackend(backend['modules']);
    final effectiveModules = backendModules.isNotEmpty ? backendModules : fallback.modules;
    final maxModuleIndex = effectiveModules.isEmpty ? 0 : effectiveModules.length - 1;
    final currentIndex =
        _coerceInt(backend['currentModuleIndex']) ?? fallback.currentModuleIndex;
    final progress =
        _coerceDouble(backend['progress']) ?? _calculateProgress(effectiveModules);

    return LearningPath(
      type: (backend['type'] as String?) ?? fallback.type,
      currentLevel: (backend['currentLevel'] as String?) ?? fallback.currentLevel,
      modules: effectiveModules,
      currentModuleIndex: currentIndex.clamp(0, maxModuleIndex).toInt(),
      progress: progress.clamp(0.0, 1.0).toDouble(),
    );
  }

  List<LearningModule> _modulesFromBackend(dynamic payload) {
    if (payload is! List) return const [];
    final modules = <LearningModule>[];

    for (final raw in payload) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final moduleId = (map['moduleId'] ?? map['id'])?.toString();
      if (moduleId == null || moduleId.isEmpty) continue;

      modules.add(
        LearningModule(
          id: moduleId,
          title: (map['title'] as String?) ?? 'Untitled Module',
          description: (map['description'] as String?) ?? '',
          lessons: _stringList(map['lessons']),
          estimatedTime: _coerceInt(map['estimatedTime']) ?? 0,
          isCompleted: map['isCompleted'] == true,
          isLocked: map['isLocked'] == true,
        ),
      );
    }

    return modules;
  }

  List<String> _stringList(dynamic payload) {
    if (payload is! List) return const [];
    return payload.map((item) => item.toString()).toList();
  }

  int? _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _coerceDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<Map<String, dynamic>> _modulesToBackend(List<LearningModule> modules) {
    return modules
        .map(
          (module) => <String, dynamic>{
            'moduleId': module.id,
            'title': module.title,
            'description': module.description,
            'lessons': module.lessons,
            'estimatedTime': module.estimatedTime,
            'isCompleted': module.isCompleted,
            'isLocked': module.isLocked,
          },
        )
        .toList();
  }

  List<LearningModule> _getModulesForPath(String pathType, String proficiency) {
    // All paths support all languages - content is language-agnostic in structure
    // Language-specific content comes from backend
    switch (pathType) {
      case 'career':
        return _getCareerModules(proficiency);
      case 'academic':
        return _getAcademicModules(proficiency);
      case 'dialect':
        return _getDialectModules(proficiency);
      default:
        return _getExploreModules(proficiency);
    }
  }

  /// Modules when the learner prioritizes local speech patterns (pairs with dialect preference API).
  List<LearningModule> _getDialectModules(String proficiency) {
    return [
      LearningModule(
        id: 'dialect_1',
        title: 'Sound & identity',
        description: 'Tune your ear to everyday speech in your chosen locale',
        lessons: ['pronunciation_basics', 'tone_patterns', 'greetings_local'],
        estimatedTime: 35,
      ),
      LearningModule(
        id: 'dialect_2',
        title: 'Living phrases',
        description: 'Phrases you hear at home, market, and community events',
        lessons: ['market_talk', 'family_kinship', 'proverbs'],
        estimatedTime: 40,
      ),
      LearningModule(
        id: 'dialect_3',
        title: 'Heritage & story',
        description: 'Connect language to songs, stories, and cultural memory',
        lessons: ['storytelling', 'songs', 'heritage_prompts'],
        estimatedTime: 45,
      ),
    ];
  }
  
  // Ensure all supported languages have learning paths
  bool isLanguageSupported(String language) {
    final languageKey = language.toLowerCase();
    // Check if it's a language key (e.g., 'yoruba', 'hausa')
    if (SupportedLanguages.allLanguages.contains(languageKey)) {
      return true;
    }
    // Check if it's a language code (e.g., 'yo', 'ha')
    final info = SupportedLanguages.getLanguageInfo(languageKey);
    return info.isNotEmpty && info['code'] == languageKey;
  }

  List<LearningModule> _getCareerModules(String proficiency) {
    return [
      LearningModule(
        id: 'career_1',
        title: 'Professional Greetings',
        description: 'Learn formal greetings for business settings',
        lessons: ['greeting_formal', 'introductions', 'business_etiquette'],
        estimatedTime: 30,
      ),
      LearningModule(
        id: 'career_2',
        title: 'Workplace Communication',
        description: 'Essential phrases for the workplace',
        lessons: ['meetings', 'emails', 'presentations'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'career_3',
        title: 'Networking',
        description: 'Build professional relationships',
        lessons: ['networking', 'small_talk', 'follow_up'],
        estimatedTime: 30,
      ),
    ];
  }

  List<LearningModule> _getAcademicModules(String proficiency) {
    return [
      LearningModule(
        id: 'academic_1',
        title: 'Academic Vocabulary',
        description: 'Essential academic terms',
        lessons: ['academic_terms', 'research', 'analysis'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'academic_2',
        title: 'Writing Skills',
        description: 'Academic writing in target language',
        lessons: ['essay_structure', 'citations', 'arguments'],
        estimatedTime: 60,
      ),
      LearningModule(
        id: 'academic_3',
        title: 'Classroom Communication',
        description: 'Participate in academic discussions',
        lessons: ['discussions', 'presentations', 'debates'],
        estimatedTime: 45,
      ),
    ];
  }

  List<LearningModule> _getExploreModules(String proficiency) {
    return [
      LearningModule(
        id: 'explore_1',
        title: 'Cultural Basics',
        description: 'Introduction to culture and customs',
        lessons: ['culture_intro', 'traditions', 'festivals'],
        estimatedTime: 30,
      ),
      LearningModule(
        id: 'explore_2',
        title: 'Everyday Conversations',
        description: 'Common phrases for daily life',
        lessons: ['greetings', 'shopping', 'dining'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'explore_3',
        title: 'Travel Essentials',
        description: 'Phrases for traveling',
        lessons: ['directions', 'transportation', 'accommodation'],
        estimatedTime: 30,
      ),
    ];
  }

  Future<void> completeModule(String moduleId) async {
    final modules = List<LearningModule>.from(state.modules);
    final index = modules.indexWhere((m) => m.id == moduleId);
    if (index == -1) return;

    modules[index] = modules[index].copyWith(isCompleted: true);
    final localState = state.copyWith(
      modules: modules,
      currentModuleIndex: index + 1 < modules.length ? index + 1 : index,
      progress: _calculateProgress(modules),
    );
    state = localState;

    final onboarding = ref.read(onboardingProvider);
    final language = onboarding.selectedLanguage?.trim();
    if (language == null || language.isEmpty) {
      return;
    }

    final pathType = _resolvePathType(onboarding.selectedPath);
    final api = ref.read(apiProvider.notifier);

    final completed = await api.completeLearningPathModule(
      language: language,
      pathType: pathType,
      moduleId: moduleId,
    );
    if (completed != null) {
      state = _pathFromBackend(completed, fallback: localState);
      return;
    }

    final synced = await api.updateLearningPath(
      language: language,
      pathType: pathType,
      updates: {
        'currentLevel': localState.currentLevel,
        'currentModuleIndex': localState.currentModuleIndex,
        'progress': localState.progress,
        'modules': _modulesToBackend(localState.modules),
      },
    );
    if (synced != null) {
      state = _pathFromBackend(synced, fallback: localState);
    }
  }

  double _calculateProgress(List<LearningModule> modules) {
    if (modules.isEmpty) return 0.0;
    final completed = modules.where((m) => m.isCompleted).length;
    return completed / modules.length;
  }
}

final learningPathProvider = NotifierProvider<LearningPathNotifier, LearningPath>(() {
  return LearningPathNotifier();
});

class LearningPath {
  final String type; // 'explore', 'career', 'academic', 'dialect'
  final String currentLevel;
  final List<LearningModule> modules;
  final int currentModuleIndex;
  final double progress;

  LearningPath({
    required this.type,
    required this.currentLevel,
    required this.modules,
    required this.currentModuleIndex,
    required this.progress,
  });

  LearningPath copyWith({
    String? type,
    String? currentLevel,
    List<LearningModule>? modules,
    int? currentModuleIndex,
    double? progress,
  }) {
    return LearningPath(
      type: type ?? this.type,
      currentLevel: currentLevel ?? this.currentLevel,
      modules: modules ?? this.modules,
      currentModuleIndex: currentModuleIndex ?? this.currentModuleIndex,
      progress: progress ?? this.progress,
    );
  }

  LearningModule? get currentModule {
    if (currentModuleIndex >= 0 && currentModuleIndex < modules.length) {
      return modules[currentModuleIndex];
    }
    return null;
  }
}

class LearningModule {
  final String id;
  final String title;
  final String description;
  final List<String> lessons;
  final int estimatedTime; // minutes
  final bool isCompleted;
  final bool isLocked;

  LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.estimatedTime,
    this.isCompleted = false,
    this.isLocked = false,
  });

  LearningModule copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? lessons,
    int? estimatedTime,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return LearningModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessons: lessons ?? this.lessons,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

// --- F-007 path screen (P7-952) ---

enum PathLessonSource { drift, network }

class PathLessonsSnapshot {
  const PathLessonsSnapshot({
    required this.lessons,
    required this.source,
  });

  final List<Lesson> lessons;
  final PathLessonSource source;
}

class PathUnitBannerData {
  const PathUnitBannerData({
    required this.unitKey,
    required this.unitName,
    required this.cefrLevel,
    required this.canDoStatement,
    required this.firstLessonIndex,
  });

  final String unitKey;
  final String unitName;
  final String cefrLevel;
  final String canDoStatement;
  final int firstLessonIndex;
}

sealed class PathScrollItem {
  const PathScrollItem();
}

class PathScrollBannerItem extends PathScrollItem {
  const PathScrollBannerItem(this.banner);
  final PathUnitBannerData banner;
}

class PathScrollNodeItem extends PathScrollItem {
  const PathScrollNodeItem({
    required this.lessonIndex,
    required this.lesson,
  });

  final int lessonIndex;
  final Lesson lesson;
}

/// Node row extent: 72px node + 24px gap (path recipe) + BEGIN pill slack.
const double kPathScrollItemExtent = 96;
/// Inline unit block (scene strip + ribbon).
const double kPathBannerExtent = 160;
const double kPathFrameBudgetMs = 16.7;

Map<String, List<PathUnitBannerData>>? _candoUnitsCache;

Future<List<PathUnitBannerData>> loadPathUnitsForKit(String kitLang) async {
  _candoUnitsCache ??= await _parseCandoUnits();
  final units = _candoUnitsCache![kitLang] ?? const [];
  return units;
}

Future<Map<String, List<PathUnitBannerData>>> _parseCandoUnits() async {
  final raw = await rootBundle.loadString('assets/data/cando_map.json');
  final root = jsonDecode(raw) as Map<String, dynamic>;
  final unitsMap = root['units'] as Map<String, dynamic>? ?? {};
  final byKit = <String, List<PathUnitBannerData>>{};

  for (final entry in unitsMap.entries) {
    final unit = Map<String, dynamic>.from(entry.value as Map);
    final kit = unit['kit_lang'] as String? ?? '';
    if (kit.isEmpty) continue;
    final canDos = unit['can_dos'] as List<dynamic>? ?? [];
    final statement = canDos.isEmpty
        ? ''
        : (canDos.first as Map<String, dynamic>)['statement_en']?.toString() ??
            '';
    final cefr = unit['cefr_band']?.toString() ?? 'A1';
    final list = byKit.putIfAbsent(kit, () => []);
    list.add(
      PathUnitBannerData(
        unitKey: entry.key,
        unitName: pathUnitDisplayName(entry.key),
        cefrLevel: cefr,
        canDoStatement: statement,
        firstLessonIndex: 0,
      ),
    );
  }

  for (final list in byKit.values) {
    list.sort((a, b) => a.unitKey.compareTo(b.unitKey));
  }
  return byKit;
}

String pathUnitDisplayName(String unitKey) {
  final match = RegExp(r'-u(\d+)$', caseSensitive: false).firstMatch(unitKey);
  if (match != null) {
    return 'Unit ${match.group(1)}';
  }
  return unitKey;
}

List<PathScrollItem> buildPathScrollItems({
  required List<Lesson> lessons,
  required List<PathUnitBannerData> units,
}) {
  if (lessons.isEmpty) return const [];

  final items = <PathScrollItem>[];
  final unitCount = units.isEmpty ? 1 : units.length;
  final lessonsPerUnit = (lessons.length / unitCount).ceil().clamp(1, lessons.length);

  for (var u = 0; u < unitCount; u++) {
    final start = u * lessonsPerUnit;
    if (start >= lessons.length) break;

    if (units.isNotEmpty && u < units.length) {
      final banner = PathUnitBannerData(
        unitKey: units[u].unitKey,
        unitName: units[u].unitName,
        cefrLevel: units[u].cefrLevel,
        canDoStatement: units[u].canDoStatement,
        firstLessonIndex: start,
      );
      items.add(PathScrollBannerItem(banner));
    }

    final end = (u == unitCount - 1) ? lessons.length : (start + lessonsPerUnit);
    for (var i = start; i < end && i < lessons.length; i++) {
      items.add(PathScrollNodeItem(lessonIndex: i, lesson: lessons[i]));
    }
  }
  return items;
}

int pathScrollIndexForLesson(List<PathScrollItem> items, int lessonIndex) {
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is PathScrollNodeItem && item.lessonIndex == lessonIndex) {
      return i;
    }
  }
  return 0;
}

double pathScrollOffsetForIndex(List<PathScrollItem> items, int scrollIndex) {
  var offset = 0.0;
  for (var i = 0; i < scrollIndex && i < items.length; i++) {
    offset += items[i] is PathScrollBannerItem
        ? kPathBannerExtent
        : kPathScrollItemExtent;
  }
  return offset;
}

Future<List<Lesson>> _lessonsFromDrift(int languageId) async {
  final db = LocalDatabaseService();
  if (!db.isInitialized) return const [];
  final payloads = await readPayloads(db.database, 'lessons');
  final lessons = <Lesson>[];
  for (final row in payloads) {
    final map = Map<String, dynamic>.from(row);
    final lesson = Lesson.fromMap(map);
    if (lesson.lessons_language == languageId) {
      lessons.add(lesson);
    }
  }
  lessons.sort((a, b) => a.id.compareTo(b.id));
  return lessons;
}

Future<void> _persistLessonsToDrift(List<Lesson> lessons) async {
  final db = LocalDatabaseService();
  if (!db.isInitialized) return;
  for (final lesson in lessons) {
    await storeLessonPayload(db.database, lesson.toMap());
  }
}

final pathLessonsProvider =
    FutureProvider.autoDispose.family<PathLessonsSnapshot, Language>((ref, language) async {
  final languageId = language.id;
  final driftLessons = await _lessonsFromDrift(languageId);
  if (driftLessons.isNotEmpty) {
    unawaited(
      ref.read(apiProvider.notifier).getLessons(languageId).then((response) async {
        final network = response.results
            .where((e) => e.lessons_language == languageId)
            .toList();
        if (network.isNotEmpty) {
          await _persistLessonsToDrift(network);
        }
      }),
    );
    return PathLessonsSnapshot(
      lessons: driftLessons,
      source: PathLessonSource.drift,
    );
  }

  final response = await ref.read(apiProvider.notifier).getLessons(languageId);
  final lessons = response.results
      .where((e) => e.lessons_language == languageId)
      .toList();
  if (lessons.isNotEmpty) {
    await _persistLessonsToDrift(lessons);
  }
  return PathLessonsSnapshot(
    lessons: lessons,
    source: PathLessonSource.network,
  );
});

final pathUnitsProvider =
    FutureProvider.autoDispose.family<List<PathUnitBannerData>, Language>((ref, language) async {
  final langKey = CurriculumLanguages.keyForApiLanguage(language);
  final kit = SupportedLanguages.getLanguageCode(langKey);
  return loadPathUnitsForKit(kit);
});

/// Median frame duration from [TimingsCallback] samples (P7-952 AC5/AC7).
class PathFrameBudgetSampler {
  PathFrameBudgetSampler();

  final List<double> _frameMs = [];
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final ms = timing.totalSpan.inMicroseconds / 1000.0;
      if (ms > 0) {
        _frameMs.add(ms);
      }
    }
  }

  void detach() {
    if (!_attached) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _attached = false;
  }

  double? medianFrameMs() {
    if (_frameMs.isEmpty) return null;
    final sorted = List<double>.from(_frameMs)..sort();
    return sorted[sorted.length ~/ 2];
  }

  bool exceedsBudget({double budgetMs = kPathFrameBudgetMs}) {
    final median = medianFrameMs();
    if (median == null) return false;
    return median > budgetMs;
  }

  void reset() => _frameMs.clear();

  /// Test hook for frame budget without a live [TimingsCallback].
  void recordFrameMs(double ms) {
    if (ms > 0) _frameMs.add(ms);
  }
}

