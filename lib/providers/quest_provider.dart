import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest_model.dart';
import 'gamification_provider.dart';
import 'gamification_services_provider.dart';
import 'user_provider.dart';
import 'base_provider.dart';
import '../utils/progress_integration.dart';

final questProvider = NotifierProvider<QuestProvider, BaseProviderState>(() {
  return QuestProvider();
});

/// Quest provider for "The Great Journey" story mode
class QuestProvider extends Notifier<BaseProviderState> {
  List<QuestChapter> _chapters = QuestDefinitions.getGreatJourneyChapters();
  final Map<String, int> _lessonProgress = {}; // lessonId -> completion status

  List<QuestChapter> get chapters => List.unmodifiable(_chapters);
  List<QuestChapter> get unlockedChapters =>
      _chapters.where((c) => c.isUnlocked).toList();
  List<QuestChapter> get completedChapters =>
      _chapters.where((c) => c.isCompleted).toList();

  @override
  BaseProviderState build() {
    _loadQuestProgress();
    _loadJourneyFromAPI();
    _updateUnlockedChapters();
    return BaseProviderState();
  }

  /// Load journey progress from API
  Future<void> _loadJourneyFromAPI() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final journeyService = ref.read(journeyServiceProvider);
      final progress = await journeyService.getUserProgress(user.id.toString(), campaign: 'great_journey');
      
      // Update local progress from API
      // Map journey nodes to quest lessons/chapters
      final Map<String, String> nodeToLessonMap = {}; // nodeId -> lessonId
      
      for (var progressEntry in progress) {
        final nodeId = progressEntry['node_id']?['_id']?.toString() ?? '';
        final nodeData = progressEntry['node_id'];
        final status = progressEntry['status']?.toString() ?? '';
        
        if (nodeId.isNotEmpty && status == 'completed') {
          // Extract lesson ID from node metadata or payload
          final lessonId = nodeData?['lesson_id']?.toString() ?? 
                          nodeData?['metadata']?['lessonId']?.toString() ??
                          progressEntry['payload']?['lessonId']?.toString() ??
                          '';
          
          if (lessonId.isNotEmpty) {
            nodeToLessonMap[nodeId] = lessonId;
            // Mark lesson as completed
            _lessonProgress[lessonId] = 1;
          }
        }
      }
      
