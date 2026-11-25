import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/game/game_session_model.dart';
import '../../screens/games/base_game_screen.dart';
import 'proverb_unlocker_catalog.dart';
import 'proverb_unlocker_feedback.dart';

/// GameKit proverb unlocker. The played round comes from [dealProverbUnlocker].
class ProverbUnlockerScreen extends BaseGameScreen {
  const ProverbUnlockerScreen({
    super.key,
    required super.language,
    super.level,
    super.onBack,
    this.seed,
  });

  /// When set, this seed is the only source of shuffle and blank choice.
  final int? seed;

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerScreen> createState() =>
      _ProverbUnlockerScreenState();
}

class _ProverbUnlockerScreenState
    extends BaseGameScreenState<ProverbUnlockerScreen> {
  int _round = 0;
  String? _selected;

  int get _seed =>
      widget.seed ?? proverbUnlockerStableSeed(widget.language, widget.level);

  @override
  bool get requiresPhraseCards => false;

  @override
  int getCardCount() => 6;

  @override
  Widget build(BuildContext context) {
    final deal = dealProverbUnlocker(
      seed: _seed,
      language: widget.language,
      roundIndex: _round,
    );
    final selected = _selected;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Text(deal.proverb.original, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(deal.proverb.translation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final option in deal.options)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: selected == null
                      ? () => setState(() => _selected = option)
                      : null,
                  child: Text(option),
                ),
              ),
            if (selected != null) ...[
              const SizedBox(height: 16),
              Text(
                proverbChoiceFeedback(
                  correct: selected == deal.correctAnswer,
                  meaning: deal.correctAnswer,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _round += 1;
                      _selected = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget buildGameContent(BuildContext context) => const SizedBox.shrink();
}
