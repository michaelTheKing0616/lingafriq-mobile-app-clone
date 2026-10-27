import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../games/danfo_rush/danfo_rush_screen.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';

class TaxiSurvivalGame extends BaseGameScreen {
  const TaxiSurvivalGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.taxiBusStopSurvival;

  @override
  ConsumerState<TaxiSurvivalGame> createState() => _TaxiSurvivalGameState();
}

class _TaxiSurvivalGameState extends BaseGameScreenState<TaxiSurvivalGame> {
  /// Legacy shelf route → flagship Danfo / Matatu Rush (P8-923 / ADR-036).
  @override
  Widget build(BuildContext context) {
    return DanfoRushScreen(
      language: widget.language,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildGameContent(BuildContext context) => const SizedBox.shrink();
}
