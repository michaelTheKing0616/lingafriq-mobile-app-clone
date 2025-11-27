import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';

/// Comprehensive AI Chat Provider using Groq API with Aya 8B
/// Features:
/// - Streaming responses
/// - Adaptive tutor mode
/// - Spaced repetition system (SRS)
/// - CEFR level tracking
/// - Grammar error detection
/// - Pronunciation scoring
/// - Speech shadowing
/// - Listening comprehension
/// - Curriculum generation
/// 
/// To use:
/// 1. Get a free Groq API key: https://console.groq.com/
/// 2. Replace YOUR_GROQ_API_KEY below or use environment variable
/// 3. The API is FREE with unlimited usage (no credit card required)

final groqChatProvider = NotifierProvider<GroqChatProvider, BaseProviderState>(() {
  return GroqChatProvider();
});

// Re-export ChatMessage class
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

// Word Memory for SRS
class WordMemory {
  int strength = 0; // 0-5
  DateTime nextReview = DateTime.now();
  int attempts = 0;
  int successes = 0;

  WordMemory({
    this.strength = 0,
    DateTime? nextReview,
    this.attempts = 0,
    this.successes = 0,
  }) : nextReview = nextReview ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'nextReview': nextReview.toIso8601String(),
        'attempts': attempts,
        'successes': successes,
      };

  factory WordMemory.fromJson(Map<String, dynamic> json) => WordMemory(
        strength: json['strength'] ?? 0,
        nextReview: DateTime.parse(json['nextReview']),
        attempts: json['attempts'] ?? 0,
        successes: json['successes'] ?? 0,
      );
}

// CEFR Info
class CEFRInfo {
  String level; // A1, A2, B1, B2, C1, C2
  double score; // 0-100
  DateTime lastUpdated;

