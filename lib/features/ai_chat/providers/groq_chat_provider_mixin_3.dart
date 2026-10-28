part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatProviderMixin3 on GroqChatProviderMixin2 {
  Future<String> sendMessage(String userMessage, {String? systemPromptOverride}) async {
    String fullResponse = '';
    await for (final chunk in sendMessageStream(userMessage, systemPromptOverride: systemPromptOverride)) {
      fullResponse += chunk;
    }
    final corrected = DiacriticsEnforcer.enforceWithMetadata(
      fullResponse.trim(),
      _selectedLanguage,
      enableFuzzy: true,
      fuzzyThreshold: 0.75,
    );
    return corrected['text'] as String;
  }

  /// JSON-only completion: bypasses chat history, hybrid routing, and diacritics
  /// enforcement to return raw JSON from the LLM for structured mode UIs.
  Future<String> sendMessageForJson(
    String userMessage, {
    String? groqModelOverride,
  }) async {
    try {
      return await _gateway.completePolieJson(
        polieModeName: _mode.name,
        userMessage: userMessage,
        temperature: 0.3,
        maxTokens: _maxTokensForMode(),
        language: _targetLanguage,
        languageCode: SupportedLanguages.getLanguageCode(_targetLanguage),
        sourceLanguage: SupportedLanguages.getLanguageCode(_sourceLanguage),
        targetLanguage: SupportedLanguages.getLanguageCode(_targetLanguage),
      );
    } on AiGatewayException catch (e) {
      throw Exception(AiGatewayClient.userMessageFor(e, body: e.body));
    }
  }

  LearningEngineUpdate? get lastLearningUpdate => _lastLearningUpdate;
  int get lastXpEarned => _lastXpEarned;
  double get lastMasteryDelta => _lastMasteryDelta;

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
    // Explicit inclusive boundaries to match CEFR thresholds used across the app/tests.
    if (pct <= 19) return 'A1';
    if (pct <= 40) return 'A2';
    if (pct <= 59) return 'B1';
    if (pct <= 84) return 'B2';
    if (pct <= 89) return 'C1';
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
      final text = await _gateway.completePolieJson(
        polieModeName: 'tutor',
        userMessage: prompt,
        temperature: 0.0,
        maxTokens: 300,
        language: language,
      );
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
      logger.error('Grammar check error', tag: 'ai-chat', error: e);
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
    for (var i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
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
    final refWords = reference
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final hypWords = hypothesis
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // If there's no reference text, WER is defined as:
    // - 0.0 if both are empty
    // - 1.0 if hypothesis has content (max error)
    if (refWords.isEmpty) return hypWords.isEmpty ? 0.0 : 1.0;

    final errs = _wordErrorCount(refWords, hypWords);
    // Cap at 1.0 to avoid >1 values when hypothesis is much longer than reference.
    return (errs / refWords.length).clamp(0.0, 1.0);
  }

  // ----- Audio Transcription -----
  Future<String> transcribeAudio(Uint8List audioData) async {
    try {
      final response = await _gatewayDio.post(
        '/api/voice/stt/transcribe',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(audioData, filename: 'audio.wav'),
        }),
      );
      final data = response.data;
      final text = data is Map ? data['text']?.toString() ?? '' : '';
      return text.trim();
    } catch (e) {
      logger.error('Audio transcription error', tag: 'ai-chat', error: e);
      return '';
    }
  }

  // ----- Pronunciation Scoring -----
  Future<double> scorePronunciation(Uint8List audioData) async {
    try {
      final response = await _gatewayDio.post(
        '/api/voice/stt/transcribe',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(audioData, filename: 'audio.wav'),
        }),
      );
      final data = response.data;
      if (data is! Map) throw pronunciationUnavailable;
      final raw = data['confidence'];
      if (raw is! num) throw pronunciationUnavailable;
      final confidence = raw.toDouble();
      _recordSessionMetrics(pron: confidence);
      return confidence;
    } catch (e) {
      logger.error('Pronunciation scoring error', tag: 'ai-chat', error: e);
      throw pronunciationUnavailable;
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
        '/api/voice/stt/transcribe',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(userAudio, filename: 'speech.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(),
      );

      final userText = transResp.data['text']?.toString() ?? '';
      final wer = wordErrorRate(referenceText, userText);
      final rawConfidence = transResp.data['confidence'];
      if (rawConfidence is! num) throw pronunciationUnavailable;
      final pronunciationScore = rawConfidence.toDouble();

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
      logger.error('Shadowing exercise error', tag: 'ai-chat', error: e);
      if (e is LingAfriqFailure) rethrow;
      throw pronunciationUnavailable;
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
      final text = await _gateway.completePolieJson(
        polieModeName: 'tutor',
        userMessage: prompt,
        temperature: 0.3,
        maxTokens: 500,
        language: language,
      );
      return jsonDecode(text);
    } catch (e) {
      logger.error('Listening passage generation error', tag: 'ai-chat', error: e);
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
      final raw = await _gateway.completePolieJson(
        polieModeName: 'tutor',
        userMessage: prompt,
        temperature: 0.0,
        maxTokens: 150,
      );
      final json = jsonDecode(raw);
      final score = (json['score'] as num).toDouble();
      _recordSessionMetrics(comp: score);
      return score;
    } catch (e) {
      logger.error('Answer evaluation error', tag: 'ai-chat', error: e);
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
      final text = await _gateway.completePolieJson(
        polieModeName: 'tutor',
        userMessage: prompt,
        temperature: 0.2,
        maxTokens: 1500,
        language: language,
      );
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      logger.error('Curriculum generation error', tag: 'ai-chat', error: e);
      return {
        'language': language,
        'level': targetCEFR,
        'weeks': [],
      };
    }
  }

  // ----- Chat Management -----
}
