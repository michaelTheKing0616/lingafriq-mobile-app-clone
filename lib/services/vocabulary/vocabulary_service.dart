import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../providers/ai_chat_provider_groq.dart';

/// Vocabulary Word with full metadata
class VocabWord {
  final String id;
  final String word;
  final String language;
  final String translation;
  final String? pronunciation; // IPA or phonetic guide
  final String? audioUrl;
  final List<String> exampleSentences;
  final List<String> collocations; // Common word pairings
  final String? culturalNote;
  final String partOfSpeech;
  final int frequencyRank; // Higher = more common
  final List<String> tags;
  final DateTime addedAt;
  final DateTime? lastReviewed;
  
  // SRS fields
  double ease;
  int repetitions;
  int intervalDays;
  DateTime nextReview;
  int masteryLevel; // 0-5 (0=new, 5=mastered)

  VocabWord({
    required this.id,
    required this.word,
    required this.language,
    required this.translation,
    this.pronunciation,
    this.audioUrl,
    this.exampleSentences = const [],
    this.collocations = const [],
    this.culturalNote,
    this.partOfSpeech = 'unknown',
    this.frequencyRank = 1000,
    this.tags = const [],
    DateTime? addedAt,
    this.lastReviewed,
    this.ease = 2.5,
    this.repetitions = 0,
    this.intervalDays = 1,
    DateTime? nextReview,
    this.masteryLevel = 0,
  })  : addedAt = addedAt ?? DateTime.now(),
        nextReview = nextReview ?? DateTime.now();

  bool get isDueForReview => DateTime.now().isAfter(nextReview);
  
  bool get isMastered => masteryLevel >= 4;

  /// Update SRS using SM-2 algorithm
  void updateSRS(int quality) {
    // quality: 0-5 (0=complete blackout, 5=perfect recall)
    if (quality < 3) {
      // Failed: reset
      repetitions = 0;
      intervalDays = 1;
      masteryLevel = (masteryLevel - 1).clamp(0, 5);
    } else {
      // Passed
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * ease).round();
      }
      
      repetitions++;
      masteryLevel = (masteryLevel + 1).clamp(0, 5);
      
      // Update ease factor
      ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (ease < 1.3) ease = 1.3;
    }
    
    nextReview = DateTime.now().add(Duration(days: intervalDays));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'language': language,
    'translation': translation,
    'pronunciation': pronunciation,
    'audioUrl': audioUrl,
    'exampleSentences': exampleSentences,
    'collocations': collocations,
    'culturalNote': culturalNote,
    'partOfSpeech': partOfSpeech,
    'frequencyRank': frequencyRank,
    'tags': tags,
    'addedAt': addedAt.toIso8601String(),
    'lastReviewed': lastReviewed?.toIso8601String(),
    'ease': ease,
    'repetitions': repetitions,
    'intervalDays': intervalDays,
    'nextReview': nextReview.toIso8601String(),
    'masteryLevel': masteryLevel,
  };

  factory VocabWord.fromJson(Map<String, dynamic> json) => VocabWord(
    id: json['id'] as String,
    word: json['word'] as String,
    language: json['language'] as String,
    translation: json['translation'] as String,
    pronunciation: json['pronunciation'] as String?,
    audioUrl: json['audioUrl'] as String?,
    exampleSentences: List<String>.from(json['exampleSentences'] ?? []),
    collocations: List<String>.from(json['collocations'] ?? []),
    culturalNote: json['culturalNote'] as String?,
    partOfSpeech: json['partOfSpeech'] as String? ?? 'unknown',
    frequencyRank: json['frequencyRank'] as int? ?? 1000,
    tags: List<String>.from(json['tags'] ?? []),
    addedAt: DateTime.parse(json['addedAt'] as String),
    lastReviewed: json['lastReviewed'] != null 
        ? DateTime.parse(json['lastReviewed'] as String) 
        : null,
    ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
    repetitions: json['repetitions'] as int? ?? 0,
    intervalDays: json['intervalDays'] as int? ?? 1,
    nextReview: json['nextReview'] != null 
        ? DateTime.parse(json['nextReview'] as String)
        : DateTime.now(),
    masteryLevel: json['masteryLevel'] as int? ?? 0,
  );
}

/// Vocabulary Statistics
class VocabStats {
  final int totalWords;
  final int masteredWords;
  final int learningWords;
  final int dueForReview;
  final Map<String, int> wordsByLanguage;
  final Map<int, int> masteryDistribution; // level -> count
  
  VocabStats({
    required this.totalWords,
    required this.masteredWords,
    required this.learningWords,
    required this.dueForReview,
    required this.wordsByLanguage,
    required this.masteryDistribution,
  });
  
