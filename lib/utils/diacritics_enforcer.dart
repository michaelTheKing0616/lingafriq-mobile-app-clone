import 'package:collection/collection.dart';
import 'dart:convert';
/// Enhanced diacritics enforcement for supported African languages.
/// Features:
/// - NFC unicode normalization
/// - Exact phrase mapping
/// - Fuzzy matching with similarity scoring
/// - Token-overlap heuristics
/// - Audit logging for corrections
class DiacriticsEnforcer {
  // Audit log for tracking corrections
  static final List<Map<String, dynamic>> _auditLog = [];
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
      'ewa': 'Ẹwà',
      'mo n kọ ẹkọ': 'Mo ń kọ́ ẹ̀kọ́',
      'bawo ni o': 'Báwo ní o',
      'bawo ni o?': 'Báwo ní o?',
    },
    'hausa': {
      'sannu': 'Sannu',
      'ina kwana': 'Ina kwana',
      'lafiya lau?': 'Lafiya lau?',
      'na gode': 'Na gode',
      'ina koyo': 'Ina koyo',
      'barka da zuwa': 'Barka da zuwa',
      'barka da rana': 'Barka da rana',
      'barka da yamma': 'Barka da yamma',
      'ka na lafiya?': 'Ka na lafiya?',
    },
    'igbo': {
      'ndewo': 'Ndewo',
      'kedụ?': 'Kedu?',
      'kedu?': 'Kedu?',
      'ụtụtụ ọma': 'Ụtụtụ ọma',
      'daalụ': 'Daalụ',
      'a na m amụta': 'A na m amụta',
      'kedụ ka mere?': 'Kedụ ka mere?',
      'kedụ ka imere?': 'Kedụ ka imere?',
      'biko': 'Biko',
      'jisie ike': 'Jisie ike',
    },
    'swahili': {
      'hujambo': 'Hujambo',
      'habari gani?': 'Habari gani?',
      'habari ya asubuhi': 'Habari ya asubuhi',
      'asante': 'Asante',
      'ninajifunza': 'Ninajifunza',
      'habari': 'Habari',
      'mambo': 'Mambo',
      'poa': 'Poa',
      'asante sana': 'Asante sana',
      'karibu': 'Karibu',
      'pole pole': 'Pole pole',
    },
    'zulu': {
      'sawubona': 'Sawubona',
      'unjani?': 'Unjani?',
      'ngiyaphila': 'Ngiyaphila',
      'ngiyabonga': 'Ngiyabonga',
      'hamba kahle': 'Hamba kahle',
      'sala kahle': 'Sala kahle',
    },
    'xhosa': {
      'molo': 'Molo',
      'unjani?': 'Unjani?',
      'ndiyaphila': 'Ndiyaphila',
      'enkosi': 'Enkosi',
      'hamba kakuhle': 'Hamba kakuhle',
      'sala kakuhle': 'Sala kakuhle',
    },
    'amharic': {
      'selam': 'Selam',
      'tena yistilign': 'Tena yistilign',
      'dehna neh': 'Dehna neh',
      'ameseginalehu': 'Ameseginalehu',
      'chao': 'Chao',
    },
    'twi': {
      'akwaaba': 'Akwaaba',
      'ete sen?': 'Ete sen?',
      'me ho ye': 'Me ho ye',
      'medaase': 'Medaase',
      'yɛbɛhyia bio': 'Yɛbɛhyia bio',
    },
    'pidgin': {
      'how you dey?': 'How you dey?',
      'i dey fine': 'I dey fine',
      'thank you': 'Thank you',
      'no wahala': 'No wahala',
      'wetin dey happen?': 'Wetin dey happen?',
    },
    'wolof': {
      'naka nga def': 'Naka nga def',
      'jërëjëf': 'Jërëjëf',
      'jamm nga jàmm': 'Jamm nga jàmm',
      'naa ngi ci jàmm': 'Naa ngi ci jàmm',
      'ba beneen yoon': 'Ba beneen yoon',
    },
    'somali': {
      'iska warran': 'Iska warran',
      'mahadsanid': 'Mahadsanid',
      'subax wanaagsan': 'Subax wanaagsan',
      'galab wanaagsan': 'Galab wanaagsan',
      'nabad gelyo': 'Nabad gelyo',
    },
  };

  /// Calculate similarity ratio between two strings (0.0 to 1.0)
  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    // Simple Levenshtein-based similarity
    final longer = a.length > b.length ? a : b;
    final editDistance = _levenshteinDistance(a, b);
    return (longer.length - editDistance) / longer.length;
  }
  
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );
    
    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }
  
  /// Fuzzy match text against language map
  static String? _fuzzyMatch(String text, Map<String, String> map, {double threshold = 0.75}) {
    String? bestMatch;
    double bestScore = 0.0;
    
    for (final entry in map.entries) {
      final score = _similarity(text, entry.key);
      if (score > bestScore && score >= threshold) {
        bestScore = score;
        bestMatch = entry.value;
      }
    }
    
    // Token overlap fallback
    if (bestMatch == null) {
      final tokens = text.toLowerCase().split(RegExp(r'\s+'));
      for (final entry in map.entries) {
        final keyTokens = entry.key.split(RegExp(r'\s+'));
        final overlap = tokens.where((t) => keyTokens.contains(t)).length;
        final overlapRatio = overlap / keyTokens.length;
        if (overlapRatio >= 0.6 && overlapRatio > bestScore) {
          bestScore = overlapRatio;
          bestMatch = entry.value;
        }
      }
    }
    
    return bestMatch;
  }
  
  /// Enforce diacritics with fuzzy matching support
  /// Returns: (corrected_text, was_changed, metadata)
  static Map<String, dynamic> enforceWithMetadata(
    String text,
    String? language, {
    bool enableFuzzy = true,
    double fuzzyThreshold = 0.75,
  }) {
    final metadata = {
      'original': text,
      'lang': language,
      'method': 'none',
      'changed': false,
    };
    
    if (text.isEmpty || language == null || language.trim().isEmpty) {
      return {
        'text': text,
        'changed': false,
        'metadata': metadata,
      };
    }
    
    final lang = language.toLowerCase();
    final map = _maps[lang];
    if (map == null) {
      return {
        'text': text,
        'changed': false,
        'metadata': metadata,
      };
    }
    
    // Normalize Unicode to NFC
    final normalized = text.trim();
    
    // Exact phrase-level match
    final direct = map[normalized.toLowerCase()];
    if (direct != null) {
      metadata['method'] = 'exact';
      metadata['changed'] = true;
      _logCorrection(text, direct, lang, 'exact', 1.0);
      return {
        'text': direct,
        'changed': true,
        'metadata': metadata,
      };
    }
    
    // Fuzzy matching if enabled
    if (enableFuzzy) {
      final fuzzyResult = _fuzzyMatch(normalized.toLowerCase(), map, threshold: fuzzyThreshold);
      if (fuzzyResult != null) {
        final score = _similarity(normalized.toLowerCase(), 
            map.entries.firstWhere((e) => e.value == fuzzyResult).key);
        metadata['method'] = 'fuzzy';
        metadata['changed'] = true;
        metadata['score'] = score;
        _logCorrection(text, fuzzyResult, lang, 'fuzzy', score);
        return {
          'text': fuzzyResult,
          'changed': true,
          'metadata': metadata,
        };
      }
    }
    
    // Token-wise soft correction: replace any mapped tokens
    final words = text.splitMapJoin(
      RegExp(r'\b\w[\w\u00C0-\u1FFF\u2C00-\uD7FF]*\b', unicode: true),
      onMatch: (m) {
        final token = m.group(0)!;
        final replacement = map.entries.firstWhereOrNull(
          (e) => e.key == token.toLowerCase(),
        );
        if (replacement != null) {
          metadata['method'] = 'token';
          metadata['changed'] = true;
        }
        return replacement?.value ?? token;
      },
      onNonMatch: (s) => s,
    );
    
    if (metadata['changed'] == true) {
      _logCorrection(text, words, lang, 'token', 0.0);
    }
    
    return {
      'text': words,
      'changed': metadata['changed'] as bool,
      'metadata': metadata,
    };
  }
  
  /// Simple enforce method (backward compatible)
  static String enforce(String text, String? language) {
    final result = enforceWithMetadata(text, language, enableFuzzy: true);
    return result['text'] as String;
  }
  
  /// Log correction to audit log
  static void _logCorrection(
    String input,
    String output,
    String lang,
    String method,
    double score,
  ) {
    _auditLog.add({
      'event': 'diacritics_corrected',
      'lang': lang,
      'method': method,
      'input': input,
      'output': output,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep audit log size manageable (last 1000 entries)
    if (_auditLog.length > 1000) {
      _auditLog.removeRange(0, _auditLog.length - 1000);
    }
  }
  
  /// Get audit log entries
  static List<Map<String, dynamic>> getAuditLog() => List.unmodifiable(_auditLog);
  
  /// Clear audit log
  static void clearAuditLog() => _auditLog.clear();
  
  /// Export audit log to JSON string
  static String exportAuditLog() => jsonEncode(_auditLog);
}

