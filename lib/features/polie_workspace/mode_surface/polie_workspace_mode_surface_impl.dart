import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_layout.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';

import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_translation.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_tutor.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_roleplay.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_conversation.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_vocab.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_review.dart';

Widget polieWorkspaceModeSurface({
  required Key key,
  required BuildContext context,
  required PolieMode mode,
  required ModeTheme theme,
  required bool isBusy,
  required String? modeError,
  required TextEditingController translationInput,
  required TranslationPayload? translationOutput,
  required ValueNotifier<String> translationTone,
  required ValueNotifier<bool> autoTranslate,
  required ValueNotifier<bool> translationTrayOpen,
  required ValueNotifier<String> translationHistoryQuery,
  required List<dynamic> translationHistory,
  required Future<void> Function(String) onRunTranslation,
  required Future<void> Function() onSearchHistory,
  required Future<void> Function() onOpenTranslationHistory,
  required ValueNotifier<String> translationSourceLang,
  required ValueNotifier<String> translationTargetLang,
  required Future<void> Function() onTranslationLanguagesChanged,
  required TutorLessonPayload? tutorLesson,
  required TutorFeedbackPayload? tutorFeedback,
  required ValueNotifier<String> tutorDifficulty,
  required ValueNotifier<bool> tutorFlipped,
  required TextEditingController tutorInput,
  required Future<void> Function() onLoadTutorLesson,
  required Future<void> Function() onCheckTutorAnswer,
  required Future<void> Function() onSaveTutorCard,
  required Future<void> Function() onOpenTutorSavedCards,
  required ValueNotifier<bool> tutorIsCurrentSaved,
  required ValueNotifier<String> roleplayDifficulty,
  required ValueNotifier<String> roleplayScene,
  required List<RoleplayTurn> roleplayMessages,
  required TextEditingController roleplayInput,
  required Future<void> Function() onSendRoleplay,
  required List<ConversationTurn> conversationMessages,
  required TextEditingController conversationInput,
  required ValueNotifier<bool> conversationIncludeEnglishTranslations,
  required ValueNotifier<String> conversationResponseStyle,
  required double languageRatio,
  required Future<void> Function([String?]) onSendConversation,
  required Future<void> Function(String text, {String? languageName})
      onSpeakText,
  required bool conversationStreamingActive,
  required String conversationStreamingTarget,
  required bool conversationVoiceListening,
  required Future<void> Function() onToggleConversationVoiceInput,
  required VocabPayload? vocabCard,
  required ValueNotifier<bool> vocabReveal,
  required ValueNotifier<String> vocabSetName,
  required ValueNotifier<String> vocabDifficultyTarget,
  required int vocabDeckCount,
  required String? vocabSrsChoice,
  required Future<void> Function() onLoadVocabCard,
  required Future<void> Function(String) onScoreSrs,
  required ReviewPayload? reviewPayload,
  required ValueNotifier<String> reviewPeriod,
  required Future<void> Function() onLoadReview,
  required Set<String> introDismissed,
  required void Function(String modeName) onDismissIntro,
  required String tutorStreakBannerText,
})  {
  final a = PolieModeSurfaceArgs(
    key: key,
    context: context,
    mode: mode,
    theme: theme,
    isBusy: isBusy,
    modeError: modeError,
    translationInput: translationInput,
    translationOutput: translationOutput,
    translationTone: translationTone,
    autoTranslate: autoTranslate,
    translationTrayOpen: translationTrayOpen,
    translationHistoryQuery: translationHistoryQuery,
    translationHistory: translationHistory,
    onRunTranslation: onRunTranslation,
    onSearchHistory: onSearchHistory,
    onOpenTranslationHistory: onOpenTranslationHistory,
    translationSourceLang: translationSourceLang,
    translationTargetLang: translationTargetLang,
    onTranslationLanguagesChanged: onTranslationLanguagesChanged,
    tutorLesson: tutorLesson,
    tutorFeedback: tutorFeedback,
    tutorDifficulty: tutorDifficulty,
    tutorFlipped: tutorFlipped,
    tutorInput: tutorInput,
    onLoadTutorLesson: onLoadTutorLesson,
    onCheckTutorAnswer: onCheckTutorAnswer,
    onSaveTutorCard: onSaveTutorCard,
    onOpenTutorSavedCards: onOpenTutorSavedCards,
    tutorIsCurrentSaved: tutorIsCurrentSaved,
    roleplayDifficulty: roleplayDifficulty,
    roleplayScene: roleplayScene,
    roleplayMessages: roleplayMessages,
    roleplayInput: roleplayInput,
    onSendRoleplay: onSendRoleplay,
    conversationMessages: conversationMessages,
    conversationInput: conversationInput,
    conversationIncludeEnglishTranslations: conversationIncludeEnglishTranslations,
    conversationResponseStyle: conversationResponseStyle,
    languageRatio: languageRatio,
    onSendConversation: onSendConversation,
    onSpeakText: onSpeakText,
    conversationStreamingActive: conversationStreamingActive,
    conversationStreamingTarget: conversationStreamingTarget,
    conversationVoiceListening: conversationVoiceListening,
    onToggleConversationVoiceInput: onToggleConversationVoiceInput,
    vocabCard: vocabCard,
    vocabReveal: vocabReveal,
    vocabSetName: vocabSetName,
    vocabDifficultyTarget: vocabDifficultyTarget,
    vocabDeckCount: vocabDeckCount,
    vocabSrsChoice: vocabSrsChoice,
    onLoadVocabCard: onLoadVocabCard,
    onScoreSrs: onScoreSrs,
    reviewPayload: reviewPayload,
    reviewPeriod: reviewPeriod,
    onLoadReview: onLoadReview,
    introDismissed: introDismissed,
    onDismissIntro: onDismissIntro,
    tutorStreakBannerText: tutorStreakBannerText,
  );
  return switch (mode) {
    PolieMode.translation => buildPolieTranslationModeSurface(a),
    PolieMode.tutor => buildPolieTutorModeSurface(a),
    PolieMode.roleplay => buildPolieRoleplayModeSurface(a),
    PolieMode.conversation => buildPolieConversationModeSurface(a),
    PolieMode.vocab => buildPolieVocabModeSurface(a),
    PolieMode.review => buildPolieReviewModeSurface(a),
    _ => const SizedBox.shrink(),
  };
}
