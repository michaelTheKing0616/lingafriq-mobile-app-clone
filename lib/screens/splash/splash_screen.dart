import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';

import '../../widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    safeAsync(
      context: context,
      operation: () async {
        await Future.delayed(800.milliseconds);
        ref.read(authProvider.notifier).navigateBasedOnCondition();
      },
      errorContext: 'splash_navigation',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: context.isDarkMode
      //     ? const Color.fromRGBO(3, 3, 3, 1)
      //     : const Color.fromRGBO(251, 251, 251, 1),
      backgroundColor: const Color.fromRGBO(251, 251, 251, 1),
      body: Center(
        child: AppLogo(
          width: 1.sw,
          logoOverride: Images.splash,
          // logoOverride: context.isDarkMode ? Images.logoAnimatedDark : Images.logoAnimatedLight,
        ),
      ),
    );
  }
}
