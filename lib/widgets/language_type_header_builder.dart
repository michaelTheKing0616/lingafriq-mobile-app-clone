import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

import 'greegins_builder.dart';

class LangguageTypeHeaderBuilder extends StatelessWidget {
  final String title;
  // final bool showCount;
  final String? level;
  final int count;
  final int? allCount;
  final int points;
  final String type;
  final int completed;
  const LangguageTypeHeaderBuilder({
    Key? key,
    required this.title,
    required this.level,
    required this.count,
    this.allCount,
    required this.points,
    required this.type,
    required this.completed,
    // this.showCount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var subtitle = 'Lessons';
    if (title.toLowerCase().contains('sectio')) {
      subtitle = title;
      subtitle = count == 1 ? "Section" : "Sections";
    } else {
      subtitle = count == 1 ? "Lesson" : "Lessons";
    }

    return Column(
      children: [
        GreetingsBuilder(
          greetingTitle: level,
          pageTitle: title,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              "$count $subtitle • Points to earn: $points"
                  .text
                  .color(Colors.white70)
                  .maxLines(1)
                  .make()
                  .pOnly(top: 4, bottom: 4),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            completed.toString().richText.white.size(18.sp).withTextSpanChildren([
              "/ ${allCount ?? count} Completed".textSpan.size(16.sp).make(),
            ]).make()
          ],
        ).px16(),
        4.heightBox,
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: count == 0 ? 1 : completed / count,
            color: Colors.white,
            backgroundColor: AppColors.primaryGreen,
          ),
        ).px16(),
        12.heightBox,
      ],
    );
  }
}
