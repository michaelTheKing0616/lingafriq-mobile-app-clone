import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Feedback Types
enum FeedbackType {
  pronunciation,
  tone,
  fluency,
  grammar,
  vocabulary,
  cultural,
  encouragement,
  correction,
}

/// Feedback Severity
enum FeedbackSeverity {
  positive,    // "Great job!"
  neutral,     // "Here's a tip..."
  constructive, // "Try this instead..."
  critical,    // "Watch out for..."
}

/// Structured Feedback Item
class FeedbackItem {
  final FeedbackType type;
  final FeedbackSeverity severity;
  final String message;
  final String? actionableTip;
  final String? exampleCorrect;
  final String? exampleIncorrect;
  final double? score; // 0-1 for specific metric
  
  FeedbackItem({
    required this.type,
    required this.severity,
    required this.message,
    this.actionableTip,
    this.exampleCorrect,
    this.exampleIncorrect,
    this.score,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'actionableTip': actionableTip,
    'exampleCorrect': exampleCorrect,
    'exampleIncorrect': exampleIncorrect,
    'score': score,
  };
}

/// Coaching Response
class CoachingResponse {
  final String mainMessage;
  final List<FeedbackItem> feedbackItems;
  final String? encouragement;
  final String? nextStep;
  final double overallScore;
  final bool shouldRetry;
  final int suggestedDifficulty; // 1-10
  
  CoachingResponse({
    required this.mainMessage,
    required this.feedbackItems,
    this.encouragement,
    this.nextStep,
    required this.overallScore,
    this.shouldRetry = false,
    this.suggestedDifficulty = 5,
  });
  
  /// Get the primary feedback type
  FeedbackType? get primaryIssue {
    if (feedbackItems.isEmpty) return null;
    final criticalItems = feedbackItems.where((f) => f.severity == FeedbackSeverity.critical);
    if (criticalItems.isNotEmpty) return criticalItems.first.type;
    final constructiveItems = feedbackItems.where((f) => f.severity == FeedbackSeverity.constructive);
    if (constructiveItems.isNotEmpty) return constructiveItems.first.type;
    return feedbackItems.first.type;
  }
  
  Map<String, dynamic> toJson() => {
    'mainMessage': mainMessage,
    'feedbackItems': feedbackItems.map((f) => f.toJson()).toList(),
    'encouragement': encouragement,
    'nextStep': nextStep,
    'overallScore': overallScore,
    'shouldRetry': shouldRetry,
    'suggestedDifficulty': suggestedDifficulty,
  };
}

/// Provider for Feedback Engine
final feedbackEngineProvider = Provider<FeedbackEngine>((ref) {
  return FeedbackEngine();
});

/// Intelligent Feedback & Coaching Engine
/// 
/// Converts raw scores into human-friendly, actionable coaching.
/// Focus on improvement, not judgment.
class FeedbackEngine {
  
  // Encouraging phrases by score range
  static const Map<String, List<String>> _encouragementPhrases = {
    'excellent': [
      "Outstanding work! 🌟",
      "You're crushing it! 💪",
      "That was perfect! ✨",
      "Native speaker quality! 🎯",
    ],
    'good': [
      "Great progress! 👏",
      "You're getting better! 📈",
      "Nice job! Keep it up! 🙌",
      "Almost there! 💫",
    ],
    'okay': [
      "Good effort! Let's polish it. 🔧",
      "You're on the right track! 🛤️",
      "Practice makes progress! 📚",
      "Every attempt teaches you something! 💡",
    ],
    'struggling': [
      "Don't give up! You've got this! 💪",
      "Learning takes time - you're doing great! ⏳",
      "This one's tricky - let's work through it! 🤝",
      "Small steps lead to big progress! 👣",
    ],
  };

