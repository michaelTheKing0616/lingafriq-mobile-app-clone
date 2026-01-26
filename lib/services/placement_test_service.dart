import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/placement_question.dart';
import 'curriculum_service.dart';

/// Static placement test content and evaluation logic.
/// This gives each supported language a small but meaningful set of
/// questions at different CEFR bands. The structure is easy to extend.
class PlacementTestService {
  /// Load questions for a language, expanding the static bank with
  /// curriculum- and Polie-generated items when available.
  static Future<List<PlacementQuestion>> loadQuestionsForLanguage(
    dynamic ref,
    String languageCode,
  ) async {
    // Start from the curated static bank.
    final base = questionsForLanguage(languageCode);

    try {
      final curriculumService = CurriculumService(ref as Ref);
      final langKey = languageCode.toLowerCase();

      // Try to generate a small set of additional exercises using Polie,
      // seeded from curriculum vocab/grammar when available.
      final compactA1 = await curriculumService.loadCompactCurriculum(langKey, 'A1');
      final vocabList = <Map<String, dynamic>>[];
      final grammarList = <String>[];

      if (compactA1 != null) {
        final units = (compactA1['units'] as List?) ?? [];
        if (units.isNotEmpty) {
          final firstUnit = units.first as Map<String, dynamic>;
          final lessons = (firstUnit['lessons'] as List?) ?? [];
          if (lessons.isNotEmpty) {
            final firstLesson = lessons.first as Map<String, dynamic>;
            final vocab = (firstLesson['vocab'] as List?) ?? [];
            for (final v in vocab.take(8)) {
              if (v is Map<String, dynamic>) {
                final word = (v['word'] ?? '').toString();
                final meaning = (v['meaning'] ?? '').toString();
                if (word.isNotEmpty && meaning.isNotEmpty) {
                  vocabList.add({'word': word, 'meaning': meaning});
                }
              } else if (v is String) {
                vocabList.add({'word': v, 'meaning': ''});
              }
            }
            final grammar = (firstLesson['grammar'] as List?) ?? [];
            for (final g in grammar.take(4)) {
              grammarList.add(g.toString());
            }
          }
        }
      }

      // Fall back to deriving a bit of vocab from static questions if needed.
      if (vocabList.isEmpty) {
        for (final q in base.take(6)) {
          vocabList.add({
            'word': q.prompt,
            'meaning': q.options[q.correctIndex],
          });
        }
      }

      final exercises = await curriculumService.generateExercises(
        language: langKey,
        level: 'A1',
        vocab: vocabList,
        grammar: grammarList,
      );

      final generated = <PlacementQuestion>[];
      var counter = 0;
      for (final ex in exercises) {
        if (counter >= 8) break; // keep placement test tight
        final type = (ex['type'] ?? '').toString().toLowerCase();
        final prompt = (ex['prompt'] ?? '').toString();
        final options = (ex['options'] as List?)?.map((e) => e.toString()).toList();
        final answer = ex['answer'];

        if (prompt.isEmpty || options == null || options.length < 2) continue;

        final correctIndex = options.indexWhere(
          (o) => o.toString().trim().toLowerCase() == answer.toString().trim().toLowerCase(),
        );
        if (correctIndex < 0) continue;

        final level = ex['level']?.toString() ?? 'A1';
        final skill = type.contains('grammar')
            ? 'grammar'
            : type.contains('listening')
                ? 'listening'
                : type.contains('reading')
                    ? 'reading'
                    : 'vocab';

        generated.add(
          PlacementQuestion(
            id: 'gen_${langKey}_${level}_$counter',
            languageCode: langKey,
            level: level,
            skill: skill,
            prompt: prompt,
            options: options,
            correctIndex: correctIndex,
          ),
        );
        counter++;
      }

      if (generated.isEmpty) {
        return base;
      }

      // Combine static and generated, giving a richer, multi-skill placement.
      return [...base, ...generated];
    } catch (_) {
      // If anything goes wrong, fall back to the static bank.
      return base;
    }
  }

