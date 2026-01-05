/// Drum Rhythm game models
class DrumRhythmContent {
  final String pattern;
  final String context;
  final String correctWord;
  final List<String> options;
  final String contentId;

  DrumRhythmContent({
    required this.pattern,
    required this.context,
    required this.correctWord,
    required this.options,
    required this.contentId,
  });

  factory DrumRhythmContent.fromPolieContent(Map<String, dynamic> polieData) {
    final pattern = polieData['pattern']?.toString() ?? 'DUM da-da DUM';
    final context = polieData['context']?.toString() ?? '';
    final correctWord = _extractWordFromContext(context);
    
    final distractors = [
      'greeting',
      'farewell',
      'celebration',
      'work',
    ];
    
    final options = [correctWord, ...distractors];
    // Shuffle for UI variety - this is just presentation, not correctness logic
    final random = DateTime.now().millisecondsSinceEpoch;
    options.shuffle((random % 1000000).toInt());

    return DrumRhythmContent(
      pattern: pattern,
      context: context,
      correctWord: correctWord,
      options: options,
      contentId: polieData['content_id'] as String? ?? '',
    );
  }

  static String _extractWordFromContext(String context) {
    final words = ['dance', 'music', 'festival', 'ceremony', 'tradition'];
    if (context.toLowerCase().contains('dance')) return 'dance';
    if (context.toLowerCase().contains('music')) return 'music';
    if (context.toLowerCase().contains('festival')) return 'festival';
    if (context.toLowerCase().contains('ceremony')) return 'ceremony';
    if (context.toLowerCase().contains('tradition')) return 'tradition';
    return words[0];
  }
}

class DrumRhythmInput {
  final String selectedWord;

  DrumRhythmInput({required this.selectedWord});
}

