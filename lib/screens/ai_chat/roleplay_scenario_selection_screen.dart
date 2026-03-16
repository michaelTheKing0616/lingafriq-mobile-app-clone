import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Roleplay Scenario Selection Screen - Polie Dark Theme
/// World-class scenario selection with categories, difficulty levels, and previews
class RoleplayScenarioSelectionScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const RoleplayScenarioSelectionScreen({
    super.key,
    required this.language,
    required this.languageName,
  });

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

    final filteredScenarios = useMemoized(() {
      var list = List<CuratedScenario>.from(curatedScenarios);
      if (selectedCategory.value != null) {
        list = list.where((s) => s.categoryId == selectedCategory.value).toList();
      }
      if (searchQuery.value.isNotEmpty) {
        final q = searchQuery.value.toLowerCase();
        list = list.where((s) {
          return s.title.toLowerCase().contains(q) ||
              s.shortDescription.toLowerCase().contains(q) ||
              s.categoryId.toLowerCase().contains(q);
        }).toList();
      }
      return list;
    }, [selectedCategory.value, searchQuery.value]);

    Future<void> startScenario(CuratedScenario curated) async {
      HapticFeedback.mediumImpact();
      final initialScene = _sceneForCurated(curated);
      if (context.mounted) {
        Navigator.push(
          context,
          SmoothPageRoute(
            child: PolieWorkspaceScreen(
              sourceLanguage: 'English',
              targetLanguage: languageName,
              initialMode: PolieMode.roleplay,
              initialRoleplayScene: initialScene,
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
                child: filteredScenarios.isEmpty
                    ? _buildEmptyState(context)
                    : _buildScenariosList(context, filteredScenarios, startScenario),
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
          Semantics(
            label: 'Back',
            button: true,
            child: _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
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
        child: Semantics(
          label: 'Search scenarios',
          textField: true,
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
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildCategoryChips(
    BuildContext context,
    ValueNotifier<String?> selectedCategory,
  ) {
    return SizedBox(
      height: 44.h,
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
            'Try a different category or search term',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _sceneForCurated(CuratedScenario curated) {
    switch (curated.categoryId) {
      case 'shopping':
        return 'Market';
      case 'food':
        return 'Restaurant';
      case 'social':
      case 'greetings':
      case 'family':
        return 'Family Dinner';
      case 'business':
        return 'Job Interview';
      case 'health':
      case 'emergency':
      case 'travel':
      default:
        return 'Meeting Elder';
    }
  }

  Widget _buildScenariosList(
    BuildContext context,
    List<CuratedScenario> scenarios,
    Future<void> Function(CuratedScenario) onTap,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        final category = categories.firstWhere(
          (c) => c.id == scenario.categoryId,
          orElse: () => categories.first,
        );
        return _ScenarioCard(
          curated: scenario,
          category: category,
          onTap: () => onTap(scenario),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
    );
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

class CuratedScenario {
  final String id;
  final String title;
  final String difficulty;
  final String shortDescription;
  final String categoryId;
  final String estimatedTime;
  final IconData icon;

  const CuratedScenario({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.shortDescription,
    required this.categoryId,
    required this.estimatedTime,
    required this.icon,
  });
}

const List<CuratedScenario> curatedScenarios = [
  CuratedScenario(
    id: 'market',
    title: 'At the Market',
    difficulty: 'A1',
    shortDescription: 'Buy fruits and vegetables from a friendly vendor.',
    categoryId: 'shopping',
    estimatedTime: '~5 min',
    icon: Icons.shopping_basket_rounded,
  ),
  CuratedScenario(
    id: 'restaurant',
    title: 'At a Restaurant',
    difficulty: 'A1',
    shortDescription: 'Order food and drinks at a local restaurant.',
    categoryId: 'food',
    estimatedTime: '~5 min',
    icon: Icons.restaurant_rounded,
  ),
  CuratedScenario(
    id: 'directions',
    title: 'Asking for Directions',
    difficulty: 'A1',
    shortDescription: 'Find your way around town with help from locals.',
    categoryId: 'travel',
    estimatedTime: '~5 min',
    icon: Icons.directions_rounded,
  ),
  CuratedScenario(
    id: 'meeting',
    title: 'Meeting New People',
    difficulty: 'A1',
    shortDescription: 'Introduce yourself at a social gathering.',
    categoryId: 'social',
    estimatedTime: '~5 min',
    icon: Icons.people_rounded,
  ),
  CuratedScenario(
    id: 'airport',
    title: 'At the Airport',
    difficulty: 'A2',
    shortDescription: 'Check in and navigate the terminal confidently.',
    categoryId: 'travel',
    estimatedTime: '~7 min',
    icon: Icons.flight_rounded,
  ),
  CuratedScenario(
    id: 'phone',
    title: 'Phone Call',
    difficulty: 'A2',
    shortDescription: 'Make a phone call to schedule an appointment.',
    categoryId: 'business',
    estimatedTime: '~5 min',
    icon: Icons.phone_rounded,
  ),
  CuratedScenario(
    id: 'job_interview',
    title: 'Job Interview',
    difficulty: 'B1',
    shortDescription: 'Interview for a position at a local company.',
    categoryId: 'business',
    estimatedTime: '~10 min',
    icon: Icons.work_rounded,
  ),
  CuratedScenario(
    id: 'doctor',
    title: "Doctor's Visit",
    difficulty: 'A2',
    shortDescription: 'Describe symptoms and understand medical advice.',
    categoryId: 'health',
    estimatedTime: '~7 min',
    icon: Icons.local_hospital_rounded,
  ),
  CuratedScenario(
    id: 'haggling',
    title: 'Haggling / Negotiation',
    difficulty: 'B1',
    shortDescription: 'Negotiate prices with a savvy market trader.',
    categoryId: 'shopping',
    estimatedTime: '~7 min',
    icon: Icons.handshake_rounded,
  ),
  CuratedScenario(
    id: 'family',
    title: 'Family Gathering',
    difficulty: 'A2',
    shortDescription: 'Participate in warm family conversations.',
    categoryId: 'social',
    estimatedTime: '~7 min',
    icon: Icons.family_restroom_rounded,
  ),
  CuratedScenario(
    id: 'festival',
    title: 'Cultural Festival',
    difficulty: 'B1',
    shortDescription: 'Discuss traditions and join in the celebration.',
    categoryId: 'social',
    estimatedTime: '~10 min',
    icon: Icons.celebration_rounded,
  ),
  CuratedScenario(
    id: 'emergency',
    title: 'Emergency Situation',
    difficulty: 'B2',
    shortDescription: 'Handle an urgent situation with clarity.',
    categoryId: 'emergency',
    estimatedTime: '~7 min',
    icon: Icons.emergency_rounded,
  ),
];

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
    return Semantics(
      label: 'Category: $label',
      button: true,
      selected: isSelected,
      child: GestureDetector(
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
              semanticLabel: label,
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
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final CuratedScenario curated;
  final ScenarioCategory category;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.curated,
    required this.category,
    required this.onTap,
  });

  static Color _difficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'A1':
        return PolieColors.success;
      case 'A2':
        return PolieColors.electricTeal;
      case 'B1':
        return PolieColors.goldEmber;
      case 'B2':
        return PolieColors.error;
      default:
        return PolieColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(curated.difficulty);

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PolieRadius.lg),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Semantics(
          label: 'Scenario: ${curated.title}. ${curated.shortDescription}. Tap to start.',
          button: true,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(PolieSpacing.sm),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(PolieRadius.md),
                          ),
                          child: Icon(
                            curated.icon,
                            color: category.color,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: PolieSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                curated.title,
                                style: PolieTypography.h2(context).copyWith(
                                  color: PolieColors.textPrimary,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: PolieSpacing.xs),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PolieSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: diffColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(PolieRadius.sm),
                                    ),
                                    child: Text(
                                      curated.difficulty,
                                      style: PolieTypography.label(context).copyWith(
                                        color: diffColor,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: PolieSpacing.sm),
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14.sp,
                                    color: PolieColors.textSecondary,
                                  ),
                                  SizedBox(width: PolieSpacing.xs),
                                  Text(
                                    curated.estimatedTime,
                                    style: PolieTypography.bodySmall(context).copyWith(
                                      color: PolieColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
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
                            semanticLabel: 'Start scenario',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PolieSpacing.md),
                    Text(
                      curated.shortDescription,
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
