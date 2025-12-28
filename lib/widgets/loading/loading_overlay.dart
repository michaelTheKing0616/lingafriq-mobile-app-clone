/// Loading Overlay Widget - Shows loading indicator over content
/// Provides a clean loading experience with optional message

import 'package:flutter/material.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? color;
  final Color? progressIndicatorColor;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
    this.progressIndicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayPro(
      isLoading: isLoading,
      progressIndicator: CircularProgressIndicator(
        valueColor: progressIndicatorColor != null
            ? AlwaysStoppedAnimation<Color>(progressIndicatorColor!)
            : null,
      ),
      color: color ?? Colors.black54,
      child: child,
    );
  }
}

