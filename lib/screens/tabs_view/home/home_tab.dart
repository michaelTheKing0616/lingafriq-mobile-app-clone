import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart' show debugPrint;
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/greegins_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../../detail_types/introduction_screen.dart';
import '../../../lessons/screens/lessons_list_screen.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/primary_button.dart';
import 'language_detail_screen.dart';
import 'take_quiz_screen.dart';

// Remove autoDispose to prevent data loss on tab changes
// Cache data to improve stability and offline experience
final languagesProvider = FutureProvider((ref) async {
  try {
    final languages = await ref.read(apiProvider.notifier).getLanguages();
    // Cache the result in shared preferences
    ref.read(sharedPreferencesProvider).cacheLanguages(languages.toJson());
    return languages;
  } catch (e) {
    // Try to load from cache if API fails
    final cachedData = ref.read(sharedPreferencesProvider).getCachedLanguages();
    if (cachedData != null) {
      return LanguageResponse.fromJson(cachedData);
    }
    rethrow;
  }
});

final _timerProvider = Provider((ref) {
  final welcomeTexts = [
    'Sannu da zuwa',
    'Wehcome o',
    'Karibu',
    'Ẹ Káàbọ',
    'Wamukelekile',
    'Nnọọ',
    'Welcome',
  ];

  Timer.periodic(2.seconds, (tick) {
    final index = tick.tick % welcomeTexts.length;
    final greeting = welcomeTexts[index];
    ref.read(_titleProvider.notifier).setTitle(greeting);
  });
});

class TitleNotifier extends Notifier<String> {
  @override
  String build() => "Welcome";

  void setTitle(String value) {
    state = value;
  }
}

final _titleProvider =
    NotifierProvider.autoDispose<TitleNotifier, String>(() {
  return TitleNotifier();
});

class HomeTab extends HookConsumerWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);
    ref.watch(_timerProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopGradientBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(scaffoldKeyProvider).currentState!.openDrawer();
                          },
                          icon: const Icon(Icons.menu_rounded, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final title = ref.watch(_titleProvider);
                              return GreetingsBuilder(
                                // pageTitle: "Welcome Back",
                                pageTitle: "$title, ${ref.watch(userProvider)?.username}",
                                showGreeting: ref.watch(userProvider) != null,
                                greetingTitle: "",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernSectionHeader(
                title: "Featured Languages",
                subtitle: "Start your learning journey",
              ),
              Expanded(
                child: languagesAsync.when(
                  data: (languageRespponse) {
                    final languages = languageRespponse.results;
                    final featuredLanguages = languages.where((e) => e.is_featured).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RefreshIndicator(
                          onRefresh: () {
                            ref.invalidate(languagesProvider);
                            return Future.value();
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive grid columns based on screen width
                              final screenWidth = MediaQuery.of(context).size.width;
                              final crossAxisCount = screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 2);
                              final spacing = screenWidth > 600 ? 16.0 : 12.0;
                              
                              return GridView.count(
                                padding: EdgeInsets.zero,
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: screenWidth > 600 ? 1.2 : 1.1,
                                children:
                                    featuredLanguages.map((e) => LanguageItem(language: e)).toList(),
                              );
                            },
                          ),
                        ).expand(),
                        "More Languages".text.size(22.sp).medium.make().py8().px8(),
                        InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            showSearch(
                              context: context,
                              delegate: SearchLanguageDelegate(languages),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8.sp),
                            decoration: BoxDecoration(
                              color: context.adaptive12,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                "Search".text.size(16.sp).make(),
                                const Icon(Icons.chevron_right).rotate(90),
                              ],
                            ),
                          ),
                        )
                      ],
                    );
                  },
                  error: (e, s) {
                    return StreamErrorWidget(
                      error: e,
                      onTryAgain: () {
                        // ref.read(navigationProvider).naviateTo(
                        //       LanguageDetailScreen(
                        //         language: Language(
                        //           id: 2,
                        //           total_score: 100,
                        //           total_count: 5,
                        //           completed: 4,
                        //           name: "Test",
                        //           background: 'background',
                        //           Inrtoduction: 'Inrtoduction',
                        //           is_published: true,
                        //           is_featured: true,
                        //           level_language: "Beginner",
                        //         ),
                        //       ),
                        //     );
                        ref.invalidate(languagesProvider);
                      },
                    );
                  },
                  loading: () => const AdaptiveProgressIndicator(
                    message: "Loading Languages ...",
                  ),
                ),
              ),
            ],
          ).pSymmetric(v: 12, h: 24).expand()
        ],
      ),
    );
  }
}

