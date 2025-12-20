import 'package:flutter/material.dart';
import 'package:lingafriq/utils/design_system.dart';

class TopGradientBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const TopGradientBox({
    Key? key,
    required this.child,
    this.borderRadius = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
        gradient: DesignSystem.primaryGradient,
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: SafeArea(
        bottom: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewPadding.top + 16,
            bottom: 8,
            left: 8,
            right: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}
