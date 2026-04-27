// AI Chat Navigation Helper
// Utility functions for navigating to AI chat screens and dashboards
import 'package:flutter/material.dart';
import '../screens/ai_chat/roleplay_scenario_selection_screen.dart';
import '../screens/ai_chat/roleplay_completion_summary_screen.dart';
import '../screens/ai_chat/roleplay_progress_dashboard_screen.dart';
import '../screens/ai_chat/enhanced_translation_screen.dart';
import '../screens/ai_chat/tutor_progress_dashboard_screen.dart';
import '../screens/ai_chat/conversation_analytics_screen.dart';
import '../screens/ai_chat/vocabulary_dashboard_screen.dart';
import '../screens/ai_chat/review_dashboard_screen.dart';
import '../models/roleplay_progress_model.dart';
import '../widgets/animations/smooth_transitions.dart';

/// Navigate to roleplay scenario selection
void navigateToRoleplayScenarioSelection(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: RoleplayScenarioSelectionScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}

/// Navigate to roleplay completion summary
void navigateToRoleplayCompletionSummary(
  BuildContext context, {
  required RoleplaySessionResult result,
  required String language,
  required String languageName,
  VoidCallback? onContinue,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: RoleplayCompletionSummaryScreen(
        result: result,
        language: language,
        languageName: languageName,
        onContinue: onContinue,
      ),
    ),
  );
}

/// Navigate to roleplay progress dashboard
void navigateToRoleplayProgressDashboard(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: RoleplayProgressDashboardScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}

/// Navigate to enhanced translation screen
void navigateToEnhancedTranslation(
  BuildContext context, {
  required String sourceLanguage,
  required String targetLanguage,
  String? initialText,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: EnhancedTranslationScreen(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        initialText: initialText,
      ),
    ),
  );
}

/// Navigate to tutor progress dashboard
void navigateToTutorProgressDashboard(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: TutorProgressDashboardScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}

/// Navigate to conversation analytics screen
void navigateToConversationAnalytics(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: ConversationAnalyticsScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}

/// Navigate to vocabulary dashboard
void navigateToVocabularyDashboard(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: VocabularyDashboardScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}

/// Navigate to review dashboard
void navigateToReviewDashboard(
  BuildContext context, {
  required String language,
  required String languageName,
}) {
  Navigator.push(
    context,
    SmoothPageRoute.platform(
      child: ReviewDashboardScreen(
        language: language,
        languageName: languageName,
      ),
    ),
  );
}