class LanguageItem extends ConsumerWidget {
  final Language language;
  final Function? onTap;
  const LanguageItem({
    Key? key,
    required this.language,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernLanguageCard(
      languageName: language.name,
      imageUrl: language.background,
      isFeatured: language.is_featured,
      onTap: () async {
        onTap?.call();
        final result = ref.read(sharedPreferencesProvider).showLanguageIntro(language.id);
        if (result) {
          ref.read(navigationProvider).naviateTo(IntroductionScreen(language: language));
          return;
        }
        // Show lesson/quiz options
        _showLanguageOptions(context, ref);
      },
    );
  }

  void _showLanguageOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.adaptive12,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusXL)),
        ),
        padding: EdgeInsets.only(
          top: DesignSystem.spacingL,
          left: DesignSystem.spacingL,
          right: DesignSystem.spacingL,
          bottom: MediaQuery.of(context).viewPadding.bottom + DesignSystem.spacingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.adaptive38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: DesignSystem.spacingL),
            Text(
              language.name,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignSystem.spacingL),
            PrimaryButton(
              onTap: () {
                Navigator.pop(context);
                // Pre-load lessons data for faster navigation
                ref.read(apiProvider.notifier).getLessons(language.id);
                ref.read(navigationProvider).naviateTo(LessonsListScreen(language: language));
              },
              text: "Take a Lesson",
              color: AppColors.primaryGreen,
            ),
            SizedBox(height: DesignSystem.spacingM),
            PrimaryButton(
              onTap: () {
                Navigator.pop(context);
                // Pre-load quiz data for faster navigation
                ref.read(apiProvider.notifier).getRandomQuizLessons(language.id);
                ref.read(navigationProvider).naviateTo(TakeQuizScreen(language: language));
              },
              text: "Take a Quiz",
              color: AppColors.primaryOrange,
            ),
            SizedBox(height: DesignSystem.spacingM),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(navigationProvider).naviateTo(LanguageDetailScreen(language: language));
              },
              child: Text(
                "View Details",
                style: TextStyle(color: context.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageItemOld extends ConsumerWidget {
  final Language language;
  final Function? onTap;
  const LanguageItemOld({
    Key? key,
    required this.language,
    this.onTap,
  }) : super(key: key);

  void _showLanguageOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.adaptive12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              language.name,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onTap: () {
                Navigator.pop(context);
                // Pre-load lessons data for faster navigation
                ref.read(apiProvider.notifier).getLessons(language.id);
                ref.read(navigationProvider).naviateTo(LessonsListScreen(language: language));
              },
              text: "Take a Lesson",
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              onTap: () {
                Navigator.pop(context);
                // Pre-load quiz data for faster navigation
                ref.read(apiProvider.notifier).getRandomQuizLessons(language.id);
                ref.read(navigationProvider).naviateTo(TakeQuizScreen(language: language));
              },
              text: "Take a Quiz",
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(navigationProvider).naviateTo(LanguageDetailScreen(language: language));
              },
              child: Text(
                "View Details",
                style: TextStyle(color: context.primaryColor),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        onTap?.call();
        final result = ref.read(sharedPreferencesProvider).showLanguageIntro(language.id);
        if (result) {
          ref.read(navigationProvider).naviateTo(IntroductionScreen(language: language));
          return;
        }
        // Show lesson/quiz options
        _showLanguageOptions(context, ref);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: language.background ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget: kErrorLogoWidget,
              placeholder: kImagePlaceHolder,
            ).cornerRadius(kBorderRadius),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.32),
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
            ),
            language.name.text.xl2.semiBold.white.make().p12(),
          ],
        ),
      ),
    );
  }
}


// Let me explain how it works.

// When user opens the app here is the flow,
// Check if email and password is stored.

// If email and password is not stored -> Take the user to login screen

// If email and password is stored -> 
// 1) Make a request to server to recieve the token. (We can't cache the token as it will be expired after some time)
// 2) Token Recievd (Token is required to make any further requests)
// 3) Check if the user data is stored in the cache based on the email
// 4) If user data is not stored in the cache -> Make a request to server to get the user data and save it to cache (This request takes a lot of time)
// 5) If the user data in cache -> Use the user data from cache and take user to home screen


// we can show an error message to the user if the request fails.
// The app requirement is to unlock the next lesson only when the preceeding lesson is complete Correct?

// To Mark the lesson complete, api request has to be made and successfully.
// If it fails and takes the user to next lessson, the purpose is gone, now the user will be on the next lesson, but the previous lesson is not marked complete.
// Now the next question request is success and that question is marked as complete.


// Now we have such heirachy
// Lesson 1 -> Completed
// Lesson 2 -> Not Completed
// Lesson 3 -> Completed


// What workaround do you have for this



// Hello,


// Thank you for your resubmission. Upon further review, we identified an additional issue that needs your attention. See below for more information.


// If you have any questions, we are here to help. Reply to this message in App Store Connect and let us know.


// Guideline 2.5.4 - Performance - Software Requirements

// Your app declares support for location in the UIBackgroundModes key in your Info.plist file but does not have any features that require persistent location. Apps that declare support for location in the UIBackgroundModes key in your Info.plist file must have features that require persistent location.


// Next Steps


// To resolve this issue, please revise your app to include features that require the persistent use of real-time location updates while the app is in the background.


// If your app does not require persistent real-time location updates, please remove the "location" setting from the UIBackgroundModes key. You may wish to use the significant-change location service or the region monitoring location service if persistent real-time location updates are not required for your app features.


// Resources


// For more information, please review the Starting the Significant-Change Location Service and Monitoring Geographical Regions.


// Guideline 5.1.2 - Legal - Privacy - Data Use and Sharing

// The app privacy information you provided in App Store Connect indicates you collect data in order to track the user, including Precise Location. However, you do not use App Tracking Transparency to request the user's permission before tracking their activity.


// Starting with iOS 14.5, apps on the App Store need to receive the user’s permission through the AppTrackingTransparency framework before collecting data used to track them. This requirement protects the privacy of App Store users.


// Next Steps


// Here are two ways to resolve this issue:


// - If you do not currently track, or decide to stop tracking, update your app privacy information in App Store Connect. You must have the Account Holder or Admin role to update app privacy information.


// - If you track users, you must implement App Tracking Transparency and request permission before collecting data used to track. When you resubmit, indicate in the Review Notes where the permission request is located.


// Resources