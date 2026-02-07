import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/screens/tabs_view/courses/courses_tab.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/screens/tabs_view/standings/standings_tab.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
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

class TabsView extends StatefulHookConsumerWidget {
  const TabsView({Key? key}) : super(key: key);

  @override
  ConsumerState<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends ConsumerState<TabsView> {
  @override
  void initState() {
    ref.read(firebaseMessagingProvider).initFCM();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(tabIndexProvider);
    final scaffoldKey = ref.watch(scaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: OfflineIndicator(
        child: IndexedStack(
          index: index,
          children: const [
            HomeTab(),
            CoursesTab(),
            StandingsTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavigationBar(),
    );
  }
}

class _BottomNavigationBar extends HookConsumerWidget {
  const _BottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AnimatedBottomNavigationBar(
        gapLocation: GapLocation.none,
        backgroundColor: context.primaryColor,
        activeColor: context.isDarkMode ? Colors.black : PanAfricanColors.tertiary,
        inactiveColor: Colors.white54,
        splashColor: context.isDarkMode ? PanAfricanColors.primary : PanAfricanColors.tertiary,
        splashRadius: 30.sp,
        icons: const [
          Icons.home_rounded,
          Icons.folder_copy_rounded,
          Icons.bar_chart_rounded,
          Icons.person_rounded
        ],
        iconSize: 30.sp,
        activeIndex: index,
        onTap: (value) {
          //Refresh languages provider when tab is changed to courses tab
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
          // if (value == 2) {
          //   ref.invalidate(profilesProvider);
          // }
          HapticFeedback.lightImpact();
          ref.read(tabIndexProvider.notifier).setIndex(value);
        },
      ),
    );
  }
}
