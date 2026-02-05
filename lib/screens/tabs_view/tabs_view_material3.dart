import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer_material3.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart' show languagesProvider;
import 'package:lingafriq/screens/tabs_view/courses/courses_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/standings/standings_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab_material3.dart';
import 'package:lingafriq/screens/dashboard/dashboard_screen_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

// Re-export for consumers that imported from tabs_view_material3
export 'package:lingafriq/providers/tab_scaffold_provider.dart'
    show tabIndexProvider, scaffoldKeyProvider;

/// Beautiful Material 3 Tabs View with Pan-African Design
class TabsViewMaterial3 extends StatefulHookConsumerWidget {
  const TabsViewMaterial3({super.key});

  @override
  ConsumerState<TabsViewMaterial3> createState() => _TabsViewMaterial3State();
}

class _TabsViewMaterial3State extends ConsumerState<TabsViewMaterial3> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseMessagingProvider).initFCM();
    });
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
        child: IndexedStack(
          index: index,
          children: const [
            DashboardScreenMaterial3(),
            CoursesTabMaterial3(),
            StandingsTabMaterial3(),
            ProfileTabMaterial3(),
          ],
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

    return ResponsiveSafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        indicatorColor: PanAfricanColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(PanAfricanIcons.home),
            selectedIcon: Icon(PanAfricanIcons.homeSelected),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PanAfricanIcons.courses),
            selectedIcon: Icon(PanAfricanIcons.coursesSelected),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(PanAfricanIcons.standings),
            selectedIcon: Icon(PanAfricanIcons.standingsSelected),
            label: 'Standings',
          ),
          NavigationDestination(
            icon: Icon(PanAfricanIcons.profile),
            selectedIcon: Icon(PanAfricanIcons.profileSelected),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

