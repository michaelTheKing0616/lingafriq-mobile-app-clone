import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/data/roleplay_dataset.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen_with_tracking.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Roleplay Scenario Selection Screen - Polie Dark Theme
/// World-class scenario selection with categories, difficulty levels, and previews
class RoleplayScenarioSelectionScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const RoleplayScenarioSelectionScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  static const List<ScenarioCategory> categories = [
    ScenarioCategory(
      id: 'greetings',
      name: 'Greetings',
      icon: Icons.waving_hand_rounded,
      color: PolieColors.electricTeal,
      description: 'Learn how to greet people respectfully',
    ),
    ScenarioCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: PolieColors.goldEmber,
      description: 'Practice buying and negotiating',
    ),
    ScenarioCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: PolieColors.error,
      description: 'Order food and dine like a local',
    ),
    ScenarioCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight_rounded,
      color: PolieColors.electricTealLight,
      description: 'Navigate airports, hotels, and transportation',
    ),
    ScenarioCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital_rounded,
      color: PolieColors.royalAmethyst,
      description: 'Visit doctors and pharmacies',
    ),
    ScenarioCategory(
      id: 'social',
      name: 'Social',
      icon: Icons.people_rounded,
      color: PolieColors.success,
      description: 'Make friends and socialize',
    ),
    ScenarioCategory(
      id: 'business',
      name: 'Business',
      icon: Icons.business_rounded,
      color: PolieColors.textSecondary,
      description: 'Professional conversations',
    ),
    ScenarioCategory(
      id: 'emergency',
      name: 'Emergency',
      icon: Icons.emergency_rounded,
      color: PolieColors.errorMuted,
      description: 'Handle emergency situations',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(null);
    final searchQuery = useState('');

    final scenarios = useMemoized(() {
      var allScenarios = RoleplayDataset.getByLanguage(languageName);
      
      if (allScenarios.isEmpty) {
        allScenarios = RoleplayDataset.getByLanguage(language);
      }
      
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
      
      final chat = ref.read(groqChatProvider.notifier);
      // Atomic mode+language switch to avoid history key mismatch
      await chat.setModeAndLanguage(
        mode: PolieMode.roleplay,
        targetLanguage: languageName,
      );
      await chat.setRoleplayScenario(scenario);
      
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(context, searchQuery),
              _buildCategoryChips(context, selectedCategory),
              Expanded(
                child: scenarios.isEmpty
                    ? _buildEmptyState(context)
                    : _buildScenariosList(context, scenarios, startScenario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roleplay Scenarios',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  languageName,
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildSearchBar(BuildContext context, ValueNotifier<String> searchQuery) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PolieSpacing.md,
        vertical: PolieSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: TextField(
          onChanged: (value) => searchQuery.value = value,
          style: PolieTypography.body(context).copyWith(
            color: PolieColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search scenarios...',
            hintStyle: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: PolieColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: PolieSpacing.lg,
              vertical: PolieSpacing.sm,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildCategoryChips(
    BuildContext context,
    ValueNotifier<String?> selectedCategory,
  ) {
    return SizedBox(
      height: 80.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
        children: [
          _CategoryChip(
            label: 'All',
            icon: Icons.apps_rounded,
            isSelected: selectedCategory.value == null,
            onTap: () {
              HapticFeedback.lightImpact();
              selectedCategory.value = null;
            },
            color: PolieColors.royalAmethyst,
          ),
          SizedBox(width: PolieSpacing.sm),
          ...categories.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: PolieSpacing.sm),
              child: _CategoryChip(
                label: category.name,
                icon: category.icon,
                isSelected: selectedCategory.value == category.id,
                onTap: () {
                  HapticFeedback.lightImpact();
                  selectedCategory.value = category.id;
                },
                color: category.color,
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(PolieSpacing.xl),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PolieColors.surfaceContainerLight,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48.sp,
              color: PolieColors.textSecondary,
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'No scenarios found',
            style: PolieTypography.h2(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            'Try selecting a different category',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScenariosList(
    BuildContext context,
    List<RoleplayEntry> scenarios,
    Future<void> Function(RoleplayEntry) onTap,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        return _ScenarioCard(
          scenario: scenario,
          language: languageName,
          onTap: () => onTap(scenario),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
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
  final Color color;
  final String description;

  const ScenarioCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PolieSpacing.md,
          vertical: PolieSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? color : PolieColors.textSecondary,
            ),
            SizedBox(width: PolieSpacing.xs),
            Text(
              label,
              style: PolieTypography.label(context).copyWith(
                color: isSelected ? color : PolieColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final RoleplayEntry scenario;
  final String language;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = _getCategory(scenario.scenario);
    final categoryColor = _getCategoryColor(category);

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PolieRadius.lg),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: categoryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PolieRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(PolieSpacing.sm),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(PolieRadius.md),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: categoryColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: PolieSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scenario.scenario,
                              style: PolieTypography.h2(context).copyWith(
                                color: PolieColors.textPrimary,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: PolieSpacing.xs),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: PolieSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(PolieRadius.sm),
                              ),
                              child: Text(
                                category,
                                style: PolieTypography.bodySmall(context).copyWith(
                                  color: categoryColor,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(PolieSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [PolieColors.royalAmethyst, PolieColors.electricTeal],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.md),
                  Container(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    decoration: BoxDecoration(
                      color: PolieColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14.sp,
                              color: PolieColors.goldEmber,
                            ),
                            SizedBox(width: PolieSpacing.xs),
                            Text(
                              'You:',
                              style: PolieTypography.label(context).copyWith(
                                color: PolieColors.goldEmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PolieSpacing.xs),
                        Text(
                          scenario.userUtterance,
                          style: PolieTypography.body(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (scenario.notes.isNotEmpty) ...[
                    SizedBox(height: PolieSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14.sp,
                          color: PolieColors.textSecondary,
                        ),
                        SizedBox(width: PolieSpacing.xs),
                        Expanded(
                          child: Text(
                            scenario.notes,
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: PolieColors.textSecondary,
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
        return PolieColors.electricTeal;
      case 'Shopping':
        return PolieColors.goldEmber;
      case 'Food':
        return PolieColors.error;
      case 'Travel':
        return PolieColors.electricTealLight;
      case 'Health':
        return PolieColors.royalAmethyst;
      case 'Social':
        return PolieColors.success;
      case 'Business':
        return PolieColors.textSecondary;
      case 'Emergency':
        return PolieColors.errorMuted;
      default:
        return PolieColors.royalAmethyst;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Greetings':
        return Icons.waving_hand_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Health':
        return Icons.local_hospital_rounded;
      case 'Social':
        return Icons.people_rounded;
      case 'Business':
        return Icons.business_rounded;
      case 'Emergency':
        return Icons.emergency_rounded;
      default:
        return Icons.chat_bubble_rounded;
    }
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: PolieColors.surfaceContainerLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: PolieColors.textPrimary,
          size: 22.sp,
        ),
      ),
    );
  }
}
