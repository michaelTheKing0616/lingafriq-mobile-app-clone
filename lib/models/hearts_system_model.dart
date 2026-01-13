import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hearts/Lives System Configuration
class HeartsConfig {
  static const int maxHearts = 5;
  static const Duration regenerationTime = Duration(minutes: 30);
  static const int heartsPerPurchase = 5;
  static const int cowriesCostPerRefill = 100;
  
  // Premium users get unlimited hearts
  static const bool premiumUnlimitedHearts = true;
}

/// Hearts/Lives System State
class HeartsState {
  final int currentHearts;
  final int maxHearts;
  final DateTime? nextHeartAt;
  final bool isUnlimited; // For premium users or challenge mode off
  final bool challengeModeEnabled;

  HeartsState({
    this.currentHearts = HeartsConfig.maxHearts,
    this.maxHearts = HeartsConfig.maxHearts,
    this.nextHeartAt,
    this.isUnlimited = false,
    this.challengeModeEnabled = false,
  });

  /// Check if user has hearts to continue
  bool get hasHearts => isUnlimited || currentHearts > 0;

  /// Check if hearts are regenerating
  bool get isRegenerating => 
      nextHeartAt != null && 
      currentHearts < maxHearts && 
      DateTime.now().isBefore(nextHeartAt!);

  /// Time until next heart
  Duration get timeUntilNextHeart {
    if (nextHeartAt == null || currentHearts >= maxHearts) {
      return Duration.zero;
    }
    final remaining = nextHeartAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format time remaining as string
  String get timeUntilNextHeartFormatted {
    final duration = timeUntilNextHeart;
    if (duration == Duration.zero) return '';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress to next heart (0.0 to 1.0)
  double get regenerationProgress {
    if (nextHeartAt == null || currentHearts >= maxHearts) return 0.0;
    
    final totalSeconds = HeartsConfig.regenerationTime.inSeconds;
    final remainingSeconds = timeUntilNextHeart.inSeconds;
    
    return 1.0 - (remainingSeconds / totalSeconds);
  }

  HeartsState copyWith({
    int? currentHearts,
    int? maxHearts,
    DateTime? nextHeartAt,
    bool? isUnlimited,
    bool? challengeModeEnabled,
  }) {
    return HeartsState(
      currentHearts: currentHearts ?? this.currentHearts,
      maxHearts: maxHearts ?? this.maxHearts,
      nextHeartAt: nextHeartAt ?? this.nextHeartAt,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      challengeModeEnabled: challengeModeEnabled ?? this.challengeModeEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentHearts': currentHearts,
    'maxHearts': maxHearts,
    'nextHeartAt': nextHeartAt?.toIso8601String(),
    'isUnlimited': isUnlimited,
    'challengeModeEnabled': challengeModeEnabled,
  };

  factory HeartsState.fromJson(Map<String, dynamic> json) {
    return HeartsState(
      currentHearts: json['currentHearts'] as int? ?? HeartsConfig.maxHearts,
      maxHearts: json['maxHearts'] as int? ?? HeartsConfig.maxHearts,
      nextHeartAt: json['nextHeartAt'] != null 
          ? DateTime.parse(json['nextHeartAt'] as String)
          : null,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      challengeModeEnabled: json['challengeModeEnabled'] as bool? ?? false,
    );
  }
}

/// Hearts Display Widget Data
class HeartDisplayData {
  final int filledHearts;
  final int emptyHearts;
  final bool showRegeneration;
  final double regenerationProgress;
  final String timeRemaining;

  HeartDisplayData({
    required this.filledHearts,
    required this.emptyHearts,
    required this.showRegeneration,
    required this.regenerationProgress,
    required this.timeRemaining,
  });

  factory HeartDisplayData.fromState(HeartsState state) {
    return HeartDisplayData(
      filledHearts: state.currentHearts,
      emptyHearts: state.maxHearts - state.currentHearts,
      showRegeneration: state.isRegenerating,
      regenerationProgress: state.regenerationProgress,
      timeRemaining: state.timeUntilNextHeartFormatted,
    );
  }
}

