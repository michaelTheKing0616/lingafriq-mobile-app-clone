import 'package:flutter/foundation.dart';

/// Extended emotion states for avatars
/// Goes beyond basic emotions to create nuanced, believable character reactions
enum AvatarEmotion {
  // Core emotions (indices 0-5)
  idle,
  thinking,
  encouraging,
  proud,
  disappointed,
  happy,
  
  // Extended emotions (indices 6-12)
  excited,
  curious,
  focused,
  sleepy,
  celebrating,
  empathetic,
  playful,
  
  // Additional nuanced emotions (indices 13-18)
  listening,
  speaking,
  surprised,
  confused,
  determined,
  relieved,
}

/// Emotion intensity levels
enum EmotionIntensity {
  subtle,    // 0.3
  moderate,  // 0.6
  strong,    // 0.85
  extreme,   // 1.0
}

/// Represents a blended emotion state for natural transitions
class EmotionState {
  final AvatarEmotion primary;
  final AvatarEmotion? secondary;
  final double primaryWeight;
  final EmotionIntensity intensity;
  final Duration? duration;
  
  const EmotionState({
    required this.primary,
    this.secondary,
    this.primaryWeight = 1.0,
    this.intensity = EmotionIntensity.moderate,
    this.duration,
  });
  
  /// Create a simple single emotion state
  factory EmotionState.simple(AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    return EmotionState(primary: emotion, intensity: intensity);
  }
  
  /// Create a blended emotion state
  factory EmotionState.blended({
    required AvatarEmotion primary,
    required AvatarEmotion secondary,
    double blend = 0.5,
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    return EmotionState(
      primary: primary,
      secondary: secondary,
      primaryWeight: 1.0 - blend,
      intensity: intensity,
    );
  }
  
  /// Get the numeric value for Rive state machine
  double get primaryValue => primary.index.toDouble();
  double? get secondaryValue => secondary?.index.toDouble();
  
  /// Get intensity as a numeric value
  double get intensityValue {
    switch (intensity) {
      case EmotionIntensity.subtle:
        return 0.3;
      case EmotionIntensity.moderate:
        return 0.6;
      case EmotionIntensity.strong:
        return 0.85;
      case EmotionIntensity.extreme:
        return 1.0;
    }
  }
  
  @override
  String toString() => 'EmotionState($primary${secondary != null ? ' + $secondary' : ''}, intensity: $intensity)';
}

/// Emotion transition configuration
class EmotionTransition {
  final EmotionState from;
  final EmotionState to;
  final Duration duration;
  final Curve curve;
  
  const EmotionTransition({
    required this.from,
    required this.to,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });
}

/// Emotion System - manages avatar emotional states with natural transitions
class EmotionSystem {
  EmotionState _currentState = const EmotionState(primary: AvatarEmotion.idle);
  final List<EmotionTransition> _transitionHistory = [];
  
  /// Current emotion state
  EmotionState get currentState => _currentState;
  
  /// Set emotion with optional transition
  EmotionTransition setEmotion(
    AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
    Duration? transitionDuration,
    AvatarEmotion? blendWith,
    double blendAmount = 0.3,
  }) {
    final newState = blendWith != null
        ? EmotionState.blended(
            primary: emotion,
            secondary: blendWith,
            blend: blendAmount,
            intensity: intensity,
          )
        : EmotionState.simple(emotion, intensity: intensity);
    
    final transition = EmotionTransition(
      from: _currentState,
      to: newState,
      duration: transitionDuration ?? _getDefaultTransitionDuration(emotion),
    );
    
    _currentState = newState;
    _transitionHistory.add(transition);
    
    // Keep history manageable
    if (_transitionHistory.length > 50) {
      _transitionHistory.removeRange(0, 25);
    }
    
    return transition;
  }
  
