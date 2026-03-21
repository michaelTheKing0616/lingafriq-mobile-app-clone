import '../base_game_screen.dart';
import '../shell_labels.dart';

/// Maps common multi-round cultural game fields to [GameTemplateShell] chips
/// via [BaseGameScreenState] shell getters.
mixin RoundProgressGameShellMixin<T extends BaseGameScreen> on BaseGameScreenState<T> {
  int get gameRound;
  int get gameMaxRounds;
  int get gameScore;

  @override
  String? get shellProgressLabel => roundProgressLabelForRound(
        currentRound: gameRound,
        maxRounds: gameMaxRounds,
      );

  @override
  String? get shellScoreLabel => shellScorePointsLabel(gameScore);
}
