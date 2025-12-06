import 'package:collection/collection.dart';

/// Lightweight diacritics enforcement for supported African languages.
/// Uses conservative phrase-level maps; safe to extend at runtime.
class DiacriticsEnforcer {
  static final Map<String, Map<String, String>> _maps = {
    'yoruba': {
      'bawo': 'Báwo',
      'bawo ni': 'Báwo ní',
      'bawo ni?': 'Báwo ní?',
      'bawo ni o': 'Báwo ní o',
      'bawo ni o?': 'Báwo ní o?',
      'e kaaro': 'Ẹ káàrọ̀',
      'e kaale': 'Ẹ káalẹ́',
      'e kaabo': 'Ẹ káàbọ̀',
      'e n le': 'Ẹ n lẹ',
      'e n lẹ': 'Ẹ n lẹ',
      'mo n ko eko': 'Mo ń kọ́ ẹ̀kọ́',
      'mo n ko': 'Mo ń kọ́',
      'e se': 'Ẹ ṣé',
      'e seun': 'Ẹ ṣéun',
      'o se': 'Ó ṣé',
      'mo n ko ẹkọ': 'Mo ń kọ́ ẹ̀kọ́',
      'mo n kọ ẹkọ': 'Mo ń kọ́ ẹ̀kọ́',
      'mo n kọ': 'Mo ń kọ́',
    },
    'hausa': {
      'sannu': 'Sannu',
      'ina kwana': 'Ina kwana',
      'lafiya lau?': 'Lafiya lau?',
      'na gode': 'Na gode',
      'ina koyo': 'Ina koyo',
    },
    'igbo': {
      'ndewo': 'Ndewo',
      'kedụ?': 'Kedu?',
      'kedu?': 'Kedu?',
      'ụtụtụ ọma': 'Ụtụtụ ọma',
      'daalụ': 'Daalụ',
      'a na m amụta': 'A na m amụta',
    },
    'swahili': {
      'hujambo': 'Hujambo',
      'habari gani?': 'Habari gani?',
      'habari ya asubuhi': 'Habari ya asubuhi',
      'asante': 'Asante',
      'ninajifunza': 'Ninajifunza',
    },
  };

  static String enforce(String text, String? language) {
    if (text.isEmpty || language == null || language.trim().isEmpty) {
      return text;
    }
    final lang = language.toLowerCase();
    final map = _maps[lang];
    if (map == null) return text;

    // Phrase-level replacement if full match found
    final normalized = text.trim().toLowerCase();
    final direct = map[normalized];
    if (direct != null) return direct;

    // Token-wise soft correction: replace any mapped tokens
    final words = text.splitMapJoin(
      RegExp(r'\\b\\w[\\w\\u00C0-\\u1FFF\\u2C00-\\uD7FF]*\\b',
          unicode: true),
      onMatch: (m) {
        final token = m.group(0)!;
        final replacement =
            map.entries.firstWhereOrNull((e) => e.key == token.toLowerCase());
        return replacement?.value ?? token;
      },
      onNonMatch: (s) => s,
    );
    return words;
  }
}

