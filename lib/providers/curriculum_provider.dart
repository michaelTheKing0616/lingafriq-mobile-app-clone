import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final curriculumProvider = NotifierProvider<CurriculumProvider, BaseProviderState>(() {
  return CurriculumProvider();
});

class CurriculumProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  Curriculum? _curriculum;
  String? _selectedLanguage;
  String? _selectedLevel;
  final Map<String, Map<String, Map<String, bool>>> _completionStatus = {}; // language -> level -> lessonId -> completed

  Curriculum? get curriculum => _curriculum;
  String? get selectedLanguage => _selectedLanguage;
  String? get selectedLevel => _selectedLevel;

  @override
  BaseProviderState build() {
    _loadCurriculum();
    _loadCompletionStatus();
    return BaseProviderState();
  }

  Future<void> loadCurriculumFromBundle({bool useExpanded = false}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // First, try to load from saved preferences (cached)
      final prefs = await SharedPreferences.getInstance();
      final cachedCurriculum = prefs.getString('curriculum_data');
      if (cachedCurriculum != null && cachedCurriculum.isNotEmpty) {
        try {
          _curriculum = Curriculum.fromJson(cachedCurriculum);
          state = state.copyWith(isLoading: false);
          state = state.copyWith(); // Trigger rebuild
          return;
        } catch (e) {
          logger.error('Error loading cached curriculum', tag: 'curriculum', error: e);
          // Continue to try loading from bundle
        }
      }
      
      final curriculumService = ref.read(curriculumServiceProvider);
      
      // Load master index to get available languages and levels
      final masterIndex = await curriculumService.loadMasterIndex();
      if (masterIndex == null) {
        throw Exception('Master index not found. Please ensure curriculum bundle is properly installed.');
      }

      final languages = List<String>.from(masterIndex['languages'] ?? []);
      final levels = List<String>.from(masterIndex['levels'] ?? ['A1', 'A2', 'B1']);
      
      // Build curriculum from all languages and levels
      final languagesMap = <String, Map<String, List<CurriculumUnit>>>{};
      
      for (final language in languages) {
        final levelsMap = <String, List<CurriculumUnit>>{};
        
        for (final level in levels) {
          try {
            Map<String, dynamic>? curriculumData;
            
            if (useExpanded) {
              curriculumData = await curriculumService.loadExpandedCurriculum(language, level);
            }
            
            if (curriculumData == null) {
              curriculumData = await curriculumService.loadCompactCurriculum(language, level);
            }
            
            if (curriculumData != null && curriculumData['units'] != null) {
              final units = (curriculumData['units'] as List)
                  .map((u) => CurriculumUnit.fromMap(u as Map<String, dynamic>))
                  .toList();
              levelsMap[level] = units;
            }
          } catch (e) {
            logger.error('Error loading curriculum', tag: 'curriculum', error: e, context: {'language': language, 'level': level});
            // Continue with other languages/levels
          }
        }
        
        if (levelsMap.isNotEmpty) {
          languagesMap[language] = levelsMap;
        }
      }

      if (languagesMap.isEmpty) {
        throw Exception('No curriculum data found. Please ensure curriculum bundle is properly installed.');
      }

      // Create curriculum object
      _curriculum = Curriculum(
        meta: CurriculumMeta(
          title: 'Comprehensive Curriculum',
          generatedAt: DateTime.now(),
          languages: languages,
          levels: levels,
        ),
        languages: languagesMap,
      );
      
      await _saveCurriculum();
      state = state.copyWith(isLoading: false);
      state = state.copyWith(); // Trigger rebuild
    } catch (e) {
      logger.error('Error loading curriculum', tag: 'curriculum', error: e);
      state = state.copyWith(isLoading: false);
      // Don't rethrow - show user-friendly error in UI
      // The UI will handle showing the error message
    }
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    state = state.copyWith();
  }

  void setSelectedLevel(String level) {
    _selectedLevel = level;
    state = state.copyWith();
  }

  List<CurriculumLevel> getLevelsForLanguage(String language) {
    if (_curriculum == null) return [];
    
    final languageData = _curriculum!.languages[language];
    if (languageData == null) return [];

    return languageData.entries.map((entry) {
      final level = entry.key;
      final units = entry.value;
      final isCompleted = units.every((u) => _isUnitCompleted(language, level, u));
      final progress = _calculateLevelProgress(language, level, units);
      
      return CurriculumLevel(
        level: level,
        units: units.map((u) {
          final unitCompleted = _isUnitCompleted(language, level, u);
          final unitProgress = _calculateUnitProgress(language, level, u);
          
          return CurriculumUnit(
            unit: u.unit,
            title: u.title,
            lessons: u.lessons.map((l) {
              final lessonCompleted = _isLessonCompleted(language, level, l.id);
              return CurriculumLesson(
                id: l.id,
                title: l.title,
                vocab: l.vocab,
                exercises: l.exercises,
                isCompleted: lessonCompleted,
                progress: lessonCompleted ? 1.0 : 0.0,
              );
            }).toList(),
            isCompleted: unitCompleted,
            progress: unitProgress,
          );
        }).toList(),
        isCompleted: isCompleted,
        progress: progress,
      );
    }).toList();
  }

  void markLessonComplete(String language, String level, String lessonId) {
    if (!_completionStatus.containsKey(language)) {
      _completionStatus[language] = {};
    }
    if (!_completionStatus[language]!.containsKey(level)) {
      _completionStatus[language]![level] = {};
    }
    _completionStatus[language]![level]![lessonId] = true;
    _saveCompletionStatus();
    state = state.copyWith();
  }

  bool _isLessonCompleted(String language, String level, String lessonId) {
    return _completionStatus[language]?[level]?[lessonId] ?? false;
  }

  /// Public method to check if a lesson is completed
  bool isLessonCompleted(String language, String level, String lessonId) {
    return _isLessonCompleted(language, level, lessonId);
  }

  bool _isUnitCompleted(String language, String level, CurriculumUnit unit) {
    return unit.lessons.every((l) => _isLessonCompleted(language, level, l.id));
  }

  double _calculateUnitProgress(String language, String level, CurriculumUnit unit) {
    if (unit.lessons.isEmpty) return 0.0;
    final completed = unit.lessons.where((l) => _isLessonCompleted(language, level, l.id)).length;
    return completed / unit.lessons.length;
  }

  double _calculateLevelProgress(String language, String level, List<CurriculumUnit> units) {
    if (units.isEmpty) return 0.0;
    final totalProgress = units.fold<double>(0.0, (sum, unit) => sum + _calculateUnitProgress(language, level, unit));
    return totalProgress / units.length;
  }

  Future<void> _saveCurriculum() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_curriculum != null) {
        await prefs.setString('curriculum_data', _curriculum!.toJson());
      }
    } catch (e) {
      logger.error('Error saving curriculum', tag: 'curriculum', error: e);
    }
  }

  Future<void> _loadCurriculum() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final curriculumJson = prefs.getString('curriculum_data');
      if (curriculumJson != null) {
        _curriculum = Curriculum.fromJson(curriculumJson);
        state = state.copyWith();
      }
    } catch (e) {
      logger.error('Error loading curriculum', tag: 'curriculum', error: e);
    }
  }

  Future<void> _saveCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('curriculum_completion', jsonEncode(_completionStatus));
    } catch (e) {
      logger.error('Error saving completion status', tag: 'curriculum', error: e);
    }
  }

  Future<void> _loadCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completionJson = prefs.getString('curriculum_completion');
      if (completionJson != null) {
        _completionStatus.clear();
        final decoded = jsonDecode(completionJson) as Map<String, dynamic>;
        decoded.forEach((lang, levels) {
          _completionStatus[lang] = {};
          (levels as Map).forEach((level, lessons) {
            _completionStatus[lang]![level] = Map<String, bool>.from(lessons as Map);
          });
        });
      }
    } catch (e) {
      logger.error('Error loading completion status', tag: 'curriculum', error: e);
    }
  }
}

