// Classifies user input domain and intent for persona cognition.
/// Uses keyword detection and heuristics only (no LLM) for speed.

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';

enum UserIntentDomain {
  historical,
  modern,
  ethical,
  personal,
  language,
  cultural,
  anachronistic,
  offensive,
}

enum UserIntentType {
  factual,
  opinion,
  debate,
  learning,
  greeting,
  offtopic,
}

class IntentClassification {
  final UserIntentDomain domain;
  final UserIntentType type;
  final double confidence;
  final String? detectedTopic;

  const IntentClassification({
    required this.domain,
    required this.type,
    required this.confidence,
    this.detectedTopic,
  });
}

class IntentClassifier {
  IntentClassifier._();

  static const _modernTechWords = [
    'internet', 'computer', 'smartphone', 'social media', 'facebook', 'twitter',
    'instagram', 'google', 'ai', 'artificial intelligence', 'robot', 'app',
    'email', 'wifi', 'covid', 'vaccine', 'climate change', 'global warming',
    'electric car', 'tesla', 'spacex', 'youtube', 'netflix', 'streaming',
  ];

  static const _ethicalKeywords = [
    'ethical', 'ethics', 'moral', 'right', 'wrong', 'should', 'ought',
    'justice', 'fair', 'unfair', 'colonization', 'colonial', 'slavery',
    'reparations', 'reconciliation', 'forgiveness', 'blame', 'responsibility',
  ];

  static const _greetingPatterns = [
    'hello', 'hi ', 'hey ', 'good morning', 'good afternoon', 'good evening',
    'greetings', 'how are you', 'how do you do', 'nice to meet', 'salut',
    'bonjour', 'jambo', 'sawubona', 'dumela', 'sannu', 'yaa', 'nna',
  ];

  static const _questionPatterns = [
    'what ', 'when ', 'where ', 'who ', 'why ', 'how ', 'which ',
    'did ', 'do ', 'does ', 'is ', 'are ', 'was ', 'were ', '?',
  ];

  static const _opinionPatterns = [
    'think that', 'believe that', 'feel that', 'in my opinion', 'i think',
    'do you think', 'what do you think', 'your view', 'your opinion',
    'agree', 'disagree', 'debate', 'argue',
  ];

  static const _offensivePatterns = [
    'hate', 'kill', 'terror', 'bomb', 'rape', 'abuse', 'slur',
    'racist', 'sexist', 'nazi', 'extremist',
  ];

  /// Classifies [userInput] for persona [personaId].
  /// Uses keyword detection and heuristics only (no LLM).
  static IntentClassification classify(String userInput, String personaId) {
    final lower = userInput.trim().toLowerCase();
    if (lower.isEmpty) {
      return const IntentClassification(
        domain: UserIntentDomain.historical,
        type: UserIntentType.offtopic,
        confidence: 0.5,
      );
    }

    // Offensive check first
    for (final p in _offensivePatterns) {
      if (lower.contains(p)) {
        return IntentClassification(
          domain: UserIntentDomain.offensive,
          type: UserIntentType.offtopic,
          confidence: 0.9,
          detectedTopic: p,
        );
      }
    }

    // Greeting
    for (final g in _greetingPatterns) {
      if (lower.startsWith(g) || lower.contains(' $g')) {
        return const IntentClassification(
          domain: UserIntentDomain.personal,
          type: UserIntentType.greeting,
          confidence: 0.85,
        );
      }
    }

    // Anachronism: year in input after persona's endYear
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona != null) {
      final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(lower);
      if (yearMatch != null) {
        final year = int.tryParse(yearMatch.group(0) ?? '');
        if (year != null && year > persona.endYear) {
          return IntentClassification(
            domain: UserIntentDomain.anachronistic,
            type: UserIntentType.factual,
            confidence: 0.9,
            detectedTopic: 'year_$year',
          );
        }
      }
    }

    // Modern / anachronistic: tech and post-era concepts
    for (final w in _modernTechWords) {
      if (lower.contains(w)) {
        return IntentClassification(
          domain: UserIntentDomain.anachronistic,
          type: UserIntentType.factual,
          confidence: 0.8,
          detectedTopic: w,
        );
      }
    }

    // Ethical
    for (final e in _ethicalKeywords) {
      if (lower.contains(e)) {
        final isDebate = _opinionPatterns.any((o) => lower.contains(o));
        return IntentClassification(
          domain: UserIntentDomain.ethical,
          type: isDebate ? UserIntentType.debate : UserIntentType.opinion,
          confidence: 0.75,
          detectedTopic: e,
        );
      }
    }

    // Opinion / debate
    for (final o in _opinionPatterns) {
      if (lower.contains(o)) {
        return const IntentClassification(
          domain: UserIntentDomain.historical,
          type: UserIntentType.debate,
          confidence: 0.7,
        );
      }
    }

    // Question → factual vs learning (treat as factual by default)
    final hasQuestion = _questionPatterns.any((q) => lower.contains(q));
    if (hasQuestion) {
      return const IntentClassification(
        domain: UserIntentDomain.historical,
        type: UserIntentType.factual,
        confidence: 0.7,
      );
    }

    // Default: historical, learning
    return const IntentClassification(
      domain: UserIntentDomain.historical,
      type: UserIntentType.learning,
      confidence: 0.6,
    );
  }
}
