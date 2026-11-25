import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/app_shell.dart';
import 'package:lingafriq/navigation/tab_routes.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';

class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

final tabIndexProvider = NotifierProvider.autoDispose<TabIndexNotifier, int>(
  () {
    return TabIndexNotifier();
  },
);

final scaffoldKeyProvider = Provider(((ref) => GlobalKey<ScaffoldState>()));

/// Five-tab shell. Me opens the drawer until Me destinations are wired.
class TabsView extends ConsumerStatefulWidget {
  const TabsView({super.key, this.initialLink});

  final String? initialLink;

  @override
  ConsumerState<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends ConsumerState<TabsView> {
  @override
  void initState() {
    super.initState();
    final String? link = widget.initialLink;
    if (link != null) {
      final ShellTab? tab = TabRoutes.resolve(link).tab;
      if (tab != null) {
        ref.read(tabIndexProvider.notifier).setIndex(tab.index);
      }
    }
    ref.read(firebaseMessagingProvider).initFCM();
  }

  @override
  Widget build(BuildContext context) {
    final int index = ref.watch(tabIndexProvider);
    final GlobalKey<ScaffoldState> scaffoldKey = ref.watch(scaffoldKeyProvider);
    return AppShell(
      index: index,
      initialLink: widget.initialLink,
      scaffoldKey: scaffoldKey,
      drawer: const AppDrawer(),
      onIndexChanged: (int value) {
        ref.read(tabIndexProvider.notifier).setIndex(value);
      },
      onMe: () => scaffoldKey.currentState?.openDrawer(),
      onSearch: () {
        Navigator.of(context).pushNamed('/living-dictionary');
      },
      onLens: () {
        Navigator.of(context).pushNamed('/import_media');
      },
    );
  }
}