  double get masteryPercentage => 
      totalWords > 0 ? (masteredWords / totalWords * 100) : 0;
}

/// Provider for Vocabulary Service
final vocabularyServiceProvider = Provider<VocabularyService>((ref) {
  return VocabularyService(ref);
});

/// Comprehensive Vocabulary System
/// 
/// Features:
/// - Personalized word bank with SRS
/// - Context-aware examples
/// - Collocations and cultural notes
/// - AI-powered word enrichment
/// - Progress tracking
class VocabularyService {
  final Ref _ref;
  
  // In-memory word bank
  final Map<String, VocabWord> _wordBank = {};
  
  // Cache key
  static const String _cacheKey = 'vocabulary_word_bank';
  
  VocabularyService(this._ref) {
    _loadWordBank();
  }
  
  /// Get all words
  List<VocabWord> get allWords => _wordBank.values.toList();
  
  /// Get words for a specific language
  List<VocabWord> getWordsByLanguage(String language) {
    return _wordBank.values
        .where((w) => w.language.toLowerCase() == language.toLowerCase())
        .toList();
  }
  
  /// Get words due for review
  List<VocabWord> getDueForReview({String? language}) {
    var words = _wordBank.values.where((w) => w.isDueForReview);
    if (language != null) {
      words = words.where((w) => w.language.toLowerCase() == language.toLowerCase());
    }
    return words.toList()..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }
  
  /// Get recently added words
  List<VocabWord> getRecentlyAdded({int limit = 20, String? language}) {
    var words = _wordBank.values.toList();
    if (language != null) {
      words = words.where((w) => w.language.toLowerCase() == language.toLowerCase()).toList();
    }
    words.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return words.take(limit).toList();
  }
  
  /// Get mastered words
  List<VocabWord> getMasteredWords({String? language}) {
    var words = _wordBank.values.where((w) => w.isMastered);
    if (language != null) {
      words = words.where((w) => w.language.toLowerCase() == language.toLowerCase());
    }
    return words.toList();
  }
  
  /// Get vocabulary statistics
  VocabStats getStats({String? language}) {
    var words = _wordBank.values.toList();
    if (language != null) {
      words = words.where((w) => w.language.toLowerCase() == language.toLowerCase()).toList();
    }
    
    final masteryDist = <int, int>{};
    final langDist = <String, int>{};
    
    for (final word in words) {
      masteryDist[word.masteryLevel] = (masteryDist[word.masteryLevel] ?? 0) + 1;
      langDist[word.language] = (langDist[word.language] ?? 0) + 1;
    }
    
    return VocabStats(
      totalWords: words.length,
      masteredWords: words.where((w) => w.isMastered).length,
      learningWords: words.where((w) => !w.isMastered && w.repetitions > 0).length,
      dueForReview: words.where((w) => w.isDueForReview).length,
      wordsByLanguage: langDist,
      masteryDistribution: masteryDist,
    );
  }
  
  /// Add a word to the word bank
  Future<VocabWord> addWord({
    required String word,
    required String language,
    required String translation,
    String? pronunciation,
    List<String>? exampleSentences,
    List<String>? collocations,
    String? culturalNote,
    String? partOfSpeech,
    List<String>? tags,
    bool enrichWithAI = true,
  }) async {
    final id = '${language.toLowerCase()}_${word.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
    
    var vocabWord = VocabWord(
      id: id,
      word: word,
      language: language,
      translation: translation,
      pronunciation: pronunciation,
      exampleSentences: exampleSentences ?? [],
      collocations: collocations ?? [],
      culturalNote: culturalNote,
      partOfSpeech: partOfSpeech ?? 'unknown',
      tags: tags ?? [],
    );
    
    // Enrich with AI if requested
    if (enrichWithAI) {
      vocabWord = await _enrichWordWithAI(vocabWord);
    }
    
    _wordBank[id] = vocabWord;
    await _saveWordBank();
    await _syncToBackend();
    
    return vocabWord;
  }
  
