import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/screens/tabs_view/home/take_quiz_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../../history/screens/history_list_screen.dart';
import '../../../lessons/screens/lessons_list_screen.dart';
import '../../../mannerisms/screens/mannerism_list_screen.dart';
import '../../../providers/navigation_provider.dart';
import '../../../widgets/greegins_builder.dart';

class LanguageDetailScreen extends ConsumerWidget {
  final Language language;
  const LanguageDetailScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(color: Colors.white),
                // const PointsAndProfileImageBuilder(),
                // 0.05.sh.heightBox,
                GreetingsBuilder(
                  greetingTitle: '',
                  pageTitle: language.name,
                )
              ],
            ),
          ),
          Stack(
            children: [
              IgnorePointer(
                ignoring: true,
                child: Image.asset(
                  Images.courseBackground,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: EdgeInsets.all(16.0.sp),
                            child: Stack(
                              children: [
                                IgnorePointer(
                                  ignoring: true,
                                  child: Image.asset(Images.map).offset(offset: Offset(0, -12.sp)),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * 0.12,
                                  top: constraints.maxHeight * 0.075,
                                  // child: PrimaryButton(
                                  //   elevation: 4,
                                  //   verticalPadding: 10,
                                  //   onTap: () {
                                  //     ref
                                  //         .read(navigationProvider)
                                  //         .naviateTo(LessonsListScreen(language: language));
                                  //   },
                                  //   text: "Lessons",
                                  // ).w(0.35.sw),
                                  child: _LessonTextBuilder(
                                    onTap: () {
                                      ref
                                          .read(navigationProvider)
                                          .naviateTo(LessonsListScreen(language: language));
                                    },
                                  ),
                                ).animate(effects: kGradientTextEffects),
                                Positioned(
                                  left: constraints.maxWidth * 0.365,
                                  top: constraints.maxHeight * (context.isSmall ? 0.315 : 0.265),
                                  // child: PrimaryButton(
                                  //   elevation: 4,
                                  //   verticalPadding: 10,
                                  //   onTap: () {
                                  //     ref
                                  //         .read(navigationProvider)
                                  //         .naviateTo(MannerismsListScreen(language: language));
                                  //   },
                                  //   text: "Mannerisms",
                                  // ).w(0.4.sw),
                                  child: _MannerismTextBuilder(
                                    onTap: () {
                                      ref
                                          .read(navigationProvider)
                                          .naviateTo(MannerismsListScreen(language: language));
                                    },
                                  ).animate(effects: kGradientTextEffects),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * (context.isSmall ? 0.45 : 0.425),
                                  top: constraints.maxHeight * (context.isSmall ? 0.6 : 0.475),
                                  // child: PrimaryButton(
                                  //   elevation: 4,
                                  //   verticalPadding: 10,
                                  //   onTap: () {
                                  //     ref
                                  //         .read(navigationProvider)
                                  //         .naviateTo(LessonsListScreen(language: language));
                                  //   },
                                  //   text: "History",
                                  // ).w(0.3.sw),
                                  child: _HistoryTextBuilder(
                                    size: Size(18.sp, 18.sp),
                                    onTap: () {
                                      ref
                                          .read(navigationProvider)
                                          .naviateTo(HistoryListScreen(language: language));
                                    },
                                  ).animate(effects: kGradientTextEffects),
                                ),
                                // const _MannerismTextBuilder(),
                                // const _HistoryTextBuilder(),
                              ],
                            ),
                          );
                        },
                      ).px16(),
                    ),
                    20.heightBox,
                    PrimaryButton(
                      width: 0.6.sw,
                      onTap: () {
                        ref.read(navigationProvider).naviateTo(TakeQuizScreen(language: language));
                      },
                      color: AppColors.primaryGreen,
                      text: "Take Quiz",
                    ).centered(),
                  ],
                ),
              )
            ],
          ).expand()
        ],
      ),
    );
  }
}

class _LessonTextBuilder extends StatelessWidget {
  final VoidCallback onTap;
  const _LessonTextBuilder({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['l', 'e', 's', 's', 'o', 'n', 's'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 19.sp,
                height: 19.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: 20.sp * 6.5,
          //   child: const LinearProgressIndicator(value: 1).offset(offset: Offset(8.sp, 0)),
          // ),
        ],
      ),
    );
  }
}

class _MannerismTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  const _MannerismTextBuilder({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['m', 'a', 'n', 'n', 'e', 'r', 'i', 's', 'm', 's'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 18.sp,
                height: 18.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: 14.sp * 9.5,
          //   child: const LinearProgressIndicator(value: 1).offset(
          //     offset: Offset(8.sp, 0),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _HistoryTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  final Size? size;
  const _HistoryTextBuilder({
    Key? key,
    required this.onTap,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['h', 'i', 's', 't', 'o', 'r', 'y'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: size?.width ?? 19.sp,
                height: size?.height ?? 19.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: (size?.width ?? 20.sp) * 6.5,
          //   child: const LinearProgressIndicator(value: 1).offset(
          //     offset: Offset(8.sp, 0),
          //   ),
          // ),
        ],
      ),
    );
  }
}
