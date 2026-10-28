import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/services/ai/conversation_persistence_service.dart';
import 'package:lingafriq/services/ai/polie_conversation_stream_service.dart';
import 'package:lingafriq/services/telemetry_service.dart';
import 'package:uuid/uuid.dart' as uuid;


import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_state.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_1.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_2.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_3.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_5.dart' show sendPolieWorkspaceConversationJsonFallback;

mixin PolieWorkspaceHostHandlers4 on PolieWorkspaceHostState, PolieWorkspaceHostHandlers1, PolieWorkspaceHostHandlers2, PolieWorkspaceHostHandlers3 {
Future<void> sendConversation([String? prefilledText]) async {
  final text = (prefilledText ?? conversationInput.text).trim();
  if (text.isEmpty) return;
  final wantsEnglish =
      conversationIncludeEnglishTranslations.value ||
      RegExp(
        r'english translation|with english|translate to english|english in',
        caseSensitive: false,
      ).hasMatch(text);
  final style = conversationResponseStyle.value.trim().toLowerCase();
  final styleInstruction = switch (style) {
    'formal' => 'Use a formal, respectful register. Avoid slang. Be precise.',
    'humorous' =>
      'Be humorous and playful, but never rude. Keep accuracy and clarity.',
    'witty' =>
      'Be witty and clever. Light wordplay is welcome if it fits the topic. Keep accuracy.',
    'terse' =>
      'Be concise: 2–4 sentences max, but still answer fully and accurately.',
    _ =>
      'Be richly detailed: 12–20 sentences. Smart, accurate, engaging, and complete.',
  };
  conversationMessages.value = [
    ...conversationMessages.value,
    ConversationTurn.user(text),
  ];
  if (prefilledText == null) conversationInput.clear();
  isBusy.value = true;
  final turnStarted = DateTime.now();

  // Ensure this.conversationId is set for this.persistence + sync.
  conversationId.value ??= const uuid.Uuid().v4();
  final activeConversationId = conversationId.value!;

  // Persist user turn locally; non-blocking.
  unawaited(
    persistence.appendTurn(
      conversationId: activeConversationId,
      language: targetLanguage,
      persona: 'encouraging_mentor',
      titleHint: text,
      turn: PersistedTurn(
        role: 'user',
        text: text,
        language: targetLanguage,
        createdAt: DateTime.now(),
      ),
    ),
  );

  // ---------------------------------------------------------------------
  // Primary path: streaming SSE conversation.
  //
  // We attempt the new /api/v2/polie/conversation/stream endpoint first so
  // the user sees token-by-token output (p50 first token < 1.2s). If the
  // stream returns a server error OR yields no meaningful text, we fall
  // through to the legacy JSON-only path below.
  // ---------------------------------------------------------------------
  bool streamingSucceeded = false;
  try {
    final streamService = PolieConversationStreamService();
    final streamHistory = <PolieConversationTurnInput>[];
    for (final turn in conversationMessages.value) {
      if (turn.userText != null && turn.userText!.trim().isNotEmpty) {
        streamHistory.add(
          PolieConversationTurnInput(
            role: 'user',
            text: turn.userText!.trim(),
          ),
        );
      } else if (turn.ai != null &&
          !turn.ai!.isError &&
          turn.ai!.messageTarget.trim().isNotEmpty) {
        streamHistory.add(
          PolieConversationTurnInput(
            role: 'assistant',
            text: turn.ai!.messageTarget.trim(),
          ),
        );
      }
    }
    // Pop the just-appended current user message — it's passed separately.
    if (streamHistory.isNotEmpty &&
        streamHistory.last.role == 'user' &&
        streamHistory.last.text == text) {
      streamHistory.removeLast();
    }

    conversationStreamingTarget.value = '';
    conversationStreamingActive.value = true;

    PolieConversationStreamFinalEvent? finalEvent;
    String? streamError;

    await for (final evt in streamService.sendConversationTurn(
      language: targetLanguage,
      userMessage: text,
      conversationId: conversationId.value,
      responseStyle: conversationResponseStyle.value,
      wantsEnglish: wantsEnglish,
      history: streamHistory,
    )) {
      if (evt is PolieConversationStreamMetaEvent) {
        conversationId.value = evt.conversationId;
      } else if (evt is PolieConversationStreamDeltaEvent) {
        conversationStreamingTarget.value =
            '${conversationStreamingTarget.value}${evt.text}';
      } else if (evt is PolieConversationStreamFinalEvent) {
        finalEvent = evt;
      } else if (evt is PolieConversationStreamErrorEvent) {
        streamError = evt.error;
      } else if (evt is PolieConversationStreamDoneEvent) {
        break;
      }
    }

    conversationStreamingActive.value = false;
    conversationStreamingTarget.value = '';
    streamService.dispose();

    if (streamError == null &&
        finalEvent != null &&
        finalEvent.messageTarget.trim().isNotEmpty) {
      final payload = enforceConversationDiacritics(
        ConversationPayload(
          messageTarget: finalEvent.messageTarget,
          englishTranslation: finalEvent.englishTranslation,
          correction: ConversationCorrection(
            tier: finalEvent.correction.tier,
            hasCorrection: finalEvent.correction.hasCorrection,
            wasCorrect: finalEvent.correction.wasCorrect,
            correction: finalEvent.correction.correction,
            note: finalEvent.correction.note,
          ),
          suggestedReplies: finalEvent.suggestedReplies,
          newVocab: finalEvent.newVocab
              .map(
                (v) => ConversationVocab(
                  word: v.word,
                  meaning: v.meaning,
                ),
              )
              .toList(),
        ),
        targetLanguage,
      );
      conversationMessages.value = [
        ...conversationMessages.value,
        ConversationTurn.ai(payload),
      ];
      // Update language ratio for the in-app progress bar.
      final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
      final oldRatio = languageRatio.value;
      languageRatio.value =
          ((oldRatio * (conversationMessages.value.length - 1)) +
                  (targetLetters ? 1 : 0)) /
              conversationMessages.value.length;
      // Persist assistant turn (server already saved its copy, this is
      // the local cache for offline resilience).
      unawaited(
        persistence.appendTurn(
          conversationId: activeConversationId,
          language: targetLanguage,
          persona: 'encouraging_mentor',
          turn: PersistedTurn(
            role: 'assistant',
            text: payload.messageTarget,
            language: targetLanguage,
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
      streamingSucceeded = true;
      unawaited(
        ref.read(telemetryServiceProvider).trackPolieConversationTurn(
          language: targetLanguage,
          success: true,
          usedStreaming: true,
          durationMs:
              DateTime.now().difference(turnStarted).inMilliseconds,
          messageLength: payload.messageTarget.length,
        ),
      );
    } else {
      // Streaming failed: fall through to legacy JSON path.
      debugPrint(
        '[Polie] stream failed; falling back to JSON path: $streamError',
      );
      unawaited(
        ref.read(telemetryServiceProvider).trackPolieConversationTurn(
          language: targetLanguage,
          success: false,
          usedStreaming: true,
          durationMs:
              DateTime.now().difference(turnStarted).inMilliseconds,
          errorCode: streamError ?? 'empty_stream',
        ),
      );
    }
  } catch (e) {
    conversationStreamingActive.value = false;
    conversationStreamingTarget.value = '';
    debugPrint('[Polie] streaming threw $e; using JSON fallback');
    unawaited(
      ref.read(telemetryServiceProvider).trackPolieConversationTurn(
        language: targetLanguage,
        success: false,
        usedStreaming: true,
        durationMs: DateTime.now().difference(turnStarted).inMilliseconds,
        errorCode: 'stream_exception',
      ),
    );
  }

  if (streamingSucceeded) {
    isBusy.value = false;
    return;
  }
  await sendPolieWorkspaceConversationJsonFallback(this, 
    text: text,
    wantsEnglish: wantsEnglish,
    styleInstruction: styleInstruction,
    activeConversationId: activeConversationId,
    turnStarted: turnStarted,
  );
}

}
