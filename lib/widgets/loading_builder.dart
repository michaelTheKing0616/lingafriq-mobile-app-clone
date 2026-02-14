import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

import '../utils/constants.dart';
import 'language_type_header_builder.dart';
import 'top_gradient_box_builder.dart';

class LoadingBuilder extends StatelessWidget {
  final String title;
  const LoadingBuilder({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopGradientBox(
          borderRadius: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(color: Theme.of(context).colorScheme.onPrimary),
              LangguageTypeHeaderBuilder(
                title: title,
                level: "",
                count: 1,
                points: 0,
                type: "Written & Oral",
                completed: 1,
              ).shimmer(),
            ],
          ),
        ),
        12.heightBox,
        ...List.generate(4, (index) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26),
              borderRadius: BorderRadius.circular(kBorderRadius / 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 0.5.sw,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).shimmer(),
                8.heightBox,
                Container(
                  height: 20,
                  width: 0.75.sw,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).shimmer(),
              ],
            ),
          ).shimmer();
        }),
        // LessonsList(language: language).expand(),
      ],
    );
  }
}
