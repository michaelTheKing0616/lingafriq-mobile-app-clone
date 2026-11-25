/// Viseme contract for Rive Character VM (P11-042). Phoneme tables live in assets.
library;

/// Canonical mouth shapes; wire names match [character_vm.schema.json].
enum Viseme {
  sil('sil'),
  pp('PP'),
  ff('FF'),
  th('TH'),
  dd('DD'),
  kk('kk'),
  ch('CH'),
  ss('SS'),
  nn('nn'),
  rr('RR'),
  aa('aa'),
  e('E'),
  i('I'),
  o('O'),
  u('U'),
  kp('KP'),
  gb('GB'),
  clickC('C'),
  clickQ('Q'),
  clickX('X'),
  /// Nasal vowel / N~ (Rive wire: Nnasal).
  nasal('Nnasal');

  const Viseme(this.wireName);

  final String wireName;

  static Viseme? parseWire(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final key = raw.trim();
    if (key == 'N~') return Viseme.nasal;
    for (final v in Viseme.values) {
      if (v.wireName == key) return v;
    }
    return null;
  }
}

const Map<String, double> visemeOpennessByWire = {
  'sil': 0,
  'PP': 0.12,
  'FF': 0.18,
  'TH': 0.22,
  'DD': 0.28,
  'kk': 0.22,
  'CH': 0.24,
  'SS': 0.16,
  'nn': 0.2,
  'RR': 0.34,
  'aa': 0.85,
  'E': 0.42,
  'I': 0.28,
  'O': 0.5,
  'U': 0.32,
  'KP': 0.12,
  'GB': 0.14,
  'C': 0.2,
  'Q': 0.3,
  'X': 0.16,
  'Nnasal': 0.36,
};

/// Built-in tables (mirrors [assets/lipsync/maps/phoneme_maps.json]).
class PhonemeVisemeMapRegistry {
  PhonemeVisemeMapRegistry._();

  static final Map<String, Map<String, String>> _byLanguage =
      _loadFromBundleJson(kPhonemeMapsBundleJson);

  static Map<String, Map<String, String>> _loadFromBundleJson(
    Map<String, dynamic> root,
  ) {
    final shared = Map<String, String>.from(
      (root['shared'] as Map).cast<String, String>(),
    );
    final langs = root['languages'] as Map<String, dynamic>;
    final out = <String, Map<String, String>>{'default': shared};
    for (final entry in langs.entries) {
      out[entry.key] = {...shared, ...Map<String, String>.from(entry.value as Map)};
    }
    return out;
  }

  /// Merges decoded [phoneme_maps.json] at runtime (tests / hot reload).
  static void applyBundleJson(Map<String, dynamic> root) {
    _byLanguage
      ..clear()
      ..addAll(_loadFromBundleJson(root));
  }

  static Map<String, Map<String, String>> tables() =>
      Map<String, Map<String, String>>.from(_byLanguage);

  /// IPA / MFA phoneme → viseme wire. Never reads orthographic letters.
  static String? visemeWireForPhoneme(String languageId, String phoneme) {
    final key = phoneme.trim();
    if (key.isEmpty) return null;
    final lang = languageId.trim().toLowerCase();
    final table = _byLanguage[lang] ?? _byLanguage['default']!;
    return table[key] ?? _byLanguage['default']![key];
  }

  static Viseme? visemeForPhoneme(String languageId, String phoneme) {
    final wire = visemeWireForPhoneme(languageId, phoneme);
    return wire == null ? null : Viseme.parseWire(wire);
  }
}

/// Top-level helper used by lip-sync track code.
String? visemeWireForPhoneme(String language, String phoneme) =>
    PhonemeVisemeMapRegistry.visemeWireForPhoneme(language, phoneme);

String? visemeForPhoneme(String language, String phoneme) =>
    PhonemeVisemeMapRegistry.visemeForPhoneme(language, phoneme)?.wireName;

const Map<String, dynamic> kPhonemeMapsBundleJson = {
  'version': 1,
  'shared': {
    'sil': 'sil',
    'a': 'aa',
    'ɑ': 'aa',
    'e': 'E',
    'ɛ': 'E',
    'i': 'I',
    'ɪ': 'I',
    'o': 'O',
    'ɔ': 'O',
    'u': 'U',
    'ʊ': 'U',
    'p': 'PP',
    'b': 'PP',
    'm': 'PP',
    'f': 'FF',
    'v': 'FF',
    'θ': 'TH',
    'ð': 'TH',
    't': 'DD',
    'd': 'DD',
    'k': 'kk',
    'g': 'kk',
    's': 'SS',
    'z': 'SS',
    'ʃ': 'CH',
    'ʒ': 'CH',
    'tʃ': 'CH',
    'dʒ': 'CH',
    'n': 'nn',
    'ŋ': 'nn',
    'ɲ': 'nn',
    'r': 'RR',
    'ɾ': 'RR',
    'l': 'DD',
    'h': 'aa',
    'w': 'U',
    'j': 'I',
    'kp': 'KP',
    'gb': 'GB',
  },
  'languages': {
    'yo': {
      'ã': 'Nnasal',
      'ɛ̃': 'Nnasal',
      'ĩ': 'Nnasal',
      'ɔ̃': 'Nnasal',
      'ũ': 'Nnasal',
      'ẹ': 'E',
      'ọ': 'O',
    },
    'zu': {
      'ǀ': 'C',
      'ǁ': 'Q',
      'ǃ': 'X',
    },
    'am': {
      'kʼ': 'Q',
      'tʼ': 'Q',
      'pʼ': 'Q',
      'sʼ': 'Q',
      'tʃʼ': 'Q',
      'x': 'X',
      'χ': 'X',
    },
    'ti': {
      'kʼ': 'Q',
      'tʼ': 'Q',
      'pʼ': 'Q',
      'sʼ': 'Q',
      'tʃʼ': 'Q',
      'x': 'X',
      'χ': 'X',
    },
  },
};
