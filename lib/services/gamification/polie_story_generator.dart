import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/ai_chat_provider_groq.dart';
import '../../models/quest_model.dart';
import 'dart:convert';

/// Polie-powered story generator for "The Great Journey"
/// Generates dynamic, high-quality stories and lessons for each chapter
class PolieStoryGenerator {
  final GroqChatProvider _polieProvider;
  
  PolieStoryGenerator(this._polieProvider);
  
  /// Generate a complete story for a chapter using Polie
  Future<ChapterStory> generateChapterStory({
    required QuestChapter chapter,
    required String targetLanguage,
    String? userProgress, // Previous chapters completed
  }) async {
    try {
      // Set Polie to story mode (using tutor mode with special prompt)
      await _polieProvider.setMode(PolieMode.tutor);
      await _polieProvider.setLanguageDirection('English', targetLanguage);
      
      // Generate story prompt
      final storyPrompt = _buildStoryPrompt(chapter, targetLanguage, userProgress);
      
      // Generate story using Polie
      String fullStory = '';
      final storyStream = _polieProvider.sendMessageStream(storyPrompt);
      
      await for (final chunk in storyStream) {
        fullStory += chunk;
      }
      
      // Parse story and extract lessons
      final parsedStory = _parseStoryResponse(fullStory, chapter);
      
      return parsedStory;
    } catch (e) {
      debugPrint('Error generating story with Polie: $e');
      // Return fallback story
      return _getFallbackStory(chapter, targetLanguage);
    }
  }
  
  /// Generate lessons for a chapter using Polie
  Future<List<QuestLesson>> generateChapterLessons({
    required QuestChapter chapter,
    required String targetLanguage,
    required int lessonCount,
  }) async {
    try {
      await _polieProvider.setMode(PolieMode.tutor);
      await _polieProvider.setLanguageDirection('English', targetLanguage);
      
      final lessonPrompt = _buildLessonPrompt(chapter, targetLanguage, lessonCount);
      
      String fullResponse = '';
      final responseStream = _polieProvider.sendMessageStream(lessonPrompt);
      
      await for (final chunk in responseStream) {
        fullResponse += chunk;
      }
      
      // Parse lessons from response
      final lessons = _parseLessonsResponse(fullResponse, chapter, lessonCount);
      
      return lessons;
    } catch (e) {
      debugPrint('Error generating lessons with Polie: $e');
      return _getFallbackLessons(chapter, lessonCount);
    }
  }
  
  String _buildStoryPrompt(QuestChapter chapter, String language, String? progress) {
    return '''You are Polie, a master storyteller creating an engaging educational story for "The Great Journey" - an epic adventure across Africa.

CHAPTER: ${chapter.title}
CHAPTER NUMBER: ${chapter.chapterNumber}
TARGET LANGUAGE: $language
DESCRIPTION: ${chapter.description}

${progress != null ? 'USER PROGRESS: The user has completed: $progress' : 'This is the first chapter.'}

Create a captivating, culturally authentic story that:
1. Takes place in an African setting related to ${chapter.title}
2. Teaches vocabulary and phrases in $language naturally through dialogue and narrative
3. Is engaging and age-appropriate
4. Includes cultural context and traditions
5. Has a clear beginning, middle, and end
6. Is approximately 800-1200 words

Format your response as:
STORY:
[Your engaging story here, with $language phrases naturally integrated]

VOCABULARY:
- [word/phrase in $language] - [English translation] - [usage example]
- [repeat for key vocabulary]

CULTURAL NOTES:
- [Important cultural context]
- [Traditions or customs mentioned]

Return ONLY the story in this format. Make it immersive and educational.''';
  }
  
  String _buildLessonPrompt(QuestChapter chapter, String language, int count) {
    return '''You are Polie, creating interactive lessons for "The Great Journey" Chapter ${chapter.chapterNumber}: ${chapter.title}.

TARGET LANGUAGE: $language
NUMBER OF LESSONS: $count
CHAPTER THEME: ${chapter.description}

Create $count engaging, progressive lessons that:
1. Build vocabulary related to ${chapter.title}
2. Teach grammar concepts appropriate for the chapter
3. Include interactive exercises (translation, fill-in-the-blank, conversation)
4. Progress from beginner to intermediate
5. Are culturally relevant to African contexts

Format your response as JSON:
{
  "lessons": [
    {
      "order": 1,
      "title": "Lesson title",
      "description": "What students will learn",
      "content": {
        "vocabulary": ["word1", "word2"],
        "grammar": "Grammar concept",
        "exercises": [
          {"type": "translation", "question": "...", "answer": "..."},
          {"type": "fill_blank", "question": "...", "answer": "..."}
        ],
        "conversation": "Practice dialogue"
      },
      "xpReward": 50
    }
  ]
}

Return ONLY valid JSON.''';
  }
  
