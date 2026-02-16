import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// AI Chat Select Screen - Entry point for Polie
/// Navigates to mode selection screen with all 6 modes
class AiChatSelectScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const AiChatSelectScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simply navigate to the mode selection screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(
          child: PolieModeSelectionScreen(onBack: onBack),
        ),
      );
    });
    
    // Show loading while transitioning
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? PolieColors.obsidian 
          : PolieColors.surfaceContainerLight,
      body: Semantics(
        label: 'Loading. Opening chat selection.',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
