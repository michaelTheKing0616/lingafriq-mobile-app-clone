import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer_material3.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart' show languagesProvider;
import 'package:lingafriq/screens/tabs_view/courses/courses_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab_material3.dart';
import 'package:lingafriq/screens/dashboard/dashboard_screen_material3.dart';
import 'package:lingafriq/screens/chat/lingchat_ai_conversation_screen.dart';
import 'package:lingafriq/screens/social/language_villages_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';
import 'package:lingafriq/widgets/lingafriq_scaffold.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/screens/home_screen.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

// Re-export for consumers that imported from tabs_view_material3
export 'package:lingafriq/providers/tab_scaffold_provider.dart'
    show tabIndexProvider, scaffoldKeyProvider;

/// Beautiful Material 3 Tabs View with Pan-African Design
class TabsViewMaterial3 extends StatefulHookConsumerWidget {
  const TabsViewMaterial3({super.key});

  @override
  ConsumerState<TabsViewMaterial3> createState() => _TabsViewMaterial3State();
}

bool _autoDownloadTriggeredThisSession = false;

class _TabsViewMaterial3State extends ConsumerState<TabsViewMaterial3> {
  Widget _tabChildAt(int index) {
    switch (index) {
      case 0:
        return const DashboardScreenMaterial3();
      case 1:
        return const CoursesTabMaterial3();
      case 2:
        return const LearnerPolieScreen();
      case 3:
        return const LanguageVillagesScreen();
      case 4:
        return const ProfileTabMaterial3();
      default:
        return const DashboardScreenMaterial3();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseMessagingProvider).initFCM();
      _triggerAutoDownloadOnce();
    });
  }

  Future<void> _triggerAutoDownloadOnce() async {
    if (_autoDownloadTriggeredThisSession) return;
    final hasConnection = await ConnectivityService.hasInternet();
    if (!hasConnection) return;
    _autoDownloadTriggeredThisSession = true;
    final languageId = ref.read(curriculumProvider.notifier).selectedLanguage;
    if (languageId != null && languageId.isNotEmpty) {
      ref.read(offlineDownloadProvider.notifier).autoDownloadNextLessons(languageId, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(tabIndexProvider);
    final scaffoldKey = ref.watch(scaffoldKeyProvider);
    final socialBlocked = ref.watch(agePolicyProvider).maybeWhen(
          data: (p) => p.socialSurfacesBlocked,
          orElse: () => true,
        );
    final navIndex =
        socialBlocked ? _navBarIndexWhenSocialHidden(index) : index;

    return LingafriqScaffold(
      scaffoldKey: scaffoldKey,
      // Tab shells: each inner screen manages its own top safe area ([AppBar]/[ResponsiveSafeArea]);
      // avoid double-padding the whole subtree from the notch down.
      applyTopSafeArea: false,
      applyBottomSafeArea: false,
      drawer: const AppDrawerMaterial3(),
      body: OfflineIndicator(
        child: GamificationAvatarOverlay(
          // Gamification overlay shows Polie avatar that reacts to XP, levels, streaks
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(index),
              child: _tabChildAt(index),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _Material3BottomNavigationBar(
        currentIndex: navIndex,
        hideSocialTab: socialBlocked,
        onTap: (value) {
          final logicalIndex = socialBlocked
              ? _logicalTabIndexWhenSocialHidden(value)
              : value;
          // Refresh languages provider when tab is changed to courses tab
          // CRITICAL FIX: Only invalidate if not already loading/refreshing to prevent excessive API calls
          if (logicalIndex == 1) {
            final languagesAsync = ref.read(languagesProvider);
            // Only invalidate if data is not loading, not refreshing, and not in error state
            if (!languagesAsync.isLoading && 
                !languagesAsync.isRefreshing && 
                !languagesAsync.hasError) {
              ref.invalidate(languagesProvider);
            }
          }
          HapticFeedback.lightImpact();
          ref.read(tabIndexProvider.notifier).setIndex(logicalIndex);
        },
      ),
    );
  }
}

int _navBarIndexWhenSocialHidden(int logicalIndex) {
  if (logicalIndex <= 2) return logicalIndex;
  if (logicalIndex == kSocialTabIndex) return 0;
  return 3;
}

int _logicalTabIndexWhenSocialHidden(int navIndex) {
  if (navIndex <= 2) return navIndex;
  return 4;
}

class _Material3BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hideSocialTab;

  const _Material3BottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    this.hideSocialTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: true,
      left: false,
      right: false,
      maintainBottomViewPadding: true,
      minimum: EdgeInsets.zero,
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        destinations: [
          Semantics(
            label: l10nOf(context).shellHomeTab,
            button: true,
            child: NavigationDestination(
              icon: const Icon(PanAfricanIcons.home),
              selectedIcon: const Icon(PanAfricanIcons.homeSelected),
              label: l10nOf(context).shellHome,
            ),
          ),
          Semantics(
            label: l10nOf(context).shellCoursesTab,
            button: true,
            child: NavigationDestination(
              icon: const Icon(PanAfricanIcons.courses),
              selectedIcon: const Icon(PanAfricanIcons.coursesSelected),
              label: l10nOf(context).shellCourses,
            ),
          ),
          Semantics(
            label: l10nOf(context).shellAiTutorTab,
            button: true,
            child: NavigationDestination(
              icon: const Icon(PanAfricanIcons.ai),
              selectedIcon: const Icon(PanAfricanIcons.aiSelected),
              label: l10nOf(context).shellAi,
            ),
          ),
          if (!hideSocialTab)
            Semantics(
              label: l10nOf(context).shellSocialTab,
              button: true,
              child: NavigationDestination(
                icon: const Icon(PanAfricanIcons.social),
                selectedIcon: const Icon(PanAfricanIcons.socialSelected),
                label: l10nOf(context).shellSocial,
              ),
            ),
          Semantics(
            label: l10nOf(context).shellProfileTab,
            button: true,
            child: NavigationDestination(
              icon: const Icon(PanAfricanIcons.profile),
              selectedIcon: const Icon(PanAfricanIcons.profileSelected),
              label: l10nOf(context).shellProfile,
            ),
          ),
        ],
      ),
    );
  }
}

