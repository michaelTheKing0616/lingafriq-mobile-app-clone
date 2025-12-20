import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/utils.dart';

import '../../providers/api_provider.dart';

class IndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

final _indexProvider =
    NotifierProvider.autoDispose<IndexNotifier, int>(() {
  return IndexNotifier();
});

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = usePageController();
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: controller,
              onPageChanged: (value) {
                HapticFeedback.lightImpact();
                if (value == 4) {
                  ref.read(navigationProvider).naviateOffAll(const TabsView());
                } else {
                  ref.read(_indexProvider.notifier).setIndex(value);
                }
              },
              children: [
                _OnboardingItem(
                  topImage: Images.obTop1,
                  bottomImage: Images.obBottom1,
                  title: "What Do We Offer Uniqely",
                  description: "54 countries, 2000+ languages, 1+ billion voices. One origin. ",
                  textfontsize: 24.sp,
                ),
                _OnboardingItem(
                  textfontsize: 22.sp,
                  topImage: Images.obTop2,
                  bottomImage: Images.obBottom2,
                  title: "What Do We Offer Uniqely",
                  description:
                      "Afrika has a voice, and our duty is to amplify it.  We’d love take you on a journey through history, and  help you express yourself through language. One thing is certain, we bring you closer to Afrika and her culture.",
                ),
                _OnboardingItem(
                    textfontsize: 17.sp,
                    topImage: Images.obTop3,
                    bottomImage: Images.obBottom3,
                    title: "What Do We Offer Uniqely",
                    description:
                        '''This app provides you with learning tools such as video, audio, and illustrations to teach you your preferred Afrikan language from scratch. 

Learn about the history of the people who speak this language, and how they express themselves in their interactions with each other through their mannerisms. 

LingAfriq offers interactive quizzes  to test and improve your knowledge on language topics, history, and current affairs. 

Earn points as you progress and see how you compare to other learners on the leaderboard.'''),
                _OnboardingItem(
                  topImage: Images.obTop4,
                  bottomImage: Images.obBottom2,
                  title: "What Do We Offer Uniqely",
                  description:
                      '''We aim to have all Afrikan languages, but we’re not there yet. We’re working to feature more languages. Don’t see a language you’d like to learn, let’s know about it and we’d work to include it (that’s if we’re not working on it already 😉♥️). 

You can do this by going to your profile tab, and selecting the “Feedback” option to enter this information. Now let’s get to learning!''',
                  width: 0.9.sw,
                  textfontsize: 19.5.sp,
                ),
                const SizedBox(),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Spacer(),
                AspectRatio(
                  aspectRatio: 1121.9 / 792.81,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      Consumer(
                        builder: (context, ref, child) {
                          final index = ref.watch(_indexProvider);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [0, 1, 2, 3].map((e) {
                                  final selected = index == e;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.fastLinearToSlowEaseIn,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: selected ? 24 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.white : Colors.white38,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  );
                                }).toList(),
                              ),
                              IconButton(
                                onPressed: () async {
                                  if (index < 3) {
                                    controller.nextPage(
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.fastLinearToSlowEaseIn,
                                    );
                                  } else {
                                    ref.read(apiProvider.notifier).regiserDevice();
                                    ref.read(navigationProvider).naviateOffAll(const TabsView());
                                  }
                                },
                                icon: Icon(
                                  Icons.chevron_right,
                                  size: 36.sp,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          );
                        },
                      ).expand()
                    ],
                  ).py24().px16(),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem extends StatelessWidget {
  final String topImage;
  final String bottomImage;
  final String title;
  final String description;
  final double? width;
  final double? textfontsize;
  const _OnboardingItem({
    Key? key,
    required this.topImage,
    required this.bottomImage,
    required this.title,
    required this.description,
    this.width,
    this.textfontsize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.sh,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(topImage, width: width ?? 0.5.sw),
              ],
            ),
          ).expand(flex: 8),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bottomImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                4.heightBox,
                if (textfontsize != null)
                  description.text.center.white.size(textfontsize).make() //.pOnly(right: 0.1.sw)
                else
                  description.text.center.white.make(), //.pOnly(right: 0.1.sw),
                64.heightBox,
              ],
            ).safeArea(top: false),
          ).expand(flex: 9),
          // AspectRatio(
          //   // aspectRatio: 1121.9 / 792.81,
          //   aspectRatio: 1,
          //   child: Stack(
          //     fit: StackFit.expand,
          //     children: [
          //       Image.asset(
          //         bottomImage,
          //         fit: BoxFit.cover,
          //       ),
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           12.heightBox,
          //         ],
          //       ).py24().px16()
          //     ],
          //   ),
          // )
        ],
      ),
    );
  }
}
