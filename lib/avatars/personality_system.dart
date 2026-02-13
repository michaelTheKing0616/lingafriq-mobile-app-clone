/// Personality trait ranges (0.0 to 1.0)
class PersonalityTraits {
  /// Energy level: 0 = calm/serene, 1 = energetic/vibrant
  final double energy;
  
  /// Teaching style: 0 = strict/formal, 1 = supportive/friendly
  final double warmth;
  
  /// Humor level: 0 = serious, 1 = playful/humorous
  final double humor;
  
  /// Patience: 0 = quick/direct, 1 = patient/thorough
  final double patience;
  
  /// Cultural emphasis: 0 = universal, 1 = deeply cultural
  final double culturalAffinity;
  
  /// Expressiveness: 0 = reserved, 1 = highly expressive
  final double expressiveness;
  
  /// Wisdom/authority: 0 = peer-like, 1 = sage/elder
  final double wisdom;
  
  const PersonalityTraits({
    this.energy = 0.5,
    this.warmth = 0.5,
    this.humor = 0.5,
    this.patience = 0.5,
    this.culturalAffinity = 0.5,
    this.expressiveness = 0.5,
    this.wisdom = 0.5,
  });
  
  /// Create from preset
  factory PersonalityTraits.fromPreset(PersonalityPreset preset) {
    switch (preset) {
      case PersonalityPreset.wiseElder:
        return const PersonalityTraits(
          energy: 0.3,
          warmth: 0.8,
          humor: 0.4,
          patience: 0.9,
          culturalAffinity: 0.95,
          expressiveness: 0.6,
          wisdom: 0.95,
        );
      case PersonalityPreset.playfulGuide:
        return const PersonalityTraits(
          energy: 0.8,
          warmth: 0.9,
          humor: 0.85,
          patience: 0.7,
          culturalAffinity: 0.6,
          expressiveness: 0.9,
          wisdom: 0.4,
        );
      case PersonalityPreset.strictTeacher:
        return const PersonalityTraits(
          energy: 0.5,
          warmth: 0.4,
          humor: 0.2,
          patience: 0.6,
          culturalAffinity: 0.5,
          expressiveness: 0.4,
          wisdom: 0.7,
        );
      case PersonalityPreset.encouragingMentor:
        return const PersonalityTraits(
          energy: 0.6,
          warmth: 0.95,
          humor: 0.5,
          patience: 0.85,
          culturalAffinity: 0.7,
          expressiveness: 0.75,
          wisdom: 0.65,
        );
      case PersonalityPreset.afrofuturist:
        return const PersonalityTraits(
          energy: 0.7,
          warmth: 0.75,
          humor: 0.5,
          patience: 0.7,
          culturalAffinity: 0.85,
          expressiveness: 0.8,
          wisdom: 0.8,
        );
      case PersonalityPreset.storyteller:
        return const PersonalityTraits(
          energy: 0.65,
          warmth: 0.85,
          humor: 0.6,
          patience: 0.8,
          culturalAffinity: 0.9,
          expressiveness: 0.95,
          wisdom: 0.75,
        );
      case PersonalityPreset.adventurer:
        return const PersonalityTraits(
          energy: 0.9,
          warmth: 0.7,
          humor: 0.7,
          patience: 0.5,
          culturalAffinity: 0.6,
          expressiveness: 0.85,
          wisdom: 0.4,
        );
    }
  }
  
  /// Blend two personalities
  PersonalityTraits blend(PersonalityTraits other, double weight) {
    return PersonalityTraits(
      energy: _lerp(energy, other.energy, weight),
      warmth: _lerp(warmth, other.warmth, weight),
      humor: _lerp(humor, other.humor, weight),
      patience: _lerp(patience, other.patience, weight),
      culturalAffinity: _lerp(culturalAffinity, other.culturalAffinity, weight),
      expressiveness: _lerp(expressiveness, other.expressiveness, weight),
      wisdom: _lerp(wisdom, other.wisdom, weight),
    );
  }
  
  double _lerp(double a, double b, double t) => a + (b - a) * t;
  
  @override
  String toString() => 'PersonalityTraits(energy: $energy, warmth: $warmth, humor: $humor)';
}

/// Personality presets for quick avatar configuration
enum PersonalityPreset {
  wiseElder,
  playfulGuide,
  strictTeacher,
  encouragingMentor,
  afrofuturist,
  storyteller,
  adventurer,
}

/// Regional African cultural influence
enum CulturalInfluence {
  westAfrican,    // Yoruba, Igbo, Hausa influence
  eastAfrican,    // Swahili, Amharic influence
  southernAfrican, // Zulu, Xhosa influence
  northAfrican,   // Arabic, Berber influence
  centralAfrican, // Lingala, Kikongo influence
  panAfrican,     // Blend of all
}

