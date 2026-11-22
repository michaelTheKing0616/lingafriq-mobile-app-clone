import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/gamekit/game_session.dart' as gamekit;
import 'package:lingafriq/games/learning_game_adapter.dart';
import 'package:lingafriq/games/minimal_pair_duel/minimal_pair_duel_screen.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/games/word_forge/word_forge_screen.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_router.dart';

/// Where a plan item is played. Play itself uses [playGameWidget].
enum PracticeOrigin { today, path }

/// Kind of row on a Today or Path plan.
enum PracticePlanItemType { game, lesson, review, speaking, culture }

/// One row from a Today or Path plan. A game row carries the Play game id.
class PracticePlanItem {
  const PracticePlanItem({
    required this.id,
    required this.type,
    this.gameId,
    this.itemIds = const <String>[],
  });

  final String id;
  final PracticePlanItemType type;
  final String? gameId;
  final List<String> itemIds;
}

/// Finder keys for the practice game states.
abstract final class PracticeGameMarks {
  static const Key playing = ValueKey<String>('practice-game-default');
  static const Key saving = ValueKey<String>('practice-game-saving');
  static const Key saveFailed = ValueKey<String>('practice-game-save-failed');
  static const Key saved = ValueKey<String>('practice-game-saved');
}

/// Game id Play's arcade uses, after alias lookup. Empty when Play has no game.
String? canonicalPlayGameId(String gameId) {
  final String trimmed = gameId.trim();
  if (trimmed.isEmpty) return null;
  final GameDefinition? definition = AllGamesRegistry.getGame(trimmed);
  if (definition != null) return definition.gameId;
  return AllGamesRegistry.listingFor(trimmed)?.gameId;
}

/// The GameKit screen Play opens for [gameId].
///
/// The branches match the arcade opener: Tone Forge, Word Forge for Grammar
/// Jam, Minimal Pair Duel, then [buildGameScreen] for a routed catalogue game.
/// A game Play does not open is null here too.
Widget? playGameWidget({
  required String gameId,
  required String language,
  VoidCallback? onBack,
}) {
  final String? id = canonicalPlayGameId(gameId);
  if (id == null) return null;
  if (id == AllGamesRegistry.toneForgeGameId) {
    return ToneForgeScreen(language: language, onBack: onBack);
  }
  if (id == GameType.grammarJam.name) {
    return WordForgeScreen(language: language, onBack: onBack);
  }
  if (id == AllGamesRegistry.minimalPairDuelGameId) {
    return MinimalPairDuelScreen(language: language, onBack: onBack);
  }
  final GameType? gameType = AllGamesRegistry.listingFor(id)?.routeGameType;
  if (gameType == null) return null;
  return PlayRoutedGame(gameType: gameType, language: language, onBack: onBack);
}

/// Catalogue game Play builds with [buildGameScreen].
class PlayRoutedGame extends ConsumerWidget {
  const PlayRoutedGame({
    super.key,
    required this.gameType,
    required this.language,
    this.onBack,
  });

  final GameType gameType;
  final String language;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buildGameScreen(
      gameType: gameType,
      language: language,
      onBack: onBack,
      ref: ref,
    );
  }
}

/// Opens [item] from Today or Path on the same GameKit screen as Play.
///
/// A row that is not a game, or a game Play does not open, returns null.
PracticeGameHost? openPracticeGame({
  required PracticePlanItem item,
  required PracticeOrigin origin,
  required String language,
  required PracticeOutboxEnqueue enqueue,
  required String clientEventId,
  gamekit.GameSession? endedSession,
  VoidCallback? onBack,
}) {
  if (item.type != PracticePlanItemType.game) return null;
  final String gameId = item.gameId?.trim() ?? '';
  if (gameId.isEmpty) return null;
  final Widget? game = playGameWidget(
    gameId: gameId,
    language: language,
    onBack: onBack,
  );
  if (game == null) return null;
  return PracticeGameHost(
    game: game,
    item: item,
    origin: origin,
    enqueue: enqueue,
    clientEventId: clientEventId,
    endedSession: endedSession,
  );
}

enum _PracticePhase { playing, saving, failed, saved }

/// Host for a practice game. When [endedSession] is set, the round has ended
/// and the host writes one learner-model event. A failed write stays on the
/// retry state and does not show a save.
class PracticeGameHost extends StatefulWidget {
  const PracticeGameHost({
    super.key,
    required this.game,
    required this.item,
    required this.origin,
    required this.enqueue,
    required this.clientEventId,
    this.endedSession,
  });

  final Widget game;
  final PracticePlanItem item;
  final PracticeOrigin origin;
  final PracticeOutboxEnqueue enqueue;
  final String clientEventId;
  final gamekit.GameSession? endedSession;

  @override
  State<PracticeGameHost> createState() => _PracticeGameHostState();
}

class _PracticeGameHostState extends State<PracticeGameHost> {
  late _PracticePhase _phase;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phase = widget.endedSession == null
        ? _PracticePhase.playing
        : _PracticePhase.saving;
    if (widget.endedSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _save();
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    if (mounted) setState(() => _phase = _PracticePhase.saving);
    final gamekit.GameSession? session = widget.endedSession;
    PracticeOutboxSave save = const PracticeOutboxSave(saved: false);
    if (session != null) {
      final PracticeLearnerEvent? event = practiceLearnerEventFromSession(
        session: session,
        clientEventId: widget.clientEventId,
        planItemId: widget.item.id,
        planItemIds: widget.item.itemIds,
        origin: widget.origin.name,
      );
      if (event != null) {
        save = await writePracticeLearnerEvent(
          event: event,
          enqueue: widget.enqueue,
        );
      }
    }
    _saving = false;
    if (!mounted) return;
    setState(() {
      _phase = save.saved ? _PracticePhase.saved : _PracticePhase.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final l10n = l10nOf(context);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: switch (_phase) {
          _PracticePhase.playing => KeyedSubtree(
            key: PracticeGameMarks.playing,
            child: Semantics(
              label: l10n.practiceGamePlayingLabel,
              child: widget.game,
            ),
          ),
          _PracticePhase.saving => Semantics(
            key: PracticeGameMarks.saving,
            label: l10n.loading,
            child: const SizedBox.expand(),
          ),
          _PracticePhase.failed => ListView(
            key: PracticeGameMarks.saveFailed,
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.practiceGameSaveFailedWhat,
                child: LingErrorState(
                  whatHappened: l10n.practiceGameSaveFailedWhat,
                  why: l10n.practiceGameSaveFailedWhy,
                  whatToDo: l10n.practiceGameSaveFailedNext,
                  actionLabel: l10n.practiceGameRetry,
                  unavailableLabel: l10n.practiceGameUnavailable,
                  onAction: _save,
                ),
              ),
            ],
          ),
          _PracticePhase.saved => ListView(
            key: PracticeGameMarks.saved,
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              Semantics(
                container: true,
                label: l10n.practiceGameSaved,
                child: Text(
                  l10n.practiceGameSaved,
                  style: lingBody(palette.onSurface),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
