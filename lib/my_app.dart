import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

import 'app_theme.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/splash/splash_screen.dart';

// Route screen imports
import 'screens/ai_chat/ai_mode_selection_screen.dart';
import 'screens/ai_chat/polie_mode_selection_screen.dart';
import 'screens/curriculum/curriculum_screen_material3.dart';
import 'screens/games/games_screen_material3.dart';
import 'screens/goals/daily_goals_screen.dart';
import 'screens/progress/progress_dashboard_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/gamification/leaderboard_screen.dart';
import 'screens/social/tribe_vs_tribe_screen.dart';
import 'screens/gamification/tribe_selection_screen.dart';
import 'screens/social/language_villages_screen.dart';
import 'screens/village/villages_hub_screen.dart';
import 'screens/village/swahili_village_map_screen.dart';
import 'screens/village/village_market_screen.dart';
import 'screens/village/village_cafe_screen.dart';
import 'screens/village/elder_hut_screen.dart';
import 'screens/village/practice_room_setup_screen.dart';
import 'screens/village/practice_session_screen.dart';
import 'screens/village/practice_room_collaborative_screen.dart';
import 'screens/village/session_summary_screen.dart';
import 'screens/village/flashcard_focus_screen.dart';
import 'screens/village/matching_pairs_screen.dart';
import 'screens/village/tonal_lesson_screen.dart';
import 'screens/village/tribe_hub_screen.dart';
import 'screens/village/tribe_discovery_screen.dart';
import 'screens/village/my_tribe_screen.dart';
import 'screens/village/tribal_duel_screen.dart';
import 'screens/village/inter_tribe_leaderboard_screen.dart';
import 'screens/chat/global_chat_screen_material3.dart';
import 'screens/social/user_connections_screen.dart';
import 'screens/gamification/quest_screen.dart';
import 'screens/gamification/seasonal_events_screen.dart';
import 'screens/gamification/magic_items_screen.dart';
import 'screens/social/ancestral_tree_screen.dart';
import 'screens/magazine/culture_magazine_screen_enhanced.dart';
import 'screens/heritage/flb_heritage_archive_screen.dart';
import 'screens/heritage/flb_heritage_detail_screen.dart';
import 'screens/ugc/ugc_hub_screen.dart';
import 'screens/voice_contribution/voice_contribution_screen.dart';
import 'screens/media/import_media_screen.dart';
import 'screens/settings/settings_screen_material3.dart';
import 'screens/help/features_guide_screen.dart';
import 'screens/tabs_view/profile/app_policy_screen.dart';
import 'screens/lesson/lesson_flow_screen.dart';
import 'screens/grammar/grammar_hub_screen.dart' show GrammarHubScreen, GrammarTopic;
import 'screens/grammar/grammar_lesson_screen.dart';
import 'screens/grammar/grammar_exercise_screen.dart';
import 'screens/social/social_hub_screen.dart';
import 'screens/social/friend_profile_screen.dart';
import 'screens/social/challenge_friend_screen.dart';
import 'screens/social/share_progress_screen.dart';
import 'screens/content/conversation_scenarios_screen.dart';
import 'screens/content/cultural_hub_screen.dart';
import 'screens/content/vocabulary_builder_screen.dart';
import 'screens/content/listening_practice_screen.dart';
import 'screens/content/writing_practice_screen.dart';
import 'screens/learning/learning_path_screen.dart';
import 'screens/social/friend_quests_screen.dart';
import 'screens/social/create_friend_quest_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/vocabulary/flashcard_review_screen.dart';
import 'screens/vocabulary/vocabulary_screen.dart';
import 'screens/wa/wa_status_list_screen.dart';
import 'screens/wa/wa_status_create_screen.dart';
import 'screens/wa/wa_status_view_screen.dart';
import 'screens/wa/wa_starred_messages_screen.dart';
import 'screens/wa/wa_media_gallery_screen.dart';
import 'screens/snap/snap_inbox_screen.dart';
import 'screens/snap/snap_story_feed_screen.dart';
import 'screens/snap/snap_camera_screen.dart';
import 'screens/snap/snap_streaks_screen.dart';
import 'screens/snap/snap_viewer_screen.dart';
import 'screens/feed/x_compose_screen.dart';
import 'screens/feed/x_explore_screen.dart';
import 'screens/feed/x_feed_home_screen.dart';
import 'screens/feed/x_lists_screen.dart';
import 'x_feed_notifications_screen.dart';
import 'screens/feed/x_post_detail_screen.dart';
import 'screens/feed/x_profile_screen.dart';
import 'screens/personalities/personality_selection_screen.dart';
import 'lessons/models/section_lesson_model.dart';
import 'models/language_response.dart';
import 'models/offline/local_vocabulary.dart';
import 'widgets/empty_state_widget.dart';

