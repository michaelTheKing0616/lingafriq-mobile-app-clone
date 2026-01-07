import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/standings/leader_board_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/utils.dart';
import 'country_tab.dart';
import 'global_tab.dart';

class StandingsTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final _tabIndexProvider = NotifierProvider<StandingsTabIndexNotifier, int>(
  StandingsTabIndexNotifier.new,
);

/// Beautiful Material 3 Standings Tab with Pan-African Design
class StandingsTabMaterial3 extends HookConsumerWidget {
  const StandingsTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final index = ref.watch(_tabIndexProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Pan-African App Bar
              PanAfricanAppBar(
                title: 'Leaderboard',
                showBackButton: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () {
                      ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                    },
                    tooltip: 'Menu',
                  ),
                  Image.asset(
                    Images.goldBar,
                    height: 0.1.sh,
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Material 3 Segmented Button
                      Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(
                              value: 0,
                              label: Text('Global'),
                            ),
                            ButtonSegment<int>(
                              value: 1,
                              label: Text('Country'),
                            ),
                          ],
                          selected: {index},
                          onSelectionChanged: (Set<int> newSelection) {
                            ref.read(_tabIndexProvider.notifier).state =
                                newSelection.first;
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: PanAfricanColors.primary,
                            selectedForegroundColor: Colors.white,
                            backgroundColor: isDark
                                ? PanAfricanColors.surfaceContainerDark
                                : PanAfricanColors.surfaceContainerLight,
                            foregroundColor: isDark
                                ? PanAfricanColors.textPrimaryDark
                                : PanAfricanColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Expanded(
                        child: const _StandingsBuilder(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingsBuilder extends HookConsumerWidget {
  const _StandingsBuilder({super.key});

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
        return Center(
          child: StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(leaderboardProvider);
            },
          ),
        );
      },
      loading: () => const AdaptiveProgressIndicator(
        message: "Loading Leaderboard...",
      ),
    );
  }
}

