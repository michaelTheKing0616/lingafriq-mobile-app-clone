import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/content/persona_mission_service.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/screens/persona_missions/persona_mission_setup_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Hub for blueprint §42 persona narrative missions.
class PersonaMissionsHubScreen extends ConsumerWidget {
  const PersonaMissionsHubScreen({super.key, this.initialLanguage});

  /// When opened from Curriculum, use the selected study language.
  final String? initialLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final rawLang = initialLanguage ?? user?.learningLanguage ?? 'yoruba';
    final lang = CurriculumService.normalizeLanguageKey(rawLang);
    final missionsAsync = ref.watch(personaMissionsForLanguageProvider(lang));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona Missions'),
        backgroundColor: PanAfricanColors.primary,
        foregroundColor: Colors.white,
      ),
      body: missionsAsync.when(
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No missions for your language yet. Try Yoruba, Hausa, Swahili, or Pidgin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = missions[index];
              return Card(
                elevation: 0,
                color: PanAfricanColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: PanAfricanColors.primary.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  title: Text(
                    m.personaTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${m.historicalSetting}\n${m.steps.length} steps · ${m.culturalFocus.join(', ')}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PersonaMissionSetupScreen(mission: m),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load missions: $e')),
      ),
    );
  }
}