  static List<PlacementQuestion> questionsForLanguage(String languageCode) {
    final code = languageCode.toLowerCase();

    if (code.contains('yoruba')) return _yorubaQuestions;
    if (code.contains('swahili')) return _swahiliQuestions;
    if (code.contains('hausa')) return _hausaQuestions;
    if (code.contains('igbo')) return _igboQuestions;
    if (code.contains('zulu')) return _zuluQuestions;
    if (code.contains('xhosa')) return _xhosaQuestions;
    if (code.contains('amharic') || code == 'am') return _amharicQuestions;
    if (code.contains('twi')) return _twiQuestions;
    if (code.contains('afrikaans')) return _afrikaansQuestions;
    if (code.contains('pidgin')) return _pidginQuestions;
    if (code.contains('wolof')) return _wolofQuestions;
    if (code.contains('somali')) return _somaliQuestions;

    // Fallback: use Swahili set as a reasonable default
    return _swahiliQuestions;
  }

  /// Evaluate answers and map to a CEFR-ish level using simple bands.
  static PlacementResult evaluate({
    required String languageCode,
    required List<PlacementQuestion> questions,
    required List<int?> selectedIndices,
  }) {
    int correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final sel = (i < selectedIndices.length) ? selectedIndices[i] : null;
      if (sel != null && sel == questions[i].correctIndex) {
        correct++;
      }
    }

    final total = questions.length;
    final pct = total == 0 ? 0.0 : (correct / total * 100.0);
    final level = _mapScoreToCEFR(pct);

