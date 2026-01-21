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

    // Nigerian Pidgin English (Nigeria/West Africa) - ELITE FEATURE
    LoadingScreenContent(
      id: 'pidgin_nigeria_1',
      imageUrl: 'assets/images/loading/pidgin_nigeria_1.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'How far?',
      greetingTranslation: 'How are you? / What\'s up?',
      language: 'Nigerian Pidgin',
      fact: 'Nigerian Pidgin is spoken by over 75 million people across Nigeria and West Africa, making it one of the most widely spoken creole languages in the world.',
    ),
    LoadingScreenContent(
      id: 'pidgin_nigeria_2',
      imageUrl: 'assets/images/loading/pidgin_nigeria_2.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Wetin dey happen?',
      greetingTranslation: 'What\'s happening?',
      language: 'Nigerian Pidgin',
      fact: 'Nigerian Pidgin blends English vocabulary with indigenous African grammar structures, creating a unique and vibrant linguistic fusion.',
    ),
    LoadingScreenContent(
      id: 'pidgin_nigeria_3',
      imageUrl: 'assets/images/loading/pidgin_nigeria_3.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'How you dey?',
      greetingTranslation: 'How are you doing?',
      language: 'Nigerian Pidgin',
      fact: 'Despite not being an official language, Nigerian Pidgin serves as a lingua franca uniting over 500 ethnic groups in Nigeria.',
    ),
    LoadingScreenContent(
      id: 'pidgin_nigeria_4',
      imageUrl: 'assets/images/loading/pidgin_nigeria_4.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Na so!',
      greetingTranslation: 'Exactly! / That\'s right!',
      language: 'Nigerian Pidgin',
      fact: 'Nigerian Pidgin has rich expressions and idioms, like "No wahala" (no problem) and "I go come" (I will come), that reflect Nigerian culture.',
    ),

    // Additional Swahili Facts
    LoadingScreenContent(
      id: 'swahili_kenya_3',
      imageUrl: 'assets/images/loading/swahili_kenya_3.png',
      country: 'Kenya',
      countryFlag: '🇰🇪',
      greeting: 'Hujambo?',
      greetingTranslation: 'How are you? (formal)',
      language: 'Swahili',
      fact: 'Swahili is the official language of the African Union and is taught in schools across East Africa.',
    ),
    LoadingScreenContent(
      id: 'swahili_tanzania_3',
      imageUrl: 'assets/images/loading/swahili_tanzania_3.png',
      country: 'Tanzania',
      countryFlag: '🇹🇿',
      greeting: 'Asante sana!',
      greetingTranslation: 'Thank you very much!',
      language: 'Swahili',
      fact: 'Swahili literature dates back centuries and includes epic poetry, prose, and modern novels.',
    ),

    // Additional Yoruba Facts
    LoadingScreenContent(
      id: 'yoruba_nigeria_3',
      imageUrl: 'assets/images/loading/yoruba_nigeria_3.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'E seun!',
      greetingTranslation: 'Thank you!',
      language: 'Yoruba',
      fact: 'Yoruba has a tonal system with three tones (high, mid, low) that change word meanings entirely.',
    ),
    LoadingScreenContent(
      id: 'yoruba_nigeria_4',
      imageUrl: 'assets/images/loading/yoruba_nigeria_4.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'E kasan!',
      greetingTranslation: 'Good afternoon!',
      language: 'Yoruba',
      fact: 'Yoruba is spoken in Nigeria, Benin, and Togo, and has a strong presence in Brazil and Cuba due to the transatlantic slave trade.',
    ),

    // Additional Zulu Facts
    LoadingScreenContent(
      id: 'zulu_south_africa_3',
      imageUrl: 'assets/images/loading/zulu_south_africa_3.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Yebo!',
      greetingTranslation: 'Yes!',
      language: 'Zulu',
      fact: 'Zulu has 15 click consonants, making it one of the most distinctive languages in the world.',
    ),
    LoadingScreenContent(
      id: 'zulu_south_africa_4',
      imageUrl: 'assets/images/loading/zulu_south_africa_4.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Ngiyabonga!',
      greetingTranslation: 'Thank you!',
      language: 'Zulu',
      fact: 'Zulu culture has a rich tradition of praise poetry (izibongo) performed at important ceremonies.',
    ),

    // Additional Igbo Facts
    LoadingScreenContent(
      id: 'igbo_nigeria_2',
      imageUrl: 'assets/images/loading/igbo_nigeria_2.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Kedu ka ị mere?',
      greetingTranslation: 'How did you do? / How are you?',
      language: 'Igbo',
      fact: 'Igbo is known for its complex system of vowel harmony, where vowels within a word must agree.',
    ),
    LoadingScreenContent(
      id: 'igbo_nigeria_3',
      imageUrl: 'assets/images/loading/igbo_nigeria_3.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Ndewo!',
      greetingTranslation: 'Hello! (welcome)',
      language: 'Igbo',
      fact: 'The Igbo calendar is based on a 4-day week and 13-month year, reflecting ancient timekeeping traditions.',
    ),

    // Additional Hausa Facts
    LoadingScreenContent(
      id: 'hausa_nigeria_2',
      imageUrl: 'assets/images/loading/hausa_nigeria_2.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Ina kwana?',
      greetingTranslation: 'Good morning / How did you sleep?',
      language: 'Hausa',
      fact: 'Hausa is written in both Latin script (Boko) and Arabic script (Ajami), reflecting its dual heritage.',
    ),
    LoadingScreenContent(
      id: 'hausa_nigeria_3',
      imageUrl: 'assets/images/loading/hausa_nigeria_3.png',
      country: 'Nigeria',
      countryFlag: '🇳🇬',
      greeting: 'Nagode!',
      greetingTranslation: 'Thank you!',
      language: 'Hausa',
      fact: 'Hausa poetry (wakoki) is a celebrated art form, with poets composing verses on social, religious, and political themes.',
    ),

    // Additional Amharic Facts
    LoadingScreenContent(
      id: 'amharic_ethiopia_2',
      imageUrl: 'assets/images/loading/amharic_ethiopia_2.png',
      country: 'Ethiopia',
      countryFlag: '🇪🇹',
      greeting: 'Amesegenallo!',
      greetingTranslation: 'Thank you!',
      language: 'Amharic',
      fact: 'Amharic uses the Ge\'ez script, one of the oldest writing systems still in use today, dating back over 2,000 years.',
    ),

    // Additional Xhosa Facts
    LoadingScreenContent(
      id: 'xhosa_south_africa_2',
      imageUrl: 'assets/images/loading/xhosa_south_africa_2.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Molo kakuhle!',
      greetingTranslation: 'Hello well! / Hello, good day!',
      language: 'Xhosa',
      fact: 'Xhosa has 18 click sounds, making it one of the languages with the most clicks in the world.',
    ),

    // Additional Twi Facts
    LoadingScreenContent(
      id: 'twi_ghana_2',
      imageUrl: 'assets/images/loading/twi_ghana_2.png',
      country: 'Ghana',
      countryFlag: '🇬🇭',
      greeting: 'Ete sen?',
      greetingTranslation: 'How is it? / How are you?',
      language: 'Twi',
      fact: 'Twi proverbs (ebe) are an essential part of Akan culture, used in daily conversation to convey wisdom.',
    ),

    // Afrikaans (South Africa)
    LoadingScreenContent(
      id: 'afrikaans_south_africa_1',
      imageUrl: 'assets/images/loading/afrikaans_south_africa_1.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Goeie môre!',
      greetingTranslation: 'Good morning!',
      language: 'Afrikaans',
      fact: 'Afrikaans evolved from Dutch and is spoken by over 7 million people in South Africa and Namibia.',
    ),
    LoadingScreenContent(
      id: 'afrikaans_south_africa_2',
      imageUrl: 'assets/images/loading/afrikaans_south_africa_2.png',
      country: 'South Africa',
      countryFlag: '🇿🇦',
      greeting: 'Baie dankie!',
      greetingTranslation: 'Thank you very much!',
      language: 'Afrikaans',
      fact: 'Afrikaans is the third most spoken language in South Africa and has influenced South African English significantly.',
    ),

    // Wolof (Senegal/Gambia)
    LoadingScreenContent(
      id: 'wolof_senegal_1',
      imageUrl: 'assets/images/loading/wolof_senegal_1.png',
      country: 'Senegal',
      countryFlag: '🇸🇳',
      greeting: 'Asalamu alaikum!',
      greetingTranslation: 'Peace be upon you!',
      language: 'Wolof',
      fact: 'Wolof is the lingua franca of Senegal and Gambia, spoken by over 10 million people.',
    ),
    LoadingScreenContent(
      id: 'wolof_senegal_2',
      imageUrl: 'assets/images/loading/wolof_senegal_2.png',
      country: 'Senegal',
      countryFlag: '🇸🇳',
      greeting: 'Nanga def?',
      greetingTranslation: 'How are you?',
      language: 'Wolof',
      fact: 'Wolof culture is famous for its griots (storytellers) who preserve history through oral traditions.',
    ),

    // Somali (Somalia)
    LoadingScreenContent(
      id: 'somali_somalia_1',
      imageUrl: 'assets/images/loading/somali_somalia_1.png',
      country: 'Somalia',
      countryFlag: '🇸🇴',
      greeting: 'Iska warran!',
      greetingTranslation: 'How are you?',
      language: 'Somali',
      fact: 'Somali is an official language in Somalia, Somaliland, and Djibouti, with over 20 million speakers.',
    ),
    LoadingScreenContent(
      id: 'somali_somalia_2',
      imageUrl: 'assets/images/loading/somali_somalia_2.png',
      country: 'Somalia',
      countryFlag: '🇸🇴',
      greeting: 'Mahadsanid!',
      greetingTranslation: 'Thank you!',
      language: 'Somali',
      fact: 'Somali poetry (gabay) is highly valued and used in traditional storytelling, politics, and daily communication.',
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

