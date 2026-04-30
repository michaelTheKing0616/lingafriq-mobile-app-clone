import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Height below which vertical insets can be capped slightly so constrained
/// layouts retain usable vertical space (e.g. short landscape shells).
const double _kShortScreenHeightThreshold = 560;
const double _kShortScreenMaxVerticalInset = 12;

/// View-based safe area widget.
///
/// **Critical:** Unlike the previous implementation, device-reported bottom/top
/// insets are **never capped downward** above the short-screen path. Older
/// clamping (max 34px bottom) made bottom navigation sit too high on iPhones
/// with larger home-indicator safe areas.
///
/// Prefer this over `[MediaQuery].padding = EdgeInsets.zero` at app root —
/// combine with Flutter's `[SafeArea]` here for consistent behavior.
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height;

    if (height <= _kShortScreenHeightThreshold) {
      final viewPadding = media.viewPadding;
      double topInset = top ? viewPadding.top : 0;
      double bottomInset = bottom ? viewPadding.bottom : 0;
      double leftInset = left ? viewPadding.left : 0;
      double rightInset = right ? viewPadding.right : 0;

      topInset = math.min(topInset, _kShortScreenMaxVerticalInset);
      bottomInset = math.min(bottomInset, _kShortScreenMaxVerticalInset);

      return Padding(
        padding: EdgeInsets.only(
          top: topInset,
          bottom: bottomInset,
          left: leftInset,
          right: rightInset,
        ),
        child: child,
      );
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      maintainBottomViewPadding: true,
      minimum: EdgeInsets.zero,
      child: child,
    );
  }
}
