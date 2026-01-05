import 'game_feedback.dart';
import 'game_result.dart';
import 'game_scoring.dart';
import '../animation/rive_game_guide.dart';

/// Bridge between game engine and Rive animation system
/// All games use this to trigger animations
class GameAnimationBridge {
  final RiveGameGuideController? guideController;

  GameAnimationBridge({this.guideController});

  /// Emit an animation event
  void emit(AnimationEvent event, GameScore score) {
    if (guideController == null) return;

    switch (event) {
      case AnimationEvent.idle:
        guideController!.setEmotion(GuideEmotion.idle);
        break;
      case AnimationEvent.thinking:
        guideController!.setEmotion(GuideEmotion.thinking);
        break;
      case AnimationEvent.listening:
        guideController!.setListening(true);
        break;
      case AnimationEvent.speaking:
        guideController!.setSpeaking(true);
        break;
      case AnimationEvent.happy:
        guideController!.setEmotion(GuideEmotion.encouraging);
        guideController!.setConfidence(score.accuracy);
        break;
      case AnimationEvent.proud:
        guideController!.celebrate();
        guideController!.setConfidence(score.accuracy);
        break;
      case AnimationEvent.disappointed:
        guideController!.setEmotion(GuideEmotion.disappointed);
        guideController!.setConfidence(score.accuracy);
        break;
      case AnimationEvent.encouraging:
        guideController!.setEmotion(GuideEmotion.encouraging);
        guideController!.setConfidence(score.accuracy);
        break;
      case AnimationEvent.confused:
        guideController!.setEmotion(GuideEmotion.thinking);
        break;
    }
  }
}

