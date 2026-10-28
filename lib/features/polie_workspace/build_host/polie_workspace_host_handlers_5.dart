import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/models/correction_result.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_mode_surface.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/content/polie_conversation_prompt_builder.dart';
import 'package:lingafriq/services/ai/conversation_persistence_service.dart';
import 'package:lingafriq/services/ai/polie_conversation_stream_service.dart';
import 'package:lingafriq/services/ai/polie_voice_input_service.dart';
import 'package:lingafriq/services/content/polie_prompt_service.dart';
import 'package:lingafriq/services/content/polie_conversation_service.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/services/polie_tutor_saved_cards_service.dart';
import 'package:lingafriq/services/telemetry_service.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/utils/diacritics_enforcer.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart' as uuid;

import 'package:lingafriq/features/polie_workspace/polie_workspace_history_helpers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_screen_widget.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';

import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_state.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_1.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_2.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_3.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_4.dart';

Future<void> sendPolieWorkspaceConversationJsonFallback(
  PolieWorkspaceHostState host, {
  required String text,
  required bool wantsEnglish,
  required String styleInstruction,
  required String activeConversationId,
  required DateTime turnStarted,
}) async {
try {
    bool _userAskedForGreeting(String userText) {
      final t = userText.toLowerCase();
      // Keep this broad but safe: only exempt greeting-only responses when the user
      // explicitly asked for greetings/hello/how to greet.
      return t.contains('greeting') ||
          t.contains('greetings') ||
          t.contains('say hello') ||
          t.contains('hello') ||
          t.contains('hi') ||
          t.contains('good morning') ||
          t.contains('good afternoon') ||
          t.contains('good evening') ||
          t.contains('how do i greet') ||
          t.contains('how to greet') ||
          t.contains('teach me a greeting');
    }

    bool _looksLikeGreetingOnly(String candidate) {
      final normalized = candidate
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[\u2019\u2018]'), "'")
          // NOTE: raw strings (r'') cannot escape `'` with backslash.
          // Use a raw double-quoted string so `'` is allowed inside.
          .replaceAll(
            RegExp(r"[^a-zA-ZÀ-ÖØ-öø-ÿẸỌṢẹọṣ'\s?!.]"),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (normalized.isEmpty) return false;

      // Quick reject: if there's enough content, it's not "greeting-only".
      final words =
          normalized.split(' ').where((w) => w.trim().isNotEmpty).toList();
      if (words.length >= 6) return false;

      // Common greeting-only outputs we want to catch (across several languages).
      const greetingPhrases = <String>{
        // Yoruba
        'bawo',
        'báwo',
        'bawo ni',
        'báwo ni',
        'ẹ káàrọ̀',
        'ẹ kaaro',
        'ẹ káàsán',
        'ẹ kaasan',
        'ẹ kúalẹ́',
        'ẹ kuale',
        'ẹ n lẹ',
        'ẹ nle',
        'ẹ̀ n lẹ',
        // Igbo / Hausa / Swahili / generic
        'kedu',
        'sannu',
        'habari',
        'habari yako',
        'jambo',
        'mambo',
        'ndewo',
        'hello',
        'hi',
      };

      // Strip trailing punctuation for comparison.
      final bare = normalized.replaceAll(RegExp(r'[?!.]+$'), '').trim();
      if (greetingPhrases.contains(bare)) return true;

      // Also catch "báwo ni?" variants etc.
      if (greetingPhrases.contains(bare.replaceAll('?', ''))) return true;

      return false;
    }

    // Relaxed gate (v4): only reject clearly broken outputs. Previously this
    // gate enforced an 80-char minimum + sentence-richness which caused
    // valid short, idiomatic replies to be discarded. We now accept any
    // reasonable answer and only retry when:
    //   - The response is empty after cleaning, OR
    //   - It looks like raw JSON or markdown fences leaked through, OR
    //   - It is a bare greeting when the user did not ask for one, OR
    //   - It is severely truncated mid-word (no terminal punctuation AND
    //     ends with a partial token).
    bool _isMissingOrWeakMessageTarget(Map<String, dynamic> obj) {
      final raw = (obj['message_target'] ?? obj['message'] ?? '').toString();
      final cleaned = cleanAiText(raw, fallback: '').trim();
      if (cleaned.isEmpty) return true;
      if (cleaned.startsWith('{') || cleaned.startsWith('[')) return true;
      if (!_userAskedForGreeting(text) && _looksLikeGreetingOnly(cleaned)) {
        return true;
      }
      // Severe truncation: very short AND no terminal punctuation.
      if (cleaned.length < 12 && looksTruncated(cleaned)) return true;
      return false;
    }

    Future<Map<String, dynamic>?> _askConversationJson({
      required String prompt,
      int timeoutSeconds = 25,
    }) async {
      try {
        final raw = await host.chat
            .sendMessageForJson(prompt)
            .timeout(Duration(seconds: timeoutSeconds));
        host.modeResponse.value = raw;
        final parsed = tryParseJson(raw);
        if (parsed == null) return null;
        return parsed;
      } catch (_) {
        // Fall back to shared helper, but keep same behaviour.
        return await (host as PolieWorkspaceHostHandlers1).askForJson(prompt);
      }
    }

    final nonce = DateTime.now().microsecondsSinceEpoch;
    final promptService = host.ref.read(poliePromptServiceProvider);
    final personaSnippets = await promptService.persona(
      PolieConversationPromptBuilder.defaultPersonaKey,
    );
    final convBuilder = PolieConversationPromptBuilder();
    final personaPrefix = convBuilder.personaPrefixFromSnippets(
      personaSnippets,
      host.targetLanguage,
    );

    // Build the rolling multi-turn history buffer from the in-memory
    // conversation. We include the most recent turns (up to
    // [PolieConversationPromptBuilder.maxHistoryTurns]) so the LLM has
    // proper context for coreference, follow-ups, and topic continuity.
    final history = <PolieConversationTurnContext>[];
    for (final turn in host.conversationMessages.value) {
      if (turn.userText != null && turn.userText!.trim().isNotEmpty) {
        // Skip the just-appended current user message (added at line ~920).
        history.add(
          PolieConversationTurnContext(
            role: 'user',
            text: turn.userText!.trim(),
          ),
        );
      } else if (turn.ai != null &&
          !turn.ai!.isError &&
          turn.ai!.messageTarget.trim().isNotEmpty) {
        history.add(
          PolieConversationTurnContext(
            role: 'assistant',
            text: turn.ai!.messageTarget.trim(),
          ),
        );
      }
    }
    // Pop the current user message off the tail — it's passed separately
    // via [userMessage] in the prompt. This avoids the LLM seeing it twice.
    if (history.isNotEmpty &&
        history.last.role == 'user' &&
        history.last.text == text) {
      history.removeLast();
    }

    Map<String, dynamic>? json = await (host as PolieWorkspaceHostHandlers1).askForJson(
      convBuilder.buildConversationJsonPrompt(
        targetLanguage: host.targetLanguage,
        userMessage: text,
        responseStyle: host.conversationResponseStyle.value,
        styleInstruction: styleInstruction,
        wantsEnglish: wantsEnglish,
        personaSystemPrefix: personaPrefix,
        nonce: nonce,
        history: history,
      ),
    );

    // Stricter retry if message_target is missing/too short/low-quality.
    if (json != null && _isMissingOrWeakMessageTarget(json!)) {
      final strictJson = await _askConversationJson(
        prompt: convBuilder.buildConversationJsonPrompt(
          targetLanguage: host.targetLanguage,
          userMessage: text,
          responseStyle: host.conversationResponseStyle.value,
          styleInstruction: styleInstruction,
          wantsEnglish: wantsEnglish,
          personaSystemPrefix: personaPrefix,
          nonce: DateTime.now().microsecondsSinceEpoch,
          strict: true,
          history: history,
        ),
      );
      if (strictJson != null && !_isMissingOrWeakMessageTarget(strictJson)) {
        json = strictJson;
      }
    }

    // If still weak, do a continuation retry (strict).
    if (json != null && _isMissingOrWeakMessageTarget(json!)) {
      final continuation = await _askConversationJson(prompt: '''
Return STRICT JSON only:
{
  "message_target":"string (in ${host.targetLanguage}, >= 140 chars, fully complete, no trailing truncation)",
  "message_english":${wantsEnglish ? '"string"' : 'null'},
  "correction":{"tier":"correct","has_correction":false,"was_correct":true,"correction":"","note":"short note"},
  "suggested_replies":["reply 1 in ${host.targetLanguage}","reply 2 in ${host.targetLanguage}","reply 3 in ${host.targetLanguage}"],
  "new_vocab":[]
}

Rewrite the response from scratch (do NOT output a short continuation). It must be fully complete and detailed.
User message: "$text"
Target language: ${host.targetLanguage}
Style: ${host.conversationResponseStyle.value}
Nonce: ${DateTime.now().microsecondsSinceEpoch}
''');
      if (continuation != null && !_isMissingOrWeakMessageTarget(continuation)) {
        json = continuation;
      }
    }

    // LAST RESORT: normal Groq host.chat completion (not offline translation, not JSON).
    if (json == null || (json != null && _isMissingOrWeakMessageTarget(json!))) {
      final chatPrompt = '''
You are Polie: a smart, witty, accurate conversation partner.
This is OPEN-ENDED CHAT mode. The user can ask about ANY topic.

Reply in ${host.targetLanguage} with correct orthography/diacritics.
Response style: ${host.conversationResponseStyle.value}
Style rules: $styleInstruction

Rules:
- Answer the user's question directly first.
- Be detailed and complete (prefer 12–20 sentences unless style is "terse").
- Do NOT ignore the user's prompt.
${wantsEnglish ? '- After your reply, do NOT include the English translation in the same text. (It will be handled separately.)' : '- Do NOT include any English.'}

User message: "$text"
''';

      final raw = await host.gateway.completePolieJson(
        polieModeName: PolieMode.conversation.name,
        userMessage: chatPrompt,
        language: host.targetLanguage,
        languageCode: SupportedLanguages.getLanguageCode(host.targetLanguage),
        targetLanguage: SupportedLanguages.getLanguageCode(host.targetLanguage),
      );
      final targetReply = cleanAiText(raw, fallback: raw).trim();

      String? englishTranslation;
      if (wantsEnglish && targetReply.isNotEmpty) {
        try {
          // Translate the Polie reply to English using the hybrid translation stack.
          // Avoid offline dictionary here so it can't collapse to phrase-pack outputs.
          final tr = await TranslationService().translate(
            text: targetReply,
            sourceLang: polieBackendKeyForDisplayOrGroq(host.targetLanguage),
            targetLang: polieBackendKeyForDisplayOrGroq('English'),
            includePhraseBreakdown: false,
            allowOffline: false,
          );
          final maybe = tr.translation.trim();
          if (maybe.isNotEmpty && maybe != targetReply) {
            englishTranslation = maybe;
          }
        } catch (_) {
          // Best-effort; keep null if translation fails.
        }
      }

      if (targetReply.isEmpty) {
        // Generation failed end-to-end. Surface a real error turn so the
        // user can retry instead of seeing a meaningless "-" placeholder.
        host.conversationMessages.value = [
          ...host.conversationMessages.value,
          ConversationTurn.aiError(
            'Polie could not generate a reply just now. Tap retry to try again.',
            retryUserText: text,
          ),
        ];
        unawaited(
          host.persistence.appendTurn(
            conversationId: activeConversationId,
            language: host.targetLanguage,
            persona: 'encouraging_mentor',
            turn: PersistedTurn(
              role: 'assistant',
              text: '',
              language: host.targetLanguage,
              isError: true,
              errorMessage:
                  'Polie could not generate a reply just now. Tap retry to try again.',
              createdAt: DateTime.now(),
            ),
          ),
        );
        return;
      }

      final fallbackPayload = enforceConversationDiacritics(
        ConversationPayload(
          messageTarget: targetReply,
          englishTranslation: englishTranslation,
          correction: const ConversationCorrection(
            tier: 'correct',
            hasCorrection: false,
            wasCorrect: true,
            correction: null,
            note: '',
          ),
          suggestedReplies: const [],
          newVocab: const [],
        ),
        host.targetLanguage,
      );

      host.conversationMessages.value = [
        ...host.conversationMessages.value,
        ConversationTurn.ai(fallbackPayload),
      ];
      unawaited(
        host.persistence.appendTurn(
          conversationId: activeConversationId,
          language: host.targetLanguage,
          persona: 'encouraging_mentor',
          turn: PersistedTurn(
            role: 'assistant',
            text: fallbackPayload.messageTarget,
            language: host.targetLanguage,
            englishTranslation: fallbackPayload.englishTranslation,
            createdAt: DateTime.now(),
          ),
        ),
      );
      return;
    }

    if (json != null) {
      final rawPayload = ConversationPayload.fromJson(
        json,
        host.modeResponse.value,
      );
      final payload = enforceConversationDiacritics(
        rawPayload,
        host.targetLanguage,
      );
      host.conversationMessages.value = [
        ...host.conversationMessages.value,
        ConversationTurn.ai(payload),
      ];
      final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
      final oldRatio = host.languageRatio.value;
      host.languageRatio.value =
          ((oldRatio * (host.conversationMessages.value.length - 1)) +
              (targetLetters ? 1 : 0)) /
          host.conversationMessages.value.length;
      unawaited(
        host.persistence.appendTurn(
          conversationId: activeConversationId,
          language: host.targetLanguage,
          persona: 'encouraging_mentor',
          turn: PersistedTurn(
            role: 'assistant',
            text: payload.messageTarget,
            language: host.targetLanguage,
            englishTranslation: payload.englishTranslation,
            correction: PersistedCorrection(
              tier: payload.correction.tier,
              hasCorrection: payload.correction.hasCorrection,
              wasCorrect: payload.correction.wasCorrect,
              correction: payload.correction.correction,
              note: payload.correction.note,
            ),
            suggestedReplies: payload.suggestedReplies,
            newVocab: payload.newVocab
                .map(
                  (v) => PersistedVocab(
                    word: v.word,
                    meaning: v.meaning,
                  ),
                )
                .toList(),
            createdAt: DateTime.now(),
          ),
        ),
      );
      unawaited(
        host.ref.read(telemetryServiceProvider).trackPolieConversationTurn(
          language: host.targetLanguage,
          success: true,
          usedStreaming: false,
          durationMs:
              DateTime.now().difference(turnStarted).inMilliseconds,
          messageLength: payload.messageTarget.length,
        ),
      );
    }
  } catch (e) {
    host.modeError.value =
        'Conversation error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
    unawaited(
      host.ref.read(telemetryServiceProvider).trackPolieConversationTurn(
        language: host.targetLanguage,
        success: false,
        usedStreaming: false,
        durationMs: DateTime.now().difference(turnStarted).inMilliseconds,
        errorCode: 'conversation_exception',
      ),
    );
  } finally {
    host.isBusy.value = false;
  }

}

mixin PolieWorkspaceHostHandlers5 on PolieWorkspaceHostState, PolieWorkspaceHostHandlers1, PolieWorkspaceHostHandlers2, PolieWorkspaceHostHandlers3, PolieWorkspaceHostHandlers4 {
  Future<void> sendConversationJsonFallback({
    required String text,
    required bool wantsEnglish,
    required String styleInstruction,
    required String activeConversationId,
    required DateTime turnStarted,
  }) =>
      sendPolieWorkspaceConversationJsonFallback(
        this,
        text: text,
        wantsEnglish: wantsEnglish,
        styleInstruction: styleInstruction,
        activeConversationId: activeConversationId,
        turnStarted: turnStarted,
      );
}
