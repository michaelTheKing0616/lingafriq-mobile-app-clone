import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/splash/splash_screen.dart';

// Route screen imports
import 'screens/ai_chat/ai_mode_selection_screen.dart';
import 'screens/curriculum/curriculum_screen.dart';
import 'screens/games/games_screen.dart';
import 'screens/goals/daily_goals_screen.dart';
import 'screens/progress/progress_dashboard_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/gamification/leaderboard_screen.dart';
import 'screens/social/tribe_vs_tribe_screen.dart';
import 'screens/social/language_villages_screen.dart';
import 'screens/chat/global_chat_screen.dart';
import 'screens/social/user_connections_screen.dart';
import 'screens/gamification/quest_screen.dart';
import 'screens/gamification/seasonal_events_screen.dart';
import 'screens/gamification/magic_items_screen.dart';
import 'screens/social/ancestral_tree_screen.dart';
import 'screens/magazine/culture_magazine_screen.dart';
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
import 'lessons/models/section_lesson_model.dart';
import 'models/language_response.dart';
import 'models/offline/local_vocabulary.dart';
import 'widgets/empty_state_widget.dart';

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
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: DynamicLocalizationService.getSupportedLanguages()
                  .map((lang) => Locale(lang.code)),
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
  final routes = <String, WidgetBuilder>{
    'ai_chat_select': (_) => const AIModeSelectionScreen(),
    'curriculum': (_) => const CurriculumScreen(),
    'games': (_) => const GamesScreen(),
    'daily_goals': (_) => const DailyGoalsScreen(),
    'progress': (_) => const ProgressDashboardScreen(),
    'achievements': (_) => const AchievementsScreen(),
    'badges': (_) => const AchievementsScreen(), // Badges tab within Achievements
    'leaderboard': (_) => const LeaderboardScreen(),
    'tribe': (_) => const TribeVsTribeScreen(), // No separate TribeScreen; reuse
    'tribe_vs_tribe': (_) => const TribeVsTribeScreen(),
    'villages': (_) => const LanguageVillagesScreen(),
    'global_chat': (_) => const GlobalChatScreen(),
    'connections': (_) => const UserConnectionsScreen(),
    'quest': (_) => const QuestScreen(),
    'events': (_) => const SeasonalEventsScreen(),
    'magic_items': (_) => const MagicItemsScreen(),
    'ancestral_tree': (_) => const AncestralTreeScreen(),
    'magazine': (_) => const CultureMagazineScreen(),
    'ugc': (_) => const UGCHubScreen(),
    'contribute_voice': (_) => const VoiceContributionScreen(),
    'import_media': (_) => const ImportMediaScreen(),
    'settings': (_) => const SettingsScreenMaterial3(),
    'features_guide': (_) => const FeaturesGuideScreen(),
    'policy': (_) => const AppPolicyScreen(),
    // Lesson Flow
    '/lesson-flow': (_) {
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
    '/grammar-hub': (_) => const GrammarHubScreen(),
    '/grammar-lesson': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['topic'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for GrammarLessonScreen')),
        );
      }
      return GrammarLessonScreen(topic: args['topic'] as GrammarTopic);
    },
    '/grammar-exercise': (_) {
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
    '/social-hub': (_) => const SocialHubScreen(),
    '/friend-profile': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['friendId'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for FriendProfileScreen')),
        );
      }
      return FriendProfileScreen(friendId: args['friendId'] as String);
    },
    '/challenge-friend': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      return ChallengeFriendScreen(friendId: args?['friendId'] as String?);
    },
    '/share-progress': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      return ShareProgressScreen(cardType: args?['cardType'] as String? ?? 'daily_streak');
    },
    // Content
    '/conversation-scenarios': (_) => const ConversationScenariosScreen(),
    '/cultural-hub': (_) => const CulturalHubScreen(),
    '/vocabulary-builder': (_) => const VocabularyBuilderScreen(),
    '/listening-practice': (_) => const ListeningPracticeScreen(),
    '/writing-practice': (_) => const WritingPracticeScreen(),
    // Learning Path
    '/learning-path': (_) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || args['language'] == null) {
        return const Scaffold(
          body: Center(child: Text('Missing required arguments for LearningPathScreen')),
        );
      }
      return LearningPathScreen(language: args['language'] as Language);
    },
    // Friend Quests
    '/friend-quests': (_) => const FriendQuestsScreen(),
    '/create-friend-quest': (_) => const CreateFriendQuestScreen(),
    // Auth
    '/email-verification': (_) {
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
    '/flashcard-review': (_) {
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
  };

  final builder = routes[settings.name];
  if (builder != null) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  // Fallback: "Coming Soon" placeholder for unknown routes
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(settings.name ?? 'Coming Soon')),
      body: const AppEmptyState(
        icon: Icons.construction_rounded,
        title: 'Coming Soon',
        subtitle: 'This feature is being built. We\'ll notify you when it\'s ready!',
      ),
    ),
  );
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
