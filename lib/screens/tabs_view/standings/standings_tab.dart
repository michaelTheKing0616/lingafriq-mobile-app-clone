import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/standings/leader_board_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../../widgets/greegins_builder.dart';
import '../tabs_view.dart';
import 'country_tab.dart';
import 'global_tab.dart';

class StandingsTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final _tabIndexProvider = NotifierProvider<StandingsTabIndexNotifier, int>(StandingsTabIndexNotifier.new);

class StandingsTab extends HookConsumerWidget {
  const StandingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          TopGradientBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(scaffoldKeyProvider).currentState!.openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
                GreetingsBuilder(
                  pageTitle: "Leaderboard",
                  showGreeting: false,
                  trailing: Image.asset(
                    Images.goldBar,
                    alignment: Alignment.centerRight,
                    height: 0.1.sh,
                  ),
                ),
              ],
            ),
          ),
          4.heightBox,
          Consumer(
            builder: (context, ref, child) {
              final index = ref.watch(_tabIndexProvider);
              return Column(
                children: [
                  CupertinoSlidingSegmentedControl(
                    padding: const EdgeInsets.all(4),
                    groupValue: index == 0 ? "global" : "country",
                    children: {
                      "global": buildSegment("Global"),
                      "country": buildSegment("Country"),
                    },
                    onValueChanged: (value) {
                      final index = value == "global" ? 0 : 1;
                      ref.read(_tabIndexProvider.notifier).state = index;
                    },
                  ).py8(),
                  Expanded(child: child!), // Ensures proper layout
                ],
              );
            },
            child: const _StandingsBuilder(),
          ).expand(),
        ],
      ),
    );
  }

  Widget buildSegment(String text) {
    final space = (" " * 5);
    return Text(
      "$space$text$space",
      style: TextStyle(fontSize: 18.sp),
    ).p8();
  }
}

class _StandingsBuilder extends HookConsumerWidget {
  const _StandingsBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_tabIndexProvider);
    final profilesAsync = ref.watch(leaderboardProvider).profiles;
    final userCountry =
        ref.watch(userProvider.select((value) => value?.nationality)) ?? "";

    return profilesAsync.when(
      data: (profiles) {
        return IndexedStack(
          index: index,
          children: [
            GlobalTab(profiles: profiles),
            CountryTab(
              profiles: profiles
                  .where((e) =>
                      e.nationality.toLowerCase() == userCountry.toLowerCase())
                  .toList(),
            ),
          ],
        );
      },
      error: (e, s) {
        return StreamErrorWidget(
          error: e,
          onTryAgain: () {
            ref.invalidate(leaderboardProvider);
          },
        );
      },
      loading: () => const DynamicLoadingScreen(),
    );
  }
}
