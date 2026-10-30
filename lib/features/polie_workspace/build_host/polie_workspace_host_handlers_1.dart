import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/services/polie_tutor_saved_cards_service.dart';

import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';

import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_state.dart';

mixin PolieWorkspaceHostHandlers1 on PolieWorkspaceHostState {
  Future<void> refreshTutorSavedCards() async {
    final saved = await PolieTutorSavedCardsService.loadSavedCards();
    tutorSavedCards.value = saved
        .where(
          (c) =>
              c.targetLanguage.trim().toLowerCase() ==
                  targetLanguage.trim().toLowerCase() &&
              c.difficulty.trim().toLowerCase() ==
                  tutorDifficulty.value.trim().toLowerCase(),
        )
        .toList();

    final currentConceptKey =
        tutorLesson.value?.concept.trim().toLowerCase() ?? '';
    tutorIsCurrentSaved.value =
        currentConceptKey.isNotEmpty &&
        tutorSavedCards.value.any((c) => c.conceptKey == currentConceptKey);
  }

  Future<void> loadTutorSeenConcepts() async {
    final seen = await PolieTutorSavedCardsService.loadSeenConceptKeys(
      targetLanguage: targetLanguage,
      difficulty: tutorDifficulty.value,
    );
    tutorSeenConcepts.value = seen
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  String buildStreakBannerText() {
    final days = streakDays.value;
    if (days > 0) {
      return '🔥 $days day${days == 1 ? '' : 's'} streak!';
    }
    return LingAfriqUxVoice.dailyPractice.first;
  }

  Future<void> syncTranslationLanguagesToChat() async {
    if (activeMode.value != PolieMode.translation) return;
    await chat.setModeAndLanguage(
      mode: PolieMode.translation,
      sourceLanguage: translationSourceLang.value,
      targetLanguage: translationTargetLang.value,
    );
  }

  Future<void> setMode(PolieMode mode) async {
    activeMode.value = mode;
    modeError.value = null;
    modeResponse.value = '';
    final src = mode == PolieMode.translation
        ? translationSourceLang.value
        : screen.sourceLanguage;
    final tgt = mode == PolieMode.translation
        ? translationTargetLang.value
        : targetLanguage;
    await chat.setModeAndLanguage(
      mode: mode,
      sourceLanguage: src,
      targetLanguage: tgt,
    );
  }

  Future<Map<String, dynamic>?> askForJson(String prompt) async {
    try {
      final tgt = activeMode.value == PolieMode.translation
          ? translationTargetLang.value
          : targetLanguage;
      final src = activeMode.value == PolieMode.translation
          ? translationSourceLang.value
          : screen.sourceLanguage;
      final raw = await gateway
          .completePolieJson(
            polieModeName: activeMode.value.name,
            userMessage: prompt,
            language: tgt,
            languageCode: SupportedLanguages.getLanguageCode(tgt),
            sourceLanguage: SupportedLanguages.getLanguageCode(src),
            targetLanguage: SupportedLanguages.getLanguageCode(tgt),
          )
          .timeout(const Duration(seconds: 25));
      modeResponse.value = raw;
      final parsed = tryParseJson(raw);
      if (parsed == null) {
        modeError.value =
            'Polie returned an unreadable response. Please try again.';
        return null;
      }
      return parsed;
    } on AiGatewayException catch (e) {
      modeError.value = AiGatewayClient.userMessageFor(e, body: e.body);
      return null;
    } catch (e) {
      modeError.value = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<void> loadTranslationHistory() async {
    final history = await translationHistoryService.loadHistory();
    final query = translationHistoryQuery.value.trim().toLowerCase();
    final filtered = history.entries
        .where((entry) {
          if (query.isEmpty) return true;
          return entry.sourceText.toLowerCase().contains(query) ||
              entry.primaryTranslation.toLowerCase().contains(query);
        })
        .take(20)
        .toList();
    translationHistory.value = filtered;
  }

  Future<void> runTranslation(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    isBusy.value = true;
    modeError.value = null;
    try {
      Map<String, dynamic>? json = await askForJson('''
Return STRICT JSON only.
{
  "primary":"string",
  "alternatives":[{"text":"string","note":"string"}],
  "cultural_note":"string|null",
  "tone_achieved":"formal|casual|literal|poetic"
}

Translate from ${translationSourceLang.value} to ${translationTargetLang.value}.
Tone requested: ${translationTone.value}
Text: "$trimmed"
''');
      // If backend/LLM returns non-JSON prose, use the same translation stack as Hybrid Polie.
      if (json == null) {
        modeError.value = null;
        final tr = await TranslationService().translate(
          text: trimmed,
          sourceLang: polieBackendKeyForDisplayOrGroq(
            translationSourceLang.value,
          ),
          targetLang: polieBackendKeyForDisplayOrGroq(
            translationTargetLang.value,
          ),
          includePhraseBreakdown: false,
        );
        var primary = tr.translation.trim();
        // If Hybrid Polie fallback is used, it may not apply tone (Google/NLLB/MyMemory).
        // Apply a short tone-rewrite pass so the tone chips have real effect.
        if (primary.isNotEmpty && translationTone.value != 'formal') {
          final rewrite = await askForJson('''
Return STRICT JSON only.
{"rewritten":"string"}

You are rewriting a translation to match a requested tone WITHOUT changing meaning.
Target language: ${translationTargetLang.value}
Requested tone: ${translationTone.value}
Rules:
- Preserve the original meaning exactly.
- Keep it in ${translationTargetLang.value}. Do not switch languages.
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
            'tone_achieved': translationTone.value,
          };
          modeResponse.value = jsonEncode(json);
        }
      }
      if (json != null) {
        final parsed = TranslationPayload.fromJson(
          json,
          rawFallback: modeResponse.value,
        );
        translationOutput.value = normalizeTranslationPayload(
          payload: parsed,
          targetLanguage: translationTargetLang.value,
          sourceText: trimmed,
        );
        await translationHistoryService.addTranslation(
          polieToHistoryEntry(
            input: trimmed,
            payload: translationOutput.value!,
            sourceLanguage: translationSourceLang.value,
            targetLanguage: translationTargetLang.value,
          ),
        );
        await loadTranslationHistory();
      }
    } catch (e) {
      modeError.value =
          'Translation failed: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> speakText(String text, {String? languageName}) async {
    final normalized = text.trim();
    if (normalized.isEmpty || normalized == '-') return;
    final lang = (languageName ?? targetLanguage).trim();
    final ok = await ref
        .read(ttsProvider.notifier)
        .speak(normalized, languageName: lang);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not play audio. Check your connection or try again.',
          ),
        ),
      );
    }
  }

  Future<void> openTranslationHistorySheet() async {
    translationTrayOpen.value = true;
    await loadTranslationHistory();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final localSearch = TextEditingController(
          text: translationHistoryQuery.value,
        );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final query = localSearch.text.trim().toLowerCase();
            final filtered = translationHistory.value
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
                          style: LingAfriqFonts.roleStyle(
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
                        translationHistoryQuery.value = v;
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
                              style: LingAfriqFonts.roleStyle(
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
                                  translationInput.text = entry.sourceText;
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
    translationTrayOpen.value = false;
  }
}