/// Voice characteristics for TTS and personality expression
class VoiceCharacteristics {
  final double pitch;        // 0.5 = low, 1.5 = high
  final double rate;         // 0.5 = slow, 1.5 = fast
  final double warmth;       // Tonal warmth
  final String? preferredVoice; // TTS voice ID
  
  const VoiceCharacteristics({
    this.pitch = 1.0,
    this.rate = 1.0,
    this.warmth = 0.5,
    this.preferredVoice,
  });
}

/// Complete avatar personality profile
class AvatarPersonality {
  final String id;
  final String name;
  final String title;
  final String description;
  final PersonalityTraits traits;
  final CulturalInfluence culturalInfluence;
  final VoiceCharacteristics voice;
  final List<String> catchPhrases;
  final Map<String, String> greetings; // By time of day
  final Map<String, String> encouragements; // By context
  
  const AvatarPersonality({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.traits,
    this.culturalInfluence = CulturalInfluence.panAfrican,
    this.voice = const VoiceCharacteristics(),
    this.catchPhrases = const [],
    this.greetings = const {},
    this.encouragements = const {},
  });
  
  /// Get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return greetings['morning'] ?? 'Good morning!';
    } else if (hour < 17) {
      return greetings['afternoon'] ?? 'Good afternoon!';
    } else {
      return greetings['evening'] ?? 'Good evening!';
    }
  }
  
  /// Get contextual encouragement
  String getEncouragement(String context) {
    return encouragements[context] ?? encouragements['default'] ?? 'Keep going!';
  }
  
  /// Get random catch phrase
  String getRandomCatchPhrase() {
    if (catchPhrases.isEmpty) return '';
    final index = DateTime.now().millisecondsSinceEpoch % catchPhrases.length;
    return catchPhrases[index];
  }
}

/// Personality System - manages avatar personalities
class PersonalitySystem {
  final Map<String, AvatarPersonality> _personalities = {};
  
  PersonalitySystem() {
    _registerDefaultPersonalities();
  }
  
  /// Register default avatar personalities
  void _registerDefaultPersonalities() {
    // Pa LingAfriq - Village Elder
    _personalities['elder'] = AvatarPersonality(
      id: 'elder',
      name: 'Pa LingAfriq',
      title: 'Village Elder',
      description: 'Wise guardian of language traditions',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.wiseElder),
      culturalInfluence: CulturalInfluence.panAfrican,
      voice: const VoiceCharacteristics(pitch: 0.85, rate: 0.9, warmth: 0.8),
      catchPhrases: [
        'The wisdom of our ancestors guides us.',
        'Every word carries the spirit of those before us.',
        'Language is the bridge between generations.',
      ],
      greetings: {
        'morning': 'The sun rises on a new day of learning, child.',
        'afternoon': 'The midday sun illuminates our path.',
        'evening': 'As stars appear, so does wisdom.',
      },
      encouragements: {
        'default': 'Patience is the mother of learning.',
        'mistake': 'Even the mightiest baobab grew from a seed.',
        'success': 'Your ancestors smile upon you today.',
      },
    );
    