/// Union of ARB-backed locales and [DynamicLocalizationService] codes so
/// `locale` and `AppLocalizations` stay consistent.
List<Locale> _mergedAppLocales() {
  final byCode = <String, Locale>{};
  for (final l in AppLocalizations.supportedLocales) {
    byCode[l.languageCode] = l;
  }
  for (final lang in DynamicLocalizationService.getSupportedLanguages()) {
    byCode.putIfAbsent(lang.code, () => Locale(lang.code));
  }
  return byCode.values.toList();
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final navigatorKey = ref.watch(navigationProvider).navigatorKey;
    final themeMode = ref.watch(themeModeProvider);
    // Listen to locale changes to trigger UI rebuild
    final localeNotifier = DynamicLocalizationService.localeNotifier;
    
    return ScreenUtilInit(
      designSize: const Size(428, 926),
      minTextAdapt: true,
      child: const SplashScreen(),
      builder: (context, child) {
        // Watch locale changes to rebuild when language changes
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              locale: currentLocale,
              // AppLocalizations bundles intl + Material/Cupertino/Widgets delegates.
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: _mergedAppLocales(),
              localeResolutionCallback: (locale, supportedLocales) {
                // Use DynamicLocalizationService to resolve locale
                if (locale != null) {
                  final languageCode = locale.languageCode.toLowerCase();
                  final supported = DynamicLocalizationService.getSupportedLanguages()
                      .firstWhere(
                        (lang) => lang.code == languageCode,
                        orElse: () => DynamicLocalizationService.currentLanguage,
                      );
                  return Locale(supported.code);
                }
                return DynamicLocalizationService.currentLocale;
              },
              builder: (context, child) {
                ScreenUtil.init(context, designSize: const Size(428, 926));
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                    // Support edge-to-edge display
                    padding: EdgeInsets.zero,
                  ),
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: context.isDarkMode ? Brightness.light : Brightness.dark,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarIconBrightness: context.isDarkMode ? Brightness.light : Brightness.dark,
                    ),
                    child: _Unfocus(child: child),
                  ),
                );
              },
              onGenerateRoute: _onGenerateRoute,
              home: child,
            );
          },
        );
      },
    );
  }
}

