import 'package:flutter/material.dart';

/// Widget that provides safe bottom padding for edge-to-edge displays
/// This ensures buttons/inputs are never hidden by system navigation bars
class SafeBottomPadding extends StatelessWidget {
  final Widget child;
  final double additionalPadding;

  const SafeBottomPadding({
    Key? key,
    required this.child,
    this.additionalPadding = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + additionalPadding),
      child: child,
    );
  }
}

/// Extension to easily add safe bottom padding
extension SafeBottomPaddingExtension on Widget {
  Widget withSafeBottomPadding([double additionalPadding = 0]) {
    return SafeBottomPadding(
      additionalPadding: additionalPadding,
      child: this,
    );
  }
}

