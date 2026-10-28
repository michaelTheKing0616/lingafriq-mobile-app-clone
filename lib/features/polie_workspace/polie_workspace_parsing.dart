import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/utils/diacritics_enforcer.dart';

Map<String, dynamic>? tryParseJson(String raw) {
  // Strip control characters that break JSON parsing
  final cleaned = raw
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
      .trim();

  // Attempt 1: direct parse (works when response_format: json_object is used)
  try {
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}

  // Attempt 1b: truncated / invalid JSON but a complete "primary" string is present
  try {
    final primaryMatch = RegExp(
      r'"primary"\s*:\s*"((?:\\.|[^"\\])*)"',
    ).firstMatch(cleaned);
    if (primaryMatch != null) {
      final raw = primaryMatch.group(1) ?? '';
      final unescaped = raw
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\');
      if (unescaped.trim().isNotEmpty) {
        return {
          'primary': unescaped,
          'alternatives': <dynamic>[],
          'cultural_note': null,
          'tone_achieved': 'literal',
        };
      }
    }
  } catch (_) {}

  // Attempt 2: extract JSON object between first { and last }
  try {
    final first = cleaned.indexOf('{');
    final last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) {
      final jsonBody = cleaned.substring(first, last + 1);
      final decoded = jsonDecode(jsonBody);
      if (decoded is Map<String, dynamic>) return decoded;
    }
  } catch (_) {}

  // Attempt 2b: prose Polie format "Translation: …" through following lines until ASCII/Usage/Notes
  try {
    final trMatch = RegExp(
      r'Translation:\s*([\s\S]*?)(?=\n\s*(?:ASCII|Usage|Notes):|\Z)',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (trMatch != null) {
      final body = trMatch.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
      if (body.isNotEmpty) {
        return {
          'primary': body,
          'alternatives': <dynamic>[],
          'cultural_note': null,
          'tone_achieved': 'literal',
        };
      }
    }
  } catch (_) {}

  // Attempt 3: roleplay-aware extraction when nested JSON is broken
  try {
    if (cleaned.contains('character_response') ||
        cleaned.contains('target_lang')) {
      final targetMatch = RegExp(
        r'"target_lang"\s*:\s*"([^"]*)"',
      ).firstMatch(cleaned);
      final englishMatch = RegExp(
        r'"english"\s*:\s*"([^"]*)"',
      ).firstMatch(cleaned);
      final feedbackMatch = RegExp(
        r'"feedback"\s*:\s*"([^"]*)"',
      ).firstMatch(cleaned);
      if (targetMatch != null) {
        return {
          'character_response': {
            'target_lang': targetMatch.group(1) ?? '',
            'transliteration': '-',
            'english': englishMatch?.group(1) ?? '-',
            'emotion': 'neutral',
            'action': null,
          },
          'coaching': {
            'user_accuracy': 50,
            'feedback_type': 'suggestion',
            'feedback': feedbackMatch?.group(1) ?? 'Keep practicing!',
            'better_phrasing': null,
          },
        };
      }
    }
  } catch (_) {}

  // Attempt 4: build minimal JSON from key:value prose (graceful degradation)
  try {
    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty);
    final map = <String, dynamic>{};
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx > 0) {
        final key = line
            .substring(0, colonIdx)
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        final value = line.substring(colonIdx + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          map[key] = value;
        }
      }
    }
    if (map.isNotEmpty) {
      if (!map.containsKey('primary') && map.length == 1) {
        map['primary'] = map.values.first;
      }
      return map;
    }
  } catch (_) {}

  debugPrint(
    '[Polie] _tryParseJson failed on: ${raw.length > 200 ? raw.substring(0, 200) : raw}',
  );
  return null;
}

dynamic polieJsonField(Map<String, dynamic>? map, String key, dynamic fallback) =>
    map?[key] ?? fallback;

dynamic _n(Map<String, dynamic>? map, String key, dynamic fallback) =>
    polieJsonField(map, key, fallback);

