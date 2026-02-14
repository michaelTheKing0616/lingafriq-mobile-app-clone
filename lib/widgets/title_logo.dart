import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class TitleLogo extends StatelessWidget {
  final double? width;
  final double? height;
  const TitleLogo({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "logo",
      child: Image.asset(
        Images.titleLogo,
        width: width ?? 0.8.sw,
        height: height,
      ),
    );
  }
}
