import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../avatar_engine.dart';
import '../avatar_providers.dart';
import '../emotion_system.dart';

/// Polie Avatar state
class PolieAvatarState {
  final bool isInitialized;
  final bool isSpeaking;
  final bool isListening;
  final bool isThinking;
  final AvatarEmotion emotion;
  final double confidence;
  final String? currentMessage;
  final String? greeting;
  
  const PolieAvatarState({
    this.isInitialized = false,
    this.isSpeaking = false,
    this.isListening = false,
    this.isThinking = false,
    this.emotion = AvatarEmotion.idle,
    this.confidence = 0.5,
    this.currentMessage,
    this.greeting,
  });
  
  PolieAvatarState copyWith({
    bool? isInitialized,
    bool? isSpeaking,
    bool? isListening,
    bool? isThinking,
    AvatarEmotion? emotion,
    double? confidence,
    String? currentMessage,
    String? greeting,
  }) {
    return PolieAvatarState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      isThinking: isThinking ?? this.isThinking,
      emotion: emotion ?? this.emotion,
      confidence: confidence ?? this.confidence,
      currentMessage: currentMessage ?? this.currentMessage,
      greeting: greeting ?? this.greeting,
    );
  }
}

/// Polie Avatar Controller Provider
final polieAvatarControllerProvider = StateNotifierProvider<PolieAvatarControllerNotifier, PolieAvatarState>((ref) {
  return PolieAvatarControllerNotifier(ref);
});

/// Polie Avatar Controller Notifier
class PolieAvatarControllerNotifier extends StateNotifier<PolieAvatarState> {
  final Ref _ref;
  AvatarController? _avatarController;
  StreamSubscription? _stateSubscription;
  
  PolieAvatarControllerNotifier(this._ref) : super(const PolieAvatarState()) {
    _initialize();
  }
  
  /// Get the underlying avatar controller
  AvatarController? get controller => _avatarController;
  
  /// Initialize the Polie avatar
  Future<void> _initialize() async {
    try {
      final engine = _ref.read(avatarEngineProvider);
      _avatarController = await engine.getController(AvatarType.polie);
      
      // Listen to state changes
      _stateSubscription = _avatarController!.stateStream.listen((avatarState) {
        state = state.copyWith(
          isSpeaking: avatarState.isSpeaking,
          isListening: avatarState.isListening,
          emotion: avatarState.emotionState.primary,
          confidence: avatarState.confidence,
        );
      });
      
      // Get greeting
      final greeting = _avatarController!.getGreeting();
      
      state = state.copyWith(
        isInitialized: true,
        greeting: greeting,
      );
      
      debugPrint('Polie: Avatar controller initialized');
    } catch (e) {
      debugPrint('Polie: Failed to initialize - $e');
    }
  }
  
  /// Greet the user
  void greet() {
    if (_avatarController == null) return;
    
    _avatarController!.setEmotion(AvatarEmotion.happy, intensity: EmotionIntensity.moderate);
    _avatarController!.wave();
    
    final greeting = _avatarController!.getGreeting();
    state = state.copyWith(
      currentMessage: greeting,
      emotion: AvatarEmotion.happy,
    );
    
    // Speak the greeting
    _avatarController!.startSpeaking(text: greeting);
  }
  
  /// Start listening for user input
  void startListening() {
    if (_avatarController == null) return;
    
    _avatarController!.startListening();
    state = state.copyWith(
      isListening: true,
      emotion: AvatarEmotion.listening,
    );
  }
  
  /// Stop listening
  void stopListening() {
    if (_avatarController == null) return;
    
    _avatarController!.stopListening();
    state = state.copyWith(isListening: false);
  }
  
  /// Start thinking (processing user input)
  void startThinking() {
    if (_avatarController == null) return;
    
    _avatarController!.setEmotion(AvatarEmotion.thinking);
    state = state.copyWith(
      isThinking: true,
      emotion: AvatarEmotion.thinking,
    );
  }
  
  /// Stop thinking
  void stopThinking() {
    if (_avatarController == null) return;
    
    state = state.copyWith(isThinking: false);
  }
  
  /// Speak a message
  void speak(String message, {Duration? duration}) {
    if (_avatarController == null) return;
    
    _avatarController!.setEmotion(AvatarEmotion.speaking);
    _avatarController!.startSpeaking(text: message, duration: duration);
    
    state = state.copyWith(
      isSpeaking: true,
      currentMessage: message,
      emotion: AvatarEmotion.speaking,
    );
  }
  
  /// Stop speaking
  void stopSpeaking() {
    if (_avatarController == null) return;
    
    _avatarController!.stopSpeaking();
    state = state.copyWith(isSpeaking: false);
  }
  
  /// React to correct answer
  void reactToCorrectAnswer({bool isPerfect = false}) {
    if (_avatarController == null) return;
    
    if (isPerfect) {
      _avatarController!.celebrate();
      _avatarController!.playReactionSequence(AvatarReaction.perfectScore);
    } else {
      _avatarController!.setEmotion(AvatarEmotion.proud, intensity: EmotionIntensity.strong);
    }
    
    final encouragement = _avatarController!.getEncouragement('success');
    state = state.copyWith(
      emotion: isPerfect ? AvatarEmotion.celebrating : AvatarEmotion.proud,
      currentMessage: encouragement,
    );
  }
  
  /// React to incorrect answer
  void reactToIncorrectAnswer() {
    if (_avatarController == null) return;
    
    _avatarController!.playReactionSequence(AvatarReaction.encourageAfterFail);
    
    final encouragement = _avatarController!.getEncouragement('mistake');
    state = state.copyWith(
      emotion: AvatarEmotion.empathetic,
      currentMessage: encouragement,
    );
  }
  
  /// React to level up
  void reactToLevelUp(int newLevel) {
    if (_avatarController == null) return;
    
    _avatarController!.playReactionSequence(AvatarReaction.levelUp);
    
    state = state.copyWith(
      emotion: AvatarEmotion.celebrating,
      currentMessage: 'Amazing! You reached level $newLevel!',
    );
  }
  
  /// React to streak milestone
  void reactToStreakMilestone(int streak) {
    if (_avatarController == null) return;
    
    _avatarController!.playReactionSequence(AvatarReaction.streakMilestone);
    
    state = state.copyWith(
      emotion: AvatarEmotion.proud,
      currentMessage: '$streak day streak! Your dedication inspires!',
    );
  }
  
  /// Set emotion directly
  void setEmotion(AvatarEmotion emotion, {EmotionIntensity intensity = EmotionIntensity.moderate}) {
    if (_avatarController == null) return;
    
    _avatarController!.setEmotion(emotion, intensity: intensity);
    state = state.copyWith(emotion: emotion);
  }
  
  /// Set confidence level
  void setConfidence(double confidence) {
    if (_avatarController == null) return;
    
    _avatarController!.setConfidence(confidence);
    state = state.copyWith(confidence: confidence);
  }
  
  /// Reset to idle state
  void reset() {
    if (_avatarController == null) return;
    
    _avatarController!.reset();
    state = state.copyWith(
      isSpeaking: false,
      isListening: false,
      isThinking: false,
      emotion: AvatarEmotion.idle,
      confidence: 0.5,
      currentMessage: null,
    );
  }
  
  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}

/// Extension for easy access in widgets
extension PolieAvatarControllerExtension on WidgetRef {
  PolieAvatarControllerNotifier get polieAvatar => 
      read(polieAvatarControllerProvider.notifier);
  
  PolieAvatarState get polieState => 
      watch(polieAvatarControllerProvider);
}
