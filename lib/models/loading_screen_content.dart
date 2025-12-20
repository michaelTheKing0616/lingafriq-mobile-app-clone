/// Model for dynamic loading screen content
class LoadingScreenContent {
  final String id;
  final String imageUrl; // URL or asset path for the person's image
  final String country; // Country name (e.g., "Nigeria", "South Africa", "Kenya")
  final String countryFlag; // Emoji flag (e.g., "🇳🇬", "🇿🇦", "🇰🇪")
  final String greeting; // Greeting in the local language
  final String greetingTranslation; // English translation
  final String language; // Language name (e.g., "Swahili", "Yoruba", "Zulu")
  final String fact; // Interesting fact about Africa/the language
  final String? personName; // Optional: Name of the person (for AI-generated images)

  LoadingScreenContent({
    required this.id,
    required this.imageUrl,
    required this.country,
    required this.countryFlag,
    required this.greeting,
    required this.greetingTranslation,
    required this.language,
    required this.fact,
    this.personName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'country': country,
        'countryFlag': countryFlag,
        'greeting': greeting,
        'greetingTranslation': greetingTranslation,
        'language': language,
        'fact': fact,
        'personName': personName,
      };

  factory LoadingScreenContent.fromJson(Map<String, dynamic> json) =>
      LoadingScreenContent(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        country: json['country'] as String,
        countryFlag: json['countryFlag'] as String,
        greeting: json['greeting'] as String,
        greetingTranslation: json['greetingTranslation'] as String,
        language: json['language'] as String,
        fact: json['fact'] as String,
        personName: json['personName'] as String?,
      );
}

/// Curated list of loading screen content
/// This can be expanded with more entries and eventually replaced with API calls
class LoadingScreenContentData {
  static final List<LoadingScreenContent> defaultContent = [
    // Swahili (Kenya/Tanzania)
    LoadingScreenContent(
      id: 'swahili_kenya_1',
      imageUrl: 'assets/images/loading/swahili_kenya_1.png', // Placeholder - will be replaced with AI-generated
      country: 'Kenya',
      countryFlag: '🇰🇪',
      greeting: 'Karibu!',
      greetingTranslation: 'Welcome!',
      language: 'Swahili',
      fact: 'Did you know? "Jambo" is a common Swahili greeting used across East Africa.',
    ),
    LoadingScreenContent(
      id: 'swahili_tanzania_1',
      imageUrl: 'assets/images/loading/swahili_tanzania_1.png',
      country: 'Tanzania',
      countryFlag: '🇹🇿',
      greeting: 'Habari!',
      greetingTranslation: 'How are you?',
      language: 'Swahili',
      fact: 'Swahili is spoken by over 200 million people across East and Central Africa.',
    ),

    // Yoruba (Nigeria)
    LoadingScreenContent(
      id: 'yoruba_nigeria_1',
      imageUrl: 'assets/images/loading/yoruba_nigeria_1.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Bawo ni!',
      greetingTranslation: 'How are you?',
      language: 'Yoruba',
      fact: 'Yoruba is one of the three major languages of Nigeria, spoken by over 40 million people.',
    ),
    LoadingScreenContent(
      id: 'yoruba_nigeria_2',
      imageUrl: 'assets/images/loading/yoruba_nigeria_2.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'E kaaro!',
      greetingTranslation: 'Good morning!',
      language: 'Yoruba',
      fact: 'Yoruba culture is known for its rich oral traditions, including proverbs and folktales.',
    ),

    // Zulu (South Africa)
    LoadingScreenContent(
      id: 'zulu_south_africa_1',
      imageUrl: 'assets/images/loading/zulu_south_africa_1.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Sawubona!',
      greetingTranslation: 'Hello!',
      language: 'Zulu',
      fact: 'Zulu is the most widely spoken language in South Africa, with over 12 million speakers.',
    ),
    LoadingScreenContent(
      id: 'zulu_south_africa_2',
      imageUrl: 'assets/images/loading/zulu_south_africa_2.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Unjani?',
      greetingTranslation: 'How are you?',
      language: 'Zulu',
      fact: 'The Zulu kingdom was one of the most powerful empires in Southern Africa during the 19th century.',
    ),

    // Igbo (Nigeria)
    LoadingScreenContent(
      id: 'igbo_nigeria_1',
      imageUrl: 'assets/images/loading/igbo_nigeria_1.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Kedu!',
      greetingTranslation: 'How are you?',
      language: 'Igbo',
      fact: 'Igbo is one of the four official languages of Nigeria, spoken by over 30 million people.',
    ),

    // Hausa (Nigeria/West Africa)
    LoadingScreenContent(
      id: 'hausa_nigeria_1',
      imageUrl: 'assets/images/loading/hausa_nigeria_1.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Sannu!',
      greetingTranslation: 'Hello!',
      language: 'Hausa',
      fact: 'Hausa is the most widely spoken language in West Africa, with over 85 million speakers.',
    ),

    // Amharic (Ethiopia)
    LoadingScreenContent(
      id: 'amharic_ethiopia_1',
      imageUrl: 'assets/images/loading/amharic_ethiopia_1.png',
      country: 'Ethiopia',
      countryFlag: '🇪🇹',
      greeting: 'Selam!',
      greetingTranslation: 'Hello!',
      language: 'Amharic',
      fact: 'Amharic is the official language of Ethiopia and uses its own unique script called Ge\'ez.',
    ),

    // Xhosa (South Africa)
    LoadingScreenContent(
      id: 'xhosa_south_africa_1',
      imageUrl: 'assets/images/loading/xhosa_south_africa_1.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Molo!',
      greetingTranslation: 'Hello!',
      language: 'Xhosa',
      fact: 'Xhosa is known for its distinctive click consonants, which are represented by letters like "c", "q", and "x".',
    ),

    // Twi (Ghana)
    LoadingScreenContent(
      id: 'twi_ghana_1',
      imageUrl: 'assets/images/loading/twi_ghana_1.png',
      country: 'Ghana',
      countryFlag: '🇬🇭',
      greeting: 'Akwaaba!',
      greetingTranslation: 'Welcome!',
      language: 'Twi',
      fact: 'Twi is the most widely spoken language in Ghana and is part of the Akan language family.',
    ),
  ];

  /// Get a random content item
  static LoadingScreenContent getRandom() {
    final random = DateTime.now().millisecondsSinceEpoch % defaultContent.length;
    return defaultContent[random];
  }

  /// Get content by country
  static List<LoadingScreenContent> getByCountry(String country) {
    return defaultContent.where((c) => c.country == country).toList();
  }

  /// Get content by language
  static List<LoadingScreenContent> getByLanguage(String language) {
    return defaultContent.where((c) => c.language == language).toList();
  }
}

