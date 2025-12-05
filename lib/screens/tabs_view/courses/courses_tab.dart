import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/info_widget.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../../models/language_response.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/adaptive_progress_indicator.dart';
import '../../../widgets/error_widet.dart';
import '../../../widgets/greegins_builder.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import '../home/home_tab.dart';
import '../home/language_detail_screen.dart';
import '../tabs_view.dart';

class CoursesTab extends HookConsumerWidget {
  const CoursesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopGradientBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(scaffoldKeyProvider).currentState!.openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
                // const PointsAndProfileImageBuilder(),
                GreetingsBuilder(
                  pageTitle: "Your Courses!",
                  showGreeting: ref.watch(userProvider) != null,
                  greetingTitle: "Hi ${ref.watch(userProvider)?.fullName}",
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              "Progress".text.xl2.medium.make(),
              12.heightBox,
              Expanded(
                child: languagesAsync.when(
                  data: (languages) {
                    final progressLanguages =
                        languages.results.where((e) => e.total_score > 0).toList();

                    if (progressLanguages.isEmpty) {
                      return const InfoWidget(
                        text: "No Course started yet",
                        subText: "Start a course to see your progress",
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () {
                        ref.invalidate(languagesProvider);
                        return Future.value();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: progressLanguages.length,
                        itemBuilder: ((context, index) {
                          final language = progressLanguages[index];
                          return _ProgressItem(language: language);
                        }),
                      ),
                    );
                  },
                  error: (e, s) {
                    return StreamErrorWidget(
                      error: e,
                      onTryAgain: () {
                        ref.invalidate(languagesProvider);
                      },
                    );
                  },
                  loading: () => DynamicLoadingScreen(),
                ),
              ),
            ],
          ).pSymmetric(v: 12, h: 16).expand()
        ],
      ),
    );
  }
}

class _ProgressItem extends ConsumerWidget {
  final Language language;
  const _ProgressItem({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
      elevation: 12,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: () {
          ref.read(navigationProvider).naviateTo(LanguageDetailScreen(language: language));
        },
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: language.background ?? '',
                  width: 0.15.sw,
                  height: 0.15.sw,
                  fit: BoxFit.cover,
                  errorWidget: kErrorLogoWidget,
                  placeholder: kImagePlaceHolder,
                ).cornerRadius(kBorderRadius),
                12.widthBox,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        language.name.text.xl.make().expand(),
                        // Chip(
                        //   visualDensity: VisualDensity.compact,
                        //   label: language.level_language.text.normal.sm.make(),
                        // ).offset(offset: const Offset(0, -8)),
                      ],
                    ),
                    4.heightBox,
                    "Lessons completed: ${language.completed} • Points earned: ${language.total_score}"
                        .text
                        .color(context.adaptive54)
                        .maxLines(2)
                        .make()
                        .pOnly(right: 24),
                  ],
                ).expand()
              ],
            ),
            12.heightBox,
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: language.total_count == 0 ? 0 : language.completed / language.total_count,
                minHeight: 6,
              ),
            ),
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
