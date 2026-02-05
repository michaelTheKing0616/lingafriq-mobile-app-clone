import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

class ModernOnboardingScreen extends HookConsumerWidget {
  const ModernOnboardingScreen({Key? key}) : super(key: key);

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
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                currentPage.value = index;
                HapticFeedback.lightImpact();
                animationController.reset();
                animationController.forward();
              },
              itemCount: 4,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _WelcomeScreen(
                      animationController: animationController,
                    );
                  case 1:
                    return _FeaturesScreen(
                      animationController: animationController,
                    );
                  case 2:
                    return _AdventureScreen(
                      animationController: animationController,
                    );
                  case 3:
                    return _GetStartedScreen(
                      animationController: animationController,
                      onGetStarted: () async {
                        await ref.read(sharedPreferencesProvider).setOnboardingSeen();
                        ref.read(apiProvider.notifier).registerDevice();
                        ref.read(navigationProvider).navigateOffAll(const TabsViewMaterial3());
                      },
                      onLogin: () {
                        ref.read(navigationProvider).navigateTo(const WorldClassLoginScreen());
                      },
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
            // Page Indicator at bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + PanAfricanSpacing.xl,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = currentPage.value == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xxs),
                        width: isActive ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.3),
                          borderRadius: PanAfricanRadius.smBR,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            // Skip Button
            if (currentPage.value < 3)
              Positioned(
                top: MediaQuery.of(context).padding.top + PanAfricanSpacing.md,
                right: PanAfricanSpacing.md,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    'Skip',
                    style: PanAfricanTypography.labelLarge(context, color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Screen 1: Welcome Screen
class _WelcomeScreen extends StatelessWidget {
  final AnimationController animationController;
  
  const _WelcomeScreen({
    Key? key,
    required this.animationController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController,
      child: Container(
        decoration: BoxDecoration(
          gradient: PanAfricanGradients.forest,
        ),
        child: ResponsiveSafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // African-inspired illustration with animation
                      Container(
                        width: 280.w,
                        height: 280.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PanAfricanGradients.sunset,
                          boxShadow: PanAfricanShadows.xl,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Animated background pattern
                            Positioned.fill(
                              child: AfricanPatternDecoration(
                                patternColor: Colors.white,
                                opacity: 0.1,
                                child: Container(),
                              ),
                            ),
                            // Main icon
                            Icon(
                              Icons.language,
                              size: 120.sp,
                              color: Colors.white,
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3))
                                .then()
                                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1000.ms)
                                .then()
                                .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 1000.ms),
                          ],
                        ),
                      )
                          .animate()
                          .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),
                      SizedBox(height: PanAfricanSpacing.xxl),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animationController,
                          curve: Curves.easeOut,
                        )),
                        child: Text(
                          'Your journey to fluency\nstarts now!',
                          textAlign: TextAlign.center,
                          style: PanAfricanTypography.displaySmall(context, color: Colors.white).copyWith(
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
                      SizedBox(height: PanAfricanSpacing.md),
                      FadeTransition(
                        opacity: animationController,
                        child: Text(
                          'Discover the beauty of African languages',
                          textAlign: TextAlign.center,
                          style: PanAfricanTypography.bodyLarge(context, color: Colors.white.withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 2: Features Screen
class _FeaturesScreen extends StatelessWidget {
  final AnimationController animationController;
  
  const _FeaturesScreen({
    Key? key,
    required this.animationController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.games_rounded,
        'title': 'Learn languages, play games',
        'description': 'Fun, bite-sized lessons make learning addictive and effective',
        'color': PanAfricanColors.primary,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Track your progress',
        'description': 'Stay motivated with personalized challenges and daily goals',
        'color': PanAfricanColors.secondary,
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Connect with culture',
        'description': 'Learn about history, traditions, and cultural expressions',
        'color': PanAfricanColors.tertiary,
      },
    ];
    
    return Container(
      color: PanAfricanColors.surfaceLight,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(height: PanAfricanSpacing.xl),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Learn a new language,\nthe fun way',
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.headlineLarge(context),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxl),
                    ...features.asMap().entries.map((entry) {
                      final index = entry.key;
                      final feature = entry.value;
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3 + (index * 0.1)),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animationController,
                          curve: Interval(
                            index * 0.2,
                            0.5 + (index * 0.2),
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: FadeTransition(
                          opacity: animationController,
                          child: _FeatureCard(
                            icon: feature['icon'] as IconData,
                            title: feature['title'] as String,
                            description: feature['description'] as String,
                            color: feature['color'] as Color,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  
  const _FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: PanAfricanShadows.md,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: PanAfricanRadius.lgBR,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32.sp,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  description,
                  style: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Screen 3: Adventure Screen
class _AdventureScreen extends StatelessWidget {
  final AnimationController animationController;
  
  const _AdventureScreen({
    Key? key,
    required this.animationController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: AfricanPatternDecoration(
              patternColor: Colors.white,
              opacity: 0.1,
              child: Container(),
            ),
          ),
          ResponsiveSafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.8,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animationController,
                            curve: Curves.elasticOut,
                          )),
                          child: Container(
                            width: 200.w,
                            height: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: PanAfricanGradients.sunset,
                              boxShadow: PanAfricanShadows.xl,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Animated pattern
                                Positioned.fill(
                                  child: AfricanPatternDecoration(
                                    patternColor: Colors.white,
                                    opacity: 0.15,
                                    child: Container(),
                                  ),
                                ),
                                // Rotating icon
                                Icon(
                                  Icons.explore_rounded,
                                  size: 100.sp,
                                  color: Colors.white,
                                )
                                    .animate(onPlay: (controller) => controller.repeat())
                                    .rotate(duration: 3000.ms, begin: 0, end: 0.1)
                                    .then()
                                    .rotate(duration: 3000.ms, begin: 0.1, end: -0.1),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.xxl),
                        FadeTransition(
                          opacity: animationController,
                          child: Text(
                            'Ready for a\npan-African adventure?',
                            textAlign: TextAlign.center,
                            style: PanAfricanTypography.displayMedium(context, color: Colors.white).copyWith(
                              height: 1.2,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        FadeTransition(
                          opacity: animationController,
                          child: Text(
                            'Explore 54 countries, 2000+ languages,\nand connect with 1+ billion voices',
                            textAlign: TextAlign.center,
                            style: PanAfricanTypography.bodyLarge(context, color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Screen 4: Get Started Screen
class _GetStartedScreen extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;
  
  const _GetStartedScreen({
    Key? key,
    required this.animationController,
    required this.onGetStarted,
    required this.onLogin,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final paths = [
      {
        'icon': Icons.explore_rounded,
        'title': 'Explore Cultures',
        'description': 'Discover the rich heritage of African languages',
        'color': PanAfricanColors.tertiary,
      },
      {
        'icon': Icons.work_rounded,
        'title': 'Boost Your Career',
        'description': 'Open doors to international opportunities',
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'icon': Icons.school_rounded,
        'title': 'Excel Academically',
        'description': 'Prepare for studies and broaden knowledge',
        'color': PanAfricanColors.ankaraPurple,
      },
    ];
    
    return Container(
      color: PanAfricanColors.surfaceLight,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(height: PanAfricanSpacing.md),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Your Language Journey\nStarts Here!',
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.headlineLarge(context, color: PanAfricanColors.primary),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Choose your path and unlock new opportunities',
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.bodyLarge(context, color: PanAfricanColors.textSecondary),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xl),
                    ...paths.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      final pathKey = ['explore', 'career', 'academic'][index];
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3 + (index * 0.1)),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animationController,
                          curve: Interval(
                            index * 0.15,
                            0.4 + (index * 0.15),
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: FadeTransition(
                          opacity: animationController,
                          child: Consumer(
                            builder: (context, ref, child) {
                              return _PathCard(
                                icon: path['icon'] as IconData,
                                title: path['title'] as String,
                                description: path['description'] as String,
                                color: path['color'] as Color,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(onboardingProvider.notifier).updatePath(pathKey);
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: PanAfricanSpacing.xl),
                    // Get Started Button
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animationController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      )),
                      child: FadeTransition(
                        opacity: animationController,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              onGetStarted();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: PanAfricanColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: PanAfricanRadius.roundBR,
                              ),
                              elevation: 8,
                              shadowColor: PanAfricanColors.primary.withOpacity(0.4),
                            ),
                            child: Text(
                              'Get Started',
                              style: PanAfricanTypography.labelLarge(context, color: Colors.white).copyWith(
                                fontSize: 18.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    // Login Button
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onLogin();
                      },
                      child: Text(
                        'Already learning? Log in',
                        style: PanAfricanTypography.labelLarge(context, color: PanAfricanColors.primary),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;
  
  const _PathCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PanAfricanRadius.xlBR,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.xlBR,
          boxShadow: PanAfricanShadows.md,
          border: Border(
            bottom: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleMedium(context, color: color),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  description,
                  style: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

