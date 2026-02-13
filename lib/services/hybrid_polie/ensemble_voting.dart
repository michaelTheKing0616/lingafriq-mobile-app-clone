/// Ensemble Voting System
/// Uses multiple models and votes on best output for critical tasks

import 'package:flutter/foundation.dart';
import 'translation_service.dart';
import 'canonical_phrase_service.dart';
import '../../providers/ai_chat_provider_groq.dart';

class EnsembleVoting {
  /// Vote on best translation from multiple models
  static Future<String> voteOnTranslation({
    required String text,
    required String sourceLang,
    required String targetLang,
    required GroqChatProvider groqProvider,
    String? hfToken,
  }) async {
    debugPrint('🗳️ Ensemble voting: Getting translations from multiple models...');

    // Get translations from multiple sources
    final results = await Future.wait([
      // NLLB-200
      TranslationService().translate(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        hfToken: hfToken,
      ).then((r) => r.translation).catchError((e) => ''),

      // LLaMA-70B (via Groq)
      _getLlamaTranslation(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        groqProvider: groqProvider,
      ).catchError((e) => ''),

      // AfriTeVa (if available)
      CanonicalPhraseService().generateCanonical(
        phrase: text,
        language: targetLang,
        hfToken: hfToken,
      ).then((r) => r.canonicalText).catchError((e) => ''),
    ]);

    // Filter out nulls
    final validResults = results.where((r) => r != null && r.toString().isNotEmpty).toList();

    if (validResults.isEmpty) {
      throw Exception('All models failed in ensemble voting');
    }

    // Voting logic: majority vote or highest confidence
    final votes = <String, int>{};
    for (final result in validResults) {
      final key = result.toString().toLowerCase().trim();
      votes[key] = (votes[key] ?? 0) + 1;
    }

    // Get most voted result
    String? bestResult;
    int maxVotes = 0;
    votes.forEach((result, count) {
      if (count > maxVotes) {
        maxVotes = count;
        bestResult = result;
      }
    });

    // If tie, prefer NLLB result (first in list)
    if (bestResult == null && validResults.isNotEmpty) {
      bestResult = validResults[0].toString();
    }

    debugPrint('✅ Ensemble voting: Selected "$bestResult" with $maxVotes votes');
    return bestResult ?? validResults[0].toString();
  }

  /// Vote on canonical phrase from multiple models
  static Future<String> voteOnCanonical({
    required String phrase,
    required String language,
    required GroqChatProvider groqProvider,
    String? hfToken,
  }) async {
    debugPrint('🗳️ Ensemble voting: Getting canonical phrases from multiple models...');

    // Get canonical forms from multiple sources
    final results = await Future.wait([
      // AfriTeVa
      CanonicalPhraseService().generateCanonical(
        phrase: phrase,
        language: language,
        hfToken: hfToken,
      ).then((r) => r.canonicalText).catchError((e) => ''),

      // LLaMA-70B (with canonical constraint)
      _getLlamaCanonical(
        phrase: phrase,
        language: language,
        groqProvider: groqProvider,
      ).catchError((e) => ''),
    ]);

    // Filter out nulls
    final validResults = results.where((r) => r != null && r.toString().isNotEmpty).toList();

    if (validResults.isEmpty) {
      return phrase; // Fallback to original
    }

    // Prefer AfriTeVa (first result) as it's specialized for canonical forms
    final bestResult = validResults[0].toString();
    debugPrint('✅ Ensemble voting: Selected canonical "$bestResult"');
    return bestResult;
  }

  /// Get translation from LLaMA
  static Future<String> _getLlamaTranslation({
    required String text,
    required String sourceLang,
    required String targetLang,
    required GroqChatProvider groqProvider,
  }) async {
    final prompt = 'Translate "$text" from $sourceLang to $targetLang. Return only the translation, no explanations.';
    
    String fullResponse = '';
    await for (final chunk in groqProvider.sendMessageStream(prompt)) {
      fullResponse += chunk;
    }
    
    return fullResponse.trim();
  }

  /// Get canonical phrase from LLaMA
  static Future<String> _getLlamaCanonical({
    required String phrase,
    required String language,
    required GroqChatProvider groqProvider,
  }) async {
    final prompt = 'Provide the canonical (correctly spelled with diacritics) form of "$phrase" in $language. Return only the canonical form, no explanations.';
    
    String fullResponse = '';
    await for (final chunk in groqProvider.sendMessageStream(prompt)) {
      fullResponse += chunk;
    }
    
    return fullResponse.trim();
  }

  /// Confidence-weighted voting
  static Future<EnsembleResult> voteWithConfidence({
    required List<ModelResult> results,
  }) async {
    if (results.isEmpty) {
      throw Exception('No results to vote on');
    }

    // Calculate weighted average confidence
    double totalWeight = 0;
    double weightedSum = 0;
    final votes = <String, double>{};

    for (final result in results) {
      final weight = result.confidence;
      totalWeight += weight;
      weightedSum += result.confidence * result.confidence; // Confidence squared for emphasis
      
      final key = result.output.toLowerCase().trim();
      votes[key] = (votes[key] ?? 0) + weight;
    }

    // Get highest weighted result
    String? bestResult;
    double maxWeight = 0;
    votes.forEach((result, weight) {
      if (weight > maxWeight) {
        maxWeight = weight;
        bestResult = result;
      }
    });

    final averageConfidence = totalWeight > 0 ? weightedSum / totalWeight : 0.0;

    return EnsembleResult(
      output: bestResult ?? results[0].output,
      confidence: averageConfidence,
      modelCount: results.length,
      agreement: maxWeight / totalWeight, // Agreement ratio
    );
  }
}

class ModelResult {
  final String output;
  final double confidence;
  final String model;

  ModelResult({
    required this.output,
    required this.confidence,
    required this.model,
  });
}

class EnsembleResult {
  final String output;
  final double confidence;
  final int modelCount;
  final double agreement; // 0-1, how much models agree

  EnsembleResult({
    required this.output,
    required this.confidence,
    required this.modelCount,
    required this.agreement,
  });
}