  /// Enrich word with AI-generated content
  Future<VocabWord> _enrichWordWithAI(VocabWord word) async {
    try {
      final groqProvider = _ref.read(groqChatProvider.notifier);
      
      final prompt = '''For the ${word.language} word "${word.word}" meaning "${word.translation}":
1. Pronunciation guide (simple phonetics)
2. Two example sentences with translations
3. Common collocations (word pairings)
4. Any cultural notes or usage tips
5. Part of speech

Respond in JSON format:
{
  "pronunciation": "...",
  "examples": [{"native": "...", "translation": "..."}],
  "collocations": ["..."],
  "culturalNote": "...",
  "partOfSpeech": "noun/verb/etc"
}''';

      String response = '';
      await for (final chunk in groqProvider.sendMessageStream(prompt)) {
        response += chunk;
      }
      
      // Try to parse JSON from response
      try {
        final jsonStr = _extractJson(response);
        if (jsonStr != null) {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          
          return VocabWord(
            id: word.id,
            word: word.word,
            language: word.language,
            translation: word.translation,
            pronunciation: data['pronunciation'] as String? ?? word.pronunciation,
            exampleSentences: (data['examples'] as List?)
                ?.map((e) => "${e['native']} - ${e['translation']}")
                .toList()
                .cast<String>() ?? word.exampleSentences,
            collocations: List<String>.from(data['collocations'] ?? word.collocations),
            culturalNote: data['culturalNote'] as String? ?? word.culturalNote,
            partOfSpeech: data['partOfSpeech'] as String? ?? word.partOfSpeech,
            tags: word.tags,
            addedAt: word.addedAt,
            ease: word.ease,
            repetitions: word.repetitions,
            intervalDays: word.intervalDays,
            nextReview: word.nextReview,
            masteryLevel: word.masteryLevel,
          );
        }
      } catch (e) {
        debugPrint('Failed to parse AI enrichment: $e');
      }
    } catch (e) {
      debugPrint('AI enrichment error: $e');
    }
    
    return word;
  }
  
  String? _extractJson(String text) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    return jsonMatch?.group(0);
  }
  
  /// Update SRS after review
  Future<void> recordReview(String wordId, int quality) async {
    final word = _wordBank[wordId];
    if (word == null) return;
    
    word.updateSRS(quality);
    _wordBank[wordId] = word;
    
    await _saveWordBank();
    await _syncToBackend();
  }
  
  /// Remove a word
  Future<void> removeWord(String wordId) async {
    _wordBank.remove(wordId);
    await _saveWordBank();
    await _syncToBackend();
  }
  
  /// Search words
  List<VocabWord> searchWords(String query, {String? language}) {
    final lowerQuery = query.toLowerCase();
    var words = _wordBank.values.where((w) =>
        w.word.toLowerCase().contains(lowerQuery) ||
        w.translation.toLowerCase().contains(lowerQuery) ||
        w.tags.any((t) => t.toLowerCase().contains(lowerQuery)));
    
    if (language != null) {
      words = words.where((w) => w.language.toLowerCase() == language.toLowerCase());
    }
    
    return words.toList();
  }
  
  /// Generate flashcard quiz
  List<VocabWord> generateFlashcardSet({
    String? language,
    int count = 10,
    bool prioritizeDue = true,
  }) {
    var pool = _wordBank.values.toList();
    
    if (language != null) {
      pool = pool.where((w) => w.language.toLowerCase() == language.toLowerCase()).toList();
    }
    
    if (prioritizeDue) {
      // Sort by due date (overdue first, then by mastery level)
      pool.sort((a, b) {
        if (a.isDueForReview && !b.isDueForReview) return -1;
        if (!a.isDueForReview && b.isDueForReview) return 1;
        return a.masteryLevel.compareTo(b.masteryLevel);
      });
    } else {
      pool.shuffle();
    }
    
    return pool.take(count).toList();
  }
  
  /// Load word bank from storage
  Future<void> _loadWordBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        _wordBank.clear();
        
        data.forEach((key, value) {
          _wordBank[key] = VocabWord.fromJson(value as Map<String, dynamic>);
        });
        
        debugPrint('Loaded ${_wordBank.length} words from vocabulary bank');
      }
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
    }
  }
  
  /// Save word bank to storage
  Future<void> _saveWordBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      
      _wordBank.forEach((key, value) {
        data[key] = value.toJson();
      });
      
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving vocabulary: $e');
    }
  }
  
  /// Sync to backend
  Future<void> _syncToBackend() async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;
      
      // Sync vocabulary data
      // Note: This would need a corresponding backend endpoint
      // For now, we'll just save locally
      debugPrint('Vocabulary sync queued (${_wordBank.length} words)');
    } catch (e) {
      debugPrint('Vocabulary sync error: $e');
    }
  }
  
  /// Import words from lesson
  Future<void> importFromLesson(List<Map<String, dynamic>> words, String language) async {
    for (final wordData in words) {
      final word = wordData['word'] as String?;
      final translation = wordData['translation'] as String?;
      
      if (word != null && translation != null) {
        await addWord(
          word: word,
          language: language,
          translation: translation,
          enrichWithAI: false, // Don't AI-enrich bulk imports
        );
      }
    }
  }
}

