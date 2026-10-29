import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_runtime.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_mode_surface.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_screen_widget.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/widgets/ai/ai_disclosure.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget polieWorkspaceBuildHostScaffold(
  PolieWorkspaceHostRuntime host,
  ModeTheme modeTheme,
) {
  return Scaffold(
    backgroundColor: modeTheme.background,
    appBar: AppBar(
      backgroundColor: modeTheme.background,
      elevation: 0,
      bottom: const AiDisclosureBar(),
      leading: BackButton(
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(host.context).maybePop();
        },
      ),
      title: Text(
        host.screen.conversationOnly ? 'Ling Chat' : 'Polie',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          color: modeTheme.title,
          fontSize: host.isCompactTopBar ? 24 : 28,
        ),
      ),
      actions: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: host.isBusy.value
              ? null
              : () async {
                  final selected = await showModalBottomSheet<String>(
                    context: host.context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (sheetCtx) {
                      final options = kPolieTranslateLanguageOptions
                          .where((o) => o.displayName != 'Auto Detect')
                          .toList()
                        ..sort((a, b) =>
                            a.displayName.compareTo(b.displayName));
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  12,
                                ),
                                child: Text(
                                  'Choose conversation language',
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              for (final o in options)
                                ListTile(
                                  dense: true,
                                  leading: Text(
                                    o.flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  title: Text(o.displayName),
                                  trailing: o.displayName == host.targetLanguage
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFFD4822A),
                                        )
                                      : null,
                                  onTap: () => Navigator.of(sheetCtx)
                                      .pop(o.displayName),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null && selected != host.targetLanguage) {
                    host.activeTargetLanguage.value = selected;
                    try {
                      await host.chat.setModeAndLanguage(
                        mode: host.activeMode.value,
                        targetLanguage: selected,
                      );
                    } catch (e) {
                      debugPrint(
                        '[Polie] setModeAndLanguage failed: $e',
                      );
                    }
                  }
                },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(
              horizontal: host.isCompactTopBar ? 8 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: modeTheme.border),
              color: modeTheme.card,
            ),
            child: Row(
              children: [
                if (!host.isCompactTopBar)
                  Text(
                    (polieOptionForDisplayName(host.targetLanguage)?.flag ??
                        '🌍'),
                  ),
                if (!host.isCompactTopBar) const SizedBox(width: 6),
                Text(host.targetLanguage),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
        if (!host.isCompactTopBar)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        if (!host.isCompactTopBar)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline_rounded),
          ),
        if (host.isCompactTopBar)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'profile', child: Text('Profile')),
            ],
          ),
        const SizedBox(width: 4),
      ],
    ),
    body: Column(
      children: [
        if (!host.screen.conversationOnly)
          Padding(
            padding: EdgeInsets.fromLTRB(
              host.isCompactTopBar ? 8 : 12,
              0,
              host.isCompactTopBar ? 8 : 12,
              8,
            ),
            child: PolieModeSwitcherRail<PolieMode>(
              selected: host.activeMode.value,
              items: PolieWorkspaceScreen.modeItems
                  .map(
                    (e) => PolieModeSwitcherItem<PolieMode>(
                      value: e.mode,
                      icon: e.icon,
                      label: e.label,
                    ),
                  )
                  .toList(),
              onChanged: (PolieMode mode) async {
                await host.setMode(mode);
                if (mode == PolieMode.tutor && host.tutorLesson.value == null) {
                  await host.loadTutorLesson();
                }
              if (mode == PolieMode.vocab && host.vocabCard.value == null) {
                await host.loadVocabCard();
              }
              if (mode == PolieMode.review && host.reviewPayload.value == null) {
                await host.loadReview();
              }
              },
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation);
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.992,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
              );
            },
            child: polieWorkspaceModeSurface(
              key: ValueKey(host.activeMode.value),
              context: host.context,
              mode: host.activeMode.value,
              theme: modeTheme,
              isBusy: host.isBusy.value,
              modeError: host.modeError.value,
              // translation
              translationInput: host.translationInput,
              translationOutput: host.translationOutput.value,
              translationTone: host.translationTone,
              autoTranslate: host.autoTranslate,
              translationTrayOpen: host.translationTrayOpen,
              translationHistoryQuery: host.translationHistoryQuery,
              translationHistory: host.translationHistory.value,
              onRunTranslation: host.runTranslation,
              onSearchHistory: () async => host.loadTranslationHistory(),
              onOpenTranslationHistory: host.openTranslationHistorySheet,
              translationSourceLang: host.translationSourceLang,
              translationTargetLang: host.translationTargetLang,
              onTranslationLanguagesChanged: host.syncTranslationLanguagesToChat,
              // tutor
              tutorLesson: host.tutorLesson.value,
              tutorFeedback: host.tutorFeedback.value,
              tutorDifficulty: host.tutorDifficulty,
              tutorFlipped: host.tutorFlipped,
              tutorInput: host.tutorInput,
              onLoadTutorLesson: host.loadTutorLesson,
              onCheckTutorAnswer: host.checkTutorAnswer,
              onSaveTutorCard: host.saveCurrentTutorCard,
              onOpenTutorSavedCards: host.openTutorSavedCards,
              tutorIsCurrentSaved: host.tutorIsCurrentSaved,
              // roleplay
              roleplayDifficulty: host.roleplayDifficulty,
              roleplayScene: host.roleplayScene,
              roleplayMessages: host.roleplayMessages.value,
              roleplayInput: host.roleplayInput,
              onSendRoleplay: host.sendRoleplayTurn,
              // conversation
              conversationMessages: host.conversationMessages.value,
              conversationInput: host.conversationInput,
              conversationIncludeEnglishTranslations:
                  host.conversationIncludeEnglishTranslations,
              conversationResponseStyle: host.conversationResponseStyle,
              languageRatio: host.languageRatio.value,
              onSendConversation: host.sendConversation,
              onSpeakText: host.speakText,
              conversationStreamingActive:
                  host.conversationStreamingActive.value,
              conversationStreamingTarget:
                  host.conversationStreamingTarget.value,
              conversationVoiceListening: host.voiceListening.value,
              onToggleConversationVoiceInput:
                  host.toggleConversationVoiceInput,
              // vocab
              vocabCard: host.vocabCard.value,
              vocabReveal: host.vocabReveal,
              vocabSetName: host.vocabSetName,
              vocabDifficultyTarget: host.vocabDifficultyTarget,
              vocabDeckCount: host.vocabDeckCount.value,
              vocabSrsChoice: host.vocabSrsChoice.value,
              onLoadVocabCard: host.loadVocabCard,
              onScoreSrs: host.scoreSrs,
              // review
              reviewPayload: host.reviewPayload.value,
              reviewPeriod: host.reviewPeriod,
              onLoadReview: host.loadReview,
              introDismissed: host.modeIntroDismissed.value,
              onDismissIntro: (modeName) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                  'polie_mode_intro_${modeName}_dismissed',
                  true,
                );
                host.modeIntroDismissed.value = {
                  ...host.modeIntroDismissed.value,
                  modeName,
                };
              },
              tutorStreakBannerText: host.buildStreakBannerText(),
            ),
          ),
        ),
      ],
    ),
  );
}
