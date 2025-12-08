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
import 'package:lingafriq/utils/haptic_feedback_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      body: IndexedStack(
        index: index,
        children: [
          const HomeTab().animate().fadeIn(duration: 200.ms),
          const CoursesTab().animate().fadeIn(duration: 200.ms),
          const StandingsTab().animate().fadeIn(duration: 200.ms),
          const ProfileTab().animate().fadeIn(duration: 200.ms),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: const _BottomNavigationBar(),
      ),
    );
  }
}

class _BottomNavigationBar extends HookConsumerWidget {
  const _BottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    final theme = Theme.of(context);
    
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) {
        //Refresh languages provider when tab is changed to courses tab
        if (value == 1) {
          ref.invalidate(languagesProvider);
        }
        HapticHelper.lightImpact();
        ref.read(tabIndexProvider.notifier).setIndex(value);
      },
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
