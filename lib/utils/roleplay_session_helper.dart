// Roleplay Session Helper
// Utility functions for tracking roleplay sessions
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/roleplay_progress_model.dart';
import '../services/ai_chat_integration_service.dart';

/// Track a roleplay session
class RoleplaySessionHelper {
  final Ref _ref;
  DateTime? _startTime;
  String? _scenarioId;
  String? _language;
  int _turnCount = 0;
  final List<String> _branchesTaken = [];
  final List<String> _vocabularyLearned = [];
  final List<String> _grammarPoints = [];
  final List<String> _corrections = [];
  final Map<String, dynamic> _metadata = {};

  RoleplaySessionHelper(this._ref);

  /// Start a new session
  void startSession({
    required String scenarioId,
    required String language,
    Map<String, dynamic>? metadata,
  }) {
    _startTime = DateTime.now();
    _scenarioId = scenarioId;
    _language = language;
    _turnCount = 0;
    _branchesTaken.clear();
    _vocabularyLearned.clear();
    _grammarPoints.clear();
    _corrections.clear();
    _metadata.clear();
    if (metadata != null) {
      _metadata.addAll(metadata);
    }
  }

  /// Record a turn
  void recordTurn({
    String? branch,
    List<String>? vocabulary,
    List<String>? grammar,
    String? correction,
  }) {
    _turnCount++;
    if (branch != null) _branchesTaken.add(branch);
    if (vocabulary != null) _vocabularyLearned.addAll(vocabulary);
    if (grammar != null) _grammarPoints.addAll(grammar);
    if (correction != null) _corrections.add(correction);
  }

  /// Complete the session and return result
  Future<RoleplaySessionResult?> completeSession({
    double? accuracy,
    double? fluency,
    int? score,
  }) async {
    if (_startTime == null || _scenarioId == null || _language == null) {
      return null;
    }

    final timeSpent = DateTime.now().difference(_startTime!).inSeconds;

    // Calculate default metrics if not provided
    final finalAccuracy = accuracy ?? 0.85;
    final finalFluency = fluency ?? 0.80;
    final finalScore = score ?? ((finalAccuracy * 0.4 + finalFluency * 0.3 + (_turnCount / 10.0) * 0.3) * 100).round();

    final result = RoleplaySessionResult(
      scenarioId: _scenarioId!,
      language: _language!,
      turnCount: _turnCount,
      accuracy: finalAccuracy,
      fluency: finalFluency,
      score: finalScore,
      branchesTaken: List.from(_branchesTaken),
      vocabularyLearned: List.from(_vocabularyLearned),
      grammarPoints: List.from(_grammarPoints),
      corrections: List.from(_corrections),
      timeSpent: timeSpent,
      completedAt: DateTime.now(),
      metadata: Map.from(_metadata),
    );

    // Record session
    final integrationService = _ref.read(aiChatIntegrationServiceProvider);
    await integrationService.recordRoleplaySession(
      scenarioId: _scenarioId!,
      language: _language!,
      turnCount: _turnCount,
      accuracy: finalAccuracy,
      fluency: finalFluency,
      score: finalScore,
      branchesTaken: List.from(_branchesTaken),
      vocabularyLearned: List.from(_vocabularyLearned),
      grammarPoints: List.from(_grammarPoints),
      corrections: List.from(_corrections),
      timeSpent: timeSpent,
      metadata: Map.from(_metadata),
    );

    // Clear session
    _startTime = null;
    _scenarioId = null;
    _language = null;
    _turnCount = 0;
    _branchesTaken.clear();
    _vocabularyLearned.clear();
    _grammarPoints.clear();
    _corrections.clear();
    _metadata.clear();

    return result;
  }

  /// Get current session state
  RoleplaySessionState? getCurrentState() {
    if (_startTime == null || _scenarioId == null || _language == null) {
      return null;
    }

    return RoleplaySessionState(
      scenarioId: _scenarioId!,
      language: _language!,
      startTime: _startTime!,
      turnCount: _turnCount,
      branchesTaken: List.from(_branchesTaken),
      vocabularyLearned: List.from(_vocabularyLearned),
      grammarPoints: List.from(_grammarPoints),
      corrections: List.from(_corrections),
      metadata: Map.from(_metadata),
    );
  }
}

/// Roleplay session state (duplicate from tracker for convenience)
class RoleplaySessionState {
  final String scenarioId;
  final String language;
  final DateTime startTime;
  final int turnCount;
  final List<String> branchesTaken;
  final List<String> vocabularyLearned;
  final List<String> grammarPoints;
  final List<String> corrections;
  final Map<String, dynamic> metadata;

  RoleplaySessionState({
    required this.scenarioId,
    required this.language,
    required this.startTime,
    this.turnCount = 0,
    this.branchesTaken = const [],
    this.vocabularyLearned = const [],
    this.grammarPoints = const [],
    this.corrections = const [],
    this.metadata = const {},
  });
}

