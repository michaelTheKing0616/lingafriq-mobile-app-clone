import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/roleplay_progress_model.dart';
import 'package:lingafriq/screens/ai_chat/conversation_analytics_screen.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';

/// copy_keys: rev.rv_speak.*
///
/// One completed scenario. Words and corrections are the saved lines.
/// Accuracy, fluency, and points are not painted unless a real scorer
/// stored them on [RoleplaySessionResult.metadata].
class RoleplaySummaryStory {
  const RoleplaySummaryStory({
    required this.title,
    this.turns = 0,
    this.vocabulary = const <String>[],
    this.grammar = const <String>[],
    this.corrections = const <String>[],
    this.pronunciation,
    this.tone,
  });

  final String title;
  final int turns;
  final List<String> vocabulary;
  final List<String> grammar;
  final List<String> corrections;
  final GameScore? pronunciation;
  final GameScore? tone;
}

/// What [RoleplayCompletionSummaryScreen] should paint.
class RoleplaySummaryLoad {
  const RoleplaySummaryLoad._(this.status, this.story);

  const RoleplaySummaryLoad.ready(RoleplaySummaryStory story)
    : this._(SpeakInsightStatus.ready, story);

  const RoleplaySummaryLoad.empty() : this._(SpeakInsightStatus.empty, null);

  const RoleplaySummaryLoad.error() : this._(SpeakInsightStatus.error, null);

  const RoleplaySummaryLoad.offline()
    : this._(SpeakInsightStatus.offline, null);

  final SpeakInsightStatus status;
  final RoleplaySummaryStory? story;
}