  // Actionable tips by issue type
  static const Map<FeedbackType, List<String>> _actionableTips = {
    FeedbackType.pronunciation: [
      "Listen to the native audio again, then immediately try to repeat it.",
      "Try exaggerating the sounds first, then speak naturally.",
      "Record yourself and compare with the native speaker.",
      "Focus on one sound at a time - don't rush!",
    ],
    FeedbackType.tone: [
      "Imagine you're singing the word - pitch matters!",
      "Try humming the tone pattern before speaking.",
      "High tone = light and lifted. Low tone = deep and grounded.",
      "Watch the pitch contour graph and try to match it.",
    ],
    FeedbackType.fluency: [
      "Speak in complete phrases, not word-by-word.",
      "Don't pause to think - just let it flow, even if imperfect.",
      "Practice shadowing: speak along with the audio.",
      "Speed comes with confidence - focus on smooth transitions.",
    ],
    FeedbackType.grammar: [
      "Notice the word order - it's different from English!",
      "Pay attention to verb agreement patterns.",
      "Try creating similar sentences with different words.",
      "Grammar mistakes are learning opportunities!",
    ],
    FeedbackType.vocabulary: [
      "Use this word in three different sentences today.",
      "Connect it to a word you already know.",
      "Visualize the meaning - create a mental picture.",
      "Review this word again tomorrow for better retention.",
    ],
    FeedbackType.cultural: [
      "Language carries culture - meaning goes beyond words.",
      "Consider: When and where would a native speaker use this?",
      "Ask yourself: Is this formal or casual?",
      "Cultural context makes your speech more natural.",
    ],
  };

