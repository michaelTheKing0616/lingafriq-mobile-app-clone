/// Cultural Mastery Profile
/// Tracks user's mastery across different cultural and linguistic dimensions
class CulturalMasteryProfile {
  final String userId;
  final String language;
  final double tones; // 0.0 to 1.0
  final double rhythm; // 0.0 to 1.0
  final double politeness; // 0.0 to 1.0
  final double proverbDepth; // 0.0 to 1.0
  final double storytelling; // 0.0 to 1.0
  final double culturalContext; // 0.0 to 1.0
  final DateTime lastUpdated;

  CulturalMasteryProfile({
    required this.userId,
    required this.language,
    this.tones = 0.0,
    this.rhythm = 0.0,
    this.politeness = 0.0,
    this.proverbDepth = 0.0,
    this.storytelling = 0.0,
    this.culturalContext = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Overall mastery score
  double get overallMastery {
    return (tones + rhythm + politeness + proverbDepth + storytelling + culturalContext) / 6.0;
  }

  /// Update mastery based on game result
  CulturalMasteryProfile updateFromGame({
    required String gameId,
    required double accuracy,
    required double learningSignal,
  }) {
    double newTones = tones;
    double newRhythm = rhythm;
    double newPoliteness = politeness;
    double newProverbDepth = proverbDepth;
    double newStorytelling = storytelling;
    double newCulturalContext = culturalContext;

    // Update based on game type
    switch (gameId) {
      case 'tone_forge':
      case 'tone_trainer':
        newTones = (tones + learningSignal).clamp(0.0, 1.0);
        break;
      case 'drum_rhythm_shadowing':
      case 'rhythm_typing':
        newRhythm = (rhythm + learningSignal).clamp(0.0, 1.0);
        break;
      case 'greeting_diplomacy_challenge':
      case 'cultural_etiquette_scenarios':
        newPoliteness = (politeness + learningSignal).clamp(0.0, 1.0);
        break;
      case 'proverb_unlocker':
      case 'elders_blessings_challenge':
        newProverbDepth = (proverbDepth + learningSignal).clamp(0.0, 1.0);
        break;
      case 'clan_lineage_story_builder':
      case 'folktale_reconstruction':
        newStorytelling = (storytelling + learningSignal).clamp(0.0, 1.0);
        break;
      default:
        newCulturalContext = (culturalContext + learningSignal).clamp(0.0, 1.0);
    }

    return CulturalMasteryProfile(
      userId: userId,
      language: language,
      tones: newTones,
      rhythm: newRhythm,
      politeness: newPoliteness,
      proverbDepth: newProverbDepth,
      storytelling: newStorytelling,
      culturalContext: newCulturalContext,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language,
      'tones': tones,
      'rhythm': rhythm,
      'politeness': politeness,
      'proverb_depth': proverbDepth,
      'storytelling': storytelling,
      'cultural_context': culturalContext,
      'overall_mastery': overallMastery,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory CulturalMasteryProfile.fromJson(Map<String, dynamic> json) {
    return CulturalMasteryProfile(
      userId: json['user_id'] as String,
      language: json['language'] as String,
      tones: (json['tones'] as num?)?.toDouble() ?? 0.0,
      rhythm: (json['rhythm'] as num?)?.toDouble() ?? 0.0,
      politeness: (json['politeness'] as num?)?.toDouble() ?? 0.0,
      proverbDepth: (json['proverb_depth'] as num?)?.toDouble() ?? 0.0,
      storytelling: (json['storytelling'] as num?)?.toDouble() ?? 0.0,
      culturalContext: (json['cultural_context'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }
}