  /// Get context-aware emotion based on situation
  EmotionState getContextualEmotion({
    required AvatarContext context,
    double userConfidence = 0.5,
    bool userSucceeded = true,
  }) {
    switch (context) {
      case AvatarContext.greeting:
        return EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.teaching:
        return EmotionState.simple(AvatarEmotion.focused, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.waitingForInput:
        return EmotionState.blended(
          primary: AvatarEmotion.curious,
          secondary: AvatarEmotion.listening,
          intensity: EmotionIntensity.subtle,
        );
        
      case AvatarContext.processingAnswer:
        return EmotionState.simple(AvatarEmotion.thinking, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.correctAnswer:
        final intensity = userConfidence > 0.8 
            ? EmotionIntensity.extreme 
            : EmotionIntensity.strong;
        return EmotionState.simple(AvatarEmotion.proud, intensity: intensity);
        
      case AvatarContext.incorrectAnswer:
        return EmotionState.blended(
          primary: AvatarEmotion.empathetic,
          secondary: AvatarEmotion.encouraging,
          blend: 0.4,
          intensity: EmotionIntensity.moderate,
        );
        
      case AvatarContext.celebration:
        return EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme);
        
      case AvatarContext.encouragement:
        return EmotionState.simple(AvatarEmotion.encouraging, intensity: EmotionIntensity.strong);
        
      case AvatarContext.hint:
        return EmotionState.blended(
          primary: AvatarEmotion.thinking,
          secondary: AvatarEmotion.playful,
          intensity: EmotionIntensity.moderate,
        );
        
      case AvatarContext.idle:
      default:
        return EmotionState.simple(AvatarEmotion.idle, intensity: EmotionIntensity.subtle);
    }
  }
  
  /// Get default transition duration based on emotion type
  Duration _getDefaultTransitionDuration(AvatarEmotion emotion) {
    switch (emotion) {
      case AvatarEmotion.celebrating:
      case AvatarEmotion.excited:
        return const Duration(milliseconds: 200); // Quick, energetic
      case AvatarEmotion.thinking:
      case AvatarEmotion.focused:
        return const Duration(milliseconds: 400); // Thoughtful transition
      case AvatarEmotion.sleepy:
        return const Duration(milliseconds: 600); // Slow, drowsy
      default:
        return const Duration(milliseconds: 300); // Standard
    }
  }
  
  /// Reset to idle state
  void reset() {
    _currentState = const EmotionState(primary: AvatarEmotion.idle);
  }
  
  /// Get emotion sequence for complex reactions
  List<EmotionState> getReactionSequence(AvatarReaction reaction) {
    switch (reaction) {
      case AvatarReaction.perfectScore:
        return [
          EmotionState.simple(AvatarEmotion.surprised, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.proud, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.levelUp:
        return [
          EmotionState.simple(AvatarEmotion.excited, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.streakMilestone:
        return [
          EmotionState.simple(AvatarEmotion.proud, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.encourageAfterFail:
        return [
          EmotionState.simple(AvatarEmotion.empathetic, intensity: EmotionIntensity.moderate),
          EmotionState.simple(AvatarEmotion.encouraging, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.determined, intensity: EmotionIntensity.moderate),
        ];
        
      case AvatarReaction.thinking:
        return [
          EmotionState.simple(AvatarEmotion.curious, intensity: EmotionIntensity.subtle),
          EmotionState.simple(AvatarEmotion.thinking, intensity: EmotionIntensity.moderate),
        ];
        
      case AvatarReaction.greeting:
        return [
          EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.idle, intensity: EmotionIntensity.subtle),
        ];
    }
  }
}

/// Context for emotion selection
enum AvatarContext {
  greeting,
  teaching,
  waitingForInput,
  processingAnswer,
  correctAnswer,
  incorrectAnswer,
  celebration,
  encouragement,
  hint,
  idle,
}

/// Complex reaction sequences
enum AvatarReaction {
  perfectScore,
  levelUp,
  streakMilestone,
  encourageAfterFail,
  thinking,
  greeting,
}

/// Curves for smooth transitions
class Curves {
  static const Curve easeInOut = _EaseInOutCurve();
  static const Curve easeOut = _EaseOutCurve();
  static const Curve bounce = _BounceCurve();
}

class _EaseInOutCurve implements Curve {
  const _EaseInOutCurve();
  @override
  double transform(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

class _EaseOutCurve implements Curve {
  const _EaseOutCurve();
  @override
  double transform(double t) => 1 - (1 - t) * (1 - t);
}

class _BounceCurve implements Curve {
  const _BounceCurve();
  @override
  double transform(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      t -= 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }
}

/// Abstract curve interface
abstract class Curve {
  const Curve();
  double transform(double t);
}