      // Save updated progress
      await _saveQuestProgress();
    } catch (e) {
      debugPrint('Error loading journey from API: $e');
      // Continue with local data
    }
  }

  /// Complete a lesson
  Future<void> completeLesson(String lessonId) async {
    _lessonProgress[lessonId] = 1; // 1 = completed

    // Track lesson completion (but don't award XP yet - XP only after all lessons completed)
    try {
      final chapter = _chapters.firstWhere(
        (c) => c.lessons.any((l) => l.id == lessonId),
        orElse: () => _chapters.first,
      );
      final targetLanguage = chapter.metadata?['language']?.toString();
      await ProgressIntegration.onStoryLessonCompleted(ref, language: targetLanguage);
    } catch (e) {
      debugPrint('Error tracking lesson completion: $e');
    }

    // Try to complete journey node via API
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final journeyService = ref.read(journeyServiceProvider);
        
        // Find the chapter and lesson to get node mapping
        final chapter = _chapters.firstWhere(
          (c) => c.lessons.any((l) => l.id == lessonId),
          orElse: () => _chapters.first,
        );
        
        // Map lesson to journey node
        // Node ID format: campaign_chapter_lesson (e.g., "great_journey_ch1_l1")
        final chapterNum = chapter.chapterNumber;
        final lesson = chapter.lessons.firstWhere((l) => l.id == lessonId);
        final lessonOrder = lesson.order;
        final nodeId = 'great_journey_ch${chapterNum}_l${lessonOrder}';
        
        // Complete the journey node via API
        await journeyService.completeNode(
          'great_journey',
          nodeId,
        );
      }
    } catch (e) {
      debugPrint('Error completing journey node: $e');
      // Continue - local completion is already tracked
    }

    // Check if chapter is completed
    try {
      for (var chapter in _chapters) {
        if (chapter.lessons.isEmpty) continue; // Skip chapters with no lessons
        
        final allLessonsCompleted = chapter.lessons.every(
          (lesson) => _lessonProgress[lesson.id] == 1,
        );

        if (allLessonsCompleted && !chapter.isCompleted) {
          // Mark chapter as completed
          final chapterIndex = _chapters.indexWhere((c) => c.id == chapter.id);
          if (chapterIndex >= 0) {
            _chapters[chapterIndex] = QuestChapter(
              id: chapter.id,
              title: chapter.title,
              description: chapter.description,
              icon: chapter.icon,
              chapterNumber: chapter.chapterNumber,
              lessons: chapter.lessons,
              isUnlocked: chapter.isUnlocked,
              isCompleted: true,
              xpReward: chapter.xpReward,
              badgeReward: chapter.badgeReward,
              metadata: chapter.metadata,
            );

            // Award XP and badge via ProgressIntegration (server-authoritative)
            // XP is only awarded after all lessons are completed (content fully consumed)
            try {
              await ProgressIntegration.onStoryCompleted(
                ref,
                chapterId: chapter.id,
                chapterTitle: chapter.title,
                wordsLearned: chapter.lessons.length * 5, // Estimate 5 words per lesson
                xpReward: chapter.xpReward,
                allLessonsCompleted: true, // All lessons are completed at this point
              );
            } catch (e) {
              debugPrint('Error awarding story completion XP: $e');
              // Continue - XP award failure shouldn't block chapter completion
            }
            
            // Unlock badge
            if (chapter.badgeReward != null) {
              try {
                final gamification = ref.read(gamificationProvider.notifier);
                await gamification.unlockBadge(chapter.badgeReward!);
              } catch (e) {
                debugPrint('Error unlocking badge: $e');
                // Continue - badge unlock failure shouldn't block chapter completion
              }
            }

            // Unlock next chapter
            _updateUnlockedChapters();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking chapter completion: $e');
      // Continue execution - completion check failure shouldn't block lesson completion
    }

    await _saveQuestProgress();
    state = state.copyWith();
  }

  /// Update which chapters are unlocked
  void _updateUnlockedChapters() {
    // First chapter is always unlocked
    if (_chapters.isNotEmpty) {
      final firstChapter = _chapters[0];
      if (!firstChapter.isUnlocked) {
        final index = _chapters.indexWhere((c) => c.id == firstChapter.id);
        if (index >= 0) {
          _chapters[index] = QuestChapter(
            id: firstChapter.id,
            title: firstChapter.title,
            description: firstChapter.description,
            icon: firstChapter.icon,
            chapterNumber: firstChapter.chapterNumber,
            lessons: firstChapter.lessons,
            isUnlocked: true,
            isCompleted: firstChapter.isCompleted,
            xpReward: firstChapter.xpReward,
            badgeReward: firstChapter.badgeReward,
            metadata: firstChapter.metadata,
          );
        }
      }
    }

    // Unlock next chapter when previous is completed
    for (int i = 0; i < _chapters.length - 1; i++) {
      if (_chapters[i].isCompleted && !_chapters[i + 1].isUnlocked) {
        _chapters[i + 1] = QuestChapter(
          id: _chapters[i + 1].id,
          title: _chapters[i + 1].title,
          description: _chapters[i + 1].description,
          icon: _chapters[i + 1].icon,
          chapterNumber: _chapters[i + 1].chapterNumber,
          lessons: _chapters[i + 1].lessons,
          isUnlocked: true,
          isCompleted: _chapters[i + 1].isCompleted,
          xpReward: _chapters[i + 1].xpReward,
          badgeReward: _chapters[i + 1].badgeReward,
          metadata: _chapters[i + 1].metadata,
        );
      }
    }
  }

  /// Get progress for a chapter (0.0 to 1.0)
  double getChapterProgress(String chapterId) {
    try {
      final chapter = _chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => _chapters.firstOrNull ?? _chapters.first,
      );
      if (chapter.lessons.isEmpty) return 0.0;

      final completedCount = chapter.lessons
          .where((lesson) => _lessonProgress[lesson.id] == 1)
          .length;

      return completedCount / chapter.lessons.length;
    } catch (e) {
      debugPrint('Error getting chapter progress: $e');
      return 0.0;
    }
  }

  /// Persistence
  Future<void> _saveQuestProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quest_progress', jsonEncode(_lessonProgress));
    } catch (e) {
      debugPrint('Error saving quest progress: $e');
    }
  }

  Future<void> _loadQuestProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('quest_progress');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _lessonProgress.clear();
        json.forEach((key, value) {
          _lessonProgress[key] = value as int;
        });

        // Update lesson completion status
        for (var chapter in _chapters) {
          for (var lesson in chapter.lessons) {
            if (_lessonProgress[lesson.id] == 1) {
              final lessonIndex = chapter.lessons.indexWhere((l) => l.id == lesson.id);
              if (lessonIndex >= 0) {
                chapter.lessons[lessonIndex] = QuestLesson(
                  id: lesson.id,
                  title: lesson.title,
                  description: lesson.description,
                  lessonType: lesson.lessonType,
                  order: lesson.order,
                  isCompleted: true,
                  xpReward: lesson.xpReward,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading quest progress: $e');
    }
  }
}