  CEFRInfo({
    required this.level,
    required this.score,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'level': level,
        'score': score,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory CEFRInfo.fromJson(Map<String, dynamic> json) => CEFRInfo(
        level: json['level'] ?? 'A1',
        score: (json['score'] ?? 0.0).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

// Grammar Feedback
class GrammarFeedback {
  final String corrected;
  final List<Map<String, String>> errors;
  final double score; // 0.0-1.0

  GrammarFeedback({
    required this.corrected,
    required this.errors,
    required this.score,
  });
}

// Conversation Turn
enum ConversationTurn { user, ai }

class GroqChatProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();

  // API Configuration
  static String get _groqApiKey {
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY');
    return envKey;
  }

  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // Groq model names to try in order
  // Note: If Aya 8B is not available on Groq, it will try alternatives
  static const List<String> _modelNames = [
    'aya-8b',                    // Primary: Aya 8B model (if available)
    'cohere/aya-8b',             // Alternative format
    'llama-3.1-8b-instant',      // Fallback: Fast Llama model
    'llama-3.1-70b-versatile',  // Fallback: More capable model
  ];
  static String _modelName = _modelNames[0];

  // Language and System Prompt
  String _selectedLanguage = 'Yoruba';
  String? _systemPrompt;

  // Tutor & Adaptive Fields
  bool _tutorMode = true;
  bool _adaptive = true;
  int _difficulty = 1; // 1-5
  int _successStreak = 0;
  int _failureStreak = 0;
  int _turnIndex = 0;

  // Spaced Repetition
  final Map<String, WordMemory> _memory = {};

  // CEFR Tracking
  CEFRInfo _cefrInfo = CEFRInfo(level: 'A1', score: 0.0);

  // Metrics for averaging
  final List<double> _recentGrammarScores = [];
  final List<double> _recentPronScores = [];
  final List<double> _recentCompScores = [];
  final List<double> _recentVocabScores = [];

  // Conversational turn-taking
  ConversationTurn _turn = ConversationTurn.user;
  bool _userInterrupt = false;
  VoidCallback? _currentStreamCancel;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get selectedLanguage => _selectedLanguage;
  bool get hasMessages => _messages.isNotEmpty;
  bool get isBusy => state.isLoading;
  CEFRInfo get cefrInfo => _cefrInfo;
  ConversationTurn get turn => _turn;
  bool get tutorMode => _tutorMode;
  int get difficulty => _difficulty;

  @override
  BaseProviderState build() {
    _loadChatHistory();
    _loadSRSMemory();
    _loadCEFRInfo();
    _initializeSystemPrompt();
    return BaseProviderState();
  }

  void _initializeSystemPrompt() {
    _systemPrompt = '''You are LingAfriq Polyglot, an expert AI language learning tutor specializing in African languages. 
You help users learn and practice various African languages including:
- Swahili (Kiswahili)
- Yoruba
- Igbo
- Hausa
- Zulu (IsiZulu)
- Xhosa
- Amharic
- Pidgin English (Nigerian Pidgin)
- Twi
- Afrikaans
- And many other African languages

You can:
- Help users practice conversations
- Explain grammar and vocabulary
- Provide translations
- Create learning exercises
- Answer questions about African cultures and languages
- Engage in natural conversations in the selected language

Always be encouraging, patient, and culturally sensitive. Respond naturally in the language the user is learning, or in the language they're using to communicate with you.

When the user is practicing, end your responses with a question or task to keep the conversation engaging and educational.''';
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    _initializeSystemPrompt();
    state = state.copyWith();
  }

  void setTutorMode(bool enabled) {
    _tutorMode = enabled;
    state = state.copyWith();
  }

  void interruptAI() {
    _userInterrupt = true;
    _currentStreamCancel?.call();
  }

  // ----- Streaming Chat Message -----
  Stream<String> sendMessageStream(String userMessage) async* {
    if (userMessage.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    _currentStreamCancel?.call();
    final cancelToken = CancelToken();
    _currentStreamCancel = () => cancelToken.cancel();

    final userMsg = ChatMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    state = state.copyWith();
    await _saveChatHistory();

    state = state.copyWith(isLoading: true);

    int retryCount = 0;
    int modelIndex = 0;

    while (true) {
      try {
        _turn = ConversationTurn.ai;
        _userInterrupt = false;

        if (_groqApiKey == 'YOUR_GROQ_API_KEY' || _groqApiKey.isEmpty) {
          throw Exception('AI Chat is not configured. Please set your Groq API key.');
        }

        // Try different model names if previous one failed
        final currentModel = _modelNames[modelIndex];

        final response = await _dio.post(
          _groqUrl,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            responseType: ResponseType.stream,
          ),
          data: {
            "model": currentModel,
            "messages": [
              {"role": "system", "content": _systemPrompt ?? ''},
              ..._messages.map((m) => {
                    "role": m.role,
                    "content": m.content,
                  }),
            ],
            "temperature": 0.7,
            "max_tokens": 500,
            "stream": true,
          },
        );

        String buffer = "";
        String output = "";

        await for (final chunk in response.data.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())) {
          if (_userInterrupt) {
            state = state.copyWith(isLoading: false);
            return;
          }

          if (chunk.startsWith("data: ")) {
            final jsonStr = chunk.substring(6).trim();
            if (jsonStr == "[DONE]") break;

            try {
              final jsonData = jsonDecode(jsonStr);
              final delta = jsonData["choices"]?[0]?["delta"]?["content"];

              if (delta != null) {
                buffer += delta;

                final last = buffer.trim().isNotEmpty
                    ? buffer.trim()[buffer.trim().length - 1]
                    : '';

                // Language-aware sentence segmentation
                // Support for African language punctuation patterns
                final isSentenceEnd = [".", "!", "?", "…", "\n"].contains(last);
                
                // Check for language-specific patterns (Yoruba, Swahili, etc.)
                final hasLanguagePause = buffer.contains(":") || 
                    buffer.contains(";") ||
                    (buffer.length > 3 && buffer.substring(buffer.length - 3).contains(" "));

                final isTurnHandOff = buffer.toLowerCase().contains("your turn") ||
                    buffer.toLowerCase().contains("now you try") ||
                    buffer.toLowerCase().contains("ask me") ||
                    buffer.trim().endsWith("?");

                // Smart buffering: emit on sentence boundaries or long pauses
                if (isSentenceEnd || hasLanguagePause || buffer.length > 60) {
                  output += buffer;
                  yield buffer;
                  buffer = "";

                  if (isTurnHandOff) {
                    _turn = ConversationTurn.user;
                    _currentStreamCancel?.call();
                    break;
                  }
                }
              }
            } catch (_) {
              // Ignore malformed JSON chunks
            }
          }
        }

        // Flush remaining buffer
        if (buffer.isNotEmpty) {
          yield buffer;
          output += buffer;
        }

        // Evaluate user performance if tutor mode
        if (_tutorMode && _messages.length >= 2) {
          final lastUser = _messages[_messages.length - 2].content;
          _evaluateUser(lastUser, output);
        }

        // Add tutor prompt if enabled
        if (_tutorMode && !_userInterrupt) {
          final reviewWord = _dueReview();
          if (reviewWord != null) {
            final tutorCue = "Review time! Translate '$reviewWord' to $_selectedLanguage.";
            output += "\n\n$tutorCue";
            yield "\n\n$tutorCue";
          } else {
            final tutorCue = _adaptiveTutorPrompt(_selectedLanguage);
            if (!output.trim().endsWith("?") &&
                !output.toLowerCase().contains("your turn") &&
                !output.toLowerCase().contains("now you try")) {
              output += "\n\n$tutorCue";
              yield "\n\n$tutorCue";
            }
          }
        }

        _turn = ConversationTurn.user;
        state = state.copyWith(isLoading: false);

        final assistantMsg = ChatMessage(
          role: 'assistant',
          content: output.trim(),
          timestamp: DateTime.now(),
        );

        _messages.add(assistantMsg);
        state = state.copyWith();
        await _saveChatHistory();

        return;
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) {
          state = state.copyWith(isLoading: false);
          return;
        }

        // Try next model name if we get a 404 (model not found)
        if (e is DioException && e.response?.statusCode == 404) {
          if (modelIndex < _modelNames.length - 1) {
            modelIndex++;
            _modelName = _modelNames[modelIndex];
            if (kDebugMode) {
              debugPrint('Model ${_modelNames[modelIndex - 1]} not found, trying ${_modelName}');
            }
            continue; // Try with next model
          }
        }

        if (retryCount < 1) {
          retryCount++;
          continue;
        }

        state = state.copyWith(isLoading: false);

        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            throw Exception('Invalid API key. Please check your Groq API key.');
          } else if (e.response?.statusCode == 404) {
            throw Exception('Model not found. Tried: ${_modelNames.join(", ")}. Please check Groq API documentation for available models.');
          } else if (e.response?.statusCode == 429) {
            throw Exception('Rate limit exceeded. Please try again later.');
          }
        }

        throw Exception('Failed to send message: ${e.toString()}');
      }
    }
  }

  // Non-streaming version (fallback)
  Future<String> sendMessage(String userMessage) async {
    String fullResponse = '';
    await for (final chunk in sendMessageStream(userMessage)) {
      fullResponse += chunk;
    }
    return fullResponse;
  }

  // ----- Tutor Turn & Adaptive Prompt -----
  String _adaptiveTutorPrompt(String language) {
    final stages = [
      "Translate to $language:",
      "Say this in $language:",
      "Respond in $language:",
      "Translate a longer sentence to $language:",
      "Create a sentence using two words in $language:"
    ];
    final prompt = stages[_turnIndex % stages.length];
    _turnIndex++;
    return prompt;
  }

  void _evaluateUser(String user, String assistant) {
    final correct = assistant.toLowerCase().contains('correct') ||
        assistant.toLowerCase().contains('nice') ||
        assistant.toLowerCase().contains('good job') ||
        assistant.toLowerCase().contains('yes') ||
        assistant.toLowerCase().contains('excellent');

    if (correct) {
      _successStreak++;
      _failureStreak = 0;
    } else {
      _failureStreak++;
      _successStreak = 0;
    }

    if (_successStreak >= 3 && _difficulty < 5) {
      _difficulty++;
      _successStreak = 0;
    }

    if (_failureStreak >= 2 && _difficulty > 1) {
      _difficulty--;
      _failureStreak = 0;
    }
  }

  // ----- Word Memory (SRS) -----
  void _updateSRS(String word, bool correct) {
    final entry = _memory[word] ?? WordMemory();
    entry.attempts++;

    if (correct) {
      entry.successes++;
      entry.strength = (entry.strength + 1).clamp(0, 5);
    } else {
      entry.strength = (entry.strength - 1).clamp(0, 5);
    }

    final intervals = [
      const Duration(hours: 6),
      const Duration(days: 1),
      const Duration(days: 3),
      const Duration(days: 7),
      const Duration(days: 30),
      const Duration(days: 90),
    ];

    entry.nextReview = DateTime.now().add(intervals[entry.strength.clamp(0, 5)]);
    _memory[word] = entry;
    _saveSRSMemory();
  }

  String? _dueReview() {
    final now = DateTime.now();
    for (final entry in _memory.entries) {
      if (entry.value.nextReview.isBefore(now)) {
        return entry.key;
      }
    }
    return null;
  }

  // ----- CEFR Tracking -----
  void _recordSessionMetrics({
    double grammar = 0.0,
    double pron = 0.0,
    double comp = 0.0,
    double vocab = 0.0,
  }) {
    _recentGrammarScores.add(grammar);
    if (_recentGrammarScores.length > 50) _recentGrammarScores.removeAt(0);

    _recentPronScores.add(pron);
    if (_recentPronScores.length > 50) _recentPronScores.removeAt(0);

    _recentCompScores.add(comp);
    if (_recentCompScores.length > 50) _recentCompScores.removeAt(0);

    _recentVocabScores.add(vocab);
    if (_recentVocabScores.length > 50) _recentVocabScores.removeAt(0);

    updateCEFR();
  }

  double _average(List<double> scores) =>
      scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

  Future<void> updateCEFR() async {
    final composite = (_average(_recentGrammarScores) * 0.3 +
            _average(_recentPronScores) * 0.2 +
            _average(_recentCompScores) * 0.3 +
            _average(_recentVocabScores) * 0.2)
        .clamp(0.0, 1.0);
    final pct = (composite * 100).roundToDouble();
    final newLevel = _mapScoreToCEFR(pct);
    _cefrInfo = CEFRInfo(level: newLevel, score: pct);
    _saveCEFRInfo();
  }

  // Public for testing
  String mapScoreToCEFR(double pct) {
    if (pct < 20) return 'A1';
    if (pct < 40) return 'A2';
    if (pct < 55) return 'B1';
    if (pct < 70) return 'B2';
    if (pct < 85) return 'C1';
    return 'C2';
  }

  String _mapScoreToCEFR(double pct) => mapScoreToCEFR(pct);

  // ----- Grammar Error Detection -----
  Future<GrammarFeedback> grammarCheck(String language, String userText) async {
    final prompt = '''
You are a concise grammar assistant for $language. 
Analyze the user's sentence and return a strict JSON object with three keys:
{
  "corrected": "<corrected sentence>",
  "errors": [{"type":"<grammar|vocabulary|spelling|word_order>", "original":"...", "correction":"...", "explanation":"brief explanation (max 20 words)"}],
  "score": <0.0-1.0> // 1.0 perfect
}
User sentence: """$userText"""
Return only valid JSON.
''';

    try {
      final response = await _dio.post(
        _groqUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a JSON-output grammar checker."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.0,
          "max_tokens": 300,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Grammar API error: ${response.data}');
      }

      final text = response.data['choices'][0]['message']['content']?.toString() ?? '';
      final json = jsonDecode(text);

      final corrected = json['corrected'] as String? ?? userText;
      final errorsRaw = (json['errors'] as List?) ?? [];
      final errors = errorsRaw
          .map<Map<String, String>>((e) => {
                'type': e['type'] ?? '',
                'original': e['original'] ?? '',
                'correction': e['correction'] ?? '',
                'explanation': e['explanation'] ?? '',
              })
          .toList();
      final score = (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0;

      _recordSessionMetrics(grammar: score);

      return GrammarFeedback(corrected: corrected, errors: errors, score: score);
    } catch (e) {
      debugPrint('Grammar check error: $e');
      return GrammarFeedback(
        corrected: userText,
        errors: [],
        score: 0.5,
      );
    }
  }

  // ----- Word Error Rate (WER) Calculation -----
  int _wordErrorCount(List<String> ref, List<String> hyp) {
    final n = ref.length;
    final m = hyp.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) dp[i][0] = i;
    for (var j = 0; j <= m; j++) dp[0][j] = j;
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + (ref[i - 1] == hyp[j - 1] ? 0 : 1)
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[n][m];
  }

  double wordErrorRate(String reference, String hypothesis) {
    final refWords = reference.trim().toLowerCase().split(RegExp(r'\s+'));
    final hypWords = hypothesis.trim().toLowerCase().split(RegExp(r'\s+'));
    if (refWords.isEmpty) return 1.0;
    final errs = _wordErrorCount(refWords, hypWords);
    return errs / refWords.length;
  }

  // ----- Pronunciation Scoring -----
  Future<double> scorePronunciation(Uint8List audioData) async {
    try {
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(audioData, filename: 'audio.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $_groqApiKey",
          },
        ),
      );

      final confidence = (response.data['confidence'] ?? 0.5) as double? ?? 0.5;
      _recordSessionMetrics(pron: confidence);
      return confidence;
    } catch (e) {
      debugPrint('Pronunciation scoring error: $e');
      return 0.5;
    }
  }

  String pronunciationFeedback(double score) {
    if (score > 0.85) return "Excellent pronunciation! 👏";
    if (score > 0.65) return "Good! Try to be clearer on some sounds.";
    if (score > 0.45) return "Almost! Focus on the vowel sounds.";
    return "Let's practice pronunciation. Listen and repeat after me:";
  }

  // ----- Speech Shadowing Exercise -----
  Future<Map<String, dynamic>> shadowingExercise(
      Uint8List userAudio, String referenceText) async {
    try {
      // Transcribe user audio using Groq Whisper
      final transResp = await _dio.post(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(userAudio, filename: 'speech.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final userText = transResp.data['text']?.toString() ?? '';
      final wer = wordErrorRate(referenceText, userText);
      final pronunciationScore = (transResp.data['confidence'] ?? 0.6) as double? ?? 0.6;

      final score = ((1 - wer) * 0.6 + pronunciationScore * 0.4).clamp(0.0, 1.0);

      final grammar = await grammarCheck(_selectedLanguage, userText);

      _recordSessionMetrics(pron: score, grammar: grammar.score);

      return {
        'score': score,
        'wer': wer,
        'userText': userText,
        'pronunciationScore': pronunciationScore,
        'corrections': grammar.errors,
      };
    } catch (e) {
      debugPrint('Shadowing exercise error: $e');
      return {
        'score': 0.0,
        'wer': 1.0,
        'userText': '',
        'pronunciationScore': 0.0,
        'corrections': [],
      };
    }
  }

  // ----- Listening Comprehension -----
  Future<Map<String, dynamic>> generateListeningPassage(
      String language, int difficulty) async {
    final prompt = '''
You are to create a short listening comprehension passage in $language (level difficulty $difficulty). 
Return JSON:
{
  "passage": "<text to be spoken>",
  "questions": [
    {"id":1, "type":"mcq", "question":"...", "options":["a","b","c","d"], "answer":"b"},
    {"id":2, "type":"open", "question":"...", "answer":"expected short answer"}
  ]
}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a JSON-output listening generator."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "max_tokens": 500,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final text = resp.data['choices'][0]['message']['content'];
      return jsonDecode(text);
    } catch (e) {
      debugPrint('Listening passage generation error: $e');
      return {
        'passage': '',
        'questions': [],
      };
    }
  }

  Future<double> evaluateOpenAnswer(
      String question, String expected, String userAnswer) async {
    final prompt = '''
You are a grader. Given the question: "$question"
Expected short answer: "$expected"
User answer: "$userAnswer"

Return a JSON: {"score": <0.0-1.0>, "feedback": "short feedback (max 25 words)"}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.0,
          "max_tokens": 150
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final json = jsonDecode(resp.data['choices'][0]['message']['content']);
      final score = (json['score'] as num).toDouble();
      _recordSessionMetrics(comp: score);
      return score;
    } catch (e) {
      debugPrint('Answer evaluation error: $e');
      return 0.5;
    }
  }

  // ----- Curriculum Generation -----
  Future<Map<String, dynamic>> generateCurriculum({
    required String language,
    required String targetCEFR,
    int weeks = 8,
  }) async {
    final prompt = '''
Create a $weeks-week curriculum for teaching $language to reach CEFR $targetCEFR.
Return strict JSON:
{
  "language":"$language",
  "level":"$targetCEFR",
  "weeks":[
    {"week":1, "lessons":[ {"title":"", "objectives":["..."], "vocab":["..."], "exercises":[{"type":"shadow","prompt":"..."}]} ]}
  ]
}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a curriculum generator that outputs strict JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.2,
          "max_tokens": 1500,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final text = resp.data['choices'][0]['message']['content'];
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Curriculum generation error: $e');
      return {
        'language': language,
        'level': targetCEFR,
        'weeks': [],
      };
    }
  }

  // ----- Chat Management -----
  Future<void> clearChat() async {
    _messages.clear();
    state = state.copyWith();
    await _saveChatHistory();
  }

  // ----- Persistence -----
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString('ai_chat_history_groq', jsonEncode(messagesJson));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('ai_chat_history_groq');
      if (historyJson != null) {
        final List<dynamic> messagesList = jsonDecode(historyJson);
        _messages.clear();
        _messages.addAll(
          messagesList.map((json) => ChatMessage.fromJson(json)),
        );
        state = state.copyWith();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveSRSMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = _memory.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('srs_memory', jsonEncode(memoryJson));
    } catch (e) {
      debugPrint('Error saving SRS memory: $e');
    }
  }

  Future<void> _loadSRSMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = prefs.getString('srs_memory');
      if (memoryJson != null) {
        final Map<String, dynamic> memoryMap = jsonDecode(memoryJson);
        _memory.clear();
        memoryMap.forEach((key, value) {
          _memory[key] = WordMemory.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading SRS memory: $e');
    }
  }

  Future<void> _saveCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cefr_info', jsonEncode(_cefrInfo.toJson()));
    } catch (e) {
      debugPrint('Error saving CEFR info: $e');
    }
  }

  Future<void> _loadCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cefrJson = prefs.getString('cefr_info');
      if (cefrJson != null) {
        _cefrInfo = CEFRInfo.fromJson(jsonDecode(cefrJson));
      }
    } catch (e) {
      debugPrint('Error loading CEFR info: $e');
    }
  }
}

