import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/models/profiles_response.dart';
import 'package:lingafriq/providers/api_provider.dart';

class LeaderboardState {
  final AsyncValue<List<ProfileModel>> profiles;
  final bool isLoadingMore;

  LeaderboardState({
    required this.profiles,
    this.isLoadingMore = false,
  });

  LeaderboardState copyWith({
    AsyncValue<List<ProfileModel>>? profiles,
    bool? isLoadingMore,
  }) {
    return LeaderboardState(
      profiles: profiles ?? this.profiles,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final leaderboardProvider = NotifierProvider.autoDispose<LeaderBoardProvider, LeaderboardState>(() {
  return LeaderBoardProvider();
});

class LeaderBoardProvider extends Notifier<LeaderboardState> {
  MainResult? lastResult;

  @override
  LeaderboardState build() {
    getProfiles();
    return LeaderboardState(profiles: const AsyncValue.loading());
  }

  Future<void> getProfiles() async {
    try {
      state = state.copyWith(profiles: const AsyncValue.loading());
      final res = await ref.read(apiProvider.notifier).getProfilesResponse();
      lastResult = res.result;
      state = state.copyWith(
        profiles: AsyncValue.data(res.result.results),
        isLoadingMore: false,
      );
    } catch (e, s) {
      state = state.copyWith(profiles: AsyncValue.error(e, s));
    }
  }

  Future<void> getNextbatch() async {
    if (state.isLoadingMore) return;
    if (lastResult?.next == null) return;
    try {
      state = state.copyWith(isLoadingMore: true);
      final res = await ref.read(apiProvider.notifier).getProfilesResponse(lastResult!.next);
      lastResult = res.result;
      final old = state.profiles.value ?? <ProfileModel>[];
      final newProfile = res.result.results;
      state = state.copyWith(
        profiles: AsyncValue.data(<ProfileModel>{...old, ...newProfile}.toList()),
        isLoadingMore: false,
      );
    } catch (e, s) {
      state = state.copyWith(
        profiles: AsyncValue.error(e, s),
        isLoadingMore: false,
      );
    }
  }
}
