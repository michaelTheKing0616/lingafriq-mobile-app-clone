import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

import '../../../widgets/top_gradient_box_builder.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 0.3.sh,
            child: TopGradientBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButton(color: Colors.white),
                  const Spacer(),
                  "About".text.xl4.medium.white.make().p16(),
                ],
              ),
            ),
          ),
          Column(
            children: [
              aboutUs.text.lg.heightRelaxed.center.make().p32(),
            ],
          ),
        ],
      ),
    );
  }

  String get aboutUs => '''
We love Afrika, and we love Afrikan languages and culture. Let's learn together.

Take your learning experience to a whole new level by combining the history and culture of your desired language as you learn. Discover more by entering the details below and be the first to know when the app is out!
''';
}
