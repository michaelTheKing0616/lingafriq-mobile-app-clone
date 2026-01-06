import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/data/roleplay_dataset.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen_with_tracking.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Roleplay Scenario Selection Screen
/// World-class scenario selection with categories, difficulty levels, and previews
class RoleplayScenarioSelectionScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const RoleplayScenarioSelectionScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  // Scenario categories
  static const List<ScenarioCategory> categories = [
    ScenarioCategory(
      id: 'greetings',
      name: 'Greetings',
      icon: Icons.waving_hand,
      color: 0xFF1B7340,
      description: 'Learn how to greet people respectfully',
    ),
    ScenarioCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: 0xFFEB8937,
      description: 'Practice buying and negotiating',
    ),
    ScenarioCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: 0xFFC4413A,
      description: 'Order food and dine like a local',
    ),
    ScenarioCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight,
      color: 0xFF1CB0F6,
      description: 'Navigate airports, hotels, and transportation',
    ),
    ScenarioCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital,
      color: 0xFF9B59B6,
      description: 'Visit doctors and pharmacies',
    ),
    ScenarioCategory(
      id: 'social',
      name: 'Social',
      icon: Icons.people,
      color: 0xFF16A085,
      description: 'Make friends and socialize',
    ),
    ScenarioCategory(
      id: 'business',
      name: 'Business',
      icon: Icons.business,
      color: 0xFF34495E,
      description: 'Professional conversations',
    ),
    ScenarioCategory(
      id: 'emergency',
      name: 'Emergency',
      icon: Icons.emergency,
      color: 0xFFE74C3C,
      description: 'Handle emergency situations',
    ),
  ];

  // Difficulty levels
  static const List<DifficultyLevel> difficultyLevels = [
    DifficultyLevel(id: 'A1', name: 'Beginner', color: 0xFF2ECC71),
    DifficultyLevel(id: 'A2', name: 'Elementary', color: 0xFF3498DB),
    DifficultyLevel(id: 'B1', name: 'Intermediate', color: 0xFFF39C12),
    DifficultyLevel(id: 'B2', name: 'Upper Intermediate', color: 0xFFE67E22),
    DifficultyLevel(id: 'C1', name: 'Advanced', color: 0xFFE74C3C),
    DifficultyLevel(id: 'C2', name: 'Proficient', color: 0xFF8E44AD),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(null);
    final selectedDifficulty = useState<String?>(null);
    final searchQuery = useState('');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get scenarios for selected category and language
    final scenarios = useMemoized(() {
      // Try to get scenarios by language name (e.g., "Yoruba")
      var allScenarios = RoleplayDataset.getByLanguage(languageName);
      
      // If no scenarios found, try language code (e.g., "yo")
      if (allScenarios.isEmpty) {
        allScenarios = RoleplayDataset.getByLanguage(language);
      }
      
      // If still empty, get all scenarios
      if (allScenarios.isEmpty) {
        allScenarios = RoleplayDataset.getAll();
      }
      
      if (selectedCategory.value != null) {
        allScenarios = allScenarios.where((s) {
          return s.scenario.toLowerCase().contains(selectedCategory.value!.toLowerCase()) ||
                 _getCategoryForScenario(s.scenario) == selectedCategory.value;
        }).toList();
      }
      
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        allScenarios = allScenarios.where((s) {
          return s.scenario.toLowerCase().contains(query) ||
                 s.userUtterance.toLowerCase().contains(query) ||
                 s.notes.toLowerCase().contains(query);
        }).toList();
      }
      
      return allScenarios;
    }, [selectedCategory.value, searchQuery.value, languageName, language]);

    Future<void> startScenario(RoleplayEntry scenario) async {
      HapticFeedback.mediumImpact();
      
      // Set roleplay mode and language
      final chat = ref.read(groqChatProvider.notifier);
      await chat.setMode(PolieMode.roleplay);
      await chat.setLanguage(languageName);
      
      // Store scenario context for the roleplay session
      // This will be used by the enhanced roleplay system prompt
      await chat.setRoleplayScenario(scenario);
      
      // Navigate to chat with scenario context
      if (context.mounted) {
        Navigator.push(
          context,
          SmoothPageRoute(
            child: AIChatScreenWithTracking(
                language: language,
                languageName: languageName,
                mode: 'roleplay',
                modeName: 'Roleplay',
                initialScenario: scenario,
              ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roleplay Scenarios'),
            Text(
              languageName,
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search scenarios...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  onChanged: (value) => searchQuery.value = value,
                ),
              ),

              // Category Chips
              SizedBox(
                height: 100.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
                  children: [
                    // All Categories
                    _CategoryChip(
                      label: 'All',
                      icon: Icons.apps,
                      isSelected: selectedCategory.value == null,
                      onTap: () => selectedCategory.value = null,
                      color: PanAfricanColors.primary,
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    // Category Chips
                    ...categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
                        child: _CategoryChip(
                          label: category.name,
                          icon: category.icon,
                          isSelected: selectedCategory.value == category.id,
                          onTap: () => selectedCategory.value = category.id,
                          color: Color(category.color),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              SizedBox(height: PanAfricanSpacing.md),

              // Scenarios List
              Expanded(
                child: scenarios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64.sp,
                              color: PanAfricanColors.neutralMedium,
                            ),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'No scenarios found',
                              style: PanAfricanTypography.bodyLarge(context),
                            ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              'Try selecting a different category or language',
                              style: PanAfricanTypography.bodySmall(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(PanAfricanSpacing.lg),
                        itemCount: scenarios.length,
                        itemBuilder: (context, index) {
                          final scenario = scenarios[index];
                          return _ScenarioCard(
                            scenario: scenario,
                            language: languageName,
                            isDark: isDark,
                            onTap: () => startScenario(scenario),
                          )
                              .animate(delay: (index * 50).ms)
                              .fadeIn(duration: 200.ms)
                              .slideX(begin: 0.1);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getCategoryForScenario(String scenario) {
    final lower = scenario.toLowerCase();
    if (lower.contains('greet') || lower.contains('meet')) return 'greetings';
    if (lower.contains('shop') || lower.contains('buy') || lower.contains('market')) return 'shopping';
    if (lower.contains('food') || lower.contains('restaurant') || lower.contains('order') || lower.contains('eat')) return 'food';
    if (lower.contains('travel') || lower.contains('airport') || lower.contains('hotel') || lower.contains('taxi')) return 'travel';
    if (lower.contains('doctor') || lower.contains('hospital') || lower.contains('medicine') || lower.contains('sick')) return 'health';
    if (lower.contains('friend') || lower.contains('social') || lower.contains('party')) return 'social';
    if (lower.contains('business') || lower.contains('work') || lower.contains('office')) return 'business';
    if (lower.contains('emergency') || lower.contains('help') || lower.contains('police')) return 'emergency';
    return null;
  }
}

class ScenarioCategory {
  final String id;
  final String name;
  final IconData icon;
  final int color;
  final String description;

  const ScenarioCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class DifficultyLevel {
  final String id;
  final String name;
  final int color;

  const DifficultyLevel({
    required this.id,
    required this.name,
    required this.color,
  });
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: isSelected ? Colors.white : color),
          SizedBox(width: PanAfricanSpacing.xs),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: PanAfricanTypography.labelMedium(context)?.copyWith(
        color: isSelected ? Colors.white : color,
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final RoleplayEntry scenario;
  final String language;
  final bool isDark;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = _getCategory(scenario.scenario);
    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.sm),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: categoryColor,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.scenario,
                          style: PanAfricanTypography.titleMedium(context)?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.xxs),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                              ),
                              child: Text(
                                category,
                                style: PanAfricanTypography.labelSmall(context)?.copyWith(
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_filled,
                    color: PanAfricanColors.primary,
                    size: 32.sp,
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.md),
              // Preview
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.surfaceContainerDark
                      : PanAfricanColors.surfaceContainerLight,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16.sp, color: PanAfricanColors.primary),
                        SizedBox(width: PanAfricanSpacing.xs),
                        Text(
                          'You:',
                          style: PanAfricanTypography.labelSmall(context)?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      scenario.userUtterance,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
              if (scenario.notes.isNotEmpty) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16.sp, color: PanAfricanColors.neutralMedium),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        scenario.notes,
                        style: PanAfricanTypography.bodySmall(context)?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getCategory(String scenario) {
    final lower = scenario.toLowerCase();
    if (lower.contains('greet') || lower.contains('meet')) return 'Greetings';
    if (lower.contains('shop') || lower.contains('buy') || lower.contains('market')) return 'Shopping';
    if (lower.contains('food') || lower.contains('restaurant') || lower.contains('order')) return 'Food';
    if (lower.contains('travel') || lower.contains('airport') || lower.contains('hotel')) return 'Travel';
    if (lower.contains('doctor') || lower.contains('hospital') || lower.contains('medicine')) return 'Health';
    if (lower.contains('friend') || lower.contains('social')) return 'Social';
    if (lower.contains('business') || lower.contains('work')) return 'Business';
    if (lower.contains('emergency') || lower.contains('help')) return 'Emergency';
    return 'General';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Greetings':
        return Color(0xFF1B7340);
      case 'Shopping':
        return Color(0xFFEB8937);
      case 'Food':
        return Color(0xFFC4413A);
      case 'Travel':
        return Color(0xFF1CB0F6);
      case 'Health':
        return Color(0xFF9B59B6);
      case 'Social':
        return Color(0xFF16A085);
      case 'Business':
        return Color(0xFF34495E);
      case 'Emergency':
        return Color(0xFFE74C3C);
      default:
        return PanAfricanColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Greetings':
        return Icons.waving_hand;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.flight;
      case 'Health':
        return Icons.local_hospital;
      case 'Social':
        return Icons.people;
      case 'Business':
        return Icons.business;
      case 'Emergency':
        return Icons.emergency;
      default:
        return Icons.chat_bubble;
    }
  }
}