/// Cleans LLM output for safe display. Default fallback is empty string so the
/// UI can render a proper empty/error state instead of a meaningless "-".
/// Callers that need a placeholder must pass it explicitly.
String cleanAiText(String input, {String fallback = ''}) {
  var out = input.trim();
  if (out.isEmpty) return fallback;
  out = out
      .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
      .replaceAll(RegExp(r'```'), '')
      .replaceAll(RegExp(r'^\{\s*"message"\s*:\s*"', multiLine: true), '')
      .replaceAll(RegExp(r'"\s*\}\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (out.isEmpty) return fallback;
  if (out == '-' || out == '--') return fallback;
  if (out.startsWith('{') || out.startsWith('[')) return fallback;
  return out;
}

bool looksTruncated(String message) {
  final m = message.trim();
  if (m.isEmpty) return true;
  if (m.length < 8) return true;
  final last = m.codeUnitAt(m.length - 1);
  if (last == 46 || last == 33 || last == 63) return false; // . ! ?
  if ((last == 34 || last == 39) && m.length > 1) {
    final prev = m.codeUnitAt(m.length - 2);
    if (prev == 46 || prev == 33 || prev == 63) {
      return false; // . ! ? before quote
    }
  }
  return true;
}

bool isConversationResponseRich(String message) {
  final normalized = message.trim();
  if (normalized.length < 45) return false;
  final sentenceCount = RegExp(r'[.!?]+').allMatches(normalized).length;
  if (sentenceCount >= 3) return true;
  return normalized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length >=
      16;
}

List<AltItem> buildFallbackAlternatives(String primary, String tone) {
  final clean = primary.trim();
  if (clean.isEmpty || clean == '-') return const <AltItem>[];
  final note = switch (tone.toLowerCase()) {
    'formal' => 'Primary formal rendering',
    'casual' => 'Primary casual rendering',
    'poetic' => 'Primary poetic rendering',
    'literal' => 'Primary literal rendering',
    _ => 'Primary rendering',
  };
  return <AltItem>[AltItem(text: clean, note: note)];
}

TranslationPayload normalizeTranslationPayload({
  required TranslationPayload payload,
  required String targetLanguage,
  required String sourceText,
}) {
  String fixText(String value) {
    var out = value.trim();
    if (out.isEmpty) return out;
    final enforced = DiacriticsEnforcer.enforceWithMetadata(
      out,
      targetLanguage,
      enableFuzzy: true,
      fuzzyThreshold: 0.7,
    );
    out = (enforced['text'] as String?) ?? out;

    // High-impact correction for a common greeting regression.
    final asksGoodMorning = RegExp(
      r'\bgood\s+morning\b',
      caseSensitive: false,
    ).hasMatch(sourceText);
    final isYoruba = targetLanguage.toLowerCase().contains('yor');
    if (isYoruba && asksGoodMorning) {
      final normalized = out.toLowerCase().replaceAll(
        RegExp(r'[\s\-\.\,]'),
        '',
      );
      if (normalized == 'eka' ||
          normalized == 'ẹká' ||
          normalized == 'ekaaro' ||
          normalized == 'ẹkáárọ̀') {
        out = 'Ẹ káàárọ̀';
      }
    }

    // "Good evening" — repair over-truncated outputs (e.g. "E", "E ku") from bad parses/streams.
    final asksGoodEvening = RegExp(
      r'\bgood\s+evening\b',
      caseSensitive: false,
    ).hasMatch(sourceText);
    if (isYoruba && asksGoodEvening) {
      final collapsed = out.toLowerCase().replaceAll(
        RegExp(r'[\s\-\.\,]'),
        '',
      );
      final tooShort = out.runes.length <= 4;
      final looksBroken = collapsed == 'e' ||
          collapsed == 'ẹ' ||
          collapsed == 'eku' ||
          collapsed == 'ẹku' ||
          collapsed == 'ekú' ||
          collapsed == 'ẹkú' ||
          collapsed.startsWith('eku') && collapsed.length <= 5;
      if (tooShort || looksBroken) {
        out = 'Ẹ kúalẹ́';
      }
    }
    return out;
  }

  final primary = fixText(payload.primary);
  final alternatives = payload.alternatives
      .map((alt) => AltItem(text: fixText(alt.text), note: alt.note))
      .where((alt) => alt.text.trim().isNotEmpty)
      .toList();

  return TranslationPayload(
    primary: primary,
    alternatives: alternatives,
    culturalNote: payload.culturalNote,
    toneAchieved: payload.toneAchieved,
  );
}

ConversationPayload enforceConversationDiacritics(
  ConversationPayload payload,
  String language,
) {
  String enforce(String value) {
    if (value.trim().isEmpty) return value;
    final result = DiacriticsEnforcer.enforceWithMetadata(
      value,
      language,
      enableFuzzy: true,
      fuzzyThreshold: 0.7,
    );
    return (result['text'] as String?) ?? value;
  }

  return ConversationPayload(
    messageTarget: enforce(payload.messageTarget),
    englishTranslation: payload.englishTranslation,
    correction: ConversationCorrection(
      tier: payload.correction.tier,
      hasCorrection: payload.correction.hasCorrection,
      wasCorrect: payload.correction.wasCorrect,
      correction: payload.correction.correction == null
          ? null
          : enforce(payload.correction.correction!),
      note: enforce(payload.correction.note),
    ),
    suggestedReplies: payload.suggestedReplies.map(enforce).toList(),
    newVocab: payload.newVocab
        .map(
          (v) => ConversationVocab(word: enforce(v.word), meaning: v.meaning),
        )
        .toList(),
  );
}