  /// Generate coaching response from pronunciation score
  CoachingResponse generatePronunciationFeedback({
    required double overallScore,
    required double phonemeScore,
    required double toneScore,
    required double fluencyScore,
    required double confidenceScore,
    required String language,
    List<Map<String, dynamic>>? problemSegments,
  }) {
    final feedbackItems = <FeedbackItem>[];
    
    // Determine primary issue
    final scores = {
      FeedbackType.pronunciation: phonemeScore,
      FeedbackType.tone: toneScore,
      FeedbackType.fluency: fluencyScore,
    };
    
    // Sort by score (lowest first)
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Generate feedback for each area
    for (final entry in sortedScores) {
      final feedback = _generateScoreFeedback(entry.key, entry.value, language);
      if (feedback != null) {
        feedbackItems.add(feedback);
      }
    }
    
    // Add segment-specific feedback
    if (problemSegments != null && problemSegments.isNotEmpty) {
      for (final segment in problemSegments.take(2)) {
        final text = segment['text'] as String? ?? '';
        final issue = segment['issue'] as String? ?? 'pronunciation';
        
        feedbackItems.add(FeedbackItem(
          type: _mapIssueToType(issue),
          severity: FeedbackSeverity.constructive,
          message: "Watch '$text' - ${_getIssueDescription(issue)}",
          actionableTip: _getSpecificTip(issue, text),
        ));
      }
    }
    
    // Add confidence feedback if low
    if (confidenceScore < 0.5) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.encouragement,
        severity: FeedbackSeverity.neutral,
        message: "Speak with more confidence - your voice is great!",
        actionableTip: "Project your voice and don't be afraid to be loud.",
      ));
    }
    
    // Generate main message
    final mainMessage = _generateMainMessage(overallScore);
    
    // Get encouragement
    final encouragement = _getEncouragement(overallScore);
    
    // Suggest next step
    final nextStep = _suggestNextStep(overallScore, sortedScores.first.key);
    
    // Determine if should retry
    final shouldRetry = overallScore < 0.6;
    
    // Suggest difficulty adjustment
    final difficulty = _suggestDifficulty(overallScore);
    
    return CoachingResponse(
      mainMessage: mainMessage,
      feedbackItems: feedbackItems,
      encouragement: encouragement,
      nextStep: nextStep,
      overallScore: overallScore,
      shouldRetry: shouldRetry,
      suggestedDifficulty: difficulty,
    );
  }

  /// Generate feedback for vocabulary review
  CoachingResponse generateVocabFeedback({
    required bool correct,
    required String word,
    required String translation,
    required int masteryLevel,
    required int streak,
  }) {
    final feedbackItems = <FeedbackItem>[];
    
    if (correct) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.vocabulary,
        severity: FeedbackSeverity.positive,
        message: "Correct! '$word' = '$translation'",
        actionableTip: masteryLevel < 4 
            ? "Try using this word in a sentence!"
            : "You've mastered this word! 🎯",
        score: 1.0,
      ));
    } else {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.vocabulary,
        severity: FeedbackSeverity.constructive,
        message: "Not quite. '$word' means '$translation'",
        actionableTip: "Say it out loud three times to remember better.",
        score: 0.0,
      ));
    }
    
    final encouragement = correct
        ? (streak > 2 ? "🔥 $streak in a row! Keep going!" : "Nice work! 👍")
        : "Don't worry - you'll get it next time! 💪";
    
    return CoachingResponse(
      mainMessage: correct ? "Well done!" : "Let's try that again",
      feedbackItems: feedbackItems,
      encouragement: encouragement,
      nextStep: correct 
          ? "Ready for the next word?"
          : "Review this word, then continue.",
      overallScore: correct ? 1.0 : 0.0,
      shouldRetry: !correct,
      suggestedDifficulty: masteryLevel + 1,
    );
  }

  /// Generate feedback for grammar exercise
  CoachingResponse generateGrammarFeedback({
    required bool correct,
    required String userAnswer,
    required String correctAnswer,
    required String explanation,
  }) {
    final feedbackItems = <FeedbackItem>[];
    
    if (correct) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.grammar,
        severity: FeedbackSeverity.positive,
        message: "Perfect! ✓",
        score: 1.0,
      ));
    } else {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.grammar,
        severity: FeedbackSeverity.constructive,
        message: "Almost! The correct answer is: $correctAnswer",
        exampleCorrect: correctAnswer,
        exampleIncorrect: userAnswer,
        actionableTip: explanation,
        score: 0.0,
      ));
    }
    
    return CoachingResponse(
      mainMessage: correct ? "Excellent grammar!" : "Let's learn from this",
      feedbackItems: feedbackItems,
      encouragement: correct 
          ? "Your grammar is improving! 📈"
          : "Grammar takes practice - you're getting there! 📚",
      nextStep: correct ? null : "Read the explanation, then try a similar one.",
      overallScore: correct ? 1.0 : 0.0,
      shouldRetry: !correct,
      suggestedDifficulty: 5,
    );
  }

  /// Generate feedback for conversation/roleplay
  CoachingResponse generateConversationFeedback({
    required double naturalness,
    required double appropriateness,
    required double vocabulary,
    required String context,
  }) {
    final feedbackItems = <FeedbackItem>[];
    final overallScore = (naturalness + appropriateness + vocabulary) / 3;
    
    if (naturalness < 0.6) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.fluency,
        severity: FeedbackSeverity.constructive,
        message: "Try to sound more conversational.",
        actionableTip: "Imagine you're talking to a friend, not reading a script.",
        score: naturalness,
      ));
    }
    
    if (appropriateness < 0.6) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.cultural,
        severity: FeedbackSeverity.constructive,
        message: "Consider the cultural context.",
        actionableTip: "Is your response formal or casual enough for this situation?",
        score: appropriateness,
      ));
    }
    
    if (vocabulary < 0.6) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.vocabulary,
        severity: FeedbackSeverity.constructive,
        message: "Try using more varied vocabulary.",
        actionableTip: "Can you think of a synonym or more specific word?",
        score: vocabulary,
      ));
    }
    
    if (feedbackItems.isEmpty) {
      feedbackItems.add(FeedbackItem(
        type: FeedbackType.encouragement,
        severity: FeedbackSeverity.positive,
        message: "Great conversational skills! 🗣️",
        score: overallScore,
      ));
    }
    
    return CoachingResponse(
      mainMessage: _generateMainMessage(overallScore),
      feedbackItems: feedbackItems,
      encouragement: _getEncouragement(overallScore),
      nextStep: overallScore >= 0.7 
          ? "Ready for a more challenging conversation?"
          : "Let's practice this scenario again.",
      overallScore: overallScore,
      shouldRetry: overallScore < 0.6,
      suggestedDifficulty: (overallScore * 10).round().clamp(1, 10),
    );
  }

  // Helper methods
  
  FeedbackItem? _generateScoreFeedback(FeedbackType type, double score, String language) {
    final severity = _scoreToSeverity(score);
    final message = _getScoreMessage(type, score);
    final tip = _getRandomTip(type);
    
    // Only include if not excellent
    if (score >= 0.9) return null;
    
    return FeedbackItem(
      type: type,
      severity: severity,
      message: message,
      actionableTip: tip,
      score: score,
    );
  }
  
  FeedbackSeverity _scoreToSeverity(double score) {
    if (score >= 0.85) return FeedbackSeverity.positive;
    if (score >= 0.7) return FeedbackSeverity.neutral;
    if (score >= 0.5) return FeedbackSeverity.constructive;
    return FeedbackSeverity.critical;
  }
  
  String _getScoreMessage(FeedbackType type, double score) {
    final percentage = (score * 100).round();
    
    switch (type) {
      case FeedbackType.pronunciation:
        if (score >= 0.8) return "Clear pronunciation ($percentage%)";
        if (score >= 0.6) return "Pronunciation needs some polish ($percentage%)";
        return "Focus on clearer pronunciation ($percentage%)";
        
      case FeedbackType.tone:
        if (score >= 0.8) return "Great tone accuracy ($percentage%)";
        if (score >= 0.6) return "Tone patterns need work ($percentage%)";
        return "Pay attention to pitch patterns ($percentage%)";
        
      case FeedbackType.fluency:
        if (score >= 0.8) return "Natural speech flow ($percentage%)";
        if (score >= 0.6) return "Work on speaking smoothly ($percentage%)";
        return "Reduce pauses and hesitations ($percentage%)";
        
      default:
        return "Score: $percentage%";
    }
  }
  
  String _getRandomTip(FeedbackType type) {
    final tips = _actionableTips[type];
    if (tips == null || tips.isEmpty) return "Keep practicing!";
    tips.shuffle();
    return tips.first;
  }
  
  String _generateMainMessage(double score) {
    if (score >= 0.9) return "Excellent! Almost perfect!";
    if (score >= 0.8) return "Great job! Just a few refinements needed.";
    if (score >= 0.7) return "Good progress! Let's polish a few things.";
    if (score >= 0.6) return "Nice try! Here's how to improve.";
    if (score >= 0.5) return "Keep practicing! You're learning.";
    return "Let's work on this together. You've got this!";
  }
  
  String _getEncouragement(double score) {
    String category;
    if (score >= 0.85) {
      category = 'excellent';
    } else if (score >= 0.7) {
      category = 'good';
    } else if (score >= 0.5) {
      category = 'okay';
    } else {
      category = 'struggling';
    }
    
    final phrases = _encouragementPhrases[category]!;
    phrases.shuffle();
    return phrases.first;
  }
  
  String _suggestNextStep(double score, FeedbackType primaryIssue) {
    if (score >= 0.85) {
      return "Try a more challenging phrase!";
    }
    
    switch (primaryIssue) {
      case FeedbackType.pronunciation:
        return "Listen again, then record yourself.";
      case FeedbackType.tone:
        return "Watch the pitch graph and try to match it.";
      case FeedbackType.fluency:
        return "Practice speaking faster without rushing.";
      default:
        return "Try once more - you're close!";
    }
  }
  
  int _suggestDifficulty(double score) {
    if (score >= 0.9) return 8;
    if (score >= 0.8) return 7;
    if (score >= 0.7) return 6;
    if (score >= 0.6) return 5;
    if (score >= 0.5) return 4;
    return 3;
  }
  
  FeedbackType _mapIssueToType(String issue) {
    switch (issue.toLowerCase()) {
      case 'phoneme':
      case 'pronunciation':
        return FeedbackType.pronunciation;
      case 'tone':
      case 'pitch':
        return FeedbackType.tone;
      case 'fluency':
      case 'pace':
        return FeedbackType.fluency;
      default:
        return FeedbackType.pronunciation;
    }
  }
  
  String _getIssueDescription(String issue) {
    switch (issue.toLowerCase()) {
      case 'phoneme':
      case 'pronunciation':
        return "the sounds weren't quite right.";
      case 'tone':
        return "the tone pattern was off.";
      case 'fluency':
        return "try to speak more smoothly.";
      default:
        return "needs a bit more practice.";
    }
  }
  
  String _getSpecificTip(String issue, String text) {
    switch (issue.toLowerCase()) {
      case 'tone':
        return "For '$text', try exaggerating the pitch rise/fall first.";
      case 'phoneme':
        return "Listen carefully to '$text' and match each sound.";
      case 'fluency':
        return "Practice '$text' at a slower pace, then speed up.";
      default:
        return "Focus on '$text' - you'll get it!";
    }
  }
}

