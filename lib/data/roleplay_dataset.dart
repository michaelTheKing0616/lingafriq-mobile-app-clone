import 'dart:convert';
import 'dart:math';

/// Roleplay dataset entry model
class RoleplayEntry {
  final int id;
  final String language;
  final String mode;
  final String scenario;
  final String userUtterance;
  final String assistantResponse;
  final String notes;

  RoleplayEntry({
    required this.id,
    required this.language,
    required this.mode,
    required this.scenario,
    required this.userUtterance,
    required this.assistantResponse,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'language': language,
        'mode': mode,
        'scenario': scenario,
        'user_utterance': userUtterance,
        'assistant_response': assistantResponse,
        'notes': notes,
      };

  factory RoleplayEntry.fromJson(Map<String, dynamic> json) => RoleplayEntry(
        id: json['id'] as int,
        language: json['language'] as String,
        mode: json['mode'] as String,
        scenario: json['scenario'] as String,
        userUtterance: json['user_utterance'] as String,
        assistantResponse: json['assistant_response'] as String,
        notes: json['notes'] as String,
      );
}

/// Roleplay Dataset Provider
/// Manages roleplay scenarios for different languages and modes
class RoleplayDataset {
  static final List<RoleplayEntry> _dataset = [];
  static final Random _random = Random();

  /// Initialize dataset with provided entries
  static void initialize(List<RoleplayEntry> entries) {
    _dataset.clear();
    _dataset.addAll(entries);
  }

  /// Get roleplay entries for a specific language
  static List<RoleplayEntry> getByLanguage(String language) {
    final lang = language.toLowerCase();
    return _dataset.where((e) => e.language.toLowerCase() == lang).toList();
  }

  /// Get roleplay entries for a specific scenario
  static List<RoleplayEntry> getByScenario(String scenario) {
    return _dataset
        .where((e) => e.scenario.toLowerCase().contains(scenario.toLowerCase()))
        .toList();
  }

  /// Get a random roleplay entry for a language
  static RoleplayEntry? getRandomForLanguage(String language) {
    final entries = getByLanguage(language);
    if (entries.isEmpty) return null;
    return entries[_random.nextInt(entries.length)];
  }

  /// Get roleplay entries by mode
  static List<RoleplayEntry> getByMode(String mode) {
    return _dataset.where((e) => e.mode.toLowerCase() == mode.toLowerCase()).toList();
  }

  /// Get all available scenarios for a language
  static List<String> getScenariosForLanguage(String language) {
    final entries = getByLanguage(language);
    return entries.map((e) => e.scenario).toSet().toList();
  }

