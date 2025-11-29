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
    // Show dynamic loading screen for 3 seconds, then navigate
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showDynamicLoading = false;
        });
        // Navigate after loading screen completes
        ref.read(authProvider.notifier).navigateBasedOnCondition();
      }
    });
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
