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

mixin PolieWorkspaceHostHandlers1 on PolieWorkspaceHostState {
Future<void> refreshTutorSavedCards() async {
  final saved = await PolieTutorSavedCardsService.loadSavedCards();
  this.tutorSavedCards.value = saved
      .where(
        (c) =>
            c.targetLanguage.trim().toLowerCase() ==
                targetLanguage.trim().toLowerCase() &&
            c.difficulty.trim().toLowerCase() ==
                this.tutorDifficulty.value.trim().toLowerCase(),
      )
      .toList();

  final currentConceptKey =
      this.tutorLesson.value?.concept.trim().toLowerCase() ?? '';
  this.tutorIsCurrentSaved.value = currentConceptKey.isNotEmpty &&
      this.tutorSavedCards.value.any((c) => c.conceptKey == currentConceptKey);
}


Future<void> loadTutorSeenConcepts() async {
  final seen = await PolieTutorSavedCardsService.loadSeenConceptKeys(
    targetLanguage: targetLanguage,
    difficulty: this.tutorDifficulty.value,
  );
  this.tutorSeenConcepts.value = seen.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
}

String buildStreakBannerText() {
  final days = this.streakDays.value;
  if (days > 0) {
    return '🔥 $days day${days == 1 ? '' : 's'} streak!';
  }
  return LingAfriqUxVoice.dailyPractice.first;
}


Future<void> syncTranslationLanguagesToChat() async {
  if (this.activeMode.value != PolieMode.translation) return;
  await this.chat.setModeAndLanguage(
    mode: PolieMode.translation,
    sourceLanguage: this.translationSourceLang.value,
    targetLanguage: this.translationTargetLang.value,
  );
}


Future<void> setMode(PolieMode mode) async {
  this.activeMode.value = mode;
  this.modeError.value = null;
  this.modeResponse.value = '';
  final src = mode == PolieMode.translation
      ? this.translationSourceLang.value
      : this.screen.sourceLanguage;
  final tgt = mode == PolieMode.translation
      ? this.translationTargetLang.value
      : targetLanguage;
  await this.chat.setModeAndLanguage(
    mode: mode,
    sourceLanguage: src,
    targetLanguage: tgt,
  );
}

Future<Map<String, dynamic>?> askForJson(String prompt) async {
  try {
    final tgt = this.activeMode.value == PolieMode.translation
        ? this.translationTargetLang.value
        : targetLanguage;
    final src = this.activeMode.value == PolieMode.translation
        ? this.translationSourceLang.value
        : this.screen.sourceLanguage;
    final raw = await this.gateway
        .completePolieJson(
          polieModeName: this.activeMode.value.name,
          userMessage: prompt,
          language: tgt,
          languageCode: SupportedLanguages.getLanguageCode(tgt),
          sourceLanguage: SupportedLanguages.getLanguageCode(src),
          targetLanguage: SupportedLanguages.getLanguageCode(tgt),
        )
        .timeout(const Duration(seconds: 25));
    this.modeResponse.value = raw;
    final parsed = tryParseJson(raw);
    if (parsed == null) {
      this.modeError.value =
          'Polie returned an unreadable response. Please try again.';
      return null;
    }
    return parsed;
  } on AiGatewayException catch (e) {
    this.modeError.value = AiGatewayClient.userMessageFor(e, body: e.body);
    return null;
  } catch (e) {
    this.modeError.value = e.toString().replaceFirst('Exception: ', '');
    return null;
  }
}


Future<void> loadTranslationHistory() async {
  final history = await this.translationHistoryService.loadHistory();
  final query = this.translationHistoryQuery.value.trim().toLowerCase();
  final filtered = history.entries
      .where((entry) {
        if (query.isEmpty) return true;
        return entry.sourceText.toLowerCase().contains(query) ||
            entry.primaryTranslation.toLowerCase().contains(query);
      })
      .take(20)
      .toList();
  this.translationHistory.value = filtered;
}


Future<void> runTranslation(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  this.isBusy.value = true;
  this.modeError.value = null;
  try {
    Map<String, dynamic>? json = await askForJson('''
Return STRICT JSON only.
{
  "primary":"string",
  "alternatives":[{"text":"string","note":"string"}],
  "cultural_note":"string|null",
  "tone_achieved":"formal|casual|literal|poetic"
}

Translate from ${this.translationSourceLang.value} to ${this.translationTargetLang.value}.
Tone requested: ${this.translationTone.value}
Text: "$trimmed"
''');
    // If backend/LLM returns non-JSON prose, use the same translation stack as Hybrid Polie.
    if (json == null) {
      this.modeError.value = null;
      final tr = await TranslationService().translate(
        text: trimmed,
        sourceLang: polieBackendKeyForDisplayOrGroq(
          this.translationSourceLang.value,
        ),
        targetLang: polieBackendKeyForDisplayOrGroq(
          this.translationTargetLang.value,
        ),
        includePhraseBreakdown: false,
      );
      var primary = tr.translation.trim();
      // If Hybrid Polie fallback is used, it may not apply tone (Google/NLLB/MyMemory).
      // Apply a short tone-rewrite pass so the tone chips have real effect.
      if (primary.isNotEmpty && this.translationTone.value != 'formal') {
        final rewrite = await askForJson('''
Return STRICT JSON only.
{"rewritten":"string"}

You are rewriting a translation to match a requested tone WITHOUT changing meaning.
Target language: ${this.translationTargetLang.value}
Requested tone: ${this.translationTone.value}
Rules:
- Preserve the original meaning exactly.
- Keep it in ${this.translationTargetLang.value}. Do not switch languages.
- Keep it natural and idiomatic for native speakers.
- For "literal", keep it as close to word-for-word as possible while still grammatical.
- For "poetic", allow tasteful figurative language but do not add new facts.

Original translation:
"$primary"
''');
        final rewritten = (rewrite?['rewritten'] ?? '').toString().trim();
        if (rewritten.isNotEmpty) {
          primary = rewritten;
        }
      }
      if (primary.isNotEmpty) {
        json = <String, dynamic>{
          'primary': primary,
          'alternatives': <dynamic>[],
          'cultural_note': null,
          'tone_achieved': this.translationTone.value,
        };
        this.modeResponse.value = jsonEncode(json);
      }
    }
    if (json != null) {
      final parsed = TranslationPayload.fromJson(
        json,
        rawFallback: this.modeResponse.value,
      );
      this.translationOutput.value = normalizeTranslationPayload(
        payload: parsed,
        targetLanguage: this.translationTargetLang.value,
        sourceText: trimmed,
      );
      await this.translationHistoryService.addTranslation(
        polieToHistoryEntry(
          input: trimmed,
          payload: this.translationOutput.value!,
          sourceLanguage: this.translationSourceLang.value,
          targetLanguage: this.translationTargetLang.value,
        ),
      );
      await loadTranslationHistory();
    }
  } catch (e) {
    this.modeError.value =
        'Translation failed: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
  }
}


Future<void> speakText(String text, {String? languageName}) async {
  final normalized = text.trim();
  if (normalized.isEmpty || normalized == '-') return;
  final lang = (languageName ?? targetLanguage).trim();
  final ok = await this.ref.read(ttsProvider.notifier).speak(
        normalized,
        languageName: lang,
      );
  if (!ok && this.context.mounted) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not play audio. Check your connection or try again.',
        ),
      ),
    );
  }
}


Future<void> openTranslationHistorySheet() async {
  this.translationTrayOpen.value = true;
  await loadTranslationHistory();
  if (!this.context.mounted) return;
  await showModalBottomSheet<void>(
    context: this.context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final localSearch = TextEditingController(
        text: this.translationHistoryQuery.value,
      );
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final query = localSearch.text.trim().toLowerCase();
          final filtered = this.translationHistory.value
              .where((entry) {
                if (entry is! TranslationEntry) return false;
                if (query.isEmpty) return true;
                return entry.sourceText.toLowerCase().contains(query) ||
                    entry.primaryTranslation.toLowerCase().contains(query);
              })
              .cast<TranslationEntry>()
              .toList();
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Translation History',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: localSearch,
                    onChanged: (v) {
                      this.translationHistoryQuery.value = v;
                      (sheetContext as Element).markNeedsBuild();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search source or translation',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matching history entries.',
                            style: GoogleFonts.nunito(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return ListTile(
                              title: Text(
                                entry.sourceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                entry.primaryTranslation,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.north_west_rounded,
                                size: 18,
                              ),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                this.translationInput.text = entry.sourceText;
                                await runTranslation(entry.sourceText);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  this.translationTrayOpen.value = false;
}


}
