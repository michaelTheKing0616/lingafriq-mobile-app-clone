import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/components/ling_button.dart';
import '../../design/components/ling_state.dart';
import '../../design/states/empty_state.dart';
import '../../design/states/error_state.dart';
import '../../design/states/offline_state.dart';
import '../../design/tokens.g.dart';
import '../../games/gamekit/game_result.dart';
import '../../games/gamekit/game_scoring.dart';
import '../../games/tone_forge/tone_forge_scoring.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n_of.dart';
import 'game_mastery_map_screen.dart';

/// A load that failed because the phone is offline, or for another reason.
class MasteryResultsUnavailable implements Exception {
  const MasteryResultsUnavailable({this.offline = false});

  final bool offline;
}

/// What the results page is showing.
enum MasteryPageStatus { loading, empty, error, offline, scored, unsure }

/// Percent across turns that each came from the real scorer.
///
/// One unsure, unavailable, or local turn drops the number.
int? masteryShownPercent(GameMasteryResultsPayload payload) {
  if (payload.practiceNotScored) return null;
  final turns = payload.session.turns;
  if (turns.isEmpty) return null;
  var sum = 0;
  for (final turn in turns) {
    final int? percent = toneForgeShownPercent(turn.score);
    if (percent == null) return null;
    sum += percent;
  }
  return (sum / turns.length).round();
}

/// Standard post-game results for GameKit sessions.
///
/// With no payload and no loader, the page is empty. A failed load clears the
/// previous percent. A number is painted only when the real scorer returned it.
class GameMasteryResultsScreen extends StatefulWidget {
  const GameMasteryResultsScreen({
    super.key,
    this.payload,
    this.onDone,
    this.load,
  });

  const GameMasteryResultsScreen.play({super.key, this.load, this.onDone})
    : payload = null;

  /// App route `/play/mastery-results`. The map key drops the leading slash.
  static const String routePath = '/play/mastery-results';

  static const String routeKey = 'play/mastery-results';

  static const Key emptyKey = ValueKey<String>('play-mastery-empty');

  static const Key errorKey = ValueKey<String>('play-mastery-error');

  static const Key offlineKey = ValueKey<String>('play-mastery-offline');

  static const Key scoreKey = ValueKey<String>('play-mastery-score');

  static const Key unsureKey = ValueKey<String>('play-mastery-unsure');

  final GameMasteryResultsPayload? payload;
  final VoidCallback? onDone;

  /// Loads one result. Null means this open has no round.
  final Future<GameScore?> Function()? load;

  @override
  State<GameMasteryResultsScreen> createState() =>
      _GameMasteryResultsScreenState();
}

class _GameMasteryResultsScreenState extends State<GameMasteryResultsScreen> {
  MasteryPageStatus _status = MasteryPageStatus.empty;
  int? _percent;
  bool _scoreFault = false;
  GameMasteryResultsPayload? _payload;

  @override
  void initState() {
    super.initState();
    if (widget.load != null) {
      _status = MasteryPageStatus.loading;
      _run(initial: true);
      return;
    }
    _applyPayload(widget.payload);
  }

