import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'avatar_engine.dart';
import 'emotion_system.dart';
import 'personality_system.dart';
import 'social/user_avatar_customizer.dart';
import '../providers/api_provider.dart';
import '../providers/shared_preferences_provider.dart';

/// Main avatar engine provider (singleton)
final avatarEngineProvider = Provider<AvatarEngine>((ref) {
  return AvatarEngine();
});

/// Polie avatar controller provider
final polieControllerProvider = FutureProvider<AvatarController>((ref) async {
  final engine = ref.watch(avatarEngineProvider);
  return engine.getController(AvatarType.polie);
});

/// Game avatar controller provider (parameterized by category)
final gameAvatarControllerProvider = FutureProvider.family<AvatarController, GameCategory>((ref, category) async {
  final engine = ref.watch(avatarEngineProvider);
  return engine.getGameAvatar(category);
});

/// Onboarding avatar controller provider (parameterized by step)
final onboardingAvatarControllerProvider = FutureProvider.family<AvatarController, OnboardingStep>((ref, step) async {
  final engine = ref.watch(avatarEngineProvider);
  return engine.getOnboardingAvatar(step);
});

/// Personality system provider
final personalitySystemProvider = Provider<PersonalitySystem>((ref) {
  final engine = ref.watch(avatarEngineProvider);
  return engine.personalitySystem;
});

/// User avatar configuration state — persists locally and syncs with backend.
/// 
/// Data flow:
/// 1. On init: load from SharedPreferences (instant, offline-safe)
/// 2. Then fetch from backend in background (source of truth)
/// 3. On change: save to SharedPreferences immediately, then sync to backend
class UserAvatarConfigNotifier extends StateNotifier<UserAvatarConfig> {
  final Ref _ref;
  static const _storageKey = 'user_avatar_config';
  bool _isInitialized = false;
  
  UserAvatarConfigNotifier(this._ref) : super(const UserAvatarConfig()) {
    _initialize();
  }
  
  /// Load from local storage first, then sync from backend
  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Step 1: Load from local storage (fast, offline-safe)
    await _loadFromLocalStorage();
    
    // Step 2: Sync from backend in background (source of truth)
    _syncFromBackend();
  }
  
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider).prefs;
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        state = UserAvatarConfig.fromJson(map);
      }
    } catch (e) {
      debugPrint('Avatar: Failed to load from local storage: $e');
    }
  }
  
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider).prefs;
      await prefs.setString(_storageKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Avatar: Failed to save to local storage: $e');
    }
  }
  
  Future<void> _syncFromBackend() async {
    try {
      final api = _ref.read(apiProvider.notifier);
      final remoteConfig = await api.getAvatarConfig();
      if (remoteConfig != null && remoteConfig['isDefault'] != true) {
        state = UserAvatarConfig.fromJson(remoteConfig);
        await _saveToLocalStorage();
      }
    } catch (e) {
      debugPrint('Avatar: Failed to sync from backend: $e');
    }
  }
  
  Future<void> _syncToBackend() async {
    try {
      final api = _ref.read(apiProvider.notifier);
      await api.saveAvatarConfig(state.toJson());
    } catch (e) {
      debugPrint('Avatar: Failed to sync to backend: $e');
      // Silently fail — local state is preserved, will sync on next opportunity
    }
  }
  
  void _onChanged() {
    _saveToLocalStorage();
    _syncToBackend();
  }
  
  void updateSkinTone(int skinTone) {
    state = state.copyWith(skinTone: skinTone);
    _onChanged();
  }
  
  void updateHairStyle(int hairStyle) {
    state = state.copyWith(hairStyle: hairStyle);
    _onChanged();
  }
  
  void updateOutfit(int outfit) {
    state = state.copyWith(outfit: outfit);
    _onChanged();
  }
  
  void updateAccessory(int accessory) {
    state = state.copyWith(accessory: accessory);
    _onChanged();
  }
  
  void updateTribeEmblem(String? emblem) {
    state = state.copyWith(tribeEmblem: emblem);
    _onChanged();
  }
  
  void setConfig(UserAvatarConfig config) {
    state = config;
    _onChanged();
  }
  
  void reset() {
    state = const UserAvatarConfig();
    _onChanged();
  }
  
  /// Force a refresh from the backend
  Future<void> refreshFromBackend() async {
    await _syncFromBackend();
  }
}

final userAvatarConfigProvider = StateNotifierProvider<UserAvatarConfigNotifier, UserAvatarConfig>((ref) {
  return UserAvatarConfigNotifier(ref);
});

/// Avatar state for current screen/context
class AvatarContextState {
  final AvatarType? activeAvatar;
  final AvatarEmotion currentEmotion;
  final bool isSpeaking;
  final bool isListening;
  final String? currentMessage;
  
