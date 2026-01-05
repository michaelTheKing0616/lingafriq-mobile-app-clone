/// Tutor Progress Service
/// Manages tutor mode progress, CEFR advancement, and adaptive difficulty
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutor_progress_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';

final tutorProgressServiceProvider = Provider<TutorProgressService>((ref) {
  return TutorProgressService(ref);
});

class TutorProgressService {
  final Ref _ref;
  TutorProgress? _cachedProgress;

  TutorProgressService(this._ref);

  /// Load tutor progress from local storage
  Future<TutorProgress> loadProgress(String language) async {
    if (_cachedProgress != null && _cachedProgress!.language == language) {
      return _cachedProgress!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('tutor_progress_$language');
      
      if (progressJson != null && progressJson.isNotEmpty) {
        _cachedProgress = TutorProgress.fromJsonString(progressJson);
        if (_cachedProgress!.language == language) {
          return _cachedProgress!;
        }
      }
    } catch (e) {
      debugPrint('Error loading tutor progress: $e');
    }

    _cachedProgress = TutorProgress(language: language);
    return _cachedProgress!;
  }

  /// Save tutor progress to local storage
  Future<void> saveProgress(TutorProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tutor_progress_${progress.language}', progress.toJsonString());
      _cachedProgress = progress;
      
      // Sync to backend
      await _syncToBackend(progress);
    } catch (e) {
      debugPrint('Error saving tutor progress: $e');
    }
  }

  /// Record a completed tutor session
  Future<void> recordSession(TutorSessionResult result) async {
    final progress = await loadProgress(result.language);
    
    // Update skill levels
    final updatedSkillLevels = Map<String, double>.from(progress.skillLevels);
    result.skillScores.forEach((skill, score) {
      final current = updatedSkillLevels[skill] ?? 0.0;
      // Weighted average: 70% old, 30% new
      updatedSkillLevels[skill] = (current * 0.7) + (score * 0.3);
    });

    // Update topics mastered
    final updatedTopics = Map<String, int>.from(progress.topicsMastered);
    for (final topic in result.topicsCovered) {
      updatedTopics[topic] = (updatedTopics[topic] ?? 0) + 1;
    }

    // Update vocabulary mastered
    final updatedVocab = Map<String, int>.from(progress.vocabularyMastered);
    for (final word in result.vocabularyLearned) {
      updatedVocab[word] = (updatedVocab[word] ?? 0) + 1;
    }

    // Update grammar points mastered
    final updatedGrammar = Map<String, int>.from(progress.grammarPointsMastered);
    for (final point in result.grammarPoints) {
      updatedGrammar[point] = (updatedGrammar[point] ?? 0) + 1;
    }

    // Update CEFR level and score
    String newCefrLevel = progress.currentCefrLevel;
    double newCefrScore = progress.cefrScore;
    
    // Calculate new CEFR score (weighted average of skills)
    final grammarScore = updatedSkillLevels['grammar'] ?? 0.0;
    final pronunciationScore = updatedSkillLevels['pronunciation'] ?? 0.0;
    final vocabularyScore = updatedSkillLevels['vocabulary'] ?? 0.0;
    final comprehensionScore = updatedSkillLevels['comprehension'] ?? 0.0;
    
    newCefrScore = (grammarScore * 0.3) +
        (pronunciationScore * 0.2) +
        (vocabularyScore * 0.25) +
        (comprehensionScore * 0.25);

    // Check if ready to advance CEFR level
    final recommendedLevel = _calculateCefrLevel(newCefrScore);
    if (_shouldAdvanceLevel(progress.currentCefrLevel, recommendedLevel, updatedSkillLevels)) {
      newCefrLevel = recommendedLevel;
    }

    // Update recent sessions (keep last 20)
    final updatedSessions = [result, ...progress.recentSessions].take(20).toList();

    // Calculate new average score
    final totalScore = updatedSessions.fold<double>(0.0, (sum, s) => sum + s.overallScore);
    final newAverageScore = updatedSessions.isEmpty ? 0.0 : totalScore / updatedSessions.length;

    final updatedProgress = progress.copyWith(
      currentCefrLevel: newCefrLevel,
      cefrScore: newCefrScore,
      skillLevels: updatedSkillLevels,
      topicsMastered: updatedTopics,
      vocabularyMastered: updatedVocab,
      grammarPointsMastered: updatedGrammar,
      recentSessions: updatedSessions,
      totalSessions: progress.totalSessions + 1,
      averageScore: newAverageScore,
      totalTimeSpent: progress.totalTimeSpent + result.timeSpent,
      lastActivity: result.completedAt,
    );

    await saveProgress(updatedProgress);
  }

  /// Calculate CEFR level from score
  String _calculateCefrLevel(double score) {
    if (score < 20) return 'A1';
    if (score < 40) return 'A2';
    if (score < 55) return 'B1';
    if (score < 70) return 'B2';
    if (score < 85) return 'C1';
    return 'C2';
  }

  /// Determine if user should advance to next CEFR level
  bool _shouldAdvanceLevel(
    String currentLevel,
    String recommendedLevel,
    Map<String, double> skillLevels,
  ) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(currentLevel);
    final recommendedIndex = levels.indexOf(recommendedLevel);

    if (recommendedIndex <= currentIndex) return false;

    // All skills must be at least 70% to advance
    final allSkillsGood = skillLevels.values.every((score) => score >= 70.0);
    if (!allSkillsGood) return false;

    // Score must be consistently high (check last 3 sessions)
    // This would be checked in the calling code with recent sessions

    return true;
  }

  /// Get recommended topics based on progress
  Future<List<String>> getRecommendedTopics(String language) async {
    final progress = await loadProgress(language);
    
    // Get weak areas
    final weakAreas = progress.getWeakAreas();
    
    // Get topics that haven't been mastered yet
    final allTopics = [
      'Greetings',
      'Numbers',
      'Colors',
      'Family',
      'Food',
      'Travel',
      'Shopping',
      'Health',
      'Time',
      'Weather',
      'Directions',
      'Emotions',
      'Work',
      'Hobbies',
      'Education',
    ];

    // Prioritize topics in weak areas
    final recommended = <String>[];
    for (final area in weakAreas) {
      final relatedTopics = allTopics.where((t) => 
          t.toLowerCase().contains(area.toLowerCase())).toList();
      recommended.addAll(relatedTopics);
    }

    // Add topics that haven't been mastered
    final unmastered = allTopics.where((t) => 
        (progress.topicsMastered[t] ?? 0) < 3).toList();
    recommended.addAll(unmastered);

    // Remove duplicates and return top 5
    return recommended.toSet().take(5).toList();
  }

  /// Get adaptive difficulty settings
  Future<Map<String, dynamic>> getAdaptiveSettings(String language) async {
    final progress = await loadProgress(language);
    
    // Calculate difficulty multiplier based on performance
    final avgScore = progress.averageScore;
    double difficultyMultiplier = 1.0;
    
    if (avgScore > 90) {
      difficultyMultiplier = 1.3; // Increase difficulty
    } else if (avgScore > 75) {
      difficultyMultiplier = 1.1;
    } else if (avgScore < 50) {
      difficultyMultiplier = 0.7; // Decrease difficulty
    } else if (avgScore < 65) {
      difficultyMultiplier = 0.85;
    }

    // Get weak areas for focused practice
    final weakAreas = progress.getWeakAreas();

    return {
      'difficulty_multiplier': difficultyMultiplier,
      'cefr_level': progress.currentCefrLevel,
      'weak_areas': weakAreas,
      'recommended_topics': await getRecommendedTopics(language),
      'focus_grammar': weakAreas.contains('grammar'),
      'focus_pronunciation': weakAreas.contains('pronunciation'),
      'focus_vocabulary': weakAreas.contains('vocabulary'),
      'focus_comprehension': weakAreas.contains('comprehension'),
    };
  }

  /// Sync progress to backend
  Future<void> _syncToBackend(TutorProgress progress) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress,
        data: {
          'user_id': user.id.toString(),
          'type': 'tutor',
          'language': progress.language,
          'progress': progress.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing tutor progress: $e');
    }
  }

  /// Clear cached progress
  void clearCache() {
    _cachedProgress = null;
  }
}

