import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Smooth page route for navigation with custom transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Keep the transition for Android/desktop. On iOS/macOS we will use
          // a Cupertino route to preserve interactive swipe-back.
          const begin = Offset(0.0, 0.1);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final slideTween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          final fadeTween = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );

  /// Use this when pushing routes to preserve iOS back-swipe.
  static Route<T> platform<T>({required Widget child}) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => child);
    }
    return SmoothPageRoute<T>(child: child);
  }
}