  /// Get few-shot examples for prompt engineering
  static List<RoleplayEntry> getFewShotExamples(String language, {int count = 3}) {
    final entries = getByLanguage(language);
    if (entries.isEmpty) return [];
    
    // Shuffle and take first N
    final shuffled = List<RoleplayEntry>.from(entries)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// Search entries by keyword
  static List<RoleplayEntry> search(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _dataset.where((e) {
      return e.scenario.toLowerCase().contains(lowerKeyword) ||
          e.userUtterance.toLowerCase().contains(lowerKeyword) ||
          e.assistantResponse.toLowerCase().contains(lowerKeyword) ||
          e.notes.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  /// Get all entries
  static List<RoleplayEntry> getAll() => List.unmodifiable(_dataset);

  /// Get entry count
  static int get count => _dataset.length;

  /// Load dataset from JSON string
  static void loadFromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _dataset.clear();
      _dataset.addAll(
        jsonList.map((json) => RoleplayEntry.fromJson(json as Map<String, dynamic>)),
      );
    } catch (e) {
      throw Exception('Failed to load roleplay dataset: $e');
    }
  }

  /// Export dataset to JSON string
  static String exportToJson() {
    final jsonList = _dataset.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }
}

/// Pre-loaded roleplay dataset (Block 1: Examples 1-40)
/// Additional blocks can be added by calling RoleplayDataset.initialize()
class RoleplayDatasetLoader {
  static void loadBlock1() {
    final entries = [
      // Yoruba entries (1-5, 26-28, 37, 49, 51, 56, 59)
      RoleplayEntry(
        id: 1,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Greeting an elder respectfully',
        userUtterance: 'Good morning, sir.',
        assistantResponse: 'Ẹ káàrọ̀ sir. Ṣé àlàáfíà ni?',
        notes: 'Honorific use; respectful register required.',
      ),
      RoleplayEntry(
        id: 2,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Buying fruit in a Lagos market',
        userUtterance: 'How much is this pineapple?',
        assistantResponse: 'Eleyi jẹ́ ẹgbẹ̀rún méjì. Ṣé ẹ fẹ́ ra meji?',
        notes: 'Market vocabulary; price negotiation phrases.',
      ),
      RoleplayEntry(
        id: 3,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Visiting a friend\'s home',
        userUtterance: 'I\'m happy to see you!',
        assistantResponse: 'Inú mi dùn láti rí yín pẹ̀lú! Ẹ bọ̀ wá sílé.',
        notes: 'Colloquial, friendly tone.',
      ),
      RoleplayEntry(
        id: 4,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Ordering food at a buka',
        userUtterance: 'Can I get amala and ewedu?',
        assistantResponse: 'Bẹ́ẹ̀ni, ẹ lè gba àmàlà àti ewédú. Ṣé ẹ fẹ́ ẹ̀gúsí tàbí gbègìrì pẹ̀lú?',
        notes: 'Food vocabulary; soft-sell upsell.',
      ),
      RoleplayEntry(
        id: 5,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Asking for directions',
        userUtterance: 'Where is the bus stop?',
        assistantResponse: 'Ibùsọ̀ ọkò̀ ojú pópó wà ní iwájú, gbà ọ̀tún lẹ́yìn ilé itaja.',
        notes: 'Spatial terms, prepositions.',
      ),
      RoleplayEntry(
        id: 26,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'At a doctor\'s office',
        userUtterance: 'I have a headache.',
        assistantResponse: 'Ó dáa. Ẹ ní orí ń dun yín? Mọ̀ pé kí n fi oogun rọ yín.',
        notes: 'Medical vocabulary.',
      ),
      RoleplayEntry(
        id: 27,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Asking for help',
        userUtterance: 'Can you help me?',
        assistantResponse: 'Bẹ́ẹ̀ni, mo lè ràn yín lọ́wọ́. Kí ni ẹ nílò?',
        notes: 'Polite request.',
      ),
      RoleplayEntry(
        id: 28,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Ordering a drink',
        userUtterance: 'I\'d like cold water.',
        assistantResponse: 'Ẹ jọ̀ọ́, ẹ fẹ́ omi tútù, ṣé bẹ́ẹ̀ ni?',
        notes: 'Adjectives + polite particle.',
      ),
      RoleplayEntry(
        id: 37,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'At school',
        userUtterance: 'Where is the classroom?',
        assistantResponse: 'Kíláàsì wà ní ilé kejì. Ẹ tẹ̀lé ọ̀pá yìí.',
        notes: 'School vocabulary.',
      ),
      RoleplayEntry(
        id: 51,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Restaurant',
        userUtterance: 'What should I say?',
        assistantResponse: 'Say: **\'Ẹ jọ̀ọ́, ẹ fun mi ní omi.\'** (Please, give me water.)',
        notes: 'Polite restaurant request.',
      ),
      RoleplayEntry(
        id: 56,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Translation',
        userUtterance: 'Translate: \'I respect your decision.\'',
        assistantResponse: 'Yoruba: \'Mo bọ̀wọ̀ fún ipinnu yín.\'',
        notes: 'Respectful expression.',
      ),
      RoleplayEntry(
        id: 59,
        language: 'yoruba',
        mode: 'roleplay',
        scenario: 'Tutor - Phonetics',
        userUtterance: 'How do I say \'Where are you going?\' with correct tones?',
        assistantResponse: 'Say: **\'Níbò lo ń lọ?\'** (High–mid–mid tones).',
        notes: 'Tone patterns.',
      ),

      // Igbo entries (6-10, 29-30, 38)
      RoleplayEntry(
        id: 6,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Meeting someone for the first time',
        userUtterance: 'Nice to meet you.',
        assistantResponse: 'Ọ dị m ụtọ izute gị. Kedu ka ị mere?',
        notes: 'Polite register.',
      ),
      RoleplayEntry(
        id: 7,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Buying vegetables',
        userUtterance: 'How much is this tomato?',
        assistantResponse: 'Ọ bụ naira iri abụọ. Ị chọrọ otu, ma ọ bụ ọtụtụ?',
        notes: 'Vendor pricing routines.',
      ),
      RoleplayEntry(
        id: 8,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Checking into a hotel',
        userUtterance: 'I have a reservation.',
        assistantResponse: 'Ọ dị mma. Biko nye m aha gị ka m lelee ya.',
        notes: 'Service / formal Igbo.',
      ),
      RoleplayEntry(
        id: 9,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Starting small talk',
        userUtterance: 'It\'s a beautiful day.',
        assistantResponse: 'Ee, ọ bụ ezigbo ụbọchị taa. Ị na-aga ebee?',
        notes: 'Conversational bridge phrases.',
      ),
      RoleplayEntry(
        id: 10,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Asking about health',
        userUtterance: 'Are you well?',
        assistantResponse: 'A dị m mma, daalụ. Kedu ka i mere?',
        notes: 'Basic wellness check.',
      ),
      RoleplayEntry(
        id: 29,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'At a bus park',
        userUtterance: 'When does the bus leave?',
        assistantResponse: 'Ọ ga-apụ n\'elekere atọ. Biko nwee ndidi.',
        notes: 'Transport timing phrases.',
      ),
      RoleplayEntry(
        id: 30,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Making a request',
        userUtterance: 'Can I borrow your pen?',
        assistantResponse: 'Ee, ị nwere ike. Naanị were n\'oge ole-ole.',
        notes: 'Borrow/lend patterns.',
      ),
      RoleplayEntry(
        id: 38,
        language: 'igbo',
        mode: 'roleplay',
        scenario: 'Talking about hobbies',
        userUtterance: 'I like music.',
        assistantResponse: 'Ọ dị mma! A hụrụ m egwu n\'anya kwa. Ị na-egwu egwu ụdị gị?',
        notes: 'Present tense verb forms.',
      ),

      // Hausa entries (11-15, 31-32, 39)
      RoleplayEntry(
        id: 11,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Greeting politely',
        userUtterance: 'Good afternoon.',
        assistantResponse: 'Ina wuni? Barka da yamma.',
        notes: 'Dual greeting patterns.',
      ),
      RoleplayEntry(
        id: 12,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Shopping for clothing',
        userUtterance: 'Do you have this in a larger size?',
        assistantResponse: 'Eh, muna da girma mafi girma. Ga shi nan.',
        notes: 'Adjective agreement.',
      ),
      RoleplayEntry(
        id: 13,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'At the pharmacy',
        userUtterance: 'I need pain medicine.',
        assistantResponse: 'Lafiya. Kina so maganin ciwo mai laushi ko mai ƙarfi?',
        notes: 'Healthcare vocabulary.',
      ),
      RoleplayEntry(
        id: 14,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Taking a taxi',
        userUtterance: 'Can you take me to the airport?',
        assistantResponse: 'I, zan kai ka filin jirgi. Za mu tafi yanzu?',
        notes: 'Transport phrases.',
      ),
      RoleplayEntry(
        id: 15,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Weather talk',
        userUtterance: 'It\'s very hot today.',
        assistantResponse: 'Hakika! Rana tana da zafi sosai yau.',
        notes: 'Descriptive adjectives.',
      ),
      RoleplayEntry(
        id: 31,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Feeling sick',
        userUtterance: 'I don\'t feel well.',
        assistantResponse: 'Sannu. Kana jin zafi a ina? Zan taimaka.',
        notes: 'Empathy phrase \'sannu\'.',
      ),
      RoleplayEntry(
        id: 32,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Ordering tea',
        userUtterance: 'I want tea with milk.',
        assistantResponse: 'Ina so shayi da madara. Ga kujerar zama.',
        notes: 'Food collocation.',
      ),
      RoleplayEntry(
        id: 39,
        language: 'hausa',
        mode: 'roleplay',
        scenario: 'Buying airtime',
        userUtterance: 'I need MTN credit.',
        assistantResponse: 'Ga shi nan. Naira ɗari. Kana so ƙara?',
        notes: 'Common Nigerian context.',
      ),

      // Swahili entries (16-20, 33-34, 40, 43, 47, 50, 55, 58)
      RoleplayEntry(
        id: 16,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Meeting someone',
        userUtterance: 'Hello, my friend!',
        assistantResponse: 'Hujambo rafiki yangu! Habari yako leo?',
        notes: 'Informal greeting.',
      ),
      RoleplayEntry(
        id: 17,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Buying street food',
        userUtterance: 'I\'d like two samosas.',
        assistantResponse: 'Sawa! Samosa mbili, tafadhali. Ungependa pilipili?',
        notes: 'Food / polite requests.',
      ),
      RoleplayEntry(
        id: 18,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Checking time',
        userUtterance: 'What time is it?',
        assistantResponse: 'Ni saa nne na nusu. Una haraka?',
        notes: 'Time expressions.',
      ),
      RoleplayEntry(
        id: 19,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Tourist asking for help',
        userUtterance: 'Where can I find a bank?',
        assistantResponse: 'Benki iko kule upande wa kushoto. Fuata barabara hii moja kwa moja.',
        notes: 'Directional guidance.',
      ),
      RoleplayEntry(
        id: 20,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'At a café',
        userUtterance: 'Do you have Wi-Fi?',
        assistantResponse: 'Ndiyo, tunayo. Hapa ni nenosiri: \'Karibu2025\'.',
        notes: 'Loanword usage (Wi-Fi).',
      ),
      RoleplayEntry(
        id: 33,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Asking for price',
        userUtterance: 'Is this cheap?',
        assistantResponse: 'Si ghali sana. Unaweza punguzo kidogo?',
        notes: 'Negotiation patterns.',
      ),
      RoleplayEntry(
        id: 34,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Calling a friend',
        userUtterance: 'Where are you?',
        assistantResponse: 'Niko njiani. Nafika dakika tano.',
        notes: 'Time estimation phrases.',
      ),
      RoleplayEntry(
        id: 40,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Asking for location',
        userUtterance: 'Where is the museum?',
        assistantResponse: 'Makumbusho iko mbele kidogo. Fuata barabara ya kulia.',
        notes: 'Directions.',
      ),
      RoleplayEntry(
        id: 50,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Corrections',
        userUtterance: 'Is \'Nataka chakula tamu sana\' good Swahili?',
        assistantResponse: 'Yes but a bit direct. A more natural, friendly version is: **\'Ningependa chakula kitamu sana.\'**',
        notes: 'Polite form correction.',
      ),
      RoleplayEntry(
        id: 55,
        language: 'swahili',
        mode: 'roleplay',
        scenario: 'Job interview',
        userUtterance: 'How would I say that?',
        assistantResponse: 'Say: **\'Shikamoo. Asante kwa kunialika.\'**',
        notes: 'Formal interview greeting.',
      ),

      // Zulu entries (21-25, 35-36)
      RoleplayEntry(
        id: 21,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Greeting politely',
        userUtterance: 'Good morning.',
        assistantResponse: 'Sawubona. Unjani namuhla?',
        notes: 'Standard Zulu greeting.',
      ),
      RoleplayEntry(
        id: 22,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Asking for water',
        userUtterance: 'Can I have some water?',
        assistantResponse: 'Ungangipha amanzi, ngiyacela? Nalu ingilazi.',
        notes: 'Softening with \'ngiyacela\'.',
      ),
      RoleplayEntry(
        id: 23,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Finding transportation',
        userUtterance: 'Where can I find a taxi?',
        assistantResponse: 'It ekisi litholakala phesheya. Landela lomgwaqo.',
        notes: 'Colloquial phrasing.',
      ),
      RoleplayEntry(
        id: 24,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Ordering food',
        userUtterance: 'I want chicken and rice.',
        assistantResponse: 'Ngifuna inyama yenkukhu nerayisi, ngiyacela.',
        notes: 'Polite forms + food nouns.',
      ),
      RoleplayEntry(
        id: 25,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Expressing gratitude',
        userUtterance: 'Thank you so much.',
        assistantResponse: 'Ngiyabonga kakhulu! Ngiyakwazisa impela.',
        notes: 'Intensifiers.',
      ),
      RoleplayEntry(
        id: 35,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'At a restaurant',
        userUtterance: 'Do you have a menu?',
        assistantResponse: 'Yebo, nansi imenyu. Ufuna ukusiza ngikuchazele?',
        notes: 'Service interactions.',
      ),
      RoleplayEntry(
        id: 36,
        language: 'zulu',
        mode: 'roleplay',
        scenario: 'Meeting family',
        userUtterance: 'This is my sister.',
        assistantResponse: 'Lo ngumfowethu wesifazane. Ngiyajabula ukumazi!',
        notes: 'Kinship terms.',
      ),
    ];

    RoleplayDataset.initialize(entries);
  }
}

