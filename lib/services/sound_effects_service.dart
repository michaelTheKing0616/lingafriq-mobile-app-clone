import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound effects service for gamification feedback
/// 
/// Provides audio feedback for:
/// - XP gains
/// - Level ups
/// - Badge unlocks
/// - Streak achievements
/// - Quiz completions
/// - Correct/incorrect answers
/// - Button taps
/// - Celebrations
final soundEffectsProvider = Provider<SoundEffectsService>((ref) {
  return SoundEffectsService();
});

/// Sound effect types
enum SoundEffect {
  // XP & Progress
  xpGain,           // Short, satisfying chime
  xpGainLarge,      // More elaborate for large XP gains
  levelUp,          // Triumphant fanfare
  
  // Achievements
  badgeUnlock,      // Achievement unlocked sound
  streakMilestone,  // Fire/streak sound
  perfectScore,     // Perfect quiz sound
  
  // Learning feedback
  correct,          // Correct answer
  incorrect,        // Wrong answer (gentle, not punishing)
  hint,             // Hint revealed
  
  // UI interactions
  buttonTap,        // Subtle tap
  menuOpen,         // Drawer/menu open
  swipe,            // Card swipe
  
  // Celebrations
  celebration,      // Big win celebration
  confetti,         // Confetti burst
  applause,         // Crowd applause
  
  // Game sounds
  timerTick,        // Timer countdown
  timerWarning,     // Timer almost done
  gameStart,        // Game begins
  gameComplete,     // Game finished
  
  // Notifications
  notification,     // New notification
  message,          // Chat message
  reminder,         // Daily reminder
}

class SoundEffectsService {
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  double _volume = 0.7;
  
  // Cached audio sources for performance
  final Map<SoundEffect, Source> _cachedSources = {};
  
  SoundEffectsService() {
    _loadPreferences();
    _preloadSounds();
  }
  
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_effects_enabled') ?? true;
      _volume = prefs.getDouble('sound_effects_volume') ?? 0.7;
    } catch (e) {
      debugPrint('Error loading sound preferences: $e');
    }
  }
  
  Future<void> _preloadSounds() async {
    // Preload commonly used sounds for instant playback
    // In production, these would be actual audio files
    // For now, we'll use system sounds as fallbacks
  }
  
  /// Play a sound effect
  Future<void> play(SoundEffect effect, {double? volume}) async {
    if (!_soundEnabled) return;
    
    try {
      final effectiveVolume = volume ?? _volume;
      await _player.setVolume(effectiveVolume);
      
      // Get the asset path for the sound
      final assetPath = _getAssetPath(effect);
      
      if (assetPath != null) {
        await _player.play(AssetSource(assetPath));
      } else {
        // Fallback to haptic feedback if sound not available
        _playHapticFallback(effect);
      }
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
      // Fallback to haptic
      _playHapticFallback(effect);
    }
  }
  
  /// Get asset path for sound effect
  String? _getAssetPath(SoundEffect effect) {
    // Map effects to asset paths
    // These files would need to be added to assets/sounds/
    final Map<SoundEffect, String> paths = {
      SoundEffect.xpGain: 'sounds/xp_gain.mp3',
      SoundEffect.xpGainLarge: 'sounds/xp_gain_large.mp3',
      SoundEffect.levelUp: 'sounds/level_up.mp3',
      SoundEffect.badgeUnlock: 'sounds/badge_unlock.mp3',
      SoundEffect.streakMilestone: 'sounds/streak.mp3',
      SoundEffect.perfectScore: 'sounds/perfect.mp3',
      SoundEffect.correct: 'sounds/correct.mp3',
      SoundEffect.incorrect: 'sounds/incorrect.mp3',
      SoundEffect.hint: 'sounds/hint.mp3',
      SoundEffect.buttonTap: 'sounds/tap.mp3',
      SoundEffect.celebration: 'sounds/celebration.mp3',
      SoundEffect.confetti: 'sounds/confetti.mp3',
      SoundEffect.applause: 'sounds/applause.mp3',
      SoundEffect.timerTick: 'sounds/tick.mp3',
      SoundEffect.timerWarning: 'sounds/warning.mp3',
      SoundEffect.gameStart: 'sounds/game_start.mp3',
      SoundEffect.gameComplete: 'sounds/game_complete.mp3',
      SoundEffect.notification: 'sounds/notification.mp3',
      SoundEffect.message: 'sounds/message.mp3',
    };
    
    return paths[effect];
  }
  
  /// Fallback haptic feedback when sound not available
  void _playHapticFallback(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.xpGain:
      case SoundEffect.correct:
      case SoundEffect.buttonTap:
        HapticFeedback.lightImpact();
        break;
      case SoundEffect.xpGainLarge:
      case SoundEffect.levelUp:
      case SoundEffect.badgeUnlock:
      case SoundEffect.celebration:
        HapticFeedback.heavyImpact();
        break;
      case SoundEffect.incorrect:
        HapticFeedback.mediumImpact();
        break;
      case SoundEffect.streakMilestone:
      case SoundEffect.perfectScore:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.mediumImpact();
        });
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }
  
  /// Play XP gain sound with intensity based on amount
  Future<void> playXPGain(int xpAmount) async {
    if (xpAmount >= 100) {
      await play(SoundEffect.xpGainLarge);
    } else if (xpAmount >= 50) {
      await play(SoundEffect.xpGain, volume: 0.9);
    } else {
      await play(SoundEffect.xpGain, volume: 0.7);
    }
  }
  
  /// Play level up with celebratory effects
  Future<void> playLevelUp() async {
    await play(SoundEffect.levelUp);
    // Add extra celebration after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      play(SoundEffect.confetti, volume: 0.5);
    });
  }
  
  /// Play badge unlock with celebration
  Future<void> playBadgeUnlock() async {
    await play(SoundEffect.badgeUnlock);
    HapticFeedback.heavyImpact();
  }
  
  /// Play correct answer feedback
  Future<void> playCorrect() async {
    await play(SoundEffect.correct);
  }
  
  /// Play incorrect answer feedback (gentle)
  Future<void> playIncorrect() async {
    await play(SoundEffect.incorrect, volume: 0.5);
  }
  
  /// Play celebration sequence
  Future<void> playCelebration() async {
    await play(SoundEffect.celebration);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      play(SoundEffect.confetti, volume: 0.6);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      play(SoundEffect.applause, volume: 0.4);
    });
  }
  
  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_effects_enabled', enabled);
  }
  
  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_effects_volume', _volume);
  }
  
  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;
  
  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

/// Extension for easy sound playing from widgets
extension SoundEffectsExtension on WidgetRef {
  SoundEffectsService get sounds => read(soundEffectsProvider);
  
  void playSound(SoundEffect effect) {
    read(soundEffectsProvider).play(effect);
  }
}

