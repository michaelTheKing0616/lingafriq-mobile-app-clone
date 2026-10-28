import 'package:lingafriq/models/game_streak.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_snapshots.dart';

/// Immutable gamification view state so [Provider.select] can avoid rebuild storms.
class GamificationState extends BaseProviderState {
  GamificationState({
    super.isLoading = false,
    super.errorMessage,
    super.errorTimestamp,
    UserGamificationModel? gamification,
    this.serverBalanceError,
    this.circleQuest,
    this.familyPhrase,
    this.heritageTree,
    this.streakCadence = StreakCadence.daily,
    this.practiceDaysThisWeek = const [],
    this.streakBrokenAt,
    this.streakBeforeBreak = 0,
    this.shopCatalog = const [],
    this.shopCatalogLoading = false,
  }) : gamification = gamification ?? UserGamificationModel();

  final UserGamificationModel gamification;
  final String? serverBalanceError;
  final CircleQuestSnapshot? circleQuest;
  final FamilyPhraseSnapshot? familyPhrase;
  final HeritageTreeSnapshot? heritageTree;
  final StreakCadence streakCadence;
  final List<String> practiceDaysThisWeek;
  final DateTime? streakBrokenAt;
  final int streakBeforeBreak;
  final List<CowriesShopItem> shopCatalog;
  final bool shopCatalogLoading;

  @override
  GamificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? errorTimestamp,
    bool clearError = false,
    UserGamificationModel? gamification,
    String? serverBalanceError,
    bool clearServerBalanceError = false,
    CircleQuestSnapshot? circleQuest,
    FamilyPhraseSnapshot? familyPhrase,
    HeritageTreeSnapshot? heritageTree,
    StreakCadence? streakCadence,
    List<String>? practiceDaysThisWeek,
    DateTime? streakBrokenAt,
    bool clearStreakBrokenAt = false,
    int? streakBeforeBreak,
    List<CowriesShopItem>? shopCatalog,
    bool? shopCatalogLoading,
  }) {
    return GamificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorTimestamp:
          clearError ? null : (errorTimestamp ?? this.errorTimestamp),
      gamification: gamification ?? this.gamification,
      serverBalanceError: clearServerBalanceError
          ? null
          : (serverBalanceError ?? this.serverBalanceError),
      circleQuest: circleQuest ?? this.circleQuest,
      familyPhrase: familyPhrase ?? this.familyPhrase,
      heritageTree: heritageTree ?? this.heritageTree,
      streakCadence: streakCadence ?? this.streakCadence,
      practiceDaysThisWeek: practiceDaysThisWeek ?? this.practiceDaysThisWeek,
      streakBrokenAt: clearStreakBrokenAt
          ? null
          : (streakBrokenAt ?? this.streakBrokenAt),
      streakBeforeBreak: streakBeforeBreak ?? this.streakBeforeBreak,
      shopCatalog: shopCatalog ?? this.shopCatalog,
      shopCatalogLoading: shopCatalogLoading ?? this.shopCatalogLoading,
    );
  }
}