List<String> _cleanLines(List<String> lines) {
  return <String>[
    for (final String line in lines)
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

bool roleplaySummaryHasBody(RoleplaySummaryStory story) {
  return story.title.trim().isNotEmpty ||
      story.turns > 0 ||
      story.vocabulary.isNotEmpty ||
      story.grammar.isNotEmpty ||
      story.corrections.isNotEmpty ||
      story.pronunciation != null ||
      story.tone != null;
}

/// Summary from a finished scenario. A score field alone is not a summary.
/// Pronunciation and tone come only from real-scorer metadata.
RoleplaySummaryStory? summaryFromResult(RoleplaySessionResult result) {
  final String named = (result.metadata['scenario_name'] ?? '')
      .toString()
      .trim();
  final String title = named.isEmpty ? result.scenarioId.trim() : named;
  final List<String> vocabulary = _cleanLines(result.vocabularyLearned);
  final List<String> grammar = _cleanLines(result.grammarPoints);
  final List<String> corrections = _cleanLines(result.corrections);
  final GameScore? pronunciation = scoreFromMetadata(
    result.metadata,
    'pronunciation',
  );
  final GameScore? tone = scoreFromMetadata(result.metadata, 'tone');
  final RoleplaySummaryStory story = RoleplaySummaryStory(
    title: title,
    turns: result.turnCount,
    vocabulary: vocabulary,
    grammar: grammar,
    corrections: corrections,
    pronunciation: pronunciation,
    tone: tone,
  );
  if (!roleplaySummaryHasBody(story)) return null;
  return story;
}

/// Scenario summary. No result shows [LingEmptyState].
/// A failed load shows [LingErrorState] and drops the summary that was on screen.
class RoleplayCompletionSummaryScreen extends StatefulWidget {
  const RoleplayCompletionSummaryScreen({
    super.key,
    this.result,
    this.language = '',
    this.languageName = '',
    this.onContinue,
    this.load,
  });

  /// App route `/speak/roleplay-summary`. The map key drops the leading slash.
  static const String routePath = '/speak/roleplay-summary';

  static const String routeKey = 'speak/roleplay-summary';

  static const Key emptyKey = ValueKey<String>('speak-summary-empty');

  static const Key errorKey = ValueKey<String>('speak-summary-error');

  static const Key offlineKey = ValueKey<String>('speak-summary-offline');

  static const Key storyKey = ValueKey<String>('speak-summary-story');

  static const Key scoreKey = ValueKey<String>('speak-summary-score');

  static const Key toneKey = ValueKey<String>('speak-summary-tone');

  static const Key unsureKey = ValueKey<String>('speak-summary-unsure');

  static const Key practiceKey = ValueKey<String>('speak-summary-practice');

  static const Key refreshKey = ValueKey<String>('speak-summary-refresh');

  static const Key backKey = ValueKey<String>('speak-summary-back');

  final RoleplaySessionResult? result;
  final String language;
  final String languageName;
  final VoidCallback? onContinue;

  /// Loads the summary. Null uses [result], or empty when [result] is null.
  final Future<RoleplaySummaryLoad> Function()? load;

  @override
  State<RoleplayCompletionSummaryScreen> createState() =>
      _RoleplayCompletionSummaryScreenState();
}

class _RoleplayCompletionSummaryScreenState
    extends State<RoleplayCompletionSummaryScreen> {
  SpeakInsightStatus _status = SpeakInsightStatus.loading;
  RoleplaySummaryStory? _story;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load != null) {
      _run(_generation);
      return;
    }
    _applyResult(widget.result);
  }

  @override
  void didUpdateWidget(RoleplayCompletionSummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        identical(oldWidget.result, widget.result)) {
      return;
    }
    _story = null;
    _generation += 1;
    if (widget.load != null) {
      _status = SpeakInsightStatus.loading;
      _run(_generation);
      return;
    }
    _applyResult(widget.result);
  }

  void _applyResult(RoleplaySessionResult? result) {
    if (result == null) {
      _status = SpeakInsightStatus.empty;
      _story = null;
      return;
    }
    final RoleplaySummaryStory? story = summaryFromResult(result);
    if (story == null) {
      _status = SpeakInsightStatus.empty;
      _story = null;
      return;
    }
    _status = SpeakInsightStatus.ready;
    _story = story;
  }

  Future<void> _run(int generation) async {
    final Future<RoleplaySummaryLoad> Function()? load = widget.load;
    if (load == null) {
      if (!mounted || generation != _generation) return;
      setState(() => _applyResult(widget.result));
      return;
    }
    try {
      final RoleplaySummaryLoad view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } on SpeakDataUnavailable catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _story = null;
        _status = error.offline
            ? SpeakInsightStatus.offline
            : SpeakInsightStatus.error;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _story = null;
        _status = SpeakInsightStatus.error;
      });
    }
  }

  void _apply(RoleplaySummaryLoad view) {
    final RoleplaySummaryStory? story = view.story;
    if (view.status == SpeakInsightStatus.ready &&
        story != null &&
        roleplaySummaryHasBody(story)) {
      _status = SpeakInsightStatus.ready;
      _story = story;
      return;
    }
    _story = null;
    if (view.status == SpeakInsightStatus.offline) {
      _status = SpeakInsightStatus.offline;
    } else if (view.status == SpeakInsightStatus.error ||
        view.status == SpeakInsightStatus.loading) {
      _status = SpeakInsightStatus.error;
    } else {
      _status = SpeakInsightStatus.empty;
    }
  }

  void _retry() {
    final Future<RoleplaySummaryLoad> Function()? load = widget.load;
    if (load == null) {
      setState(() => _applyResult(widget.result));
      return;
    }
    setState(() {
      _story = null;
      _status = SpeakInsightStatus.loading;
      _generation += 1;
    });
    _run(_generation);
  }

  void _back() {
    final VoidCallback? onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue();
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
              l10n.hubHSpeakRoleplaySummary,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            if (_status != SpeakInsightStatus.empty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: RoleplayCompletionSummaryScreen.backKey,
                label: l10n.hubHSpeakBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _back,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, LingPalette palette) {
    switch (_status) {
      case SpeakInsightStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case SpeakInsightStatus.empty:
        return LingEmptyState(
          key: RoleplayCompletionSummaryScreen.emptyKey,
          title: l10n.hubHSpeakRoleplaySummary,
          whatHappened: l10n.revRvSpeakSummaryEmptyWhat,
          why: l10n.revRvSpeakSummaryEmptyWhy,
          whatToDo: l10n.revRvSpeakSummaryEmptyNext,
          actionLabel: l10n.hubHSpeakBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case SpeakInsightStatus.error:
        return LingErrorState(
          key: RoleplayCompletionSummaryScreen.errorKey,
          whatHappened: l10n.revRvSpeakSummaryErrorWhat,
          why: l10n.revRvSpeakSummaryErrorWhy,
          whatToDo: l10n.revRvSpeakSummaryErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.offline:
        return LingOfflineState(
          key: RoleplayCompletionSummaryScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvSpeakSummaryOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.ready:
        final RoleplaySummaryStory? story = _story;
        if (story == null || !roleplaySummaryHasBody(story)) {
          return LingEmptyState(
            key: RoleplayCompletionSummaryScreen.emptyKey,
            title: l10n.hubHSpeakRoleplaySummary,
            whatHappened: l10n.revRvSpeakSummaryEmptyWhat,
            why: l10n.revRvSpeakSummaryEmptyWhy,
            whatToDo: l10n.revRvSpeakSummaryEmptyNext,
            actionLabel: l10n.hubHSpeakBack,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _back,
          );
        }
        return _storyBody(l10n, palette, story);
    }
  }

  Widget _storyBody(
    AppLocalizations l10n,
    LingPalette palette,
    RoleplaySummaryStory story,
  ) {
    return Column(
      key: RoleplayCompletionSummaryScreen.storyKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (story.title.trim().isNotEmpty) ...<Widget>[
          Text(
            story.title.trim(),
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
        ],
        if (story.turns > 0) ...<Widget>[
          Text(
            l10n.revRvSpeakTurnCount(story.turns),
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
        ],
        ..._lines(l10n.revRvSpeakVocabulary, story.vocabulary, palette),
        ..._lines(l10n.revRvSpeakGrammar, story.grammar, palette),
        ..._lines(l10n.revRvSpeakCorrections, story.corrections, palette),
        ...speakScoreLines(
          l10n: l10n,
          palette: palette,
          pronunciation: story.pronunciation,
          tone: story.tone,
          scoreKey: RoleplayCompletionSummaryScreen.scoreKey,
          toneKey: RoleplayCompletionSummaryScreen.toneKey,
          unsureKey: RoleplayCompletionSummaryScreen.unsureKey,
          practiceKey: RoleplayCompletionSummaryScreen.practiceKey,
        ),
        if (widget.load != null)
          LingButton(
            key: RoleplayCompletionSummaryScreen.refreshKey,
            label: l10n.revRvSpeakRefresh,
            unavailableLabel: l10n.commonStateUnavailable,
            onPressed: _retry,
          ),
      ],
    );
  }

  List<Widget> _lines(String heading, List<String> lines, LingPalette palette) {
    if (lines.isEmpty) return const <Widget>[];
    return <Widget>[
      Text(
        heading,
        style: lingBody(palette.onSurface),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      for (final String line in lines) ...<Widget>[
        Text(
          line,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
      ],
    ];
  }
}
