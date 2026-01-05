import '../gamekit/game_scoring.dart';
import '../gamekit/game_turn_context.dart';
import 'tone_forge_models.dart';
import 'tone_forge_audio.dart';

/// ToneForge-specific scoring engine
/// Uses real pitch analysis, not random logic
class ToneForgeScoringEngine implements GameScoringEngine {
  final ToneForgeAudioAnalyzer audioAnalyzer = ToneForgeAudioAnalyzer();

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as ToneForgeContent;
    final input = context.input as ToneForgeInput;

    // Calculate pitch accuracy using real analysis
    final mse = audioAnalyzer.calculateMSE(
      content.targetPitchContour,
      input.userPitchContour,
    );

    // Convert MSE to accuracy (0-1 scale)
    // Lower MSE = higher accuracy
    final accuracy = (1.0 - mse).clamp(0.0, 1.0);

    // Check if within tolerance
    final isWithinTolerance = mse <= content.pitchTolerance;

    return GameScore(
      accuracy: accuracy,
      isPerfect: accuracy > 0.9 && isWithinTolerance,
      isFail: accuracy < 0.4 || !isWithinTolerance,
      details: {
        'mse': mse,
        'pitch_tolerance': content.pitchTolerance,
        'is_within_tolerance': isWithinTolerance,
        'target_contour_length': content.targetPitchContour.length,
        'user_contour_length': input.userPitchContour.length,
      },
    );
  }
}

