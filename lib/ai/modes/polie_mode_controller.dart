import 'package:dio/dio.dart';

import 'package:lingafriq/ai/pedagogy/error_classifier.dart' show PhonemeResult;
import 'package:lingafriq/ai/validation/response_validator.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/scheduling/review_scheduler.dart';
import 'mode_prompts.dart';
import 'roleplay_engine.dart';

/// Unified controller for all 6 Polie chat modes.
///
/// This is the bridge between the existing GroqChatProvider
/// and the learning engine. It routes each mode through
/// the appropriate pedagogical constraints and ensures
/// every interaction updates the learner model.
///
/// Modes:
/// 1. Tutor — adaptive skill practice with error diagnosis
/// 2. Pronunciation — phoneme-level scoring with heatmaps
/// 3. Roleplay — branching conversation with consequences
/// 4. Grammar — error-driven rule explanations
/// 5. Review — spaced recall with stop conditions
/// 6. Translation — pedagogical with justification
class PolieModeController {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;
  final RoleplayEngine _roleplayEngine;
  final ReviewScheduler _reviewScheduler;

  PolieModeController({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
    LearnerModelService? learnerModel,
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model,
        _learnerModel = learnerModel ?? LearnerModelService.instance,
        _roleplayEngine = RoleplayEngine(
          dio: dio,
          apiKey: apiKey,
          apiUrl: apiUrl,
          model: model,
          learnerModel: learnerModel,
        ),
        _reviewScheduler = ReviewScheduler(learnerModel: learnerModel);

  /// Processes a message in the given mode.
  ///
  /// This is the SINGLE entry point for all Polie interactions.
  /// It ensures every mode:
  /// - Reads the learner model before responding
  /// - Validates AI output against the schema
  /// - Updates the learner model after the interaction
  Future<PolieModeResponse> processMessage({
    required PolieModeName mode,
    required String learnerId,
    required String languageCode,
    required String message,
    required String targetSkillId,
    List<PhonemeResult>? phonemeResults,
    double responseTimeSeconds = 0,
  }) async {
    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: targetSkillId,
    );

    switch (mode) {
      case PolieModeName.tutor:
        return _handleTutor(state, learnerId, languageCode, message, targetSkillId, responseTimeSeconds);
      case PolieModeName.pronunciation:
        return _handlePronunciation(state, learnerId, languageCode, message, targetSkillId, phonemeResults, responseTimeSeconds);
      case PolieModeName.roleplay:
        return _handleRoleplay(state, learnerId, languageCode, message, responseTimeSeconds);
      case PolieModeName.grammar:
        return _handleGrammar(state, learnerId, languageCode, message, targetSkillId, responseTimeSeconds);
      case PolieModeName.review:
        return _handleReview(state, learnerId, languageCode, message, targetSkillId, responseTimeSeconds);
      case PolieModeName.translation:
        return _handleTranslation(state, learnerId, languageCode, message, targetSkillId, responseTimeSeconds);
    }
  }

  // ─── Mode handlers ─────────────────────────────────────────────────

  Future<PolieModeResponse> _handleTutor(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    String skillId,
    double responseTime,
  ) async {
    final prompts = ModePrompts.forMode(
      mode: PolieModeName.tutor,
      state: state,
      targetLanguage: language,
    );
    prompts.add({'role': 'user', 'content': message});

    final raw = await _callAI(prompts);
    final validated = ResponseValidator.validateTutorFeedback(raw);

    // Update learner model
    final errors = (validated['detectedErrors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: validated['wasCorrect'] as bool,
      errorTypeIds: errors,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.tutor,
      rawJson: validated,
      displayText: _buildTutorDisplay(validated),
      wasCorrect: validated['wasCorrect'] as bool,
      detectedErrors: errors,
      nextPrompt: validated['nextPrompt'] as String?,
    );
  }

  Future<PolieModeResponse> _handlePronunciation(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    String skillId,
    List<PhonemeResult>? phonemes,
    double responseTime,
  ) async {
    final phonemeContext = phonemes != null
        ? '\nPhoneme results: ${phonemes.map((p) => '${p.phoneme}(${p.confidence.toStringAsFixed(2)})').join(', ')}'
        : '';

    final prompts = ModePrompts.forMode(
      mode: PolieModeName.pronunciation,
      state: state,
      targetLanguage: language,
    );
    prompts.add({
      'role': 'user',
      'content': 'Learner said: "$message"$phonemeContext',
    });

    final raw = await _callAI(prompts);
    final validated = ResponseValidator.validateTutorFeedback(raw);

    final errors = (validated['detectedErrors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: validated['wasCorrect'] as bool,
      errorTypeIds: errors,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.pronunciation,
      rawJson: validated,
      displayText: _buildPronunciationDisplay(validated),
      wasCorrect: validated['wasCorrect'] as bool,
      detectedErrors: errors,
      drillSuggestion: validated['drillSuggestion'] as String?,
    );
  }

  Future<PolieModeResponse> _handleRoleplay(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    double responseTime,
  ) async {
    // Delegate to the roleplay engine
    final turn = await _roleplayEngine.processResponse(
      learnerId: learnerId,
      learnerResponse: message,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.roleplay,
      rawJson: {
        'dialogue': turn.dialogue,
        'nextPrompt': turn.nextPrompt,
        'correction': turn.correction,
        'detectedErrors': turn.detectedErrors,
        'scenarioComplete': turn.scenarioComplete,
      },
      displayText: turn.correction != null
          ? '${turn.correction}\n\n${turn.dialogue}'
          : turn.dialogue,
      wasCorrect: turn.detectedErrors.isEmpty,
      detectedErrors: turn.detectedErrors,
      nextPrompt: turn.nextPrompt,
      isComplete: turn.scenarioComplete,
    );
  }

  Future<PolieModeResponse> _handleGrammar(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    String skillId,
    double responseTime,
  ) async {
    final prompts = ModePrompts.forMode(
      mode: PolieModeName.grammar,
      state: state,
      targetLanguage: language,
    );
    prompts.add({'role': 'user', 'content': 'Learner wrote: "$message"'});

    final raw = await _callAI(prompts);
    final validated = ResponseValidator.validateGrammarResponse(raw);

    final errors = (validated['detectedErrors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: validated['isCorrect'] as bool? ?? true,
      errorTypeIds: errors,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.grammar,
      rawJson: validated,
      displayText: _buildGrammarDisplay(validated),
      wasCorrect: validated['isCorrect'] as bool? ?? true,
      detectedErrors: errors,
      nextPrompt: validated['practicePrompt'] as String?,
    );
  }

  Future<PolieModeResponse> _handleReview(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    String skillId,
    double responseTime,
  ) async {
    final prompts = ModePrompts.forMode(
      mode: PolieModeName.review,
      state: state,
      targetLanguage: language,
    );
    prompts.add({'role': 'user', 'content': message});

    final raw = await _callAI(prompts);
    final validated = ResponseValidator.validateReviewResponse(raw);

    final wasCorrect = validated['wasCorrect'] as bool;
    final shouldStop = validated['shouldStop'] as bool? ?? false;

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: wasCorrect,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.review,
      rawJson: validated,
      displayText: _buildReviewDisplay(validated),
      wasCorrect: wasCorrect,
      detectedErrors: [],
      isComplete: shouldStop,
      hint: validated['hint'] as String?,
    );
  }

  Future<PolieModeResponse> _handleTranslation(
    LearnerSkillState state,
    String learnerId,
    String language,
    String message,
    String skillId,
    double responseTime,
  ) async {
    final prompts = ModePrompts.forMode(
      mode: PolieModeName.translation,
      state: state,
      targetLanguage: language,
    );
    prompts.add({'role': 'user', 'content': 'Translate and justify: "$message"'});

    final raw = await _callAI(prompts);
    final validated = ResponseValidator.validateTranslationResponse(raw);

    final errors = (validated['detectedErrors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: errors.isEmpty,
      errorTypeIds: errors,
      responseTimeSeconds: responseTime,
    );

    return PolieModeResponse(
      mode: PolieModeName.translation,
      rawJson: validated,
      displayText: _buildTranslationDisplay(validated),
      wasCorrect: errors.isEmpty,
      detectedErrors: errors,
    );
  }

  // ─── AI call ───────────────────────────────────────────────────────

  Future<String> _callAI(List<Map<String, String>> messages) async {
    final response = await _dio.post(
      _apiUrl,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': _model,
        'messages': messages,
        'temperature': 0.15,
        'max_tokens': 500,
        'response_format': {'type': 'json_object'},
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  // ─── Display builders ──────────────────────────────────────────────

  String _buildTutorDisplay(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['diagnosis'] != null) parts.add(json['diagnosis'] as String);
    if (json['microExplanation'] != null) parts.add(json['microExplanation'] as String);
    if (json['nextPrompt'] != null) parts.add('\n${json['nextPrompt']}');
    return parts.join(' ');
  }

  String _buildPronunciationDisplay(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['diagnosis'] != null) parts.add(json['diagnosis'] as String);
    if (json['microExplanation'] != null) parts.add(json['microExplanation'] as String);
    if (json['drillSuggestion'] != null) parts.add('\nTry: ${json['drillSuggestion']}');
    return parts.join(' ');
  }

  String _buildGrammarDisplay(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['isCorrect'] == true) {
      parts.add('Correct!');
    } else {
      if (json['rule'] != null) parts.add('Rule: ${json['rule']}');
      if (json['correction'] != null) parts.add('Correction: ${json['correction']}');
      if (json['explanation'] != null) parts.add(json['explanation'] as String);
    }
    if (json['practicePrompt'] != null) parts.add('\nNow try: ${json['practicePrompt']}');
    return parts.join(' ');
  }

  String _buildReviewDisplay(Map<String, dynamic> json) {
    if (json['wasCorrect'] == true) return 'Correct!';
    if (json['hint'] != null) return 'Hint: ${json['hint']}';
    return 'Try again.';
  }

  String _buildTranslationDisplay(Map<String, dynamic> json) {
    final parts = <String>[];
    parts.add(json['translation'] as String? ?? '');
    if (json['justification'] != null) parts.add('\n${json['justification']}');
    if (json['nuanceExplanation'] != null) parts.add('\n${json['nuanceExplanation']}');

    final alternatives = json['alternatives'] as List<dynamic>?;
    if (alternatives != null && alternatives.isNotEmpty) {
      parts.add('\nAlternatives:');
      for (final alt in alternatives) {
        if (alt is Map) {
          parts.add('  - ${alt['text']}: ${alt['nuance'] ?? ''}');
        }
      }
    }

    return parts.join('');
  }
}

/// Response from any Polie mode.
class PolieModeResponse {
  final PolieModeName mode;
  final Map<String, dynamic> rawJson;
  final String displayText;
  final bool wasCorrect;
  final List<String> detectedErrors;
  final String? nextPrompt;
  final String? drillSuggestion;
  final String? hint;
  final bool isComplete;

  const PolieModeResponse({
    required this.mode,
    required this.rawJson,
    required this.displayText,
    required this.wasCorrect,
    this.detectedErrors = const [],
    this.nextPrompt,
    this.drillSuggestion,
    this.hint,
    this.isComplete = false,
  });
}
