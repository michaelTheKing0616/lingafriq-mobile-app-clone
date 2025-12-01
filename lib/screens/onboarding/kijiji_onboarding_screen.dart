import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Comprehensive 10-Step Story-Driven Onboarding
/// "Kijiji cha Lugha" - The Language Village
class KijijiOnboardingScreen extends HookConsumerWidget {
  const KijijiOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    
    useEffect(() {
      animationController.forward();
      return null;
    }, []);
    
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              onPageChanged: (index) {
                currentPage.value = index;
                HapticFeedback.lightImpact();
                animationController.reset();
                animationController.forward();
              },
              itemCount: 11, // 10 steps + completion
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _WelcomeScreen(
                      animationController: animationController,
                      onNext: () => _goToNext(pageController),
                    );
                  case 1:
                    return _ElderScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 2:
                    return _WeaverScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 3:
                    return _RhythmMasterScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 4:
                    return _TimekeeperScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 5:
                    return _PathChooserScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 6:
                    return _GriotScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 7:
                    return _HealerScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 8:
                    return _SocialScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 9:
                    return _NamingScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onNext: () => _goToNext(pageController),
                    );
                  case 10:
                    return _PlacementTestScreen(
                      animationController: animationController,
                      onboardingNotifier: onboardingNotifier,
                      onComplete: () async {
                        await onboardingNotifier.saveOnboardingData();
                        await ref.read(sharedPreferencesProvider).setOnboardingSeen();
                        ref.read(apiProvider.notifier).regiserDevice();
                        ref.read(navigationProvider).naviateOffAll(const TabsView());
                      },
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
            // Progress Indicator
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(10, (index) {
                      final isActive = currentPage.value > index;
                      final isCurrent = currentPage.value == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : (isCurrent ? 16 : 8),
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            // Skip Button (only on first few screens)
            if (currentPage.value < 3)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    pageController.animateToPage(
                      10,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _goToNext(PageController controller) {
    controller.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

// Step 1: Welcome Screen
class _WelcomeScreen extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onNext;
  
  const _WelcomeScreen({
    required this.animationController,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AfricanTheme.africanSavanna,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Baobab tree illustration placeholder
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AfricanTheme.africanSunset,
                        boxShadow: AfricanTheme.africanShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.park_rounded,
                            size: 120,
                            color: Colors.white,
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
                        ],
                      ),
                    )
                        .animate()
                        .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 48),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Welcome to\nKijiji cha Lugha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'The Language Village\nYour journey begins here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: animationController,
                child: ElevatedButton(
                  onPressed: onNext,
                  key: const Key('begin_journey_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AfricanTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                    ),
                  ),
                  child: const Text(
                    'Begin Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: The Elder (Age + Purpose)
class _ElderScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _ElderScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAge = useState<String?>(null);
    final selectedReasons = useState<List<String>>([]);
    
    final reasons = ['heritage', 'travel', 'school', 'business', 'curiosity'];
    
    return Container(
      decoration: BoxDecoration(
        gradient: AfricanTheme.africanSavanna,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Elder illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.face_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(delay: 200.ms, duration: 600.ms)
                  .fadeIn(),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'Welcome, traveler. I am Mzee Kato,\nkeeper of the village memory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'Tell me: who are you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Age selection
              FadeTransition(
                opacity: animationController,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['child', 'teen', 'adult'].map((age) {
                    final isSelected = selectedAge.value == age;
                    return GestureDetector(
                      onTap: () {
                        selectedAge.value = age;
                        onboardingNotifier.updateAgeCategory(age);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          age.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? AfricanTheme.primaryGreen
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'Why are you learning?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Reason chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: reasons.map((reason) {
                  final isSelected = selectedReasons.value.contains(reason);
                  return FadeTransition(
                    opacity: animationController,
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        reason.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? AfricanTheme.primaryGreen
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          selectedReasons.value = [...selectedReasons.value, reason];
                        } else {
                          selectedReasons.value = selectedReasons.value
                              .where((r) => r != reason)
                              .toList();
                        }
                        onboardingNotifier.updateLearningReasons(selectedReasons.value);
                      },
                      backgroundColor: Colors.white.withOpacity(0.2),
                      selectedColor: Colors.white,
                      checkmarkColor: AfricanTheme.primaryGreen,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: animationController,
                child: ElevatedButton(
                  onPressed: selectedAge.value != null && selectedReasons.value.isNotEmpty
                      ? onNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AfricanTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                    ),
                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder screens for remaining steps - will be implemented similarly
class _WeaverScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _WeaverScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final selectedLevel = useState<String?>(null);
    
    final languages = ['Swahili', 'Yoruba', 'Amharic', 'Zulu', 'Hausa', 'Igbo'];
    final levels = ['beginner', 'intermediate', 'advanced'];
    
    return Container(
      decoration: BoxDecoration(
        gradient: AfricanTheme.africanSavanna,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.art_track_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'I am Adisa, the Weaver.\nChoose the threads of your voice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: languages.map((lang) {
                  final isSelected = selectedLanguage.value == lang;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(lang),
                    onSelected: (selected) {
                      selectedLanguage.value = selected ? lang : null;
                      if (selected) {
                        onboardingNotifier.updateLanguage(lang);
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                    checkmarkColor: AfricanTheme.primaryGreen,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  'What\'s your level?',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: levels.map((level) {
                  final isSelected = selectedLevel.value == level;
                  return GestureDetector(
                    onTap: () {
                      selectedLevel.value = level;
                      onboardingNotifier.updateProficiency(level);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                      ),
                      child: Text(
                        level.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? AfricanTheme.primaryGreen
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: animationController,
                child: ElevatedButton(
                  onPressed: selectedLanguage.value != null && selectedLevel.value != null
                      ? onNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AfricanTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for remaining screens - implementing core structure
class _RhythmMasterScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _RhythmMasterScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStyle = useState<String?>(null);
    final styles = ['audio', 'visual', 'stories', 'drills', 'conversation'];
    
    return _buildCharacterScreen(
      context,
      'I am Nuru the Rhythm Master.\nTap the drum that sings to your spirit.',
      Icons.music_note_rounded,
      styles,
      selectedStyle,
      (style) {
        onboardingNotifier.updateLearningStyle(style);
      },
      onNext,
    );
  }
  
  Widget _buildCharacterScreen(
    BuildContext context,
    String dialogue,
    IconData icon,
    List<String> options,
    ValueNotifier<String?> selected,
    Function(String) onSelect,
    VoidCallback onNext,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: AfricanTheme.africanSavanna,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(icon, size: 100, color: Colors.white),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animationController,
                child: Text(
                  dialogue,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: options.map((option) {
                  final isSelected = selected.value == option;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(option.toUpperCase()),
                    onSelected: (sel) {
                      selected.value = sel ? option : null;
                      if (sel) onSelect(option);
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                    checkmarkColor: AfricanTheme.primaryGreen,
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: animationController,
                child: ElevatedButton(
                  onPressed: selected.value != null ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AfricanTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simplified implementations for remaining screens
class _TimekeeperScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _TimekeeperScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = useState(15);
    final timeOfDay = useState<String?>(null);
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.access_time_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                'I am Zawadi, keeper of time.\nWhen shall we train your tongue?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text('${duration.value} minutes per day', style: TextStyle(color: Colors.white, fontSize: 18)),
              Slider(
                value: duration.value.toDouble(),
                min: 5,
                max: 25,
                divisions: 20,
                onChanged: (v) {
                  duration.value = v.toInt();
                  onboardingNotifier.updateSchedule(duration.value, timeOfDay.value ?? 'midday');
                },
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                children: ['sunrise', 'midday', 'sunset', 'night'].map((time) {
                  final isSelected = timeOfDay.value == time;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(time.toUpperCase()),
                    onSelected: (sel) {
                      timeOfDay.value = sel ? time : null;
                      if (sel) onboardingNotifier.updateSchedule(duration.value, time);
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: timeOfDay.value != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathChooserScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _PathChooserScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = useState<String?>(null);
    final goals = [
      {'id': 'travel', 'icon': Icons.flight_rounded, 'title': 'Travel'},
      {'id': 'heritage', 'icon': Icons.favorite_rounded, 'title': 'Heritage'},
      {'id': 'business', 'icon': Icons.business_rounded, 'title': 'Business'},
      {'id': 'academic', 'icon': Icons.school_rounded, 'title': 'Academic'},
      {'id': 'confidence', 'icon': Icons.mic_rounded, 'title': 'Confidence'},
      {'id': 'brain_training', 'icon': Icons.psychology_rounded, 'title': 'Brain Training'},
    ];
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose your path.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final isSelected = selectedGoal.value == goal['id'];
                  return GestureDetector(
                    onTap: () {
                      selectedGoal.value = goal['id'] as String;
                      onboardingNotifier.updateGoals(goal['id'] as String);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            goal['icon'] as IconData,
                            size: 48,
                            color: isSelected ? AfricanTheme.primaryGreen : Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            goal['title'] as String,
                            style: TextStyle(
                              color: isSelected ? AfricanTheme.primaryGreen : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: selectedGoal.value != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GriotScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _GriotScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTone = useState<String?>(null);
    final selectedGamification = useState<String?>(null);
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.campaign_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                'I am Amina the Griot.\nHow shall I speak to you?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text('Tone Preference', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ['playful', 'encouraging', 'serious'].map((tone) {
                  final isSelected = selectedTone.value == tone;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tone.toUpperCase()),
                    onSelected: (sel) {
                      selectedTone.value = sel ? tone : null;
                      if (sel && selectedGamification.value != null) {
                        onboardingNotifier.updatePersonality(tone, selectedGamification.value!);
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text('Gamification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ['high', 'medium', 'minimal'].map((level) {
                  final isSelected = selectedGamification.value == level;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(level.toUpperCase()),
                    onSelected: (sel) {
                      selectedGamification.value = sel ? level : null;
                      if (sel && selectedTone.value != null) {
                        onboardingNotifier.updatePersonality(selectedTone.value!, level);
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: selectedTone.value != null && selectedGamification.value != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealerScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _HealerScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = useState<Map<String, bool>>({
      'largeText': false,
      'highContrast': false,
      'dyslexia': false,
      'soundOff': false,
      'motionReduction': false,
    });
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.healing_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                'I am the Healer.\nLet me make your journey smooth.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              ...['largeText', 'highContrast', 'dyslexia', 'soundOff', 'motionReduction'].map((key) {
                return SwitchListTile(
                  title: Text(key.replaceAll(RegExp(r'([A-Z])'), r' $1').trim().toUpperCase()),
                  value: accessibility.value[key] ?? false,
                  onChanged: (v) {
                    accessibility.value = {...accessibility.value, key: v};
                    onboardingNotifier.updateAccessibility(
                      largeText: accessibility.value['largeText'],
                      highContrast: accessibility.value['highContrast'],
                      dyslexia: accessibility.value['dyslexia'],
                      soundOff: accessibility.value['soundOff'],
                      motionReduction: accessibility.value['motionReduction'],
                    );
                  },
                  activeColor: Colors.white,
                );
              }).toList(),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _SocialScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPreference = useState<String?>(null);
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.people_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                'Build your clan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                children: ['solo', 'buddies', 'community', 'teacher_guided'].map((pref) {
                  final isSelected = selectedPreference.value == pref;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(pref.replaceAll('_', ' ').toUpperCase()),
                    onSelected: (sel) {
                      selectedPreference.value = sel ? pref : null;
                      if (sel) onboardingNotifier.updateSocial(pref);
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: selectedPreference.value != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamingScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onNext;
  
  const _NamingScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onNext,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.celebration_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                'A learner without a name is a drum without a rhythm!\nTell us what you wish to be called.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter your username',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                onChanged: (value) {
                  onboardingNotifier.updateProfile(value);
                },
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: usernameController.text.isNotEmpty ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacementTestScreen extends HookConsumerWidget {
  final AnimationController animationController;
  final OnboardingNotifier onboardingNotifier;
  final VoidCallback onComplete;
  
  const _PlacementTestScreen({
    required this.animationController,
    required this.onboardingNotifier,
    required this.onComplete,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(gradient: AfricanTheme.africanSavanna),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_rounded, size: 120, color: Colors.white),
                    const SizedBox(height: 32),
                    Text(
                      'Let us see where you stand, traveler.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A short placement test will help us personalize your journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  // For now, skip placement test and complete onboarding
                  onboardingNotifier.updatePlacementTest({'skipped': true});
                  onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AfricanTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                  ),
                ),
                child: const Text(
                  'Begin Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

