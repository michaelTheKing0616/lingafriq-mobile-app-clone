import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/screens/chat/private_chat_list_screen.dart';
import 'package:lingafriq/screens/home_screen.dart';

/// P1-022 — DM inbox entry: restricted bands see explainer, adults see WA inbox.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(agePolicyProvider);
    return policy.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AgeRestrictedSurfaceScreen(showBack: true),
      data: (state) {
        if (state.socialSurfacesBlocked) {
          return AgeRestrictedSurfaceScreen(
            showBack: true,
            serverMessage: state.serverMessage,
          );
        }
        return const PrivateChatListScreen();
      },
    );
  }
}
