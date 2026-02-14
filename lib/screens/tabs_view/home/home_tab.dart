import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_select_screen.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';

import '../../../detail_types/introduction_screen.dart';
import 'language_detail_screen.dart';

final languagesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
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
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);
    ref.watch(_timerProvider);
    ref.watch(gamificationProvider);
    final gamification = ref.read(gamificationProvider.notifier).gamification;
    final user = ref.watch(userProvider);
    final title = ref.watch(_titleProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: PanAfricanSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context, ref, title, user?.username, gamification),
              SizedBox(height: PanAfricanSpacing.lg),
              _buildQuickActions(context, ref),
              SizedBox(height: PanAfricanSpacing.lg),
              _buildProgressHighlights(context, gamification),
              SizedBox(height: PanAfricanSpacing.lg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
                child: Text(
                  'Featured Languages',
                  style: PanAfricanTypography.titleLarge(context),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
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
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: PanAfricanSpacing.md,
                              mainAxisSpacing: PanAfricanSpacing.md,
                              childAspectRatio: 1.05,
                            ),
                            itemCount: featuredLanguages.length,
                            itemBuilder: (context, index) {
                              return LanguageItem(language: featuredLanguages[index]);
                            },
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),
                        Text(
                          'Explore More',
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        PanAfricanCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.md,
                            vertical: PanAfricanSpacing.sm,
                          ),
                          hasHoverEffect: true,
                          onTap: () {
                            showSearch(
                              context: context,
                              delegate: SearchLanguageDelegate(languages),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search languages',
                                style: PanAfricanTypography.bodyLarge(context),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: PanAfricanColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  loading: () => const AdaptiveProgressIndicator(
                    message: "Loading Languages ...",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    String? username,
    UserGamificationModel gamification,
  ) {
    final levelProgress = _getLevelProgress(gamification);
    final initials = _getInitials(username);

    return TopGradientBox(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final scaffoldState = ref.read(scaffoldKeyProvider).currentState;
                    if (scaffoldState != null) {
                      scaffoldState.openDrawer();
                    }
                  },
                  icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.onPrimary),
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title${username != null ? ', $username' : ''}',
                        style: PanAfricanTypography.displaySmall(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Text(
                        gamification.levelTitle,
                        style: PanAfricanTypography.bodyLarge(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                PanAfricanAvatar(
                  initials: initials,
                  size: PanAfricanSpacing.xl * 2,
                  showBadge: gamification.dailyStreak > 0,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            PanAfricanCard(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
              hasGlow: true,
              glowColor: PanAfricanColors.primaryLight,
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: PanAfricanSpacing.xl * 2.2,
                        height: PanAfricanSpacing.xl * 2.2,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: levelProgress,
                              strokeWidth: PanAfricanSpacing.xxs,
                              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${gamification.level}',
                                  style: PanAfricanTypography.titleLarge(context).copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                Text(
                                  'Level',
                                  style: PanAfricanTypography.labelSmall(context).copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'XP ${gamification.xp}',
                              style: PanAfricanTypography.titleMedium(context).copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              '${_getXPToNextLevel(gamification)} XP to next level',
                              style: PanAfricanTypography.bodySmall(context).copyWith(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.75),
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.sm),
                            PanAfricanProgressBar(
                              progress: levelProgress,
                              color: Theme.of(context).colorScheme.onPrimary,
                              height: PanAfricanSpacing.xxs,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Row(
                    children: [
                      _HeroPill(
                        label: '${gamification.dailyStreak} day streak',
                        icon: Icons.local_fire_department_rounded,
                        color: PanAfricanColors.tertiary,
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      _HeroPill(
                        label: '${gamification.unlockedBadges.length} badges',
                        icon: Icons.workspace_premium_rounded,
                        color: PanAfricanColors.secondary,
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      _HeroPill(
                        label: '${gamification.languagesLearned} languages',
                        icon: Icons.public_rounded,
                        color: PanAfricanColors.kenteBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'AI Tutor',
                  subtitle: 'Practice with Polie',
                  icon: Icons.auto_awesome_rounded,
                  color: PanAfricanColors.kenteBlue,
                  onTap: () {
                    ref.read(navigationProvider).navigateTo(const AiChatSelectScreen());
                  },
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  title: 'Progress',
                  subtitle: 'View dashboard',
                  icon: Icons.insights_rounded,
                  color: PanAfricanColors.primary,
                  onTap: () {
                    ref.read(navigationProvider).navigateTo(const ProgressDashboardScreen());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHighlights(
    BuildContext context,
    UserGamificationModel gamification,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _HighlightCard(
                  label: 'Lessons',
                  value: '${gamification.lessonsCompleted}',
                  icon: Icons.school_rounded,
                  color: PanAfricanColors.primary,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: _HighlightCard(
                  label: 'Words',
                  value: '${gamification.wordsLearned}',
                  icon: Icons.translate_rounded,
                  color: PanAfricanColors.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HighlightCard(
                  label: 'Games',
                  value: '${gamification.gamesPlayed}',
                  icon: Icons.videogame_asset_rounded,
                  color: PanAfricanColors.kenteTeal,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: _HighlightCard(
                  label: 'Polie',
                  value: '${gamification.polieMessages}',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: PanAfricanColors.ankaraPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getLevelProgress(UserGamificationModel gamification) {
    final currentLevel = gamification.level;
    final currentXP = gamification.xp;
    final currentLevelXP = LevelTitles.getXPForLevel(currentLevel);
    final nextLevelXP = LevelTitles.getXPForLevel(currentLevel + 1);
    final totalForLevel = (nextLevelXP - currentLevelXP).clamp(1, nextLevelXP);
    return ((currentXP - currentLevelXP) / totalForLevel).clamp(0.0, 1.0);
  }

  int _getXPToNextLevel(UserGamificationModel gamification) {
    final nextLevelXP = LevelTitles.getXPForLevel(gamification.level + 1);
    return (nextLevelXP - gamification.xp).clamp(0, nextLevelXP);
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'LA';
    }
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: PanAfricanSpacing.sm),
          SizedBox(width: PanAfricanSpacing.xxs),
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PanAfricanCard(
      hasHoverEffect: true,
      onTap: onTap,
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Icon(icon, color: color, size: PanAfricanSpacing.md),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleSmall(context),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  subtitle,
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HighlightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PanAfricanCard(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Icon(icon, color: color, size: PanAfricanSpacing.md),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            value,
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            label,
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: PanAfricanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageItem extends ConsumerWidget {
  final Language language;
  final Function? onTap;
  const LanguageItem({
    super.key,
    required this.language,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        onTap?.call();
        final result = ref.read(sharedPreferencesProvider).showLanguageIntro(language.id);
        if (result) {
          ref.read(navigationProvider).navigateTo(IntroductionScreen(language: language));
          return;
        }
        ref.read(navigationProvider).navigateTo(LanguageDetailScreen(language: language));
      },
      child: PanAfricanCard(
        padding: EdgeInsets.zero,
        hasHoverEffect: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: language.background ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: kErrorLogoWidget,
                placeholder: kImagePlaceHolder,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.scrim.withOpacity(0.15),
                      Theme.of(context).colorScheme.scrim.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: PanAfricanSpacing.sm,
                right: PanAfricanSpacing.sm,
                bottom: PanAfricanSpacing.sm,
                child: Text(
                  language.name,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
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