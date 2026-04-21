import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';

/// Village "places" (Griot Stage, Market, etc.) implemented as focused Polie modes.
///
/// This avoids routing users back to the Polie mode selection screen and ensures
/// each village node has a distinct learning experience.
class LanguageVillagePlaceScreen extends ConsumerWidget {
  const LanguageVillagePlaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const <String, dynamic>{};

    final placeName = (map['placeName'] ?? '').toString().trim();
    final languageDisplayName =
        (map['languageDisplayName'] ?? 'Yoruba').toString().trim();

    final resolved = _resolvePlace(placeName);
    return PolieWorkspaceScreen(
      sourceLanguage: 'English',
      targetLanguage: languageDisplayName.isEmpty ? 'Yoruba' : languageDisplayName,
      initialMode: resolved.mode,
      initialRoleplayScene: resolved.scene,
    );
  }

  _VillagePlaceConfig _resolvePlace(String placeName) {
    switch (placeName) {
      case 'Griot Stage':
        return const _VillagePlaceConfig(
          mode: PolieMode.roleplay,
          scene: 'Griot Stage',
        );
      case 'The Market':
        return const _VillagePlaceConfig(
          mode: PolieMode.roleplay,
          scene: 'Market',
        );
      case 'Sun Café':
        return const _VillagePlaceConfig(
          mode: PolieMode.conversation,
          scene: null,
        );
      case "Elder's Hut":
        return const _VillagePlaceConfig(
          mode: PolieMode.roleplay,
          scene: 'Meeting Elder',
        );
      case 'The School':
        return const _VillagePlaceConfig(
          mode: PolieMode.tutor,
          scene: null,
        );
      default:
        return const _VillagePlaceConfig(
          mode: PolieMode.conversation,
          scene: null,
        );
    }
  }
}

class _VillagePlaceConfig {
  final PolieMode mode;
  final String? scene;
  const _VillagePlaceConfig({required this.mode, required this.scene});
}