  ChapterStory _parseStoryResponse(String response, QuestChapter chapter) {
    try {
      // Extract story sections
      final storyMatch = RegExp(r'STORY:\s*(.+?)(?=VOCABULARY:|CULTURAL NOTES:|$)', dotAll: true).firstMatch(response);
      final vocabMatch = RegExp(r'VOCABULARY:\s*(.+?)(?=CULTURAL NOTES:|$)', dotAll: true).firstMatch(response);
      final culturalMatch = RegExp(r'CULTURAL NOTES:\s*(.+?)$', dotAll: true).firstMatch(response);
      
      final story = storyMatch?.group(1)?.trim() ?? response;
      final vocabulary = vocabMatch?.group(1)?.trim() ?? '';
      final culturalNotes = culturalMatch?.group(1)?.trim() ?? '';
      
      return ChapterStory(
        chapterId: chapter.id,
        title: chapter.title,
        story: story,
        vocabulary: _parseVocabulary(vocabulary),
        culturalNotes: culturalNotes,
        language: chapter.metadata?['language']?.toString() ?? 'English',
      );
    } catch (e) {
      debugPrint('Error parsing story: $e');
      return _getFallbackStory(chapter, 'English');
    }
  }
  
  List<VocabularyItem> _parseVocabulary(String vocabText) {
    final items = <VocabularyItem>[];
    final lines = vocabText.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty || !line.contains('-')) continue;
      
      final parts = line.split('-').map((p) => p.trim()).toList();
      if (parts.length >= 2) {
        items.add(VocabularyItem(
          word: parts[0],
          translation: parts.length > 1 ? parts[1] : '',
          example: parts.length > 2 ? parts[2] : '',
        ));
      }
    }
    
    return items;
  }
  
  List<QuestLesson> _parseLessonsResponse(String response, QuestChapter chapter, int count) {
    try {
      // Try to parse as JSON
      final jsonData = jsonDecode(response);
      final lessonsJson = jsonData['lessons'] as List? ?? [];
      
      return lessonsJson.asMap().entries.map((entry) {
        final lessonData = entry.value as Map<String, dynamic>;
        return QuestLesson(
          id: '${chapter.id}_lesson_${entry.key + 1}',
          title: lessonData['title']?.toString() ?? 'Lesson ${entry.key + 1}',
          description: lessonData['description']?.toString() ?? '',
          order: entry.key + 1,
          content: lessonData['content'],
          xpReward: (lessonData['xpReward'] as num?)?.toInt() ?? 50,
          isCompleted: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing lessons JSON: $e');
      // Fallback: parse from text format
      return _parseLessonsFromText(response, chapter, count);
    }
  }
  
  List<QuestLesson> _parseLessonsFromText(String text, QuestChapter chapter, int count) {
    final lessons = <QuestLesson>[];
    final lessonBlocks = text.split(RegExp(r'Lesson \d+:|LESSON \d+:', caseSensitive: false));
    
    for (int i = 1; i < lessonBlocks.length && lessons.length < count; i++) {
      final block = lessonBlocks[i].trim();
      if (block.isEmpty) continue;
      
      final titleMatch = RegExp(r'^(.+?)(?:\n|$)').firstMatch(block);
      final title = titleMatch?.group(1)?.trim() ?? 'Lesson ${lessons.length + 1}';
      
      lessons.add(QuestLesson(
        id: '${chapter.id}_lesson_${lessons.length + 1}',
        title: title,
        description: block.length > 100 ? block.substring(0, 100) + '...' : block,
        order: lessons.length + 1,
        content: {'text': block},
        xpReward: 50,
        isCompleted: false,
      ));
    }
    
    // Fill remaining slots with fallback lessons
    while (lessons.length < count) {
      lessons.add(_createFallbackLesson(chapter, lessons.length + 1));
    }
    
    return lessons;
  }
  
  ChapterStory _getFallbackStory(QuestChapter chapter, String language) {
    return ChapterStory(
      chapterId: chapter.id,
      title: chapter.title,
      story: 'Welcome to ${chapter.title}! This is an exciting chapter in your journey across Africa. '
          'As you progress, you will learn about the rich culture and language of this region. '
          'Complete the lessons to unlock the full story!',
      vocabulary: [],
      culturalNotes: 'This chapter explores the culture and traditions related to ${chapter.title}.',
      language: language,
    );
  }
  
  List<QuestLesson> _getFallbackLessons(QuestChapter chapter, int count) {
    return List.generate(count, (index) => _createFallbackLesson(chapter, index + 1));
  }
  
  QuestLesson _createFallbackLesson(QuestChapter chapter, int order) {
    return QuestLesson(
      id: '${chapter.id}_lesson_$order',
      title: 'Lesson $order: ${chapter.title} Basics',
      description: 'Learn the fundamentals of ${chapter.title}',
      order: order,
      content: {'type': 'interactive', 'exercises': []},
      xpReward: 50,
      isCompleted: false,
    );
  }
}

/// Story data structure for a chapter
class ChapterStory {
  final String chapterId;
  final String title;
  final String story;
  final List<VocabularyItem> vocabulary;
  final String culturalNotes;
  final String language;
  
  ChapterStory({
    required this.chapterId,
    required this.title,
    required this.story,
    required this.vocabulary,
    required this.culturalNotes,
    required this.language,
  });
}

/// Vocabulary item
class VocabularyItem {
  final String word;
  final String translation;
  final String example;
  
  VocabularyItem({
    required this.word,
    required this.translation,
    required this.example,
  });
}

