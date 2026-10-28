import 'package:flutter/material.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_layout.dart';

class PolieModeSurfaceArgs {
  final Key key;
  final BuildContext context;
  final PolieMode mode;
  final ModeTheme theme;
  final bool isBusy;
  final String? modeError;
  final TextEditingController translationInput;
  final TranslationPayload? translationOutput;
  final ValueNotifier<String> translationTone;
  final ValueNotifier<bool> autoTranslate;
  final ValueNotifier<bool> translationTrayOpen;
  final ValueNotifier<String> translationHistoryQuery;
  final List<dynamic> translationHistory;
  final Future<void> Function(String) onRunTranslation;
  final Future<void> Function() onSearchHistory;
  final Future<void> Function() onOpenTranslationHistory;
  final ValueNotifier<String> translationSourceLang;
  final ValueNotifier<String> translationTargetLang;
  final Future<void> Function() onTranslationLanguagesChanged;
  final TutorLessonPayload? tutorLesson;
  final TutorFeedbackPayload? tutorFeedback;
  final ValueNotifier<String> tutorDifficulty;
  final ValueNotifier<bool> tutorFlipped;
  final TextEditingController tutorInput;
  final Future<void> Function() onLoadTutorLesson;
  final Future<void> Function() onCheckTutorAnswer;
  final Future<void> Function() onSaveTutorCard;
  final Future<void> Function() onOpenTutorSavedCards;
  final ValueNotifier<bool> tutorIsCurrentSaved;
  final ValueNotifier<String> roleplayDifficulty;
  final ValueNotifier<String> roleplayScene;
  final List<RoleplayTurn> roleplayMessages;
  final TextEditingController roleplayInput;
  final Future<void> Function() onSendRoleplay;
  final List<ConversationTurn> conversationMessages;
  final TextEditingController conversationInput;
  final ValueNotifier<bool> conversationIncludeEnglishTranslations;
  final ValueNotifier<String> conversationResponseStyle;
  final double languageRatio;
  final Future<void> Function([String?]) onSendConversation;
  final Future<void> Function(String text, {String? languageName}) onSpeakText;
  final bool conversationStreamingActive;
  final String conversationStreamingTarget;
  final bool conversationVoiceListening;
  final Future<void> Function() onToggleConversationVoiceInput;
  final VocabPayload? vocabCard;
  final ValueNotifier<bool> vocabReveal;
  final ValueNotifier<String> vocabSetName;
  final ValueNotifier<String> vocabDifficultyTarget;
  final int vocabDeckCount;
  final String? vocabSrsChoice;
  final Future<void> Function() onLoadVocabCard;
  final Future<void> Function(String) onScoreSrs;
  final ReviewPayload? reviewPayload;
  final ValueNotifier<String> reviewPeriod;
  final Future<void> Function() onLoadReview;
  final Set<String> introDismissed;
  final void Function(String modeName) onDismissIntro;
  final String tutorStreakBannerText;
  const PolieModeSurfaceArgs({
    required this.key,
    required this.context,
    required this.mode,
    required this.theme,
    required this.isBusy,
    required this.modeError,
    required this.translationInput,
    required this.translationOutput,
    required this.translationTone,
    required this.autoTranslate,
    required this.translationTrayOpen,
    required this.translationHistoryQuery,
    required this.translationHistory,
    required this.onRunTranslation,
    required this.onSearchHistory,
    required this.onOpenTranslationHistory,
    required this.translationSourceLang,
    required this.translationTargetLang,
    required this.onTranslationLanguagesChanged,
    required this.tutorLesson,
    required this.tutorFeedback,
    required this.tutorDifficulty,
    required this.tutorFlipped,
    required this.tutorInput,
    required this.onLoadTutorLesson,
    required this.onCheckTutorAnswer,
    required this.onSaveTutorCard,
    required this.onOpenTutorSavedCards,
    required this.tutorIsCurrentSaved,
    required this.roleplayDifficulty,
    required this.roleplayScene,
    required this.roleplayMessages,
    required this.roleplayInput,
    required this.onSendRoleplay,
    required this.conversationMessages,
    required this.conversationInput,
    required this.conversationIncludeEnglishTranslations,
    required this.conversationResponseStyle,
    required this.languageRatio,
    required this.onSendConversation,
    required this.onSpeakText,
    required this.conversationStreamingActive,
    required this.conversationStreamingTarget,
    required this.conversationVoiceListening,
    required this.onToggleConversationVoiceInput,
    required this.vocabCard,
    required this.vocabReveal,
    required this.vocabSetName,
    required this.vocabDifficultyTarget,
    required this.vocabDeckCount,
    required this.vocabSrsChoice,
    required this.onLoadVocabCard,
    required this.onScoreSrs,
    required this.reviewPayload,
    required this.reviewPeriod,
    required this.onLoadReview,
    required this.introDismissed,
    required this.onDismissIntro,
    required this.tutorStreakBannerText,
  });
  PolieModeSurfaceLayout layout() => PolieModeSurfaceLayout(context, theme, mode);
}