/// Route name -> Screen widget mapping for drawer navigation.
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final normalizedRoute = _normalizeRouteName(settings.name);
  final routes = <String, WidgetBuilder>{
    'ai_chat_select': (_) => const AIModeSelectionScreen(),
    'polie_mode_selection': (_) => const PolieModeSelectionScreen(),
    'curriculum': (_) => const CurriculumScreenMaterial3(),
    'games': (_) => const GamesScreenMaterial3(),
    'daily_goals': (_) => const DailyGoalsScreen(),
    'progress': (_) => const ProgressDashboardScreen(),
    'achievements': (_) => const AchievementsScreen(),
    'badges': (_) => const AchievementsScreen(), // Badges tab within Achievements
    'leaderboard': (_) => const LeaderboardScreen(),
    'tribe': (_) => const TribeVsTribeScreen(), // No separate TribeScreen; reuse
    'tribe_vs_tribe': (_) => const TribeVsTribeScreen(),
    'tribe-selection': (_) => const TribeSelectionScreen(),
    'tribe_selection': (_) => const TribeSelectionScreen(),
    'villages': (_) => const VillagesHubScreen(),
    'villages-hub': (_) => const VillagesHubScreen(),
    'language-village': (_) => const LanguageVillagesScreen(),
    'swahili-village-map': (_) => const SwahiliVillageMapScreen(),
    'village-market': (_) => const VillageMarketScreen(),
    'village-cafe': (_) => const VillageCafeScreen(),
    'elder-hut': (_) => const ElderHutScreen(),
    'practice-room-setup': (_) => const PracticeRoomSetupScreen(),
    'practice-session': (_) => const PracticeSessionScreen(),
    'practice-room-collaborative': (_) =>
        const PracticeRoomCollaborativeScreen(),
    'session-summary': (_) => const SessionSummaryScreen(),
    'flashcard-focus': (_) => const FlashcardFocusScreen(),
    'matching-pairs': (_) => const MatchingPairsScreen(),
    'tonal-lesson': (_) => const TonalLessonScreen(),
    'tribe-hub': (_) => const TribeHubScreen(),
    'tribe-discovery': (_) => const TribeDiscoveryScreen(),
    'my-tribe': (_) => const MyTribeScreen(),
    'tribal-duel': (_) => const TribalDuelScreen(),
    'inter-tribe-leaderboard': (_) => const InterTribeLeaderboardScreen(),
    'global_chat': (_) => const GlobalChatScreenMaterial3(),
    'connections': (_) => const UserConnectionsScreen(),
    'quest': (_) => const QuestScreen(),
    'events': (_) => const SeasonalEventsScreen(),
    'magic_items': (_) => const MagicItemsScreen(),
    'ancestral_tree': (_) => const AncestralTreeScreen(),
    'magazine': (_) => const CultureMagazineScreenEnhanced(),
    'flb-heritage-archive': (_) => const FlbHeritageArchiveScreen(),
    'flb-heritage-detail': (ctx) {
      final content = heritageDetailFromArguments(settings.arguments);
      if (content == null) {
        return Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(ctx)!.flbHeritageMissingContent),
          ),
        );
      }
      return FlbHeritageDetailScreen(content: content);
    },
    'ugc': (_) => const UGCHubScreen(),
    'contribute_voice': (_) => const VoiceContributionScreen(),
    'import_media': (_) => const ImportMediaScreen(),
    'settings': (_) => const SettingsScreenMaterial3(),
    'features_guide': (_) => const FeaturesGuideScreen(),
    'policy': (_) => const AppPolicyScreen(),
    // Lesson Flow
    'lesson-flow': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['lessonId'] == null || args['sectionLessons'] == null || args['lessonTitle'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for LessonFlowScreen')),
        );
      }
      return LessonFlowScreen(
        lessonId: args['lessonId'] as int,
        sectionLessons: args['sectionLessons'] as List<SectionLessonModel>,
        lessonTitle: args['lessonTitle'] as String,
      );
    },
    // Grammar
    'grammar-hub': (_) => const GrammarHubScreen(),
    'grammar-lesson': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['topic'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for GrammarLessonScreen')),
        );
      }
      return GrammarLessonScreen(topic: args['topic'] as GrammarTopic);
    },
    'grammar-exercise': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['topicId'] == null || args['topicName'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for GrammarExerciseScreen')),
        );
      }
      return GrammarExerciseScreen(
        topicId: args['topicId'] as String,
        topicName: args['topicName'] as String,
      );
    },
    // Social
    'social-hub': (_) => const SocialHubScreen(),
    'friend-profile': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['friendId'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for FriendProfileScreen')),
        );
      }
      return FriendProfileScreen(friendId: args['friendId'] as String);
    },
    'challenge-friend': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      return ChallengeFriendScreen(friendId: args?['friendId'] as String?);
    },
    'share-progress': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      return ShareProgressScreen(cardType: args?['cardType'] as String? ?? 'daily_streak');
    },
    // Content
    'conversation-scenarios': (_) => const ConversationScenariosScreen(),
    'cultural-hub': (_) => const CulturalHubScreen(),
    'vocabulary-builder': (_) => const VocabularyBuilderScreen(),
    'listening-practice': (_) => const ListeningPracticeScreen(),
    'writing-practice': (_) => const WritingPracticeScreen(),
    // Learning Path
    'learning-path': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['language'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for LearningPathScreen')),
        );
      }
      return LearningPathScreen(language: args['language'] as Language);
    },
    // Friend Quests
    'friend-quests': (_) => const FriendQuestsScreen(),
    'create-friend-quest': (_) => const CreateFriendQuestScreen(),
    // Auth
    'email-verification': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['email'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for EmailVerificationScreen')),
        );
      }
      return EmailVerificationScreen(
        email: args['email'] as String,
        firstName: args['firstName'] as String?,
      );
    },
    // Vocabulary
    'my-vocabulary': (_) => const VocabularyScreen(),
    'flashcard-review': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['words'] == null || args['language'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for FlashcardReviewScreen')),
        );
      }
      return FlashcardReviewScreen(
        words: args['words'] as List<LocalVocabulary>,
        language: args['language'] as String,
      );
    },
    // WhatsApp upgrade screens
    'wa-status': (_) => const WaStatusListScreen(),
    'wa-status-create': (_) => const WaStatusCreateScreen(),
    'wa-status-view': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      final statusId = args?['statusId']?.toString();
      if (statusId == null || statusId.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for WaStatusViewScreen')),
        );
      }
      return WaStatusViewScreen(statusId: statusId);
    },
    'wa-starred': (_) => const WaStarredMessagesScreen(),
    'wa-media-gallery': (_) => const WaMediaGalleryScreen(),
    // Snapchat upgrade screens
    'snap-inbox': (_) => const SnapInboxScreen(),
    'snap-story-feed': (_) => const SnapStoryFeedScreen(),
    'snap-camera': (_) => const SnapCameraScreen(),
    'snap-streaks': (_) => const SnapStreaksScreen(),
    'snap-viewer': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      final snapId = args?['snapId']?.toString();
      final storyId = args?['storyId']?.toString();
      if ((snapId == null || snapId.isEmpty) && (storyId == null || storyId.isEmpty)) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for SnapViewerScreen')),
        );
      }
      return SnapViewerScreen(
        snapId: (snapId != null && snapId.isNotEmpty) ? snapId : null,
        storyId: (storyId != null && storyId.isNotEmpty) ? storyId : null,
      );
    },
    // X feed upgrade screens
    'x-feed-home': (_) => const XFeedHomeScreen(),
    'x-compose': (_) => const XComposeScreen(),
    'x-post-detail': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      final postId = args?['postId']?.toString();
      if (postId == null || postId.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for XPostDetailScreen')),
        );
      }
      return XPostDetailScreen(postId: postId);
    },
    'x-notifications': (_) => const XNotificationsScreen(),
    'x-explore': (_) => const XExploreScreen(),
    'x-lists': (_) => const XListsScreen(),
    'x-profile': (_) => const XProfileScreen(),
    'historical-personas': (_) => const PersonalitySelectionScreen(),
  };

  final builder = routes[normalizedRoute];
  if (builder != null) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  // Fallback screen for unknown routes
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(settings.name ?? 'Feature Unavailable')),
      body: const AppEmptyState(
        icon: Icons.construction_rounded,
        title: 'Feature Unavailable',
        subtitle: 'This route is not available in this build.',
      ),
    ),
  );
}

String _normalizeRouteName(String? routeName) {
  if (routeName == null || routeName.isEmpty) return '';
  return routeName.startsWith('/') ? routeName.substring(1) : routeName;
}

class _Unfocus extends StatelessWidget {
  const _Unfocus({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
