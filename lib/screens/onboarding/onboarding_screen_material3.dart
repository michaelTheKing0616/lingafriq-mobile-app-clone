import 'package:flutter/material.dart';
import 'package:lingafriq/screens/onboarding/enhanced_onboarding_flow_screen.dart';

/// Material 3 Onboarding Screen (wrapper/alias)
/// Uses the existing enhanced_onboarding_flow_screen.dart which already has Material 3 + Pan-African design
class OnboardingScreenMaterial3 extends StatelessWidget {
  const OnboardingScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedOnboardingFlowScreen();
  }
}

