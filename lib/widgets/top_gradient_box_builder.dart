import 'package:flutter/material.dart';

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
        gradient: const LinearGradient(
          colors: [
            Color(0XFFC4413A),
            Color(0XFFF7CB46),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? 0 : 0,
          ),
          child: child,
        ),
      ),
    );
  }
}
