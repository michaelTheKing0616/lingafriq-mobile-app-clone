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
import 'package:lingafriq/models/roleplay_progress_model.dart';
import 'package:lingafriq/screens/ai_chat/conversation_analytics_screen.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:lingafriq/services/roleplay_progress_service.dart';

/// copy_keys: rev.rv_speak.*
///
/// One saved scenario on the progress list. Accuracy and fluency are not
/// fields here: the stored averages have no scorer source, so they are omitted.
class RoleplaySceneRow {
  const RoleplaySceneRow({
    required this.id,
    required this.name,
    this.category = '',
    this.difficulty = '',
    this.timesCompleted = 0,
  });

  final String id;
  final String name;
  final String category;
  final String difficulty;
  final int timesCompleted;
}

/// What [RoleplayProgressDashboardScreen] should paint.
class RoleplayProgressLoad {
  const RoleplayProgressLoad._(
    this.status,
    this.scenes,
    this.pronunciation,
    this.tone,
  );

  const RoleplayProgressLoad.ready(
    List<RoleplaySceneRow> scenes, {
    GameScore? pronunciation,
    GameScore? tone,
  }) : this._(SpeakInsightStatus.ready, scenes, pronunciation, tone);

  const RoleplayProgressLoad.empty()
    : this._(SpeakInsightStatus.empty, const <RoleplaySceneRow>[], null, null);

  const RoleplayProgressLoad.error()
    : this._(SpeakInsightStatus.error, const <RoleplaySceneRow>[], null, null);

  const RoleplayProgressLoad.offline()
    : this._(
        SpeakInsightStatus.offline,
        const <RoleplaySceneRow>[],
        null,
        null,
      );

  final SpeakInsightStatus status;
  final List<RoleplaySceneRow> scenes;
  final GameScore? pronunciation;
  final GameScore? tone;
}

/// Scenes for [languageName] or [language]. Empty names keep every saved scene.
/// A scene with no name is dropped. Accuracy is not copied.
List<RoleplaySceneRow> scenesFromProgress(
  RoleplayProgress progress,
  String languageName,
  String language,
) {
  final String name = languageName.trim();
  final String code = language.trim();
  final List<RoleplaySceneRow> rows = <RoleplaySceneRow>[];
  for (final ScenarioProgress scene in progress.scenarios.values) {
    final String sceneLanguage = scene.language.trim();
    if (name.isNotEmpty || code.isNotEmpty) {
      final bool matches =
          sceneLanguage.isEmpty ||
          sceneLanguage == name ||
          sceneLanguage == code;
      if (!matches) continue;
    }
    final String title = scene.scenarioName.trim().isEmpty
        ? scene.scenarioId.trim()
        : scene.scenarioName.trim();
    if (title.isEmpty) continue;
    rows.add(
      RoleplaySceneRow(
        id: scene.scenarioId,
        name: title,
        category: scene.category.trim(),
        difficulty: scene.difficulty.trim(),
        timesCompleted: scene.timesCompleted,
      ),
    );
  }
  return rows;
}

/// Roleplay progress. No scenes shows [LingEmptyState].
/// A failed load shows [LingErrorState] and drops the list that was on screen.
class RoleplayProgressDashboardScreen extends StatefulWidget {
  const RoleplayProgressDashboardScreen({
    super.key,
    this.language = '',
    this.languageName = '',
    this.load,
  });

  /// App route `/speak/roleplay-progress`. The map key drops the leading slash.
  static const String routePath = '/speak/roleplay-progress';

  static const String routeKey = 'speak/roleplay-progress';

  static const Key emptyKey = ValueKey<String>('speak-progress-empty');

  static const Key errorKey = ValueKey<String>('speak-progress-error');

  static const Key offlineKey = ValueKey<String>('speak-progress-offline');

  static const Key listKey = ValueKey<String>('speak-progress-list');

  static const Key scoreKey = ValueKey<String>('speak-progress-score');

  static const Key toneKey = ValueKey<String>('speak-progress-tone');

  static const Key unsureKey = ValueKey<String>('speak-progress-unsure');

  static const Key practiceKey = ValueKey<String>('speak-progress-practice');

  static const Key refreshKey = ValueKey<String>('speak-progress-refresh');

  static const Key backKey = ValueKey<String>('speak-progress-back');

  static Key sceneKey(String id) => ValueKey<String>('speak-progress-$id');

  final String language;
  final String languageName;

  /// Loads the list. Null with no language means there is nothing saved.
  final Future<RoleplayProgressLoad> Function()? load;

  @override
  State<RoleplayProgressDashboardScreen> createState() =>
      _RoleplayProgressDashboardScreenState();
}

