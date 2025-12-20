import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/utils/utils.dart';

import '../../widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showDynamicLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    
    // Initialize app (any async setup)
    await Future.wait([
      // Add any initialization tasks here
      Future.delayed(const Duration(milliseconds: 100)), // Placeholder
    ]);

    // Ensure minimum 3 seconds, maximum 4 seconds
    final elapsed = DateTime.now().difference(startTime);
    final minDelay = const Duration(seconds: 3);
    final maxDelay = const Duration(seconds: 4);
    
    Duration remainingDelay;
    if (elapsed < minDelay) {
      remainingDelay = minDelay - elapsed;
    } else if (elapsed > maxDelay) {
      remainingDelay = Duration.zero;
    } else {
      remainingDelay = Duration.zero;
    }

    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

      if (mounted) {
        setState(() {
          _showDynamicLoading = false;
        });
        // Navigate after loading screen completes
        ref.read(authProvider.notifier).navigateBasedOnCondition();
      }
  }

  @override
  Widget build(BuildContext context) {
    // Show dynamic loading screen first
    if (_showDynamicLoading) {
      return DynamicLoadingScreen(
        loadingDuration: const Duration(seconds: 3),
        onLoadingComplete: () {
          // Loading complete callback (optional)
        },
      );
    }

    // Fallback to original splash (shouldn't be reached, but kept for safety)
    return Scaffold(
      backgroundColor: const Color.fromRGBO(251, 251, 251, 1),
      body: Center(
        child: AppLogo(
          width: 1.sw,
          logoOverride: Images.splash,
        ),
      ),
    );
  }
}
