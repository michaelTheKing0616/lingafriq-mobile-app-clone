import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hearts_system_model.dart';
import '../services/sound_effects_service.dart';
import 'gamification_provider.dart';

/// Provider for hearts/lives system
final heartsProvider = NotifierProvider<HeartsNotifier, HeartsState>(() {
  return HeartsNotifier();
});

class HeartsNotifier extends Notifier<HeartsState> {
  static const String _storageKey = 'hearts_state';
  Timer? _regenerationTimer;

  @override
  HeartsState build() {
    // Notifier has no dispose(); register cleanup via ref.onDispose instead.
    ref.onDispose(() {
      _regenerationTimer?.cancel();
    });
    _loadState();
    return HeartsState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);
      
      if (stateJson != null) {
        final data = jsonDecode(stateJson) as Map<String, dynamic>;
        var loadedState = HeartsState.fromJson(data);
        
        // Process any hearts that should have regenerated while app was closed
        loadedState = _processOfflineRegeneration(loadedState);
        
        state = loadedState;
        
        // Start regeneration timer if needed
        if (state.isRegenerating) {
          _startRegenerationTimer();
        }
      }
    } catch (e) {
      debugPrint('Error loading hearts state: $e');
    }
  }

  HeartsState _processOfflineRegeneration(HeartsState loadedState) {
    if (loadedState.nextHeartAt == null || loadedState.currentHearts >= loadedState.maxHearts) {
      return loadedState;
    }

    final now = DateTime.now();
    var currentHearts = loadedState.currentHearts;
    var nextHeartAt = loadedState.nextHeartAt!;

    // Calculate how many hearts should have regenerated
    while (now.isAfter(nextHeartAt) && currentHearts < loadedState.maxHearts) {
      currentHearts++;
      nextHeartAt = nextHeartAt.add(HeartsConfig.regenerationTime);
    }

    // If fully regenerated, clear the timer
    if (currentHearts >= loadedState.maxHearts) {
      return loadedState.copyWith(
        currentHearts: loadedState.maxHearts,
        nextHeartAt: null,
      );
    }

    return loadedState.copyWith(
      currentHearts: currentHearts,
      nextHeartAt: nextHeartAt,
    );
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving hearts state: $e');
    }
  }

  void _startRegenerationTimer() {
    _regenerationTimer?.cancel();
    
    _regenerationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isRegenerating || state.currentHearts >= state.maxHearts) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (state.nextHeartAt != null && now.isAfter(state.nextHeartAt!)) {
        _regenerateHeart();
      } else {
        // Just trigger a rebuild for the UI timer
        state = state.copyWith();
      }
    });
  }

  void _regenerateHeart() {
    final newHearts = state.currentHearts + 1;
    
    if (newHearts >= state.maxHearts) {
      state = state.copyWith(
        currentHearts: state.maxHearts,
        nextHeartAt: null,
      );
      _regenerationTimer?.cancel();
    } else {
      state = state.copyWith(
        currentHearts: newHearts,
        nextHeartAt: DateTime.now().add(HeartsConfig.regenerationTime),
      );
    }
    
    // Play heart regeneration sound
    ref.read(soundEffectsProvider).play(SoundEffect.notification);
    
    _saveState();
  }

  /// Use a heart (when user makes a mistake)
  /// Returns false if no hearts available
  bool useHeart() {
    if (state.isUnlimited || !state.challengeModeEnabled) {
      return true; // Unlimited hearts or challenge mode off
    }

    if (state.currentHearts <= 0) {
      return false;
    }

    final newHearts = state.currentHearts - 1;
    final needsRegenTimer = state.nextHeartAt == null;
    
    state = state.copyWith(
      currentHearts: newHearts,
      nextHeartAt: needsRegenTimer 
          ? DateTime.now().add(HeartsConfig.regenerationTime)
          : state.nextHeartAt,
    );

    // Play heart lost sound
    ref.read(soundEffectsProvider).play(SoundEffect.incorrect);

    if (needsRegenTimer) {
      _startRegenerationTimer();
    }

    _saveState();
    return true;
  }

  /// Refill hearts (with cowries or ads)
  Future<bool> refillHearts({bool useCowries = true}) async {
    if (useCowries) {
      // Check if user has enough cowries
      final gamification =
          ref.read(gamificationProvider.notifier).gamification;
      if (gamification.cowries < HeartsConfig.cowriesCostPerRefill) {
        return false;
      }

      // Deduct cowries
      await ref.read(gamificationProvider.notifier).spendCurrency(
        cowries: HeartsConfig.cowriesCostPerRefill,
      );
    }

    // Refill hearts
    state = state.copyWith(
      currentHearts: state.maxHearts,
      nextHeartAt: null,
    );

    _regenerationTimer?.cancel();

    // Play refill sound
    ref.read(soundEffectsProvider).playCelebration();

    await _saveState();
    return true;
  }

  /// Add bonus hearts (from rewards, etc.)
  void addBonusHearts(int count) {
    final newHearts = (state.currentHearts + count).clamp(0, state.maxHearts + 2);
    
    state = state.copyWith(
      currentHearts: newHearts,
    );

    ref.read(soundEffectsProvider).play(SoundEffect.xpGain);
    _saveState();
  }

  /// Toggle challenge mode
  void setChallengeModeEnabled(bool enabled) {
    state = state.copyWith(
      challengeModeEnabled: enabled,
    );
    _saveState();
  }

  /// Set unlimited hearts (for premium users)
  void setUnlimitedHearts(bool unlimited) {
    state = state.copyWith(
      isUnlimited: unlimited,
    );
    _saveState();
  }

  // Note: no dispose() override for Notifier.
}

/// Extension for easy hearts access
extension HeartsExtension on WidgetRef {
  /// Check if user can continue (has hearts or challenge mode off)
  bool get canContinue => read(heartsProvider).hasHearts;

  /// Use a heart and return if successful
  bool useHeart() => read(heartsProvider.notifier).useHeart();
}

