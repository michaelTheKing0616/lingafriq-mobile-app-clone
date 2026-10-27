import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/game/game_session_model.dart';
import '../../screens/games/base_game_screen.dart';
import '../proverb_weaver/proverb_weaver_screen.dart';

/// GameKit shelf route → flagship Proverb Weaver (P8-924 / ADR-036).
class ProverbUnlockerScreen extends BaseGameScreen {
  const ProverbUnlockerScreen({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerScreen> createState() =>
      _ProverbUnlockerScreenState();
}

class _ProverbUnlockerScreenState
    extends BaseGameScreenState<ProverbUnlockerScreen> {
  @override
  Widget build(BuildContext context) {
    return ProverbWeaverScreen(
      language: widget.language,
      learnerLevel: widget.level,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildGameContent(BuildContext context) => const SizedBox.shrink();
}
