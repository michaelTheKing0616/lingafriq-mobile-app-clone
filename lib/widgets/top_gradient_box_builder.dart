import 'package:flutter/material.dart';

const List<Color> kTopGradientColors = [Color(0XFFC4413A), Color(0XFFF7CB46)];

class TopGradientBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const TopGradientBox({
    super.key,
    required this.child,
    this.borderRadius = 6,
    this.colors = kTopGradientColors,
  });

  /// Gradient stops; screens with white text on them pass a darker set.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
        gradient: LinearGradient(colors: colors),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
