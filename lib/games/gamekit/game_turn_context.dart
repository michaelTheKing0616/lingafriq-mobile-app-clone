import 'game_session.dart';

/// Speaking turn payload for E-P6-SCORER (P8-910).
class GameSpeakingTurnInput {
  const GameSpeakingTurnInput({
    required this.audioPath,
    required this.expectedText,
    required this.language,
  });

  final String audioPath;
  final String expectedText;
  final String language;

  static GameSpeakingTurnInput? fromContext(GameTurnContext context) {
    if (!context.requiresRealSpeakingScorer) return null;

    final input = context.input;
    if (input is GameSpeakingTurnInput) return input;
    if (input is Map) {
      final map = Map<String, dynamic>.from(input);
      final audio = map['audioPath'] as String? ?? map['audio_path'] as String?;
      final expected =
          map['expectedText'] as String? ?? map['expected_text'] as String?;
      final language = map['language'] as String? ?? context.session.language;
      if (audio != null &&
          audio.isNotEmpty &&
          expected != null &&
          expected.isNotEmpty) {
        return GameSpeakingTurnInput(
          audioPath: audio,
          expectedText: expected,
          language: language,
        );
      }
    }

    final content = context.content;
    if (content is Map) {
      final map = Map<String, dynamic>.from(content);
      final expected = map['expectedText'] as String? ??
          map['expected_text'] as String? ??
          map['prompt'] as String?;
      final audio = map['audioPath'] as String? ?? map['audio_path'] as String?;
      if (expected != null &&
          expected.isNotEmpty &&
          audio != null &&
          audio.isNotEmpty) {
        return GameSpeakingTurnInput(
          audioPath: audio,
          expectedText: expected,
          language: context.session.language,
        );
      }
    }
    return null;
  }
}

/// Context for a single game turn
/// Contains all information needed to evaluate a turn
class GameTurnContext {
  final dynamic content; // Game-specific content (e.g., ToneForgeContent)
  final dynamic input; // User input (e.g., ToneForgeInput)
  final GameSession session;
  final DateTime turnStartTime;
  final Map<String, dynamic>? metadata;
  final int? queueIndex;

  GameTurnContext({
    required this.content,
    required this.input,
    required this.session,
    DateTime? turnStartTime,
    this.metadata,
    this.queueIndex,
  }) : turnStartTime = turnStartTime ?? DateTime.now();

  int get durationMs => DateTime.now().difference(turnStartTime).inMilliseconds;

  bool get requiresRealSpeakingScorer {
    final meta = metadata ?? const {};
    if (meta['requiresServerScoring'] == true) return true;
    if (meta['coreVerb'] == 'speak') return true;
    final sessionVerb = session.metadata['core_verb'] as String?;
    return sessionVerb == 'speak';
  }

  String? get queuedItemId {
    if (queueIndex == null || queueIndex! < 0 || queueIndex! >= session.turnQueue.length) {
      return null;
    }
    return session.turnQueue[queueIndex!];
  }
}

