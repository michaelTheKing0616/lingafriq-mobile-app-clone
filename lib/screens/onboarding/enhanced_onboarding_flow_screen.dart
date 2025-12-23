import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'placement_test_screen.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Enhanced 9-Step Onboarding Flow with Beautiful Material 3 + Pan-African Design
class EnhancedOnboardingFlowScreen extends HookConsumerWidget {
  const EnhancedOnboardingFlowScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentStep = useState(0);
    final onboardingData = useState<Map<String, dynamic>>({});

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      _Step1ProficiencyLanguage(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step2LearningLanguage(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step3AgeCategory(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step4LearningReasons(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step5PrimaryGoal(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step6LearningStyle(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step7PacePreference(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step8AppTone(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step9SchedulePreferences(
        onNext: (data) {
          onboardingData.value = {...onboardingData.value, ...data};
          _goToNext(pageController, currentStep);
        },
      ),
      _Step10ProfileSetup(
        onboardingData: onboardingData.value,
        onComplete: () async {
          await _completeOnboarding(onboardingData.value);
          Navigator.pushReplacement(
            context,
            SmoothPageRoute(child: const TabsView()),
          );
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(context, currentStep.value, steps.length, isDark),
              
              // Step Content
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    currentStep.value = index;
                    HapticFeedback.lightImpact();
                  },
                  itemCount: steps.length,
                  itemBuilder: (context, index) => steps[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    int currentStep,
    int totalSteps,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: PanAfricanTypography.labelMedium(context)
                    .copyWith(color: Colors.white),
              ),
              Text(
                '${((currentStep + 1) / totalSteps * 100).toInt()}%',
                style: PanAfricanTypography.labelMedium(context)
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4.h,
          ),
        ],
      ),
    );
  }

  void _goToNext(PageController controller, ValueNotifier<int> currentStep) {
    currentStep.value++;
    controller.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding(Map<String, dynamic> data) async {
    try {
      await ApiService.post(
        '/onboarding/complete',
        data: data,
      );
    } catch (e) {
      // Handle error
    }
  }
}

// Step 1: Proficiency Language
class _Step1ProficiencyLanguage extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step1ProficiencyLanguage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {'code': 'english', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'french', 'name': 'French', 'flag': '🇫🇷'},
      {'code': 'portuguese', 'name': 'Portuguese', 'flag': '🇵🇹'},
      {'code': 'spanish', 'name': 'Spanish', 'flag': '🇪🇸'},
      {'code': 'arabic', 'name': 'Arabic', 'flag': '🇸🇦'},
    ];

    Future<void> saveAndNext() async {
      if (selectedLanguage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a language')),
        );
        return;
      }

      try {
        await ApiService.post(
          '/onboarding/proficiency-language',
          data: {'proficiency_language': selectedLanguage.value},
        );

        onNext({'proficiency_language': selectedLanguage.value});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }

    return _OnboardingStepTemplate(
      title: 'What language do you speak?',
      description: 'We\'ll translate all in-app content to this language',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: PanAfricanSpacing.md,
                mainAxisSpacing: PanAfricanSpacing.md,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguage.value == lang['code'];

                return GestureDetector(
                  onTap: () {
                    selectedLanguage.value = lang['code'];
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PanAfricanColors.primary
                          : (isDark
                              ? PanAfricanColors.cardDark
                              : PanAfricanColors.cardLight),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? PanAfricanColors.secondary
                            : PanAfricanColors.borderLight,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang['flag'] ?? '🌍', style: TextStyle(fontSize: 48.sp)),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          lang['name'] ?? '',
                          style: PanAfricanTypography.titleMedium(context).copyWith(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Learning Language (triggers placement test)
class _Step2LearningLanguage extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step2LearningLanguage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {'code': 'yoruba', 'name': 'Yoruba', 'flag': '🇳🇬'},
      {'code': 'hausa', 'name': 'Hausa', 'flag': '🇳🇬'},
      {'code': 'igbo', 'name': 'Igbo', 'flag': '🇳🇬'},
      {'code': 'pidgin', 'name': 'Nigerian Pidgin English', 'flag': '🇳🇬'},
      {'code': 'swahili', 'name': 'Swahili', 'flag': '🇰🇪'},
      {'code': 'zulu', 'name': 'Zulu', 'flag': '🇿🇦'},
      {'code': 'xhosa', 'name': 'Xhosa', 'flag': '🇿🇦'},
    ];

    Future<void> saveAndNext() async {
      if (selectedLanguage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a language')),
        );
        return;
      }

      try {
        await ApiService.post(
          '/onboarding/learning-language',
          data: {'learning_language': selectedLanguage.value},
        );

        onNext({'learning_language': selectedLanguage.value});

        // Navigate to placement test
        Navigator.push(
          context,
          SmoothPageRoute(
            child: PlacementTestScreen(
              language: selectedLanguage.value!,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }

    return _OnboardingStepTemplate(
      title: 'What language do you wish to learn first?',
      description: 'This will trigger your placement test',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: PanAfricanSpacing.md,
                mainAxisSpacing: PanAfricanSpacing.md,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguage.value == lang['code'];

                return GestureDetector(
                  onTap: () {
                    selectedLanguage.value = lang['code'];
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? PanAfricanGradients.sunset
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? PanAfricanColors.cardDark
                              : PanAfricanColors.cardLight),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? PanAfricanColors.secondary
                            : PanAfricanColors.borderLight,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang['flag'] ?? '🌍', style: TextStyle(fontSize: 48.sp)),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          lang['name'] ?? '',
                          style: PanAfricanTypography.titleMedium(context).copyWith(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified step templates for remaining steps
class _Step3AgeCategory extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;

  const _Step3AgeCategory({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = ['child', 'teen', 'adult', 'senior'];

    return _OnboardingStepTemplate(
      title: 'What\'s your age category?',
      description: 'This helps us personalize your experience',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        options,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          try {
            await ApiService.post(
              '/onboarding/age-category',
              data: {'age_category': selected.value},
            );
            onNext({'age_category': selected.value});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

// Similar simplified templates for steps 4-9
class _Step4LearningReasons extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step4LearningReasons({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<Set<String>>({});
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = ['heritage', 'travel', 'school', 'business', 'curiosity', 'family', 'culture'];

    return _OnboardingStepTemplate(
      title: 'Why are you learning?',
      description: 'Select all that apply',
      isDark: isDark,
      child: _buildMultiSelect(
        context,
        reasons,
        selected.value,
        (value) {
          final newSet = Set<String>.from(selected.value);
          if (newSet.contains(value)) {
            newSet.remove(value);
          } else {
            newSet.add(value);
          }
          selected.value = newSet;
        },
        isDark,
        () async {
          if (selected.value.isEmpty) return;
          try {
            await ApiService.post(
              '/onboarding/learning-reasons',
              data: {'learning_reasons': selected.value.toList()},
            );
            onNext({'learning_reasons': selected.value.toList()});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildMultiSelect(
    BuildContext context,
    List<String> options,
    Set<String> selected,
    Function(String) onToggle,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected.contains(option);

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primaryContainer
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: CheckboxListTile(
                  title: Text(option.toUpperCase()),
                  value: isSelected,
                  onChanged: (_) {
                    onToggle(option);
                    HapticFeedback.lightImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected.isNotEmpty ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

// Steps 5-9 follow similar pattern - creating simplified versions
class _Step5PrimaryGoal extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step5PrimaryGoal({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = ['travel', 'heritage', 'business', 'academic', 'confidence', 'brain_training', 'culture'];

    return _OnboardingStepTemplate(
      title: 'What\'s your primary goal?',
      description: 'Choose your main learning objective',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        goals,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          try {
            await ApiService.post(
              '/onboarding/primary-goal',
              data: {'primary_goal': selected.value},
            );
            onNext({'primary_goal': selected.value});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.replaceAll('_', ' ').toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step6LearningStyle extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step6LearningStyle({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styles = ['audio', 'visual', 'stories', 'drills', 'conversation', 'mixed'];

    return _OnboardingStepTemplate(
      title: 'How do you learn best?',
      description: 'Select your preferred learning style',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        styles,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          try {
            await ApiService.post(
              '/onboarding/learning-style',
              data: {'learning_style': selected.value},
            );
            onNext({'learning_style': selected.value});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step7PacePreference extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step7PacePreference({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paces = ['slow', 'steady', 'fast', 'surprise'];

    return _OnboardingStepTemplate(
      title: 'What pace do you prefer?',
      description: 'How fast do you want to learn?',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        paces,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          try {
            await ApiService.post(
              '/onboarding/pace-preference',
              data: {'pace_preference': selected.value},
            );
            onNext({'pace_preference': selected.value});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step8AppTone extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step8AppTone({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tones = ['playful', 'encouraging', 'serious', 'friendly'];

    return _OnboardingStepTemplate(
      title: 'What tone do you prefer?',
      description: 'How should Polie communicate with you?',
      isDark: isDark,
      child: _buildOptionSelector(
        context,
        tones,
        selected.value,
        (value) => selected.value = value,
        isDark,
        () async {
          if (selected.value == null) return;
          try {
            await ApiService.post(
              '/onboarding/app-tone',
              data: {'app_tone': selected.value},
            );
            onNext({'app_tone': selected.value});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionSelector(
    BuildContext context,
    List<String> options,
    String? selected,
    Function(String) onSelect,
    bool isDark,
    VoidCallback onContinue,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selected == option;

              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                color: isSelected
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                child: ListTile(
                  title: Text(
                    option.toUpperCase(),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.white)
                      : null,
                  onTap: () {
                    onSelect(option);
                    HapticFeedback.mediumImpact();
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: ElevatedButton(
            onPressed: selected != null ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _Step9SchedulePreferences extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onNext;
  const _Step9SchedulePreferences({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = useState(15);
    final timeOfDay = useState<String?>(null);
    final remindersEnabled = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final times = ['sunrise', 'midday', 'sunset', 'night'];

    return _OnboardingStepTemplate(
      title: 'Set your learning schedule',
      description: 'When and how long do you want to learn?',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Duration (minutes)',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Slider(
                    value: duration.value.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${duration.value} minutes',
                    onChanged: (value) => duration.value = value.toInt(),
                  ),
                  Text(
                    '${duration.value} minutes per day',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),
                  Text(
                    'Preferred Time of Day',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  ...times.map((time) {
                    final isSelected = timeOfDay.value == time;
                    return Card(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      color: isSelected
                          ? PanAfricanColors.primary
                          : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                      child: ListTile(
                        title: Text(
                          time.toUpperCase(),
                          style: PanAfricanTypography.titleMedium(context).copyWith(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.white)
                            : null,
                        onTap: () {
                          timeOfDay.value = time;
                          HapticFeedback.mediumImpact();
                        },
                      ),
                    );
                  }),
                  SizedBox(height: PanAfricanSpacing.md),
                  SwitchListTile(
                    title: Text('Enable Reminders'),
                    value: remindersEnabled.value,
                    onChanged: (value) => remindersEnabled.value = value,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: timeOfDay.value != null
                  ? () async {
                      try {
                        await ApiService.post(
                          '/onboarding/schedule-preferences',
                          data: {
                            'daily_duration_minutes': duration.value,
                            'preferred_time_of_day': timeOfDay.value,
                            'reminders_enabled': remindersEnabled.value,
                          },
                        );
                        onNext({
                          'daily_duration_minutes': duration.value,
                          'preferred_time_of_day': timeOfDay.value,
                          'reminders_enabled': remindersEnabled.value,
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: ${e.toString()}')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step10ProfileSetup extends HookConsumerWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;

  const _Step10ProfileSetup({
    required this.onboardingData,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _OnboardingStepTemplate(
      title: 'Complete Your Profile',
      description: 'Set your username and avatar',
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                children: [
                  // Avatar Selection
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: PanAfricanColors.primary,
                    child: Icon(Icons.person, size: 60.sp, color: Colors.white),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  TextButton(
                    onPressed: () {
                      // Avatar picker
                    },
                    child: Text('Change Avatar'),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Username Input
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                    ),
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: ElevatedButton(
              onPressed: usernameController.text.isEmpty
                  ? null
                  : () async {
                      try {
                        await ApiService.post(
                          '/onboarding/profile-setup',
                          data: {'username': usernameController.text},
                        );
                        onComplete();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: ${e.toString()}')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text('Complete Onboarding'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepTemplate extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  final bool isDark;

  const _OnboardingStepTemplate({
    required this.title,
    required this.description,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.headlineMedium(context),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  description,
                  style: PanAfricanTypography.bodyMedium(context),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

