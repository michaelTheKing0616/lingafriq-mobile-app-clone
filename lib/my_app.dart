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
import 'widgets/empty_state_widget.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const _Unfocus({Key? key, required this.child}) : super(key: key);

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
