import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../games/animation/rive_game_guide.dart';
import '../providers/gamification_provider.dart';
import '../providers/user_provider.dart';
import '../providers/base_provider.dart';
import 'rive_state_service.dart';

/// Rive Gamification Service
/// Connects Rive animations to the gamification engine
/// Makes the app feel alive with character reactions to all user actions
final riveGamificationServiceProvider = Provider<RiveGamificationService>((ref) {
  return RiveGamificationService(ref);
});

class RiveGamificationService {
  final Ref _ref;
  RiveGameGuideController? _controller;
  final RiveStateService _stateService = RiveStateService();

  RiveGamificationService(this._ref);

  /// Set the Rive controller (called from widget initialization)
  void setController(RiveGameGuideController controller) async {
    _controller = controller;
    _setupGamificationListeners();
    
    // Load saved state from backend
    final user = _ref.read(userProvider);
    if (user != null) {
      final savedState = await _stateService.getState(userId: user.id.toString());
      if (savedState != null) {
        final emotion = savedState['emotion'] as String?;
        final confidence = (savedState['confidence'] as num?)?.toDouble() ?? 0.5;
        
        if (emotion != null) {
          final emotionEnum = _parseEmotion(emotion);
          _controller?.setEmotion(emotionEnum);
          _controller?.setConfidence(confidence);
        }
      }
    }
  }

  GuideEmotion _parseEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'idle':
        return GuideEmotion.idle;
      case 'thinking':
        return GuideEmotion.thinking;
      case 'encouraging':
        return GuideEmotion.encouraging;
      case 'proud':
        return GuideEmotion.proud;
      case 'disappointed':
        return GuideEmotion.disappointed;
      default:
        return GuideEmotion.idle;
    }
  }

  /// Setup listeners for gamification events
  void _setupGamificationListeners() {
    if (_controller == null) return;

    // Listen to gamification state changes
    _ref.listen<BaseProviderState>(
      gamificationProvider,
      (previous, next) {
        if (previous == null) return;
        _handleGamificationChange();
      },
    );
  }

  /// Handle gamification state changes
  void _handleGamificationChange() {
    if (_controller == null) return;

    final gamificationNotifier = _ref.read(gamificationProvider.notifier);
    
    // Reactions are handled by direct method calls (reactToXPGain, reactToLevelUp, etc.)
    // This listener is kept for future enhancements
    debugPrint('Rive: Gamification state updated');
  }

  /// React to level up
  void reactToLevelUp({required int newLevel}) {
    if (_controller == null) return;
    _controller!.celebrate();
    _controller!.setEmotion(GuideEmotion.proud);
    _controller!.setConfidence(0.9);
    _saveState(GuideEmotion.proud, 0.9);
    debugPrint('🎉 Rive: Level up celebration! Level $newLevel');
  }

  /// React to XP gain
  void reactToXPGain(int xpAmount) {
    if (_controller == null) return;

    GuideEmotion emotion;
    double confidence;

    if (xpAmount >= 100) {
      emotion = GuideEmotion.proud;
      confidence = 0.9;
    } else if (xpAmount >= 50) {
      emotion = GuideEmotion.happy;
      confidence = 0.7;
    } else {
      emotion = GuideEmotion.encouraging;
      confidence = 0.6;
    }

    _controller!.setEmotion(emotion);
    _controller!.setConfidence(confidence);
    _saveState(emotion, confidence);
  }

  /// React to perfect score
  void reactToPerfectScore() {
    if (_controller == null) return;
    _controller!.celebrate();
    _controller!.setEmotion(GuideEmotion.proud);
    _controller!.setConfidence(1.0);
  }

  /// React to mistake
  void reactToMistake() {
    if (_controller == null) return;
    _controller!.setEmotion(GuideEmotion.disappointed);
    _controller!.setConfidence(0.3);
    // After a moment, switch to encouraging
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_controller != null) {
        _controller!.setEmotion(GuideEmotion.encouraging);
        _controller!.setConfidence(0.5);
      }
    });
  }

  /// React to lesson completion
  void reactToLessonComplete() {
    if (_controller == null) return;
    _controller!.setEmotion(GuideEmotion.happy);
    _controller!.setConfidence(0.8);
  }

  /// React to quiz completion
  void reactToQuizComplete({required bool isPerfect}) {
    if (_controller == null) return;
    if (isPerfect) {
      reactToPerfectScore();
    } else {
      _controller!.setEmotion(GuideEmotion.happy);
      _controller!.setConfidence(0.7);
    }
  }

  /// React to game completion
  void reactToGameComplete({required double accuracy}) {
    if (_controller == null) return;
    if (accuracy >= 0.9) {
      _controller!.celebrate();
      _controller!.setEmotion(GuideEmotion.proud);
      _controller!.setConfidence(accuracy);
    } else if (accuracy >= 0.7) {
      _controller!.setEmotion(GuideEmotion.happy);
      _controller!.setConfidence(accuracy);
    } else {
      _controller!.setEmotion(GuideEmotion.encouraging);
      _controller!.setConfidence(accuracy);
    }
  }

  /// React to daily check-in
  void reactToDailyCheckIn({required int streak}) {
    if (_controller == null) return;
    if (streak >= 7 && streak % 7 == 0) {
      _controller!.celebrate();
      _controller!.setEmotion(GuideEmotion.proud);
    } else {
      _controller!.setEmotion(GuideEmotion.happy);
      _controller!.setConfidence(0.8);
    }
  }

  /// React to badge unlock
  void reactToBadgeUnlock() {
    if (_controller == null) return;
    _controller!.celebrate();
    _controller!.setEmotion(GuideEmotion.proud);
    _controller!.setConfidence(1.0);
  }

  /// Set idle state
  void setIdle() {
    if (_controller == null) return;
    _controller!.setEmotion(GuideEmotion.idle);
  }

  /// Set thinking state (for loading/processing)
  void setThinking() {
    if (_controller == null) return;
    _controller!.setEmotion(GuideEmotion.thinking);
  }

  /// Get controller (for direct access if needed)
  RiveGameGuideController? get controller => _controller;

  /// Save state to backend
  void _saveState(GuideEmotion emotion, double confidence) {
    final user = _ref.read(userProvider);
    if (user != null) {
      _stateService.saveState(
        userId: user.id.toString(),
        emotion: emotion.name,
        confidence: confidence,
      );
    }
  }
}

