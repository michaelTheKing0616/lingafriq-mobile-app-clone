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
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:lingafriq/screens/social/language_villages_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';

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
        return const PolieModeSelectionScreen();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
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
        currentIndex: index,
        onTap: (value) {
          // Refresh languages provider when tab is changed to courses tab
          // CRITICAL FIX: Only invalidate if not already loading/refreshing to prevent excessive API calls
          if (value == 1) {
            final languagesAsync = ref.read(languagesProvider);
            // Only invalidate if data is not loading, not refreshing, and not in error state
            if (!languagesAsync.isLoading && 
                !languagesAsync.isRefreshing && 
                !languagesAsync.hasError) {
              ref.invalidate(languagesProvider);
            }
          }
          HapticFeedback.lightImpact();
          ref.read(tabIndexProvider.notifier).setIndex(value);
        },
      ),
    );
  }
}

class _Material3BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Material3BottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveSafeArea(
      top: false,
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
            label: 'Home tab',
            button: true,
            child: const NavigationDestination(
              icon: Icon(PanAfricanIcons.home),
              selectedIcon: Icon(PanAfricanIcons.homeSelected),
              label: 'Home',
            ),
          ),
          Semantics(
            label: 'Courses tab',
            button: true,
            child: const NavigationDestination(
              icon: Icon(PanAfricanIcons.courses),
              selectedIcon: Icon(PanAfricanIcons.coursesSelected),
              label: 'Courses',
            ),
          ),
          Semantics(
            label: 'AI Tutor tab',
            button: true,
            child: const NavigationDestination(
              icon: Icon(PanAfricanIcons.ai),
              selectedIcon: Icon(PanAfricanIcons.aiSelected),
              label: 'AI',
            ),
          ),
          Semantics(
            label: 'Social tab',
            button: true,
            child: const NavigationDestination(
              icon: Icon(PanAfricanIcons.social),
              selectedIcon: Icon(PanAfricanIcons.socialSelected),
              label: 'Social',
            ),
          ),
          Semantics(
            label: 'Profile tab',
            button: true,
            child: const NavigationDestination(
              icon: Icon(PanAfricanIcons.profile),
              selectedIcon: Icon(PanAfricanIcons.profileSelected),
              label: 'Profile',
            ),
          ),
        ],
      ),
    );
  }
}

