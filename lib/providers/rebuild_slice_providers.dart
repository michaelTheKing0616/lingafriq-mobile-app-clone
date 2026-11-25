import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/hearts_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';

/// Narrow slices for high-traffic screens — prefer these over watching whole notifiers.

final apiLoadingProvider = Provider<bool>(
  (ref) => ref.watch(apiProvider.select((BaseProviderState s) => s.isLoading)),
);

final authLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authProvider.select((BaseProviderState s) => s.isLoading)),
);

final gamificationCowriesProvider = Provider<int>(
  (ref) => ref.watch(
    gamificationProvider.select((s) => s.gamification.cowries),
  ),
);

final gamificationDailyStreakProvider = Provider<int>(
  (ref) => ref.watch(
    gamificationProvider.select((s) => s.gamification.dailyStreak),
  ),
);

final gamificationXpProvider = Provider<int>(
  (ref) => ref.watch(
    gamificationProvider.select((s) => s.gamification.xp),
  ),
);

final gamificationLevelProvider = Provider<int>(
  (ref) => ref.watch(
    gamificationProvider.select((s) => s.gamification.level),
  ),
);

final heartsCountProvider = Provider<int>(
  (ref) => ref.watch(heartsProvider.select((s) => s.currentHearts)),
);

final heartsApplyProvider = Provider<bool>(
  (ref) => ref.watch(heartsProvider.select((s) => s.heartsApply)),
);

final userProfileProvider = Provider<ProfileModel?>(
  (ref) => ref.watch(userProvider),
);

final userStreakProvider = Provider<int>(
  (ref) => ref.watch(userProvider.select((u) => u?.streak ?? 0)),
);

final userLearningLanguageProvider = Provider<String?>(
  (ref) => ref.watch(userProvider.select((u) => u?.learningLanguage)),
);

final tabIndexSliceProvider = Provider<int>(
  (ref) => ref.watch(tabIndexProvider),
);
