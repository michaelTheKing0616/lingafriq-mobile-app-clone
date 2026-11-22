import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/daily_challenge_model.dart';
import 'package:lingafriq/providers/daily_challenges_provider.dart';

/// Daily challenge board.
///
/// With no loader, the page is empty. A failed load clears any rows that
/// were on screen. This screen does not create a challenge list.
class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key, this.load, this.onBack});

  /// App route that reads challenges already saved on the phone.
  const DailyChallengesScreen.saved({super.key, this.onBack})
    : load = loadSavedDailyChallenges;

  /// App route `/today/daily-challenges`. The map key drops the leading slash.
  static const String routePath = '/today/daily-challenges';

  static const String routeKey = 'today/daily-challenges';

  static const Key emptyKey = ValueKey<String>('today-daily-challenges-empty');

  static const Key errorKey = ValueKey<String>('today-daily-challenges-error');

  static const Key offlineKey = ValueKey<String>(
    'today-daily-challenges-offline',
  );

  static const Key listKey = ValueKey<String>('today-daily-challenges-list');

  static const Key backKey = ValueKey<String>('today-daily-challenges-back');

  static Key challengeKey(String id) => ValueKey<String>('today-challenge-$id');

  /// Loads the board. Null means there is nothing saved to show.
  final Future<DailyChallengeBoard> Function()? load;

  final VoidCallback? onBack;

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  DailyChallengeBoardStatus _status = DailyChallengeBoardStatus.loading;
  List<DailyChallenge> _rows = const <DailyChallenge>[];

  @override
  void initState() {
    super.initState();
    if (widget.load == null) {
      _status = DailyChallengeBoardStatus.empty;
      _rows = const <DailyChallenge>[];
      return;
    }
    _status = DailyChallengeBoardStatus.loading;
    _rows = const <DailyChallenge>[];
    _run();
  }

  @override
  void didUpdateWidget(DailyChallengesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.load, widget.load)) {
      _rows = const <DailyChallenge>[];
      if (widget.load == null) {
        _status = DailyChallengeBoardStatus.empty;
        return;
      }
      _status = DailyChallengeBoardStatus.loading;
      _run();
    }
  }

  Future<void> _run() async {
    final Future<DailyChallengeBoard> Function()? load = widget.load;
    if (load == null) {
      if (!mounted) return;
      setState(() {
        _status = DailyChallengeBoardStatus.empty;
        _rows = const <DailyChallenge>[];
      });
      return;
    }
    try {
      final DailyChallengeBoard board = await load();
      if (!mounted) return;
      setState(() => _apply(board));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = DailyChallengeBoardStatus.error;
        _rows = const <DailyChallenge>[];
      });
    }
  }

  void _apply(DailyChallengeBoard board) {
    final List<DailyChallenge> rows = <DailyChallenge>[
      for (final DailyChallenge row in board.challenges)
        if (row.title.trim().isNotEmpty) row,
    ];
    if (board.status == DailyChallengeBoardStatus.ready && rows.isNotEmpty) {
      _status = DailyChallengeBoardStatus.ready;
      _rows = List<DailyChallenge>.unmodifiable(rows);
      return;
    }
    _rows = const <DailyChallenge>[];
    if (board.status == DailyChallengeBoardStatus.offline) {
      _status = DailyChallengeBoardStatus.offline;
    } else if (board.status == DailyChallengeBoardStatus.error ||
        board.status == DailyChallengeBoardStatus.loading) {
      _status = DailyChallengeBoardStatus.error;
    } else {
      _status = DailyChallengeBoardStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _status = DailyChallengeBoardStatus.loading;
      _rows = const <DailyChallenge>[];
    });
    _run();
  }

  void _back() {
    final VoidCallback? onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.hubTodayDailyChallenges,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              key: DailyChallengesScreen.backKey,
              label: l10n.hubTodayBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: _back,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, LingPalette palette) {
    switch (_status) {
      case DailyChallengeBoardStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case DailyChallengeBoardStatus.empty:
        return LingEmptyState(
          key: DailyChallengesScreen.emptyKey,
          title: l10n.hubTodayDailyChallenges,
          whatHappened: l10n.revRvTodayChallengesEmptyWhat,
          why: l10n.revRvTodayChallengesEmptyWhy,
          whatToDo: l10n.revRvTodayChallengesEmptyNext,
          actionLabel: l10n.hubTodayBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case DailyChallengeBoardStatus.error:
        return LingErrorState(
          key: DailyChallengesScreen.errorKey,
          whatHappened: l10n.revRvTodayChallengesErrorWhat,
          why: l10n.revRvTodayChallengesErrorWhy,
          whatToDo: l10n.revRvTodayChallengesErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case DailyChallengeBoardStatus.offline:
        return LingOfflineState(
          key: DailyChallengesScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvTodayChallengesOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case DailyChallengeBoardStatus.ready:
        return Column(
          key: DailyChallengesScreen.listKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final DailyChallenge row in _rows) ...<Widget>[
              _card(l10n, palette, row),
              const SizedBox(height: LingAfriqTokens.spacing12),
            ],
          ],
        );
    }
  }

  Widget _card(AppLocalizations l10n, LingPalette palette, DailyChallenge row) {
    final String description = row.description.trim();
    return Semantics(
      container: true,
      label: row.title,
      child: DecoratedBox(
        key: DailyChallengesScreen.challengeKey(row.id),
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                row.title,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing8),
                Text(
                  description,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
              const SizedBox(height: LingAfriqTokens.spacing8),
              Text(
                l10n.revRvTodayChallengesProgress(row.progress, row.target),
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
