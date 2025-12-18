import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Wrapper widget that ensures screens are properly displayed
/// Handles errors, loading states, and provides consistent structure
class ScreenWrapper extends ConsumerWidget {
  final Widget child;
  final String? errorMessage;
  final bool showLoading;
  final VoidCallback? onRetry;

  const ScreenWrapper({
    Key? key,
    required this.child,
    this.errorMessage,
    this.showLoading = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showLoading) {
      return const DynamicLoadingScreen();
    }

    return ErrorBoundary(
      errorMessage: errorMessage ?? 'Something went wrong. Please try again.',
      onRetry: onRetry ?? () {},
      child: child,
    );
  }
}

