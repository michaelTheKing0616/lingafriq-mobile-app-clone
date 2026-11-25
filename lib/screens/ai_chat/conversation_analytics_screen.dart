import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/conversation_analytics_model.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';

/// copy_keys: rev.rv_speak.*
///
/// Saved conversation story for one language. Counts come from stored
/// sessions. A pronunciation or tone percent is painted only by [speakScoreLines].
class CoachInsightStory {
  const CoachInsightStory({
    required this.languageName,
    this.sessions = 0,
    this.messages = 0,
    this.words = 0,
    this.topics = const <String>[],
    this.pronunciation,
    this.tone,
  });

  final String languageName;
  final int sessions;
  final int messages;
  final int words;
  final List<String> topics;
  final GameScore? pronunciation;
  final GameScore? tone;
}

/// What [ConversationAnalyticsScreen] should paint.
class CoachInsightLoad {
  const CoachInsightLoad._(this.status, this.story);

  const CoachInsightLoad.ready(CoachInsightStory story)
    : this._(SpeakInsightStatus.ready, story);

  const CoachInsightLoad.empty() : this._(SpeakInsightStatus.empty, null);

  const CoachInsightLoad.error() : this._(SpeakInsightStatus.error, null);

  const CoachInsightLoad.offline() : this._(SpeakInsightStatus.offline, null);

  final SpeakInsightStatus status;
  final CoachInsightStory? story;
}

/// Story from saved sessions. An empty session list is null.
/// Fluency stored without a real scorer is not copied onto the story.
CoachInsightStory? storyFromAnalytics(ConversationAnalytics analytics) {
  if (analytics.sessions.isEmpty) return null;
  var sessions = 0;
  var messages = 0;
  var words = 0;
  final List<String> topics = <String>[];
  GameScore? pronunciation;
  GameScore? tone;
  for (final ConversationSession session in analytics.sessions) {
    sessions += 1;
    if (session.messageCount > 0) messages += session.messageCount;
    if (session.wordCount > 0) words += session.wordCount;
    for (final String topic in session.topics) {
      final String trimmed = topic.trim();
      if (trimmed.isEmpty || topics.contains(trimmed)) continue;
      topics.add(trimmed);
    }
    pronunciation ??= scoreFromMetadata(session.metadata, 'pronunciation');
    tone ??= scoreFromMetadata(session.metadata, 'tone');
  }
  if (sessions == 0 &&
      messages == 0 &&
      words == 0 &&
      topics.isEmpty &&
      pronunciation == null &&
      tone == null) {
    return null;
  }
  return CoachInsightStory(
    languageName: analytics.language,
    sessions: sessions,
    messages: messages,
    words: words,
    topics: topics,
    pronunciation: pronunciation,
    tone: tone,
  );
}

bool coachStoryHasBody(CoachInsightStory story) {
  return story.sessions > 0 ||
      story.messages > 0 ||
      story.words > 0 ||
      story.topics.isNotEmpty ||
      story.pronunciation != null ||
      story.tone != null;
}

/// Coach insights. No saved conversation shows [LingEmptyState].
/// A failed load shows [LingErrorState] and drops the story that was on screen.
/// A percent is painted only when [shownScorerPercent] has one.
class ConversationAnalyticsScreen extends StatefulWidget {
  const ConversationAnalyticsScreen({
    super.key,
    this.language = '',
    this.languageName = '',
    this.load,
  });

  /// App route `/speak/coach-insights`. The map key drops the leading slash.
  static const String routePath = '/speak/coach-insights';

  static const String routeKey = 'speak/coach-insights';

  static const Key emptyKey = ValueKey<String>('speak-coach-empty');

  static const Key errorKey = ValueKey<String>('speak-coach-error');

  static const Key offlineKey = ValueKey<String>('speak-coach-offline');

  static const Key storyKey = ValueKey<String>('speak-coach-story');

  static const Key scoreKey = ValueKey<String>('speak-coach-score');

  static const Key toneKey = ValueKey<String>('speak-coach-tone');

  static const Key unsureKey = ValueKey<String>('speak-coach-unsure');

  static const Key practiceKey = ValueKey<String>('speak-coach-practice');

  static const Key refreshKey = ValueKey<String>('speak-coach-refresh');

  static const Key backKey = ValueKey<String>('speak-coach-back');

  final String language;
  final String languageName;

  /// Loads the story. Null with no language means there is nothing saved.
  final Future<CoachInsightLoad> Function()? load;

  @override
  State<ConversationAnalyticsScreen> createState() =>
      _ConversationAnalyticsScreenState();
}

