/// Tone Drill Service
/// Generates and manages tone practice drills for tonal languages
/// Creates minimal-pair exercises, repetition drills, and contrast exercises

import '../../models/lesson_item_model.dart';
import 'tone_error_detection_service.dart';

/// Tone drill session
class ToneDrillSession {
  final String id;
  final LessonItem baseItem;
  final ToneDrill drill;
  final List<DrillAttempt> attempts;
  final DateTime createdAt;

  ToneDrillSession({
    required this.id,
    required this.baseItem,
    required this.drill,
    required this.attempts,
    required this.createdAt,
  });
}

/// Drill attempt result
class DrillAttempt {
  final String drillItemText;
  final double accuracy;
  final List<ToneError> errors;
  final DateTime timestamp;

  DrillAttempt({
    required this.drillItemText,
    required this.accuracy,
    required this.errors,
    required this.timestamp,
  });
}

/// Tone Drill Service
class ToneDrillService {
  final ToneErrorDetectionService _toneErrorService = ToneErrorDetectionService();

  /// Generate drill from lesson item
  Future<ToneDrill> generateDrillFromItem(LessonItem item) async {
    if (item.tonePattern == null || item.tonePattern!.isEmpty) {
      throw Exception('Item does not have tone pattern');
    }

    // Generate minimal pairs for all tones in the pattern
    final drillItems = <DrillItem>[];
    final syllables = _segmentIntoSyllables(item.text, item.languageCode);
    final allTones = _getAvailableTones(item.languageCode);

    for (int i = 0; i < syllables.length && i < item.tonePattern!.length; i++) {
      final syllable = syllables[i];
      final correctTone = item.tonePattern![i];

      // Add correct version
      drillItems.add(DrillItem(
        text: _applyToneToSyllable(syllable, correctTone, item.languageCode),
        ipa: item.ipa ?? '',
        tonePattern: [correctTone],
        translation: item.translation,
      ));

      // Add contrast versions
      for (final tone in allTones) {
        if (tone != correctTone) {
          drillItems.add(DrillItem(
            text: _applyToneToSyllable(syllable, tone, item.languageCode),
            ipa: item.ipa ?? '',
            tonePattern: [tone],
            translation: 'Contrast: $tone tone',
          ));
        }
      }
    }

    return ToneDrill(
      type: 'minimal_pair',
      items: drillItems,
      focusSyllable: syllables.isNotEmpty ? syllables[0] : '',
      targetTones: item.tonePattern!,
    );
  }

  /// Generate drill from errors
  Future<ToneDrill> generateDrillFromErrors(
    LessonItem item,
    List<ToneError> errors,
  ) async {
    if (errors.isEmpty) {
      return await generateDrillFromItem(item);
    }

    // Focus on the most common error
    final errorCounts = <String, int>{};
    for (final error in errors) {
      final key = '${error.expectedTone}_${error.actualTone}';
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    final mostCommonError = errorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final parts = mostCommonError.key.split('_');
    final expectedTone = parts[0];
    final actualTone = parts[1];

    final syllables = _segmentIntoSyllables(item.text, item.languageCode);
    final focusSyllable = errors.first.syllableIndex < syllables.length
        ? syllables[errors.first.syllableIndex]
        : '';

    final drillItems = <DrillItem>[
      DrillItem(
        text: _applyToneToSyllable(focusSyllable, expectedTone, item.languageCode),
        ipa: item.ipa ?? '',
        tonePattern: [expectedTone],
        translation: 'Correct: $expectedTone tone',
      ),
      DrillItem(
        text: _applyToneToSyllable(focusSyllable, actualTone, item.languageCode),
        ipa: item.ipa ?? '',
        tonePattern: [actualTone],
        translation: 'Your error: $actualTone tone',
      ),
    ];

    // Add other tones for contrast
    final allTones = _getAvailableTones(item.languageCode);
    for (final tone in allTones) {
      if (tone != expectedTone && tone != actualTone) {
        drillItems.add(DrillItem(
          text: _applyToneToSyllable(focusSyllable, tone, item.languageCode),
          ipa: item.ipa ?? '',
          tonePattern: [tone],
          translation: 'Contrast: $tone tone',
        ));
      }
    }

    return ToneDrill(
      type: 'minimal_pair',
      items: drillItems,
      focusSyllable: focusSyllable,
      targetTones: [expectedTone],
    );
  }

  /// Generate repetition drill
  Future<ToneDrill> generateRepetitionDrill(
    LessonItem item,
    int repetitions,
  ) async {
    final drillItems = <DrillItem>[];
    
    for (int i = 0; i < repetitions; i++) {
      drillItems.add(DrillItem(
        text: item.text,
        ipa: item.ipa ?? '',
        tonePattern: item.tonePattern ?? [],
        translation: item.translation,
        audioUrl: item.audioUrl,
      ));
    }

    return ToneDrill(
      type: 'repetition',
      items: drillItems,
      focusSyllable: item.text,
      targetTones: item.tonePattern ?? [],
    );
  }

  List<String> _segmentIntoSyllables(String text, String languageCode) {
    final syllables = <String>[];
    final chars = text.split('');
    
    String currentSyllable = '';
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      currentSyllable += char;
      
      if (_isVowel(char) && i < chars.length - 1 && !_isVowel(chars[i + 1])) {
        syllables.add(currentSyllable.trim());
        currentSyllable = '';
      }
    }
    
    if (currentSyllable.isNotEmpty) {
      syllables.add(currentSyllable.trim());
    }

    return syllables.isEmpty ? [text] : syllables;
  }

  bool _isVowel(String char) {
    const vowels = 'aeiouáàéèíìóòúùẹẹ́ẹ̀ọọ́ọ̀';
    return vowels.contains(char.toLowerCase());
  }

  List<String> _getAvailableTones(String languageCode) {
    switch (languageCode) {
      case 'yo':
      case 'tw':
        return ['low', 'mid', 'high'];
      case 'ig':
        return ['low', 'high'];
      default:
        return ['low', 'mid', 'high'];
    }
  }

  String _applyToneToSyllable(String syllable, String tone, String languageCode) {
    // Simplified - in production, use proper tone marking library
    return syllable;
  }
}

