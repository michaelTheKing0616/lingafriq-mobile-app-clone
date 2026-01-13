import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final String? logoOverride;
  const AppLogo({
    Key? key,
    this.logoOverride,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoOverride ?? Images.logo,
      width: width ?? 0.5.sw,
      height: height,
    );
  }
}
