import 'package:flutter/material.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';

/// Material 3 Onboarding Screen (wrapper/alias)
/// 
/// Uses the Unified Onboarding Screen which combines:
/// - Story-driven African narrative (Pa LingAfriq, Adisa the Weaver, etc.)
/// - Material 3 UI with Pan-African design system
/// - Comprehensive personalization questions
/// - Backend sync and offline-first data persistence
class OnboardingScreenMaterial3 extends StatelessWidget {
  const OnboardingScreenMaterial3({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedOnboardingScreen();
  }
}

