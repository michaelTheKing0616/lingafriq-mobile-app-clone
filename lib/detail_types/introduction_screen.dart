import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/utils/utils.dart';

import '../providers/navigation_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../screens/tabs_view/home/language_detail_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/top_gradient_box_builder.dart';

class IntroductionScreen extends ConsumerWidget {
  final Language language;
  const IntroductionScreen({Key? key, required this.language}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(color: Colors.white),
                language.name.text.xl2.semiBold
                    .maxLines(2)
                    .ellipsis
                    .color(Colors.white)
                    .make()
                    .p16(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: context.isDarkMode ? context.cardColor : Colors.white,
                elevation: 12,
                shadowColor: Colors.black38,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    double.infinity.widthBox,
                    language.Inrtoduction.text.xl.make(),
                  ],
                ).p12(),
              ).px16(),
            ],
          ).scrollVertical().expand(),
          PrimaryButton(
            width: 0.6.sw,
            onTap: () {
              ref.read(sharedPreferencesProvider).setLanguageIntro(language.id);
              ref.read(navigationProvider).pop();
              ref.read(navigationProvider).naviateTo(LanguageDetailScreen(language: language));
            },
            text: "Continue",
          ).centered().safeArea(),
          16.heightBox,
        ],
      ),
    );
  }
}
