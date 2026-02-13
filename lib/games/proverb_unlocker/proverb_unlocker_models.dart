// ProverbUnlocker game models
import 'dart:math' as math;

class ProverbUnlockerContent {
  final String proverb;
  final String translation;
  final String meaning;
  final String context;
  final List<String> options; // Multiple choice options
  final String correctAnswer;
  final String contentId;

  ProverbUnlockerContent({
    required this.proverb,
    required this.translation,
    required this.meaning,
    required this.context,
    required this.options,
    required this.correctAnswer,
    required this.contentId,
  });

  factory ProverbUnlockerContent.fromPolieContent(Map<String, dynamic> polieData) {
    final meaning = polieData['meaning'] as String? ?? 
                   polieData['context'] as String? ?? 
                   'Wisdom through experience';
    
    // Generate distractors
    final distractors = [
      'A common greeting',
      'A traditional dance',
      'A type of food',
      'A weather saying',
    ];
    
    final options = [meaning, ...distractors];
    final random = math.Random();
    options.shuffle(random);
    
    return ProverbUnlockerContent(
      proverb: polieData['proverb'] as String? ?? '',
      translation: polieData['translation'] as String? ?? '',
      meaning: meaning,
      context: polieData['context'] as String? ?? '',
      options: options,
      correctAnswer: meaning,
      contentId: polieData['content_id'] as String? ?? '',
    );
  }
}

class ProverbUnlockerInput {
  final String selectedAnswer;

  ProverbUnlockerInput({required this.selectedAnswer});
}

