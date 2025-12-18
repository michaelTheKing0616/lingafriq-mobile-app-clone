import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/standings/leader_board_provider.dart';
import 'package:lingafriq/utils/utils.dart';

import '../../../models/profile_model.dart';
import 'standing_item.dart';

class GlobalTab extends ConsumerWidget {
  final List<ProfileModel> profiles;
  const GlobalTab({
    Key? key,
    required this.profiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore =
        ref.watch(leaderboardProvider.select((value) => value.isLoadingMore));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(leaderboardProvider);
        return ref.read(leaderboardProvider.notifier).getProfiles();
      },
      child: Column(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              if (index % 5 == 0 && !isLoadingMore) {
                scheduleMicrotask(() {
                  ref.read(leaderboardProvider.notifier).getNextbatch();
                });
              }
              final profile = profiles[index];
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
