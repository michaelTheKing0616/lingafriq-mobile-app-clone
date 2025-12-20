import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/auth/login_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                        ref.read(apiProvider.notifier).regiserDevice();
                        ref.read(navigationProvider).naviateOffAll(const TabsView());
                      },
                      onLogin: () {
                        ref.read(navigationProvider).naviateTo(const LoginScreen());
                      },
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
            // Page Indicator at bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
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
            // Skip Button
            if (currentPage.value < 3)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    pageController.animateToPage(
                      3,
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
                      // African-inspired illustration with animation
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
                              size: 120,
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
                      const SizedBox(height: 48),
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
                          'Discover the beauty of African languages',
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
        'color': AfricanTheme.primaryGreen,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Track your progress',
        'description': 'Stay motivated with personalized challenges and daily goals',
        'color': AfricanTheme.accentGold,
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Connect with culture',
        'description': 'Learn about history, traditions, and cultural expressions',
        'color': AfricanTheme.deepRed,
      },
    ];
    
    return Container(
      color: AfricanTheme.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Learn a new language,\nthe fun way',
                        textAlign: TextAlign.center,
                        style: AfricanTheme.headingStyle(context).copyWith(
                          fontSize: 32,
                          color: AfricanTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AfricanTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AfricanTheme.textDark.withOpacity(0.7),
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AfricanTheme.skyBlue,
            AfricanTheme.primaryGreen,
          ],
        ),
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
          SafeArea(
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
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AfricanTheme.africanSunset,
                              boxShadow: AfricanTheme.africanShadow,
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
                                  size: 100,
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
                        const SizedBox(height: 48),
                        FadeTransition(
                          opacity: animationController,
                          child: Text(
                            'Ready for a\npan-African adventure?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: animationController,
                          child: Text(
                            'Explore 54 countries, 2000+ languages,\nand connect with 1+ billion voices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
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
        'color': AfricanTheme.deepRed,
      },
      {
        'icon': Icons.work_rounded,
        'title': 'Boost Your Career',
        'description': 'Open doors to international opportunities',
        'color': AfricanTheme.skyBlue,
      },
      {
        'icon': Icons.school_rounded,
        'title': 'Excel Academically',
        'description': 'Prepare for studies and broaden knowledge',
        'color': AfricanTheme.vibrantPurple,
      },
    ];
    
    return Container(
      color: AfricanTheme.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Your Language Journey\nStarts Here!',
                        textAlign: TextAlign.center,
                        style: AfricanTheme.headingStyle(context).copyWith(
                          fontSize: 32,
                          color: AfricanTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: animationController,
                      child: Text(
                        'Choose your path and unlock new opportunities',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AfricanTheme.textDark.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...paths.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
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
                          child: _PathCard(
                            icon: path['icon'] as IconData,
                            title: path['title'] as String,
                            description: path['description'] as String,
                            color: path['color'] as Color,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
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
                          child: ElevatedButton(
                            onPressed: onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AfricanTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                              ),
                              elevation: 8,
                              shadowColor: AfricanTheme.primaryGreen.withOpacity(0.4),
                            ),
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Login Button
                    TextButton(
                      onPressed: onLogin,
                      child: Text(
                        'Already learning? Log in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AfricanTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
  
  const _PathCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AfricanTheme.textDark.withOpacity(0.7),
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