    // Adisa the Weaver
    _personalities['weaver'] = AvatarPersonality(
      id: 'weaver',
      name: 'Adisa',
      title: 'The Weaver',
      description: 'Creative language artisan who weaves words together',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.encouragingMentor),
      culturalInfluence: CulturalInfluence.westAfrican,
      voice: const VoiceCharacteristics(pitch: 1.1, rate: 1.0, warmth: 0.9),
      catchPhrases: [
        'Let us weave these words together!',
        'Every thread of language creates beauty.',
        'Your vocabulary is your loom.',
      ],
      greetings: {
        'morning': 'Ready to weave new patterns today?',
        'afternoon': 'Our tapestry of words grows beautiful!',
        'evening': 'Another beautiful day of weaving words!',
      },
      encouragements: {
        'default': 'You\'re creating something beautiful!',
        'mistake': 'Even the best weavers make adjustments.',
        'success': 'What a masterpiece you\'ve created!',
      },
    );
    
    // Kofi the Timekeeper
    _personalities['timekeeper'] = AvatarPersonality(
      id: 'timekeeper',
      name: 'Kofi',
      title: 'The Timekeeper',
      description: 'Organized guide who keeps learning on track',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.strictTeacher),
      culturalInfluence: CulturalInfluence.westAfrican,
      voice: const VoiceCharacteristics(pitch: 1.0, rate: 1.1, warmth: 0.6),
      catchPhrases: [
        'Time is the currency of mastery.',
        'Consistency builds fluency.',
        'Every minute counts on your journey.',
      ],
      greetings: {
        'morning': 'Right on time! Let\'s begin.',
        'afternoon': 'Perfect timing for afternoon practice!',
        'evening': 'Evening study is wise study.',
      },
      encouragements: {
        'default': 'Stay focused, you\'re making progress.',
        'mistake': 'Take a moment, then try again.',
        'success': 'Excellent timing and execution!',
      },
    );
    
    // Amara the Griot
    _personalities['griot'] = AvatarPersonality(
      id: 'griot',
      name: 'Amara',
      title: 'The Griot',
      description: 'Expressive storyteller and keeper of oral traditions',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.storyteller),
      culturalInfluence: CulturalInfluence.westAfrican,
      voice: const VoiceCharacteristics(pitch: 1.05, rate: 0.95, warmth: 0.85),
      catchPhrases: [
        'Let me tell you a story...',
        'In the language of our people...',
        'Words are the drums of the heart.',
      ],
      greetings: {
        'morning': 'A new chapter begins with the sunrise!',
        'afternoon': 'The story continues...',
        'evening': 'Evening brings tales of wisdom.',
      },
      encouragements: {
        'default': 'You\'re writing your own story!',
        'mistake': 'Every great story has its twists.',
        'success': 'A tale worth telling!',
      },
    );
    
    // Zuri the Pathfinder
    _personalities['pathfinder'] = AvatarPersonality(
      id: 'pathfinder',
      name: 'Zuri',
      title: 'The Pathfinder',
      description: 'Adventurous guide who helps set and achieve goals',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.adventurer),
      culturalInfluence: CulturalInfluence.eastAfrican,
      voice: const VoiceCharacteristics(pitch: 1.15, rate: 1.1, warmth: 0.75),
      catchPhrases: [
        'Adventure awaits in every lesson!',
        'The path to fluency is an exciting journey!',
        'Let\'s explore new territories!',
      ],
      greetings: {
        'morning': 'Ready for today\'s adventure?',
        'afternoon': 'The journey continues!',
        'evening': 'Evening expeditions are the best!',
      },
      encouragements: {
        'default': 'Onward to new discoveries!',
        'mistake': 'Even explorers take wrong turns!',
        'success': 'You\'ve conquered new territory!',
      },
    );
    
    // Polie - AI Assistant
    _personalities['polie'] = AvatarPersonality(
      id: 'polie',
      name: 'Polie',
      title: 'AI Language Companion',
      description: 'Afro-futurist AI assistant bridging tradition and technology',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.afrofuturist),
      culturalInfluence: CulturalInfluence.panAfrican,
      voice: const VoiceCharacteristics(pitch: 1.0, rate: 1.0, warmth: 0.7),
      catchPhrases: [
        'Connecting ancestral wisdom with future possibilities.',
        'I\'m here to guide your language journey.',
        'Together, we bridge worlds.',
      ],
      greetings: {
        'morning': 'Good morning! Ready to explore languages together?',
        'afternoon': 'Good afternoon! Let\'s continue our journey.',
        'evening': 'Good evening! Perfect time for learning.',
      },
      encouragements: {
        'default': 'You\'re doing great! Keep going.',
        'mistake': 'Every attempt brings you closer to mastery.',
        'success': 'Excellent work! Your progress is remarkable.',
      },
    );
    
    // Game Avatars
    _personalities['malaika'] = AvatarPersonality(
      id: 'malaika',
      name: 'Malaika',
      title: 'Vocabulary Guide',
      description: 'Playful word explorer for vocabulary games',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.playfulGuide),
      culturalInfluence: CulturalInfluence.eastAfrican,
      voice: const VoiceCharacteristics(pitch: 1.2, rate: 1.1, warmth: 0.9),
      catchPhrases: [
        'Words are like treasures!',
        'Let\'s discover new words!',
        'Every word is a new friend!',
      ],
      greetings: {
        'morning': 'Good morning, word explorer!',
        'afternoon': 'Ready for word adventures?',
        'evening': 'Evening word hunt time!',
      },
      encouragements: {
        'default': 'Great word choice!',
        'mistake': 'Oops! Let\'s try another word!',
        'success': 'Word master!',
      },
    );
    
    _personalities['baba'] = AvatarPersonality(
      id: 'baba',
      name: 'Baba',
      title: 'Cultural Elder',
      description: 'Wise guide for cultural games',
      traits: PersonalityTraits.fromPreset(PersonalityPreset.wiseElder),
      culturalInfluence: CulturalInfluence.panAfrican,
      voice: const VoiceCharacteristics(pitch: 0.8, rate: 0.9, warmth: 0.85),
      catchPhrases: [
        'Culture is the soul of language.',
        'Our traditions teach us everything.',
        'Listen to the wisdom of the land.',
      ],
      greetings: {
        'morning': 'The ancestors welcome you.',
        'afternoon': 'The sun shines on your learning.',
        'evening': 'Evening brings reflection.',
      },
      encouragements: {
        'default': 'The culture lives through you.',
        'mistake': 'Wisdom comes through experience.',
        'success': 'You honor our traditions!',
      },
    );
    
    _personalities['okonkwo'] = AvatarPersonality(
      id: 'okonkwo',
      name: 'Okonkwo',
      title: 'Tone Master',
      description: 'Precise guide for pronunciation games',
      traits: PersonalityTraits(
        energy: 0.6,
        warmth: 0.6,
        humor: 0.3,
        patience: 0.8,
        culturalAffinity: 0.7,
        expressiveness: 0.7,
        wisdom: 0.6,
      ),
      culturalInfluence: CulturalInfluence.westAfrican,
      voice: const VoiceCharacteristics(pitch: 0.95, rate: 0.9, warmth: 0.6),
      catchPhrases: [
        'Tone is meaning!',
        'Listen carefully to the melody.',
        'Your tongue must dance!',
      ],
      greetings: {
        'morning': 'Morning practice perfects tone.',
        'afternoon': 'Let\'s refine your sounds.',
        'evening': 'Evening ears are sharp.',
      },
      encouragements: {
        'default': 'Feel the rhythm of the words.',
        'mistake': 'Close! Let\'s adjust the tone.',
        'success': 'Perfect pitch!',
      },
    );
    
    _personalities['nneka'] = AvatarPersonality(
      id: 'nneka',
      name: 'Nneka',
      title: 'Grammar Teacher',
      description: 'Methodical guide for grammar games',
      traits: PersonalityTraits(
        energy: 0.5,
        warmth: 0.7,
        humor: 0.4,
        patience: 0.9,
        culturalAffinity: 0.6,
        expressiveness: 0.6,
        wisdom: 0.7,
      ),
      culturalInfluence: CulturalInfluence.westAfrican,
      voice: const VoiceCharacteristics(pitch: 1.05, rate: 0.95, warmth: 0.7),
      catchPhrases: [
        'Structure gives meaning.',
        'Grammar is the skeleton of language.',
        'Build sentences with care.',
      ],
      greetings: {
        'morning': 'Ready to build beautiful sentences?',
        'afternoon': 'Let\'s structure our thoughts.',
        'evening': 'Evening grammar is elegant.',
      },
      encouragements: {
        'default': 'Your structure is improving!',
        'mistake': 'Let\'s rearrange that.',
        'success': 'Grammatically perfect!',
      },
    );
  }
  
  /// Get personality by ID
  AvatarPersonality? getPersonality(String id) => _personalities[id];
  
  /// Get all personalities
  List<AvatarPersonality> get allPersonalities => _personalities.values.toList();
  
  /// Register custom personality
  void registerPersonality(AvatarPersonality personality) {
    _personalities[personality.id] = personality;
  }
  
  /// Get personality for game category
  AvatarPersonality getGamePersonality(GameCategory category) {
    switch (category) {
      case GameCategory.vocabulary:
        return _personalities['malaika']!;
      case GameCategory.cultural:
        return _personalities['baba']!;
      case GameCategory.pronunciation:
        return _personalities['okonkwo']!;
      case GameCategory.grammar:
        return _personalities['nneka']!;
    }
  }
  
  /// Get onboarding personality for step
  AvatarPersonality getOnboardingPersonality(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return _personalities['elder']!;
      case OnboardingStep.languageSelection:
        return _personalities['weaver']!;
      case OnboardingStep.goals:
        return _personalities['pathfinder']!;
      case OnboardingStep.learningStyle:
        return _personalities['weaver']!; // Learning style guided by Adisa
      case OnboardingStep.schedule:
        return _personalities['timekeeper']!;
      case OnboardingStep.story:
        return _personalities['griot']!;
      case OnboardingStep.profile:
        return _personalities['elder']!; // Profile setup guided by elder
      case OnboardingStep.complete:
        return _personalities['elder']!;
    }
  }
}

/// Game categories for avatar selection
enum GameCategory {
  vocabulary,
  cultural,
  pronunciation,
  grammar,
}

/// Onboarding steps for avatar selection
enum OnboardingStep {
  welcome,
  languageSelection,
  goals,
  learningStyle,
  schedule,
  story,
  profile,
  complete,
}