    return PlacementResult(
      languageCode: languageCode,
      level: level,
      score: double.parse(pct.toStringAsFixed(1)),
      totalQuestions: total,
      correct: correct,
    );
  }

  static String _mapScoreToCEFR(double pct) {
    if (pct < 20) return 'A1';
    if (pct < 40) return 'A2';
    if (pct < 55) return 'B1';
    if (pct < 70) return 'B2';
    if (pct < 85) return 'C1';
    return 'C2';
  }

  // --- Question banks (trimmed but meaningful, easy to extend) ---

  static final List<PlacementQuestion> _yorubaQuestions = [
    PlacementQuestion(
      id: 'yo_a1_greeting',
      languageCode: 'yoruba',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does this Yoruba greeting mean: “Báwo ni?”',
      options: [
        'How are you?',
        'Where are you going?',
        'What is your name?',
        'Good morning',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'yo_a1_thanks',
      languageCode: 'yoruba',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you” in Yoruba?',
      options: [
        'Ṣé dáadáa ni?',
        'Ẹ kú ìròlé',
        'Ẹ ṣé',
        'Má bínú',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      id: 'yo_a2_tone',
      languageCode: 'yoruba',
      level: 'A2',
      skill: 'listening',
      prompt: 'Which pair best shows how tone changes meaning in Yoruba?',
      options: [
        '“ilé” (house) vs “ilé” (house)',
        '“bá” (to meet) vs “bà” (to spoil)',
        '“ọmọ” vs “ọmọ” (same meaning)',
        '“ẹ̀kọ́” vs “ẹ̀kọ́” (same meaning)',
      ],
      correctIndex: 1,
    ),
  ];

  static final List<PlacementQuestion> _swahiliQuestions = [
    PlacementQuestion(
      id: 'sw_a1_greeting',
      languageCode: 'swahili',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does the Swahili phrase “Habari gani?” mean?',
      options: [
        'What is your name?',
        'How are you? / What\'s the news?',
        'Where are you from?',
        'Good night',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      id: 'sw_a1_reply',
      languageCode: 'swahili',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which is a natural reply to “Asante”?',
      options: [
        'Karibu',
        'Samahani',
        'Ndiyo',
        'Hapana',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'sw_a2_verb',
      languageCode: 'swahili',
      level: 'A2',
      skill: 'grammar',
      prompt: 'Complete: “Nina ___ Kiswahili kidogo.”',
      options: [
        'sema',
        'ongea',
        'jua',
        'zungumza',
      ],
      correctIndex: 2, // "najua Kiswahili kidogo" pattern
    ),
  ];

  static final List<PlacementQuestion> _hausaQuestions = [
    PlacementQuestion(
      id: 'ha_a1_greeting',
      languageCode: 'hausa',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Sannu” mean in Hausa?',
      options: [
        'Goodbye',
        'Welcome',
        'Hello',
        'Thank you',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      id: 'ha_a1_thanks',
      languageCode: 'hausa',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you very much” in Hausa?',
      options: [
        'Na gode sosai',
        'Ina wuni',
        'Sai anjima',
        'Lafiya lau',
      ],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _igboQuestions = [
    PlacementQuestion(
      id: 'ig_a1_greeting',
      languageCode: 'igbo',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Kedu?” mean in Igbo?',
      options: [
        'How are you?',
        'What is your name?',
        'Where are you going?',
        'Good afternoon',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'ig_a1_thanks',
      languageCode: 'igbo',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you” in Igbo?',
      options: [
        'Nnoo',
        'Imela',
        'Biko',
        'Kachifo',
      ],
      correctIndex: 1,
    ),
  ];

  static final List<PlacementQuestion> _zuluQuestions = [
    PlacementQuestion(
      id: 'zu_a1_greeting',
      languageCode: 'zulu',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Sawubona” mean in isiZulu?',
      options: [
        'Goodbye',
        'Hello',
        'Thank you',
        'Please',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      id: 'zu_a1_thanks',
      languageCode: 'zulu',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you” in isiZulu?',
      options: [
        'Ngiyabonga',
        'Ngicela',
        'Sawubona',
        'Hamba kahle',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'zu_a1_please',
      languageCode: 'zulu',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which isiZulu word is commonly used for “please”?',
      options: [
        'Ngicela',
        'Ngiyabonga',
        'Yebo',
        'Cha',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'zu_a2_yesno',
      languageCode: 'zulu',
      level: 'A2',
      skill: 'vocab',
      prompt: 'Choose the correct pair for “yes” and “no” in isiZulu.',
      options: [
        'Yebo / Cha',
        'Cha / Yebo',
        'Sawubona / Hamba kahle',
        'Ngiyabonga / Ngicela',
      ],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _afrikaansQuestions = [
    PlacementQuestion(
      id: 'af_a1_greeting',
      languageCode: 'afrikaans',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Goeie more” mean in Afrikaans?',
      options: [
        'Good morning',
        'Good evening',
        'Thank you',
        'How are you?',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'af_a1_thanks',
      languageCode: 'afrikaans',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you” in Afrikaans?',
      options: [
        'Dankie',
        'Asseblief',
        'Hallo',
        'Totsiens',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'af_a1_please',
      languageCode: 'afrikaans',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Asseblief” mean?',
      options: [
        'Please',
        'Sorry',
        'Welcome',
        'Good night',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'af_a2_order',
      languageCode: 'afrikaans',
      level: 'A2',
      skill: 'grammar',
      prompt: 'Which sentence is a natural Afrikaans word order for “I like coffee”?',
      options: [
        'Ek hou van koffie.',
        'Ek koffie hou van.',
        'Hou ek van koffie.',
        'Van koffie ek hou.',
      ],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _pidginQuestions = [
    PlacementQuestion(
      id: 'pcm_a1_greeting',
      languageCode: 'pidgin',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “How far?” mean in Nigerian Pidgin?',
      options: [
        'How tall are you?',
        'How are you / what\'s up?',
        'How far is the place?',
        'Where are you?',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      id: 'pcm_a1_thanks',
      languageCode: 'pidgin',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which phrase is closest to “Thank you” in Nigerian Pidgin?',
      options: [
        'I dey thank you',
        'Wetin dey happen?',
        'Abeg',
        'You welcome',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'pcm_a1_please',
      languageCode: 'pidgin',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Abeg” commonly mean in Nigerian Pidgin?',
      options: [
        'Please',
        'Goodbye',
        'Morning',
        'Food',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'pcm_a2_meaning',
      languageCode: 'pidgin',
      level: 'A2',
      skill: 'reading',
      prompt: 'If someone says “I no fit come today”, what do they mean?',
      options: [
        'I can’t come today.',
        'I will come today.',
        'I came today.',
        'I don’t know today.',
      ],
      correctIndex: 0,
    ),
  ];

  // Additional supported languages (to avoid falling back to Swahili for users).
  static final List<PlacementQuestion> _xhosaQuestions = [
    PlacementQuestion(
      id: 'xh_a1_greeting',
      languageCode: 'xhosa',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Molo” mean in isiXhosa?',
      options: ['Hello', 'Goodbye', 'Thank you', 'Please'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'xh_a1_thanks',
      languageCode: 'xhosa',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “Thank you” in isiXhosa?',
      options: ['Enkosi', 'Ewe', 'Hayi', 'Molo'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'xh_a1_yes',
      languageCode: 'xhosa',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which word means “yes” in isiXhosa?',
      options: ['Ewe', 'Hayi', 'Enkosi', 'Ndicela'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'xh_a2_no',
      languageCode: 'xhosa',
      level: 'A2',
      skill: 'vocab',
      prompt: 'Which word means “no” in isiXhosa?',
      options: ['Hayi', 'Ewe', 'Enkosi', 'Molo'],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _amharicQuestions = [
    PlacementQuestion(
      id: 'am_a1_greeting',
      languageCode: 'amharic',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which Amharic greeting means “hello”?',
      options: ['ሰላም (Selam)', 'አመሰግናለሁ (Amesegenallo)', 'እሺ (Ishi)', 'ቻው (Chao)'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'am_a1_thanks',
      languageCode: 'amharic',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which Amharic phrase means “thank you”?',
      options: ['አመሰግናለሁ (Amesegenallo)', 'ሰላም (Selam)', 'እሺ (Ishi)', 'በጣም (Betam)'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'am_a1_yes',
      languageCode: 'amharic',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which word is commonly used for “okay/yes” in Amharic?',
      options: ['እሺ (Ishi)', 'ሰላም (Selam)', 'አመሰግናለሁ (Amesegenallo)', 'አይ (Ay)'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'am_a2_no',
      languageCode: 'amharic',
      level: 'A2',
      skill: 'vocab',
      prompt: 'Which word means “no” in Amharic?',
      options: ['አይ (Ay)', 'እሺ (Ishi)', 'ሰላም (Selam)', 'እንኳን (Enkwan)'],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _twiQuestions = [
    PlacementQuestion(
      id: 'tw_a1_greeting',
      languageCode: 'twi',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does the Twi greeting “Ɛte sɛn?” mean?',
      options: ['How are you?', 'Good morning', 'Thank you', 'Goodbye'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'tw_a1_thanks',
      languageCode: 'twi',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which Twi phrase means “thank you”?',
      options: ['Medaase', 'Aane', 'Dabi', 'Maakye'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'tw_a1_yesno',
      languageCode: 'twi',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Choose the correct pair for “yes” and “no” in Twi.',
      options: ['Aane / Dabi', 'Dabi / Aane', 'Medaase / Maakye', 'Maakye / Medaase'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'tw_a2_goodmorning',
      languageCode: 'twi',
      level: 'A2',
      skill: 'vocab',
      prompt: 'What does “Maakye” mean?',
      options: ['Good morning', 'Good night', 'Please', 'Welcome'],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _wolofQuestions = [
    PlacementQuestion(
      id: 'wo_a1_greeting',
      languageCode: 'wolof',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which Wolof greeting is commonly used for “hello”?',
      options: ['Salaam aleekum', 'Jërëjëf', 'Ba beneen yoon', 'Waaw'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'wo_a1_thanks',
      languageCode: 'wolof',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which Wolof word means “thank you”?',
      options: ['Jërëjëf', 'Waaw', 'Déedéet', 'Salaam'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'wo_a1_yesno',
      languageCode: 'wolof',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which word means “yes” in Wolof?',
      options: ['Waaw', 'Déedéet', 'Jërëjëf', 'Ba beneen yoon'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'wo_a2_no',
      languageCode: 'wolof',
      level: 'A2',
      skill: 'vocab',
      prompt: 'Which word means “no” in Wolof?',
      options: ['Déedéet', 'Waaw', 'Jërëjëf', 'Salaam'],
      correctIndex: 0,
    ),
  ];

  static final List<PlacementQuestion> _somaliQuestions = [
    PlacementQuestion(
      id: 'so_a1_greeting',
      languageCode: 'somali',
      level: 'A1',
      skill: 'vocab',
      prompt: 'What does “Salaan” mean in Somali?',
      options: ['Hello', 'Goodbye', 'Thank you', 'Please'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'so_a1_thanks',
      languageCode: 'somali',
      level: 'A1',
      skill: 'vocab',
      prompt: 'How do you say “thank you” in Somali?',
      options: ['Mahadsanid', 'Salaan', 'Haye', 'Maya'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'so_a1_yesno',
      languageCode: 'somali',
      level: 'A1',
      skill: 'vocab',
      prompt: 'Which word means “yes/okay” in Somali?',
      options: ['Haye', 'Maya', 'Mahadsanid', 'Salaan'],
      correctIndex: 0,
    ),
    PlacementQuestion(
      id: 'so_a2_no',
      languageCode: 'somali',
      level: 'A2',
      skill: 'vocab',
      prompt: 'Which word means “no” in Somali?',
      options: ['Maya', 'Haye', 'Salaan', 'Mahadsanid'],
      correctIndex: 0,
    ),
  ];
}


