// Historical Personality Selection Screen
// Browse and select historical African personalities to chat with
// 
// Production-ready implementation (December 2025)

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import '../../services/ai/historical_personality_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../services/monitoring/sentry_service.dart';
import '../../utils/debouncer.dart';
import '../../widgets/performance/lazy_image.dart';
import '../../widgets/performance/optimized_list_view.dart';
import 'personality_chat_screen.dart';

class EnrichedPersonality {
  final HistoricalPersonality backend;
  final HistoricalPersona? registry;

  const EnrichedPersonality({required this.backend, this.registry});
}

List<EnrichedPersonality> _mergeWithRegistry(List<HistoricalPersonality> fromBackend) {
  return fromBackend.map((p) {
    HistoricalPersona? reg = HistoricalPersonaRegistry.findById(p.id);
    if (reg == null) {
      final nameLower = p.name.trim().toLowerCase();
      final match = HistoricalPersonaRegistry.all
          .where((x) => x.displayName.trim().toLowerCase() == nameLower)
          .toList();
      reg = match.isNotEmpty ? match.first : null;
    }
    return EnrichedPersonality(backend: p, registry: reg);
  }).toList();
}

const List<Color> _roleChipColors = [
  PanAfricanColors.primary,
  PanAfricanColors.secondary,
  PanAfricanColors.tertiary,
  PanAfricanColors.kenteBlue,
  PanAfricanColors.ankaraPurple,
];

class PersonalitySelectionScreen extends HookConsumerWidget {
  const PersonalitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalityService = ref.read(historicalPersonalityServiceProvider);
    final personalities = useState<List<HistoricalPersonality>>([]);
    final isLoading = useState(true);
    final searchQuery = useState('');
    final selectedCountry = useState<String?>(null);
    final selectedLanguage = useState<String?>(null);
    final searchDebouncer = useMemoized(() => Debouncer(delay: Duration(milliseconds: 500)));

    useEffect(() {
      _loadPersonalities(context, personalityService, personalities, isLoading);
      return null;
    }, []);

    final enriched = useMemoized(
        () => _mergeWithRegistry(personalities.value),
        [personalities.value]);

    final filteredPersonalities = useMemoized(() {
      var filtered = enriched;

      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((e) {
          final p = e.backend;
          return p.name.toLowerCase().contains(query) ||
              p.biography.toLowerCase().contains(query) ||
              p.achievements.any((a) => a.toLowerCase().contains(query));
        }).toList();
      }

      if (selectedCountry.value != null) {
        filtered = filtered.where((e) => e.backend.country == selectedCountry.value).toList();
      }

      if (selectedLanguage.value != null) {
        filtered = filtered.where((e) => e.backend.language == selectedLanguage.value).toList();
      }

      return filtered;
    }, [enriched, searchQuery.value, selectedCountry.value, selectedLanguage.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Talk with History'),
        elevation: 0,
      ),
      body: isLoading.value
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filters
                Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search personalities...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                        ),
                        onChanged: (value) {
                          searchQuery.value = value;
                          searchDebouncer.run(() {
                            // Search is handled by filteredPersonalities
                          });
                        },
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCountry.value,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(value: null, child: Text('All Countries')),
                                ...personalities.value
                                    .map((p) => p.country)
                                    .toSet()
                                    .map((country) => DropdownMenuItem<String>(
                                          value: country,
                                          child: Text(country),
                                        )),
                              ],
                              onChanged: (value) {
                                selectedCountry.value = value;
                              },
                            ),
                          ),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedLanguage.value,
                              decoration: InputDecoration(
                                labelText: 'Language',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(value: null, child: Text('All Languages')),
                                ...personalities.value
                                    .map((p) => p.language)
                                    .toSet()
                                    .map((lang) => DropdownMenuItem<String>(
                                          value: lang,
                                          child: Text(lang),
                                        )),
                              ],
                              onChanged: (value) {
                                selectedLanguage.value = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Personalities List
                Expanded(
                  child: filteredPersonalities.isEmpty
                      ? Center(
                          child: Text(
                            'No personalities found',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        )
                      : OptimizedListView(
                          itemCount: filteredPersonalities.length,
                          itemExtent: 120.0,
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          itemBuilder: (context, index) {
                            final enriched = filteredPersonalities[index];
                            return _PersonalityCard(
                              enriched: enriched,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PersonalityChatScreen(
                                      personality: enriched.backend,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _loadPersonalities(
    BuildContext context,
    HistoricalPersonalityService service,
    ValueNotifier<List<HistoricalPersonality>> personalities,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      isLoading.value = true;
      final result = await service.getPersonalities();
      personalities.value = result;
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e);
      }
      SentryService().captureException(
        e,
        context: {
          'screen': 'PersonalitySelectionScreen',
          'action': 'loadPersonalities',
        },
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class _PersonalityCard extends StatelessWidget {
  final EnrichedPersonality enriched;
  final VoidCallback onTap;

  const _PersonalityCard({
    required this.enriched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = enriched.backend;
    final reg = enriched.registry;
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: p.imageUrl != null
                    ? LazyImage(
                        imageUrl: p.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidgetWidget: Icon(Icons.person, size: 30),
                      )
                    : Icon(Icons.person, size: 30),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14),
                        SizedBox(width: 4),
                        Text(
                          p.country,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Icon(Icons.language, size: 14),
                        SizedBox(width: 4),
                        Text(
                          p.language,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ),
                    if (reg != null) ...[
                      SizedBox(height: PanAfricanSpacing.xs),
                      Wrap(
                        spacing: PanAfricanSpacing.xs,
                        runSpacing: PanAfricanSpacing.xxs,
                        children: [
                          ..._roleChipColors.asMap().entries.where((e) => e.key < reg.historicalRoles.length).take(3).map((e) {
                            final role = reg.historicalRoles[e.key];
                            final color = e.value;
                            return Chip(
                              label: Text(
                                role,
                                style: PanAfricanTypography.labelSmall(context).copyWith(color: color),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.xs,
                                vertical: 2,
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: color.withOpacity(0.18),
                            );
                          }),
                          Text(
                            'Era: ${reg.startYear}–${reg.endYear}',
                            style: PanAfricanTypography.labelSmall(context).copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (reg.primaryLanguages.isNotEmpty) ...[
                            SizedBox(width: PanAfricanSpacing.xs),
                            Text(
                              reg.primaryLanguages.take(2).join(', '),
                              style: PanAfricanTypography.labelSmall(context).copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (reg.scenarios.isNotEmpty) ...[
                            SizedBox(width: PanAfricanSpacing.xs),
                            Text(
                              '${reg.scenarios.length} scenarios',
                              style: PanAfricanTypography.labelSmall(context).copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      p.biography.length > 100
                          ? '${p.biography.substring(0, 100)}...'
                          : p.biography,
                      style: PanAfricanTypography.bodySmall(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

