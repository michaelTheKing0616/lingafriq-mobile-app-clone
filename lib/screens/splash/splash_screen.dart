import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/splash/splash_screen_material3.dart';

/// Splash Screen - Uses Material 3 version
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SplashScreenMaterial3();
  }
}
