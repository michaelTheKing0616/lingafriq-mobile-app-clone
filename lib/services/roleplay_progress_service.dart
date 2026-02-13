// Roleplay Progress Service
// Manages roleplay progress tracking, difficulty adaptation, and analytics
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/roleplay_progress_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';
final roleplayProgressServiceProvider = Provider<RoleplayProgressService>((ref) {
  return RoleplayProgressService(ref);
});

class RoleplayProgressService {
  final Ref _ref;
  RoleplayProgress? _cachedProgress;

  RoleplayProgressService(this._ref);

  /// Load roleplay progress from local storage
  Future<RoleplayProgress> loadProgress() async {
    if (_cachedProgress != null) return _cachedProgress!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('roleplay_progress');
      
      if (progressJson != null && progressJson.isNotEmpty) {
        _cachedProgress = RoleplayProgress.fromJsonString(progressJson);
        return _cachedProgress!;
      }
    } catch (e) {
      debugPrint('Error loading roleplay progress: $e');
    }

    _cachedProgress = RoleplayProgress();
    return _cachedProgress!;
  }

  /// Save roleplay progress to local storage
  Future<void> saveProgress(RoleplayProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roleplay_progress', progress.toJsonString());
      _cachedProgress = progress;
      
      // Sync to backend
      await _syncToBackend(progress);
    } catch (e) {
      debugPrint('Error saving roleplay progress: $e');
    }
  }

  /// Record a completed roleplay session
  Future<void> recordSession(RoleplaySessionResult result) async {
    final progress = await loadProgress();
    
    // Get or create scenario progress
    final scenarioProgress = progress.scenarios[result.scenarioId] ??
        ScenarioProgress(
          scenarioId: result.scenarioId,
          scenarioName: result.metadata['scenario_name'] ?? result.scenarioId,
          language: result.language,
          category: result.metadata['category'] ?? 'general',
          difficulty: result.metadata['difficulty'] ?? 'A1',
        );

    // Update scenario progress
    final timesCompleted = scenarioProgress.timesCompleted + 1;
    final newAccuracy = (scenarioProgress.averageAccuracy * scenarioProgress.timesCompleted +
            result.accuracy) /
        timesCompleted;
    final newFluency = (scenarioProgress.averageFluency * scenarioProgress.timesCompleted +
            result.fluency) /
        timesCompleted;
    final newBestScore = result.score > scenarioProgress.bestScore
        ? result.score
        : scenarioProgress.bestScore;
    
    // Update branches explored
    final newBranches = [
      ...scenarioProgress.branchesExplored,
      ...result.branchesTaken,
    ].toSet().toList();
    
    // Update vocabulary
    final newVocabulary = Map<String, int>.from(scenarioProgress.vocabularyUsed);
    for (final word in result.vocabularyLearned) {
      newVocabulary[word] = (newVocabulary[word] ?? 0) + 1;
    }
    
    // Update grammar points
    final newGrammar = Map<String, int>.from(scenarioProgress.grammarPoints);
    for (final point in result.grammarPoints) {
      newGrammar[point] = (newGrammar[point] ?? 0) + 1;
    }
    
    // Check if mastered (accuracy > 0.9, completed 3+ times)
    final isMastered = newAccuracy > 0.9 && timesCompleted >= 3;
    
    // Update streak
    final now = DateTime.now();
    final lastCompleted = scenarioProgress.lastCompleted;
    final newStreak = lastCompleted != null &&
            now.difference(lastCompleted).inDays == 1
        ? scenarioProgress.streak + 1
        : (lastCompleted != null && now.difference(lastCompleted).inDays == 0
            ? scenarioProgress.streak
            : 1);

    final updatedScenario = scenarioProgress.copyWith(
      timesCompleted: timesCompleted,
      averageAccuracy: newAccuracy,
      averageFluency: newFluency,
      bestScore: newBestScore,
      firstCompleted: scenarioProgress.firstCompleted ?? result.completedAt,
      lastCompleted: result.completedAt,
      branchesExplored: newBranches,
      vocabularyUsed: newVocabulary,
      grammarPoints: newGrammar,
      totalTimeSpent: scenarioProgress.totalTimeSpent + result.timeSpent,
      isMastered: isMastered,
      streak: newStreak,
    );

    // Update overall progress
    final updatedScenarios = Map<String, ScenarioProgress>.from(progress.scenarios);
    updatedScenarios[result.scenarioId] = updatedScenario;

    // Recalculate overall stats
    final allScenarios = updatedScenarios.values.toList();
    final totalCompleted = allScenarios.fold<int>(
        0, (sum, s) => sum + s.timesCompleted);
    final avgAccuracy = allScenarios.isEmpty
        ? 0.0
        : allScenarios.fold<double>(0.0, (sum, s) => sum + s.averageAccuracy) /
            allScenarios.length;
    final avgFluency = allScenarios.isEmpty
        ? 0.0
        : allScenarios.fold<double>(0.0, (sum, s) => sum + s.averageFluency) /
            allScenarios.length;
    final mastered = allScenarios
        .where((s) => s.isMastered)
        .map((s) => s.scenarioId)
        .toList();

    // Update category progress
    final categoryProgress = Map<String, int>.from(progress.categoryProgress);
    final category = updatedScenario.category;
    categoryProgress[category] = (categoryProgress[category] ?? 0) + 1;

    // Update difficulty progress
    final difficultyProgress = Map<String, int>.from(progress.difficultyProgress);
    final difficulty = updatedScenario.difficulty;
    difficultyProgress[difficulty] = (difficultyProgress[difficulty] ?? 0) + 1;

    // Determine current difficulty (highest difficulty with good performance)
    String currentDifficulty = progress.currentDifficulty;
    final masteredDifficulties = allScenarios
        .where((s) => s.isMastered)
        .map((s) => s.difficulty)
        .toSet()
        .toList();
    if (masteredDifficulties.isNotEmpty) {
      final difficultyOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      final highestMastered = masteredDifficulties
          .map((d) => difficultyOrder.indexOf(d))
          .reduce((a, b) => a > b ? a : b);
      if (highestMastered >= 0 && highestMastered < difficultyOrder.length - 1) {
        currentDifficulty = difficultyOrder[highestMastered + 1];
      }
    }

    // Calculate current streak (consecutive days with roleplay activity)
    final lastActivity = progress.lastActivity;
    final currentStreak = lastActivity != null &&
            now.difference(lastActivity).inDays == 1
        ? progress.currentStreak + 1
        : (lastActivity != null && now.difference(lastActivity).inDays == 0
            ? progress.currentStreak
            : 1);

    final updatedProgress = progress.copyWith(
      scenarios: updatedScenarios,
      currentDifficulty: currentDifficulty,
      totalScenariosCompleted: totalCompleted,
      averageAccuracy: avgAccuracy,
      averageFluency: avgFluency,
      masteredScenarios: mastered,
      categoryProgress: categoryProgress,
      difficultyProgress: difficultyProgress,
      totalTimeSpent: progress.totalTimeSpent + result.timeSpent,
      currentStreak: currentStreak,
      lastActivity: now,
    );

    await saveProgress(updatedProgress);
  }

  /// Get recommended scenarios based on progress
  Future<List<String>> getRecommendedScenarios({
    required String language,
    String? category,
    int limit = 5,
  }) async {
    final progress = await loadProgress();
    
    // Get scenarios for language
    final languageScenarios = progress.scenarios.values
        .where((s) => s.language == language)
        .toList();
    
    // Filter by category if specified
    final filtered = category != null
        ? languageScenarios.where((s) => s.category == category).toList()
        : languageScenarios;
    
    // Sort by: not completed > low accuracy > not mastered
    filtered.sort((a, b) {
      if (a.timesCompleted == 0 && b.timesCompleted > 0) return -1;
      if (a.timesCompleted > 0 && b.timesCompleted == 0) return 1;
      if (a.timesCompleted == 0 && b.timesCompleted == 0) return 0;
      if (a.averageAccuracy < b.averageAccuracy) return -1;
      if (a.averageAccuracy > b.averageAccuracy) return 1;
      if (!a.isMastered && b.isMastered) return -1;
      if (a.isMastered && !b.isMastered) return 1;
      return 0;
    });
    
    return filtered.take(limit).map((s) => s.scenarioId).toList();
  }

  /// Get next difficulty level
  String getNextDifficulty(String currentDifficulty) {
    const difficulties = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = difficulties.indexOf(currentDifficulty);
    if (currentIndex >= 0 && currentIndex < difficulties.length - 1) {
      return difficulties[currentIndex + 1];
    }
    return currentDifficulty;
  }

  /// Check if user should advance difficulty
  Future<bool> shouldAdvanceDifficulty(String language) async {
    final progress = await loadProgress();
    final currentDiff = progress.currentDifficulty;
    
    // Get all scenarios at current difficulty
    final currentDiffScenarios = progress.scenarios.values
        .where((s) => s.language == language && s.difficulty == currentDiff)
        .toList();
    
    if (currentDiffScenarios.isEmpty) return true;
    
    // Check if 80% are mastered
    final masteredCount = currentDiffScenarios.where((s) => s.isMastered).length;
    final masteryRate = masteredCount / currentDiffScenarios.length;
    
    return masteryRate >= 0.8;
  }

  /// Sync progress to backend
  Future<void> _syncToBackend(RoleplayProgress progress) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress, // SyncType.progress exists in backend_sync_provider
        data: {
          'user_id': user.id.toString(),
          'type': 'roleplay',
          'progress': progress.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing roleplay progress: $e');
    }
  }

  /// Clear cached progress
  void clearCache() {
    _cachedProgress = null;
  }
}

