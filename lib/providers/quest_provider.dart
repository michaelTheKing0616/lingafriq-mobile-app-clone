import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest_model.dart';
import 'gamification_provider.dart';
import 'gamification_services_provider.dart';
import 'user_provider.dart';
import 'base_provider.dart';
import '../services/gamification/journey_service.dart';
import '../utils/progress_integration.dart';

final questProvider = NotifierProvider<QuestProvider, BaseProviderState>(() {
  return QuestProvider();
});

/// Quest provider for "The Great Journey" story mode
class QuestProvider extends Notifier<BaseProviderState> {
  static const String _campaignId = 'great_journey';

  List<QuestChapter> _chapters = QuestDefinitions.getGreatJourneyChapters();

  /// Local lesson completion map: lessonId -> completion flag (1 = completed)
  final Map<String, int> _lessonProgress = {};

  /// Mapping between local quest lessons and backend journey nodes
  /// key: quest lesson id (or node_key), value: journey_nodes._id
  final Map<String, String> _lessonToNodeId = {};

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

      // 1) Load campaign nodes so we can map node_key <-> lesson ids
      try {
        final nodes = await journeyService.getCampaignNodes(_campaignId);
        _lessonToNodeId.clear();
        for (final rawNode in nodes) {
          if (rawNode is! Map) continue;
          final node = Map<String, dynamic>.from(rawNode as Map);
          final nodeKey = node['node_key']?.toString();
          final id = node['_id']?.toString();
          if (nodeKey != null &&
              nodeKey.isNotEmpty &&
              id != null &&
              id.isNotEmpty) {
            _lessonToNodeId[nodeKey] = id;
          }
        }
      } catch (e) {
        debugPrint('Error loading journey nodes for campaign $_campaignId: $e');
      }

      // 2) Load user progress for this campaign and update local lessons
      try {
        final progress = await journeyService.getUserProgress(
          user.id.toString(),
          campaign: _campaignId,
        );

        var updated = false;

        for (final rawEntry in progress) {
          if (rawEntry is! Map) continue;
          final entry = Map<String, dynamic>.from(rawEntry as Map);
          final status = entry['status']?.toString();
          final node = entry['node_id'];

          Map<String, dynamic>? nodeMap;
          if (node is Map) {
            nodeMap = Map<String, dynamic>.from(node as Map);
          }

          final nodeKey = nodeMap?['node_key']?.toString();
          if (nodeKey == null || nodeKey.isEmpty) continue;

          // For now we treat node_key as the canonical lesson id in the quest
          if (status == 'completed') {
            _lessonProgress[nodeKey] = 1;
            updated = true;
          }
        }

        if (updated) {
          _applyLessonProgressToChapters();
          _updateUnlockedChapters();
          await _saveQuestProgress();
          state = state.copyWith();
        }
      } catch (e) {
        debugPrint('Error loading journey progress for campaign $_campaignId: $e');
      }
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

    // Try to sync this lesson with the backend journey graph
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final journeyService = ref.read(journeyServiceProvider);

        // Lazily load node mapping if needed
        if (_lessonToNodeId.isEmpty) {
          try {
            final nodes = await journeyService.getCampaignNodes(_campaignId);
            for (final rawNode in nodes) {
              if (rawNode is! Map) continue;
              final node = Map<String, dynamic>.from(rawNode as Map);
              final nodeKey = node['node_key']?.toString();
              final id = node['_id']?.toString();
              if (nodeKey != null &&
                  nodeKey.isNotEmpty &&
                  id != null &&
                  id.isNotEmpty) {
                _lessonToNodeId[nodeKey] = id;
              }
            }
          } catch (e) {
            debugPrint(
                'Error (lazy) loading journey nodes for campaign $_campaignId: $e');
          }
        }

        final nodeId = _lessonToNodeId[lessonId];
        if (nodeId != null) {
          // Best-effort: start and complete node. Backend is idempotent.
          try {
            await journeyService.startNode(_campaignId, nodeId);
          } catch (e) {
            debugPrint(
                'Error starting journey node for lesson $lessonId (node $nodeId): $e');
          }

          try {
            await journeyService.completeNode(
              _campaignId,
              nodeId,
              evidence: {
                'source': 'quest_lesson',
                'lessonId': lessonId,
              },
            );
          } catch (e) {
            debugPrint(
                'Error completing journey node for lesson $lessonId (node $nodeId): $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing journey node for lesson $lessonId: $e');
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

  /// Apply the in-memory [_lessonProgress] map to the quest chapters,
  /// so individual lessons and chapter completion flags reflect server/local state.
  void _applyLessonProgressToChapters() {
    try {
      for (var chapter in _chapters) {
        if (chapter.lessons.isEmpty) continue;

        final updatedLessons = <QuestLesson>[];
        for (final lesson in chapter.lessons) {
          final isCompleted = _lessonProgress[lesson.id] == 1;
          if (isCompleted && !lesson.isCompleted) {
            updatedLessons.add(
              QuestLesson(
                id: lesson.id,
                title: lesson.title,
                description: lesson.description,
                lessonType: lesson.lessonType,
                order: lesson.order,
                isCompleted: true,
                xpReward: lesson.xpReward,
              ),
            );
          } else {
            updatedLessons.add(lesson);
          }
        }

        final allCompleted =
            updatedLessons.isNotEmpty && updatedLessons.every((l) => l.isCompleted);

        final chapterIndex = _chapters.indexWhere((c) => c.id == chapter.id);
        if (chapterIndex >= 0) {
          _chapters[chapterIndex] = QuestChapter(
            id: chapter.id,
            title: chapter.title,
            description: chapter.description,
            icon: chapter.icon,
            chapterNumber: chapter.chapterNumber,
            lessons: updatedLessons,
            isUnlocked: chapter.isUnlocked,
            isCompleted: allCompleted || chapter.isCompleted,
            xpReward: chapter.xpReward,
            badgeReward: chapter.badgeReward,
            metadata: chapter.metadata,
          );
        }
      }
    } catch (e) {
      debugPrint('Error applying lesson progress to chapters: $e');
    }
  }

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

