import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show PolieMode;
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:lingafriq/utils/games_prefetch_language.dart';

/// Dedicated, private AI conversation surface for the Ling Chat product area.
///
/// This reuses the existing Polie conversation workspace but removes the Polie
/// mode rail so it reads as "chat", not "tools".
class LingChatAiConversationScreen extends ConsumerWidget {
  const LingChatAiConversationScreen({super.key});

  Future<String> _resolveTargetLanguageDisplay(WidgetRef ref) async {
    // Prefer the user's current learning language when available.
    // Fallback to the "games hub" persisted language which is widely set in the app.
    final user = ref.read(userProvider);
    final userLang = (user?.learningLanguage ?? '').trim();
    if (userLang.isNotEmpty) return userLang;

    final prefs = await SharedPreferences.getInstance();
    final slug = resolveGamesHubLanguageSync(prefs, fallback: 'yoruba');
    return displayTitleForGamesHubSlug(slug);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _resolveTargetLanguageDisplay(ref),
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

