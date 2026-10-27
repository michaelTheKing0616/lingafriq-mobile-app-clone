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
  final bool isUnlimited; // For premium users
  /// Learner opted in to Challenge Mode (off by default).
  final bool challengeModeEnabled;
  /// Hearts apply only while a run started from Challenge Mode is active.
  final bool challengeRunActive;

  HeartsState({
    this.currentHearts = HeartsConfig.maxHearts,
    this.maxHearts = HeartsConfig.maxHearts,
    this.nextHeartAt,
    this.isUnlimited = false,
    this.challengeModeEnabled = false,
    this.challengeRunActive = false,
  });

  /// Hearts gate gameplay only during an active Challenge Mode run.
  bool get heartsApply =>
      challengeModeEnabled && challengeRunActive && !isUnlimited;

  /// Check if user has hearts to continue (always true outside Challenge runs).
  bool get hasHearts => !heartsApply || isUnlimited || currentHearts > 0;

  bool get showHeartsUi => heartsApply;

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
    bool? challengeRunActive,
  }) {
    return HeartsState(
      currentHearts: currentHearts ?? this.currentHearts,
      maxHearts: maxHearts ?? this.maxHearts,
      nextHeartAt: nextHeartAt ?? this.nextHeartAt,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      challengeModeEnabled: challengeModeEnabled ?? this.challengeModeEnabled,
      challengeRunActive: challengeRunActive ?? this.challengeRunActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentHearts': currentHearts,
    'maxHearts': maxHearts,
    'nextHeartAt': nextHeartAt?.toIso8601String(),
    'isUnlimited': isUnlimited,
    'challengeModeEnabled': challengeModeEnabled,
    'challengeRunActive': challengeRunActive,
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
      challengeRunActive: json['challengeRunActive'] as bool? ?? false,
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

class ChallengeRunResult {
  final bool won;
  final int heartsRemaining;
  final List<String> badges;
  final bool braggingRecorded;
  final bool serverSyncFailed;

  const ChallengeRunResult({
    required this.won,
    required this.heartsRemaining,
    required this.badges,
    this.braggingRecorded = false,
    this.serverSyncFailed = false,
  });
}

