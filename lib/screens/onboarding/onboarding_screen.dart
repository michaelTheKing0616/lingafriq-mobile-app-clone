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
                  ref.read(navigationProvider).navigateOffAll(const TabsView());
                } else {
                  ref.read(_indexProvider.notifier).setIndex(value);
                }
              },
              children: [
                _OnboardingItem(
                  topImage: Images.obTop1,
                  bottomImage: Images.obBottom1,
                  title: "Welcome to LingAfriq",
                  description: "54 countries, 2000+ languages, 1+ billion voices. One origin. Discover the richness of African languages and cultures.",
                  textfontsize: 24.sp,
                ),
                _OnboardingItem(
                  textfontsize: 22.sp,
                  topImage: Images.obTop2,
                  bottomImage: Images.obBottom2,
                  title: "Amplifying Africa's Voice",
                  description:
                      "Africa has a voice, and our duty is to amplify it. We'll take you on a journey through history and help you express yourself through language. We bring you closer to Africa and her culture.",
                ),
                _OnboardingItem(
                    textfontsize: 17.sp,
                    topImage: Images.obTop3,
                    bottomImage: Images.obBottom3,
                    title: "Comprehensive Learning Tools",
                    description:
                        '''Learn your preferred African language from scratch with video, audio, and illustrations. 

Discover the history of the people who speak this language and how they express themselves through mannerisms. 

Test and improve your knowledge with interactive quizzes on language topics, history, and current affairs. 

Earn XP as you progress and compete with other learners on the leaderboard.'''),
                _OnboardingItem(
                  topImage: Images.obTop4,
                  bottomImage: Images.obBottom2,
                  title: "Growing Language Library",
                  description:
                      '''We're working to feature all African languages. Don't see your language? Let us know through your profile's Feedback option, and we'll work to include it! 

Your learning journey starts now. Let's begin!''',
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
                                    ref.read(navigationProvider).navigateOffAll(const TabsView());
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
            child: Container(
              decoration: BoxDecoration(
                // Add semi-transparent dark overlay for better text contrast
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  4.heightBox,
                  if (textfontsize != null)
                    description.text.center.white.size(textfontsize).make()
                  else
                    description.text.center.white.make(),
                  64.heightBox,
                ],
              ).safeArea(top: false),
            ),
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
