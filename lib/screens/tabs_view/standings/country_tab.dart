import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/standings/standing_item.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/info_widget.dart';

import '../../../models/profile_model.dart';
import 'leader_board_provider.dart';

class CountryTab extends ConsumerWidget {
  final List<ProfileModel> profiles;
  const CountryTab({
    Key? key,
    required this.profiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(leaderboardProvider.select((value) => value.isLoadingMore));
    if (profiles.isEmpty) {
      return const InfoWidget(
        text: 'No points earned yet',
        subText: 'Start a course to see your country ranking',
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(leaderboardProvider);
        return ref.read(leaderboardProvider.notifier).getProfiles();
      },
      child: Column(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              if (index % 5 == 0 && !isLoadingMore) {
                scheduleMicrotask(() {
                  ref.read(leaderboardProvider.notifier).getNextbatch();
                });
              }
              return StandingItem(profile: profile, index: index);
            },
          ).expand(),
          // if (isLoadingMore) ...[
          //   const LinearProgressIndicator().px24()
          //   // const CircularProgressIndicator().p8(),
          // ],
        ],
      ),
    );
  }
}
