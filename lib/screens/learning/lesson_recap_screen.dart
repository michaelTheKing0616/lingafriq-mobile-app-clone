import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';

/// What a recap load returned. [ready] is the only status that carries a lesson.
enum LessonRecapStatus { loading, ready, empty, error, offline }

/// A finished lesson. Fields are only the values the loader supplied.
class LessonRecapData {
  const LessonRecapData({required this.title, this.words = const <String>[]});

  final String title;
  final List<String> words;
}

class LessonRecapView {
  const LessonRecapView._(this.status, this.data);

  const LessonRecapView.ready(LessonRecapData data)
    : this._(LessonRecapStatus.ready, data);

  const LessonRecapView.empty() : this._(LessonRecapStatus.empty, null);

  const LessonRecapView.error() : this._(LessonRecapStatus.error, null);

  const LessonRecapView.offline() : this._(LessonRecapStatus.offline, null);

  final LessonRecapStatus status;
  final LessonRecapData? data;
}

/// Lesson recap. With no loader, the page is empty.
/// A failed load clears the lesson title and the word list.
class LessonRecapScreen extends StatefulWidget {
  const LessonRecapScreen({super.key, this.load});

  /// App route `/learn/recap`. The map key drops the leading slash.
  static const String routePath = '/learn/recap';

  static const String routeKey = 'learn/recap';

  static const Key emptyKey = ValueKey<String>('learn-recap-empty');

  static const Key errorKey = ValueKey<String>('learn-recap-error');

  static const Key offlineKey = ValueKey<String>('learn-recap-offline');

  static const Key contentKey = ValueKey<String>('learn-recap-content');

  /// Loads the recap. Null means there is no lesson to recap.
  final Future<LessonRecapView> Function()? load;

  @override
  State<LessonRecapScreen> createState() => _LessonRecapScreenState();
}

class _LessonRecapScreenState extends State<LessonRecapScreen> {
  LessonRecapStatus _status = LessonRecapStatus.loading;
  LessonRecapData? _data;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null) {
      _status = LessonRecapStatus.empty;
      _data = null;
      return;
    }
    _run(_generation);
  }

  @override
  void didUpdateWidget(LessonRecapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load)) return;
    _data = null;
    _generation += 1;
    if (widget.load == null) {
      _status = LessonRecapStatus.empty;
      return;
    }
    _status = LessonRecapStatus.loading;
    _run(_generation);
  }

  Future<void> _run(int generation) async {
    final Future<LessonRecapView> Function()? load = widget.load;
    if (load == null) {
      if (!mounted) return;
      setState(() {
        _status = LessonRecapStatus.empty;
        _data = null;
      });
      return;
    }
    try {
      final LessonRecapView view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = LessonRecapStatus.error;
        _data = null;
      });
    }
  }

  void _apply(LessonRecapView view) {
    final String title = (view.data?.title ?? '').trim();
    final List<String> words = <String>[
      for (final String word in view.data?.words ?? const <String>[])
        if (word.trim().isNotEmpty) word.trim(),
    ];
    if (view.status == LessonRecapStatus.ready &&
        (title.isNotEmpty || words.isNotEmpty)) {
      _status = LessonRecapStatus.ready;
      _data = LessonRecapData(title: title, words: words);
      return;
    }
    _data = null;
    if (view.status == LessonRecapStatus.offline) {
      _status = LessonRecapStatus.offline;
    } else if (view.status == LessonRecapStatus.error ||
        view.status == LessonRecapStatus.loading) {
      _status = LessonRecapStatus.error;
    } else {
      _status = LessonRecapStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _data = null;
      _status = LessonRecapStatus.loading;
      _generation += 1;
    });
    _run(_generation);
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  void _openPath() {
    Navigator.of(context).pushNamed(LearnRoutes.path);
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
              l10n.hubLearnLessonRecap,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubLearnBack,
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
      case LessonRecapStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case LessonRecapStatus.empty:
        return LingEmptyState(
          key: LessonRecapScreen.emptyKey,
          title: l10n.revRvLearnRecapEmptyTitle,
          whatHappened: l10n.revRvLearnRecapEmptyWhat,
          why: l10n.revRvLearnRecapEmptyWhy,
          whatToDo: l10n.revRvLearnRecapEmptyNext,
          actionLabel: l10n.hubLearnOpenPath,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _openPath,
        );
      case LessonRecapStatus.error:
        return LingErrorState(
          key: LessonRecapScreen.errorKey,
          whatHappened: l10n.revRvLearnRecapFailWhat,
          why: l10n.revRvLearnRecapFailWhy,
          whatToDo: l10n.revRvLearnRecapFailNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case LessonRecapStatus.offline:
        return LingOfflineState(
          key: LessonRecapScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvLearnRecapOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case LessonRecapStatus.ready:
        return _ready(l10n, palette, _data!);
    }
  }

  /// Trophy and the words the loader returned. No score is added here.
  Widget _ready(AppLocalizations l10n, LingPalette palette, LessonRecapData data) {
    return Column(
      key: LessonRecapScreen.contentKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.emoji_events_rounded,
          size: LingAfriqTokens.spacing48,
          color: palette.accent,
        ),
        if (data.title.isNotEmpty) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            data.title,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
        if (data.words.isNotEmpty) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            l10n.revRvLearnRecapWords,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          for (final String word in data.words) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              word,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ],
      ],
    );
  }
}