class _ConversationAnalyticsScreenState
    extends State<ConversationAnalyticsScreen> {
  SpeakInsightStatus _status = SpeakInsightStatus.loading;
  CoachInsightStory? _story;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null && _languageKey().isEmpty) {
      _status = SpeakInsightStatus.empty;
      return;
    }
    _run(_generation);
  }

  @override
  void didUpdateWidget(ConversationAnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.language == widget.language &&
        oldWidget.languageName == widget.languageName) {
      return;
    }
    _story = null;
    _generation += 1;
    if (widget.load == null && _languageKey().isEmpty) {
      _status = SpeakInsightStatus.empty;
      return;
    }
    _status = SpeakInsightStatus.loading;
    _run(_generation);
  }

  String _languageKey() {
    final String name = widget.languageName.trim();
    if (name.isNotEmpty) return name;
    return widget.language.trim();
  }

  Future<void> _run(int generation) async {
    final Future<CoachInsightLoad> Function() load = widget.load ?? _loadNamed;
    try {
      final CoachInsightLoad view = await load();
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

  Future<CoachInsightLoad> _loadNamed() async {
    final String name = _languageKey();
    if (name.isEmpty) return const CoachInsightLoad.empty();
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final ConversationAnalyticsService service = container.read(
      conversationAnalyticsServiceProvider,
    );
    final ConversationAnalytics? stored = await service.readStored(name);
    if (stored == null) return const CoachInsightLoad.empty();
    final CoachInsightStory? story = storyFromAnalytics(stored);
    if (story == null || !coachStoryHasBody(story)) {
      return const CoachInsightLoad.empty();
    }
    return CoachInsightLoad.ready(story);
  }

  void _apply(CoachInsightLoad view) {
    final CoachInsightStory? story = view.story;
    if (view.status == SpeakInsightStatus.ready &&
        story != null &&
        coachStoryHasBody(story)) {
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
    setState(() {
      _story = null;
      _status = SpeakInsightStatus.loading;
      _generation += 1;
    });
    _run(_generation);
  }

  void _back() {
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
              l10n.hubHSpeakCoach,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            if (_status != SpeakInsightStatus.empty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: ConversationAnalyticsScreen.backKey,
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
          key: ConversationAnalyticsScreen.emptyKey,
          title: l10n.hubHSpeakCoach,
          whatHappened: l10n.revRvSpeakCoachEmptyWhat,
          why: l10n.revRvSpeakCoachEmptyWhy,
          whatToDo: l10n.revRvSpeakCoachEmptyNext,
          actionLabel: l10n.hubHSpeakBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case SpeakInsightStatus.error:
        return LingErrorState(
          key: ConversationAnalyticsScreen.errorKey,
          whatHappened: l10n.revRvSpeakCoachErrorWhat,
          why: l10n.revRvSpeakCoachErrorWhy,
          whatToDo: l10n.revRvSpeakCoachErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.offline:
        return LingOfflineState(
          key: ConversationAnalyticsScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvSpeakCoachOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.ready:
        final CoachInsightStory? story = _story;
        if (story == null || !coachStoryHasBody(story)) {
          return LingEmptyState(
            key: ConversationAnalyticsScreen.emptyKey,
            title: l10n.hubHSpeakCoach,
            whatHappened: l10n.revRvSpeakCoachEmptyWhat,
            why: l10n.revRvSpeakCoachEmptyWhy,
            whatToDo: l10n.revRvSpeakCoachEmptyNext,
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
    CoachInsightStory story,
  ) {
    final List<Widget> lines = <Widget>[
      for (final Widget line in _countLines(l10n, palette, story)) line,
      if (story.topics.isNotEmpty) ...<Widget>[
        Text(
          l10n.revRvSpeakTopics,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        for (final String topic in story.topics) ...<Widget>[
          Text(
            topic,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
        ],
      ],
      ...speakScoreLines(
        l10n: l10n,
        palette: palette,
        pronunciation: story.pronunciation,
        tone: story.tone,
        scoreKey: ConversationAnalyticsScreen.scoreKey,
        toneKey: ConversationAnalyticsScreen.toneKey,
        unsureKey: ConversationAnalyticsScreen.unsureKey,
        practiceKey: ConversationAnalyticsScreen.practiceKey,
      ),
      LingButton(
        key: ConversationAnalyticsScreen.refreshKey,
        label: l10n.revRvSpeakRefresh,
        unavailableLabel: l10n.commonStateUnavailable,
        onPressed: _retry,
      ),
    ];
    return Column(
      key: ConversationAnalyticsScreen.storyKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines,
    );
  }

  List<Widget> _countLines(
    AppLocalizations l10n,
    LingPalette palette,
    CoachInsightStory story,
  ) {
    final List<String> lines = <String>[
      if (story.sessions > 0) l10n.revRvSpeakSessionCount(story.sessions),
      if (story.messages > 0) l10n.revRvSpeakMessageCount(story.messages),
      if (story.words > 0) l10n.revRvSpeakWordCount(story.words),
    ];
    return <Widget>[
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

/// Pronunciation and tone lines. A number is included only for a real scorer.
List<Widget> speakScoreLines({
  required AppLocalizations l10n,
  required LingPalette palette,
  required GameScore? pronunciation,
  required GameScore? tone,
  required Key scoreKey,
  required Key toneKey,
  required Key unsureKey,
  required Key practiceKey,
}) {
  final List<Widget> numbers = <Widget>[];
  var unsure = false;
  var practice = false;
  void consider(GameScore? score, String label, Key key) {
    final ScorerReadout readout = scorerReadout(score);
    switch (readout.kind) {
      case ScorerReadoutKind.number:
        final int? percent = readout.percent;
        if (percent == null) {
          practice = true;
          return;
        }
        final String value = l10n.revRvSpeakScoreValue(percent);
        numbers.add(
          Text(
            label,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        );
        numbers.add(const SizedBox(height: LingAfriqTokens.spacing16));
        numbers.add(
          Semantics(
            container: true,
            label: value,
            child: Text(
              value,
              key: key,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        );
        numbers.add(const SizedBox(height: LingAfriqTokens.spacing16));
      case ScorerReadoutKind.unsure:
        unsure = true;
      case ScorerReadoutKind.practice:
        practice = true;
      case ScorerReadoutKind.hidden:
        return;
    }
  }

  consider(pronunciation, l10n.revRvSpeakPronunciation, scoreKey);
  consider(tone, l10n.revRvSpeakTone, toneKey);
  if (numbers.isEmpty && unsure) {
    return <Widget>[
      Text(
        l10n.revRvSpeakUnsure,
        key: unsureKey,
        style: lingBody(palette.onSurface),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
    ];
  }
  if (numbers.isEmpty && practice) {
    return <Widget>[
      Text(
        l10n.revRvSpeakPractice,
        key: practiceKey,
        style: lingBody(palette.onSurface),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
    ];
  }
  return numbers;
}
