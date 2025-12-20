import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/core/initialization/app_initializer.dart';

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
      // Daily check-in for gamification
      ref.read(gamificationProvider.notifier).dailyCheckIn(),
      // App initialization (backend health, cache, games)
      _initializeAppServices(),
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

  /// Initialize app services (backend health, cache, games)
  Future<void> _initializeAppServices() async {
    try {
      final initializer = ref.read(appInitializerProvider);
      final result = await initializer.initialize();
      
      if (result.success) {
        debugPrint('✅ App initialization successful: ${result.duration.inMilliseconds}ms');
        if (result.backendStatus != null) {
          if (result.backendStatus!.isFullyOperational) {
            debugPrint('✅ Backend fully operational');
          } else if (result.backendStatus!.hasPartialConnectivity) {
            debugPrint('⚠️ Backend has partial connectivity');
          } else {
            debugPrint('⚠️ Backend offline - app will work in offline mode');
          }
        }
      } else {
        debugPrint('⚠️ App initialization completed with warnings');
        if (result.error != null) {
          debugPrint('Error: ${result.error}');
        }
      }
      
      // Continue background initialization
      initializer.initializeBackground();
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      // Continue anyway - app can work offline
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
