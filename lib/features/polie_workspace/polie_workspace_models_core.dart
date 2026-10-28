import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/models/correction_result.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';

class TranslationPayload {
  final String primary;
  final List<AltItem> alternatives;
  final String culturalNote;
  final String toneAchieved;
  const TranslationPayload({
    required this.primary,
    required this.alternatives,
    required this.culturalNote,
    required this.toneAchieved,
  });

  factory TranslationPayload.fromJson(
    Map<String, dynamic> json, {
    required String rawFallback,
  }) {
    final alternativesRaw = (polieJsonField(json, 'alternatives', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return TranslationPayload(
      primary: cleanAiText(
        (polieJsonField(json, 'primary', '') as String).trim().isNotEmpty
            ? (polieJsonField(json, 'primary', '') as String)
            : rawFallback,
        fallback: cleanAiText(rawFallback, fallback: '-'),
      ),
      alternatives: alternativesRaw
          .map(
            (e) => AltItem(
              text: (polieJsonField(e, 'text', '') as String),
              note: (polieJsonField(e, 'note', '') as String),
            ),
          )
          .where((e) => e.text.trim().isNotEmpty)
          .toList(),
      culturalNote: cleanAiText(
        (polieJsonField(json, 'cultural_note', '') ?? '').toString(),
        fallback: '',
      ),
      toneAchieved: cleanAiText(
        (polieJsonField(json, 'tone_achieved', '-') ?? '-').toString(),
        fallback: '-',
      ),
    );
  }
}

class TutorLessonPayload {
  final String concept;
  final String explanation;
  final TutorExample example;
  final String memoryTip;
  final String? watchOut;
  final String? practiceQuestion;
  final String? practiceHint;
  const TutorLessonPayload({
    required this.concept,
    required this.explanation,
    required this.example,
    required this.memoryTip,
    required this.watchOut,
    this.practiceQuestion,
    this.practiceHint,
  });
  factory TutorLessonPayload.fromJson(
    Map<String, dynamic> json,
    String fallback,
  ) {
    final ex = (polieJsonField(json, 'example', const {}) as Map).cast<String, dynamic>();
    String sanitize(String value, {String fallbackText = '-'}) {
      final v = value.trim();
      if (v.isEmpty) return fallbackText;
      if (v.startsWith('{') || v.startsWith('```') || v.startsWith('[')) {
        return fallbackText;
      }
      return cleanAiText(v, fallback: fallbackText);
    }

    String concept = (polieJsonField(json, 'concept', 'Lesson') as String);
    // Guard against raw JSON leaking into concept field
    if (concept.startsWith('{') || concept.startsWith('```')) {
      concept = 'Lesson';
    }
    String explanation = (polieJsonField(json, 'explanation', fallback) as String);
    if (explanation.startsWith('{') || explanation.startsWith('```')) {
      explanation =
          'Let us practice this concept step by step with a clear example.';
    }
    return TutorLessonPayload(
      concept: sanitize(concept, fallbackText: 'Lesson'),
      explanation: sanitize(
        explanation,
        fallbackText: 'Let us practice this concept step by step.',
      ),
      example: TutorExample(
        targetLang: sanitize(
          (polieJsonField(ex, 'target_lang', '-') as String),
          fallbackText: 'Example unavailable',
        ),
        transliteration: sanitize(
          (polieJsonField(ex, 'transliteration', '-') as String),
          fallbackText: '-',
        ),
        english: sanitize(
          (polieJsonField(ex, 'english', '-') as String),
          fallbackText: 'Meaning unavailable',
        ),
      ),
      memoryTip: sanitize(
        (polieJsonField(json, 'memory_tip', '-') as String),
        fallbackText: 'Repeat the pattern aloud three times.',
      ),
      watchOut: (polieJsonField(json, 'watch_out', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize((polieJsonField(json, 'watch_out', '') as String), fallbackText: ''),
      practiceQuestion:
          (polieJsonField(json, 'practice_question', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize(
              (polieJsonField(json, 'practice_question', '') as String),
              fallbackText: 'Can you write one sentence using this concept?',
            ),
      practiceHint:
          (polieJsonField(json, 'practice_hint', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize(
              (polieJsonField(json, 'practice_hint', '') as String),
              fallbackText: 'Start with a short simple sentence.',
            ),
    );
  }
}

class TutorExample {
  final String targetLang;
  final String transliteration;
  final String english;
  const TutorExample({
    required this.targetLang,
    required this.transliteration,
    required this.english,
  });
}

class TutorFeedbackPayload {
  final String verdict;
  final int score;
  final String encouragement;
  final String correction;
  final String why;
  final String? nativeSpeakerNote;
  final String nextStep;
  final String drill;
  const TutorFeedbackPayload({
    required this.verdict,
    required this.score,
    required this.encouragement,
    required this.correction,
    required this.why,
    required this.nativeSpeakerNote,
    required this.nextStep,
    required this.drill,
  });
  String uxFeedbackLine() {
    final tier = verdict.toLowerCase();
    return CorrectionResult(
      tier: tier == 'correct' || tier == 'close' || tier == 'incorrect'
          ? tier
          : 'close',
      hasCorrection:
          correction.trim().isNotEmpty && correction != '-',
      wasCorrect: verdict.toLowerCase() == 'correct',
      correction: correction,
    ).uxFeedbackLine();
  }

  factory TutorFeedbackPayload.fromJson(
    Map<String, dynamic> json,
    String fallback,
  ) {
    String sanitize(String value, {String fallbackText = '-'}) {
      final v = value.trim();
      if (v.isEmpty) return fallbackText;
      if (v.startsWith('{') || v.startsWith('```') || v.startsWith('[')) {
        return fallbackText;
      }
      return cleanAiText(v, fallback: fallbackText);
    }

    return TutorFeedbackPayload(
      verdict: (polieJsonField(json, 'verdict', 'close') as String),
      score: (polieJsonField(json, 'score', 50) as num).toInt(),
      encouragement: sanitize(
        (polieJsonField(json, 'encouragement', fallback) as String),
        fallbackText: 'Good effort. Keep practicing and try again.',
      ),
      correction: sanitize(
        (polieJsonField(json, 'correction', '-') as String),
        fallbackText: 'Try a simpler sentence pattern.',
      ),
      why: sanitize(
        (polieJsonField(json, 'why', '-') as String),
        fallbackText: 'Your structure is close; adjust word order and tense.',
      ),
      nativeSpeakerNote:
          (polieJsonField(json, 'native_speaker_note', '') as String?)?.trim().isEmpty ??
              true
          ? null
          : sanitize(
              (polieJsonField(json, 'native_speaker_note', '') as String),
              fallbackText: '',
            ),
      nextStep: sanitize(
        (polieJsonField(json, 'next_step', '') as String),
        fallbackText:
            'Write one new sentence using this pattern and read it aloud.',
      ),
      drill: sanitize(
        (polieJsonField(json, 'drill', '') as String),
        fallbackText: 'Mini drill: rewrite your answer in a shorter sentence.',
      ),
    );
  }
}

class RoleplayPayload {
  final RoleplayCharacterResponse characterResponse;
  final RoleplayCoaching coaching;
  const RoleplayPayload({
    required this.characterResponse,
    required this.coaching,
  });
  factory RoleplayPayload.fromJson(
    Map<String, dynamic> json,
    String fallback,
  ) {
    final c = (polieJsonField(json, 'character_response', const {}) as Map)
        .cast<String, dynamic>();
    final coaching = (polieJsonField(json, 'coaching', const {}) as Map)
        .cast<String, dynamic>();
    return RoleplayPayload(
      characterResponse: RoleplayCharacterResponse(
        targetLang: cleanAiText(
          (polieJsonField(c, 'target_lang', fallback) as String),
          fallback: cleanAiText(fallback),
        ),
        transliteration: cleanAiText(
          (polieJsonField(c, 'transliteration', '-') as String),
          fallback: '-',
        ),
        english: cleanAiText(
          (polieJsonField(c, 'english', '-') as String),
          fallback: 'English translation unavailable.',
        ),
        emotion: (polieJsonField(c, 'emotion', 'neutral') as String),
        action: (polieJsonField(c, 'action', '') as String?)?.trim().isEmpty ?? true
            ? null
            : (polieJsonField(c, 'action', '') as String),
      ),
      coaching: RoleplayCoaching(
        userAccuracy: (polieJsonField(coaching, 'user_accuracy', 50) as num).toInt(),
        feedbackType: (polieJsonField(coaching, 'feedback_type', 'suggestion') as String),
        feedback: cleanAiText((polieJsonField(coaching, 'feedback', '-') as String)),
        betterPhrasing:
            (polieJsonField(coaching, 'better_phrasing', '') as String?)?.trim().isEmpty ??
                true
            ? null
            : (polieJsonField(coaching, 'better_phrasing', '') as String),
      ),
    );
  }
}

class RoleplayCharacterResponse {
  final String targetLang;
  final String transliteration;
  final String english;
  final String emotion;
  final String? action;
  const RoleplayCharacterResponse({
    required this.targetLang,
    required this.transliteration,
    required this.english,
    required this.emotion,
    required this.action,
  });
}

class RoleplayCoaching {
  final int userAccuracy;
  final String feedbackType;
  final String feedback;
  final String? betterPhrasing;
  const RoleplayCoaching({
    required this.userAccuracy,
    required this.feedbackType,
    required this.feedback,
    required this.betterPhrasing,
  });
}

class RoleplayTurn {
  final String? userText;
  final RoleplayPayload? ai;
  const RoleplayTurn._({this.userText, this.ai});
  factory RoleplayTurn.user(String text) => RoleplayTurn._(userText: text);
  factory RoleplayTurn.ai(RoleplayPayload ai) => RoleplayTurn._(ai: ai);
}