  @override
  void didUpdateWidget(GameMasteryResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        identical(oldWidget.payload, widget.payload)) {
      return;
    }
    _percent = null;
    _payload = null;
    _scoreFault = false;
    if (widget.load != null) {
      _status = MasteryPageStatus.loading;
      _run();
      return;
    }
    _applyPayload(widget.payload);
  }

  void _applyPayload(GameMasteryResultsPayload? payload) {
    if (payload == null ||
        (payload.session.turns.isEmpty && payload.skillDeltas.isEmpty)) {
      _status = MasteryPageStatus.empty;
      _percent = null;
      _payload = null;
      _scoreFault = false;
      return;
    }
    final int? percent = masteryShownPercent(payload);
    if (percent != null) {
      _status = MasteryPageStatus.scored;
      _percent = percent;
      _payload = payload;
      _scoreFault = false;
      return;
    }
    _status = MasteryPageStatus.unsure;
    _percent = null;
    _payload = null;
    _scoreFault = false;
  }

  Future<void> _run({bool initial = false}) async {
    final Future<GameScore?> Function()? load = widget.load;
    if (load == null) {
      if (!mounted) return;
      setState(() => _applyPayload(widget.payload));
      return;
    }
    if (!initial) {
      setState(() {
        _status = MasteryPageStatus.loading;
        _percent = null;
        _payload = null;
        _scoreFault = false;
      });
    }
    try {
      final GameScore? score = await load();
      if (!mounted) return;
      if (score == null) {
        setState(() => _applyPayload(null));
        return;
      }
      final int? percent = toneForgeShownPercent(score);
      setState(() {
        _payload = null;
        _scoreFault = false;
        if (percent != null &&
            toneForgeScoreView(score) == ToneForgeScoreView.scored) {
          _status = MasteryPageStatus.scored;
          _percent = percent;
          return;
        }
        _percent = null;
        _status = MasteryPageStatus.unsure;
      });
    } on MasteryResultsUnavailable catch (error) {
      if (!mounted) return;
      setState(() {
        _percent = null;
        _payload = null;
        _scoreFault = false;
        _status = error.offline
            ? MasteryPageStatus.offline
            : MasteryPageStatus.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _percent = null;
        _payload = null;
        _scoreFault = true;
        _status = MasteryPageStatus.error;
      });
    }
  }

  void _done() {
    final VoidCallback? onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool backInEmpty = _status == MasteryPageStatus.empty;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.revRvPlayMasteryTitle,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            if (_status == MasteryPageStatus.scored &&
                _payload != null &&
                _payload!.skillDeltas.isNotEmpty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.gamesGameMasteryResultsSkillsHeading,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              for (final GameMasterySkillDelta delta in _payload!.skillDeltas)
                _SkillDeltaRow(delta: delta, l10n: l10n),
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.gamesMasteryMapTitle,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameMasteryMapScreen(
                        learnerId: _payload!.session.userId,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (!backInEmpty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.hubHPlayBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _done,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, LingPalette palette) {
    switch (_status) {
      case MasteryPageStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case MasteryPageStatus.empty:
        return LingEmptyState(
          key: GameMasteryResultsScreen.emptyKey,
          title: l10n.revRvPlayMasteryTitle,
          whatHappened: l10n.revRvPlayMasteryEmptyWhat,
          why: l10n.revRvPlayMasteryEmptyWhy,
          whatToDo: l10n.revRvPlayMasteryEmptyNext,
          actionLabel: l10n.hubHPlayBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _done,
        );
      case MasteryPageStatus.error:
        return LingErrorState(
          key: GameMasteryResultsScreen.errorKey,
          whatHappened: _scoreFault
              ? l10n.revRvPlayMasteryScoreErrorWhat
              : l10n.revRvPlayMasteryErrorWhat,
          why: _scoreFault
              ? l10n.revRvPlayMasteryScoreErrorWhy
              : l10n.revRvPlayMasteryErrorWhy,
          whatToDo: l10n.revRvPlayErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _run,
        );
      case MasteryPageStatus.offline:
        return LingOfflineState(
          key: GameMasteryResultsScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvPlayMasteryOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _run,
        );
      case MasteryPageStatus.scored:
        final int? percent = _percent;
        if (percent == null) return _unsure(l10n, palette);
        final String value = l10n.revRvPlayScoreValue(percent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.revRvPlayScoreLabel,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Semantics(
              container: true,
              label: value,
              child: Text(
                value,
                key: GameMasteryResultsScreen.scoreKey,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        );
      case MasteryPageStatus.unsure:
        return _unsure(l10n, palette);
    }
  }

  Widget _unsure(AppLocalizations l10n, LingPalette palette) {
    return Text(
      l10n.revRvPlayUnsure,
      key: GameMasteryResultsScreen.unsureKey,
      style: lingBody(palette.onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}

class _SkillDeltaRow extends StatelessWidget {
  const _SkillDeltaRow({required this.delta, required this.l10n});

  final GameMasterySkillDelta delta;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String changeLabel = switch (delta.changeKind) {
      GameMasteryChangeKind.improved => l10n.gamesGameMasteryResultsImproved,
      GameMasteryChangeKind.declined => l10n.gamesGameMasteryResultsDeclined,
      GameMasteryChangeKind.noChange => l10n.gamesGameMasteryResultsNoChange,
    };
    final String name = delta.skillId.replaceAll('_', ' ');
    return Semantics(
      container: true,
      label: name,
      child: Padding(
        padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            Text(
              changeLabel,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
