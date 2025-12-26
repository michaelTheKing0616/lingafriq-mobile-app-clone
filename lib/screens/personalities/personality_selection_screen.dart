/// Historical Personality Selection Screen
/// Browse and select historical African personalities to chat with
/// 
/// Production-ready implementation (December 2025)

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/ai/historical_personality_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../services/monitoring/sentry_service.dart';
import '../../utils/performance_utils.dart';
import 'personality_chat_screen.dart';

class PersonalitySelectionScreen extends HookConsumerWidget {
  const PersonalitySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalityService = ref.read(historicalPersonalityServiceProvider);
    final personalities = useState<List<HistoricalPersonality>>([]);
    final isLoading = useState(true);
    final searchQuery = useState('');
    final selectedCountry = useState<String?>(null);
    final selectedLanguage = useState<String?>(null);
    final searchDebouncer = useMemoized(() => Debouncer(delay: Duration(milliseconds: 500)));

    // Load personalities
    useEffect(() {
      _loadPersonalities(context, personalityService, personalities, isLoading);
      return null;
    }, []);

    // Filter personalities based on search
    final filteredPersonalities = useMemoized(() {
      var filtered = personalities.value;
      
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(query) ||
                 p.biography.toLowerCase().contains(query) ||
                 p.achievements.any((a) => a.toLowerCase().contains(query));
        }).toList();
      }
      
      if (selectedCountry.value != null) {
        filtered = filtered.where((p) => p.country == selectedCountry.value).toList();
      }
      
      if (selectedLanguage.value != null) {
        filtered = filtered.where((p) => p.language == selectedLanguage.value).toList();
      }
      
      return filtered;
    }, [personalities.value, searchQuery.value, selectedCountry.value, selectedLanguage.value]);

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
                                    .map((country) => DropdownMenuItem(
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
                                    .map((lang) => DropdownMenuItem(
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
                            final personality = filteredPersonalities[index];
                            return _PersonalityCard(
                              personality: personality,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PersonalityChatScreen(
                                      personality: personality,
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

/// Personality Card Widget
class _PersonalityCard extends StatelessWidget {
  final HistoricalPersonality personality;
  final VoidCallback onTap;

  const _PersonalityCard({
    required this.personality,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: personality.imageUrl != null
                    ? LazyImage(
                        imageUrl: personality.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.person, size: 30),
                      )
                    : Icon(Icons.person, size: 30),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personality.name,
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
                          personality.country,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Icon(Icons.language, size: 14),
                        SizedBox(width: 4),
                        Text(
                          personality.language,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      personality.biography.length > 100
                          ? '${personality.biography.substring(0, 100)}...'
                          : personality.biography,
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

