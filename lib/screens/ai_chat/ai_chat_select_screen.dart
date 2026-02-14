import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// AI Chat Select Screen - Entry point for Polie
/// Navigates to mode selection screen with all 6 modes
class AiChatSelectScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const AiChatSelectScreen({Key? key, this.onBack}) : super(key: key);

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
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