class _RoleplayProgressDashboardScreenState
    extends State<RoleplayProgressDashboardScreen> {
  SpeakInsightStatus _status = SpeakInsightStatus.loading;
  List<RoleplaySceneRow> _scenes = const <RoleplaySceneRow>[];
  GameScore? _pronunciation;
  GameScore? _tone;
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
  void didUpdateWidget(RoleplayProgressDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.language == widget.language &&
        oldWidget.languageName == widget.languageName) {
      return;
    }
    _clearList();
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

  void _clearList() {
    _scenes = const <RoleplaySceneRow>[];
    _pronunciation = null;
    _tone = null;
  }

  Future<void> _run(int generation) async {
    final Future<RoleplayProgressLoad> Function() load =
        widget.load ?? _loadNamed;
    try {
      final RoleplayProgressLoad view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } on SpeakDataUnavailable catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _clearList();
        _status = error.offline
            ? SpeakInsightStatus.offline
            : SpeakInsightStatus.error;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _clearList();
        _status = SpeakInsightStatus.error;
      });
    }
  }

  Future<RoleplayProgressLoad> _loadNamed() async {
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final RoleplayProgressService service = container.read(
      roleplayProgressServiceProvider,
    );
    final RoleplayProgress? stored = await service.readStored();
    if (stored == null) return const RoleplayProgressLoad.empty();
    final List<RoleplaySceneRow> scenes = scenesFromProgress(
      stored,
      widget.languageName,
      widget.language,
    );
    if (scenes.isEmpty) return const RoleplayProgressLoad.empty();
    return RoleplayProgressLoad.ready(scenes);
  }

  void _apply(RoleplayProgressLoad view) {
    if (view.status == SpeakInsightStatus.ready && view.scenes.isNotEmpty) {
      _status = SpeakInsightStatus.ready;
      _scenes = List<RoleplaySceneRow>.unmodifiable(view.scenes);
      _pronunciation = view.pronunciation;
      _tone = view.tone;
      return;
    }
    _clearList();
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
      _clearList();
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
              l10n.hubHSpeakRoleplayProgress,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            if (_status != SpeakInsightStatus.empty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: RoleplayProgressDashboardScreen.backKey,
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
          key: RoleplayProgressDashboardScreen.emptyKey,
          title: l10n.hubHSpeakRoleplayProgress,
          whatHappened: l10n.revRvSpeakProgressEmptyWhat,
          why: l10n.revRvSpeakProgressEmptyWhy,
          whatToDo: l10n.revRvSpeakProgressEmptyNext,
          actionLabel: l10n.hubHSpeakBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case SpeakInsightStatus.error:
        return LingErrorState(
          key: RoleplayProgressDashboardScreen.errorKey,
          whatHappened: l10n.revRvSpeakProgressErrorWhat,
          why: l10n.revRvSpeakProgressErrorWhy,
          whatToDo: l10n.revRvSpeakProgressErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.offline:
        return LingOfflineState(
          key: RoleplayProgressDashboardScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvSpeakProgressOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case SpeakInsightStatus.ready:
        if (_scenes.isEmpty) {
          return LingEmptyState(
            key: RoleplayProgressDashboardScreen.emptyKey,
            title: l10n.hubHSpeakRoleplayProgress,
            whatHappened: l10n.revRvSpeakProgressEmptyWhat,
            why: l10n.revRvSpeakProgressEmptyWhy,
            whatToDo: l10n.revRvSpeakProgressEmptyNext,
            actionLabel: l10n.hubHSpeakBack,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _back,
          );
        }
        return _list(l10n, palette);
    }
  }

  Widget _list(AppLocalizations l10n, LingPalette palette) {
    return Column(
      key: RoleplayProgressDashboardScreen.listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final RoleplaySceneRow scene in _scenes) ...<Widget>[
          Semantics(
            container: true,
            label: l10n.revRvSpeakSceneSemantics(scene.name),
            child: Text(
              scene.name,
              key: RoleplayProgressDashboardScreen.sceneKey(scene.id),
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
          if (scene.category.isNotEmpty) ...<Widget>[
            Text(
              scene.category,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
          ],
          if (scene.difficulty.isNotEmpty) ...<Widget>[
            Text(
              scene.difficulty,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
          ],
          if (scene.timesCompleted > 0) ...<Widget>[
            Text(
              l10n.revRvSpeakCompletedCount(scene.timesCompleted),
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
          pronunciation: _pronunciation,
          tone: _tone,
          scoreKey: RoleplayProgressDashboardScreen.scoreKey,
          toneKey: RoleplayProgressDashboardScreen.toneKey,
          unsureKey: RoleplayProgressDashboardScreen.unsureKey,
          practiceKey: RoleplayProgressDashboardScreen.practiceKey,
        ),
        LingButton(
          key: RoleplayProgressDashboardScreen.refreshKey,
          label: l10n.revRvSpeakRefresh,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _retry,
        ),
      ],
    );
  }
}
