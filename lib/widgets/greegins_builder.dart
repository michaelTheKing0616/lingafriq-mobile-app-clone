import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/points_and_profile_image_builder.dart';

class GreetingsBuilder extends StatelessWidget {
  final String? greetingTitle;
  final String pageTitle;
  final bool showGreeting;
  final Widget? subtitle;
  final Widget? trailing;
  const GreetingsBuilder({
    Key? key,
    required this.pageTitle,
    this.greetingTitle,
    this.showGreeting = true,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (showGreeting) (greetingTitle ?? "").text.xl.color(Colors.white).make(),
            pageTitle.text.xl2.semiBold.color(Colors.white).make(),
            subtitle ?? const SizedBox(),
          ],
        ).expand(),
        trailing ??
            PointsAndProfileImageBuilder(
              size: Size(0.07.sh, 0.07.sh),
            ).offset(offset: const Offset(0, -24))
      ],
    ).px24().py12();
    // return Column(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   mainAxisAlignment: MainAxisAlignment.spaceAround,
    //   children: [
    //     Row(
    //       children: [],
    //     )
    //   ],
    // ).px24();
  }
}