  const AvatarContextState({
    this.activeAvatar,
    this.currentEmotion = AvatarEmotion.idle,
    this.isSpeaking = false,
    this.isListening = false,
    this.currentMessage,
  });
  
  AvatarContextState copyWith({
    AvatarType? activeAvatar,
    AvatarEmotion? currentEmotion,
    bool? isSpeaking,
    bool? isListening,
    String? currentMessage,
  }) {
    return AvatarContextState(
      activeAvatar: activeAvatar ?? this.activeAvatar,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      currentMessage: currentMessage ?? this.currentMessage,
    );
  }
}

class AvatarContextNotifier extends StateNotifier<AvatarContextState> {
  final Ref _ref;
  
  AvatarContextNotifier(this._ref) : super(const AvatarContextState());
  
  void setActiveAvatar(AvatarType type) {
    state = state.copyWith(activeAvatar: type);
  }
  
  void setEmotion(AvatarEmotion emotion) {
    state = state.copyWith(currentEmotion: emotion);
  }
  
  void startSpeaking(String message) {
    state = state.copyWith(isSpeaking: true, currentMessage: message);
  }
  
  void stopSpeaking() {
    state = state.copyWith(isSpeaking: false);
  }
  
  void startListening() {
    state = state.copyWith(isListening: true);
  }
  
  void stopListening() {
    state = state.copyWith(isListening: false);
  }
  
  void reset() {
    state = const AvatarContextState();
  }
}

final avatarContextProvider = StateNotifierProvider<AvatarContextNotifier, AvatarContextState>((ref) {
  return AvatarContextNotifier(ref);
});

/// Avatar event types for cross-system communication
enum AvatarEvent {
  correctAnswer,
  incorrectAnswer,
  perfectScore,
  levelUp,
  streakMilestone,
  badgeUnlock,
  lessonComplete,
  quizComplete,
  gameComplete,
  dailyCheckIn,
  achievementUnlocked,
}

/// Avatar event handler
class AvatarEventHandler {
  final Ref _ref;
  
  AvatarEventHandler(this._ref);
  
  Future<void> handleEvent(AvatarEvent event, {Map<String, dynamic>? data}) async {
    final engine = _ref.read(avatarEngineProvider);
    final polieController = await engine.getController(AvatarType.polie);
    
    switch (event) {
      case AvatarEvent.correctAnswer:
        polieController.setEmotion(AvatarEmotion.proud, intensity: EmotionIntensity.strong);
        break;
        
      case AvatarEvent.incorrectAnswer:
        polieController.setEmotion(AvatarEmotion.empathetic);
        await Future.delayed(const Duration(seconds: 1));
        polieController.setEmotion(AvatarEmotion.encouraging);
        break;
        
      case AvatarEvent.perfectScore:
        polieController.celebrate();
        await polieController.playReactionSequence(AvatarReaction.perfectScore);
        break;
        
      case AvatarEvent.levelUp:
        final level = data?['level'] as int? ?? 1;
        await polieController.playReactionSequence(AvatarReaction.levelUp);
        polieController.startSpeaking(text: 'Level $level! Amazing progress!');
        break;
        
      case AvatarEvent.streakMilestone:
        final streak = data?['streak'] as int? ?? 7;
        await polieController.playReactionSequence(AvatarReaction.streakMilestone);
        polieController.startSpeaking(text: '$streak day streak!');
        break;
        
      case AvatarEvent.badgeUnlock:
        polieController.celebrate();
        break;
        
      case AvatarEvent.lessonComplete:
        polieController.setEmotion(AvatarEmotion.happy, intensity: EmotionIntensity.strong);
        break;
        
      case AvatarEvent.quizComplete:
        final isPerfect = data?['isPerfect'] as bool? ?? false;
        if (isPerfect) {
          polieController.celebrate();
        } else {
          polieController.setEmotion(AvatarEmotion.happy);
        }
        break;
        
      case AvatarEvent.gameComplete:
        final accuracy = data?['accuracy'] as double? ?? 0.7;
        if (accuracy >= 0.9) {
          polieController.celebrate();
        } else {
          polieController.setEmotion(AvatarEmotion.encouraging);
        }
        break;
        
      case AvatarEvent.dailyCheckIn:
        await polieController.playReactionSequence(AvatarReaction.greeting);
        break;
        
      case AvatarEvent.achievementUnlocked:
        polieController.celebrate();
        break;
    }
  }
}

final avatarEventHandlerProvider = Provider<AvatarEventHandler>((ref) {
  return AvatarEventHandler(ref);
});
