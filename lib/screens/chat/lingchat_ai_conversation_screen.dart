import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show PolieMode;
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:lingafriq/utils/games_prefetch_language.dart';

/// Polie the learner opens from the tab, the menu, and AI chat.
///
/// Mode chips stay on the screen. Chat is one of those chips.
class LearnerPolieScreen extends ConsumerWidget {
  const LearnerPolieScreen({
    super.key,
    this.initialMode = PolieMode.tutor,
  });

  final PolieMode initialMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: resolveLearnerTargetLanguage(ref),
      builder: (context, snapshot) {
        final lang = (snapshot.data ?? 'Yoruba').trim();
        return PolieWorkspaceScreen(
          sourceLanguage: 'English',
          targetLanguage: lang.isEmpty ? 'Yoruba' : lang,
          initialMode: initialMode,
        );
      },
    );
  }
}

/// Dedicated, private AI conversation surface for the Ling Chat product area.
///
/// This reuses the existing Polie conversation workspace but removes the Polie
/// mode rail so it reads as "chat", not "tools".
class LingChatAiConversationScreen extends ConsumerWidget {
  const LingChatAiConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: resolveLearnerTargetLanguage(ref),
      builder: (context, snapshot) {
        final lang = (snapshot.data ?? 'Yoruba').trim();
        return PolieWorkspaceScreen(
          sourceLanguage: 'English',
          targetLanguage: lang.isEmpty ? 'Yoruba' : lang,
          initialMode: PolieMode.conversation,
          conversationOnly: true,
        );
      },
    );
  }
}

Future<String> resolveLearnerTargetLanguage(WidgetRef ref) async {
  final user = ref.read(userProvider);
  final userLang = (user?.learningLanguage ?? '').trim();
  if (userLang.isNotEmpty) return userLang;

  final prefs = await SharedPreferences.getInstance();
  final slug = resolveGamesHubLanguageSync(prefs, fallback: 'yoruba');
  return displayTitleForGamesHubSlug(slug);
}
