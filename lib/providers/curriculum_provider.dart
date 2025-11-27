import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';

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
      
      final bundleName = useExpanded ? 'curriculum_expanded_bundle' : 'curriculum_bundle';
      final curriculumDir = Directory('$bundleName/curriculum');
      
      if (!await curriculumDir.exists()) {
        throw Exception('Curriculum bundle not found');
      }

      // Find the main curriculum JSON file
      final files = await curriculumDir.list().toList();
      final jsonFile = files.firstWhere(
        (file) => file.path.endsWith('.json'),
        orElse: () => throw Exception('No JSON file found'),
      );

      final jsonString = await File(jsonFile.path).readAsString();
      _curriculum = Curriculum.fromJson(jsonString);
      
      await _saveCurriculum();
      state = state.copyWith(isLoading: false);
      state = state.copyWith(); // Trigger rebuild
    } catch (e) {
      debugPrint('Error loading curriculum: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
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
      debugPrint('Error saving curriculum: $e');
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
      debugPrint('Error loading curriculum: $e');
    }
  }

  Future<void> _saveCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('curriculum_completion', jsonEncode(_completionStatus));
    } catch (e) {
      debugPrint('Error saving completion status: $e');
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
      debugPrint('Error loading completion status: $e');
    }
  }
}

