import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer_material3.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart' show HomeTabMaterial3, languagesProvider;
import 'package:lingafriq/screens/tabs_view/courses/courses_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/standings/standings_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';

class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

final tabIndexProvider =
    NotifierProvider.autoDispose<TabIndexNotifier, int>(() {
  return TabIndexNotifier();
});

final scaffoldKeyProvider = Provider(((ref) => GlobalKey<ScaffoldState>()));

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
            HomeTabMaterial3(),
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

    return NavigationBar(
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
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_copy_outlined),
          selectedIcon: Icon(Icons.folder_copy_rounded),
          label: 'Courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Standings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

