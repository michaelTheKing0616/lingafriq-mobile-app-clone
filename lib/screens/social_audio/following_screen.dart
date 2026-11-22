import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/providers/social_audio_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';

/// What a following load returned. [ready] is the only status with people.
enum FollowingListStatus { loading, ready, empty, error, offline }

/// One person returned by the following or followers list.
class RadioPerson {
  const RadioPerson({required this.id, required this.label});

  final String id;
  final String label;
}

/// People parsed from a following or followers payload.
///
/// A row with no name and no id is dropped. No stand-in name is added.
List<RadioPerson> radioPeopleFromRows(List<Map<String, dynamic>> rows) {
  final List<RadioPerson> people = <RadioPerson>[];
  for (final Map<String, dynamic> row in rows) {
    final String? label = _personLabel(row);
    if (label == null) continue;
    final Object? rawId = row['id'] ?? row['user_id'];
    final String id = rawId == null ? label : rawId.toString().trim();
    people.add(RadioPerson(id: id.isEmpty ? label : id, label: label));
  }
  return people;
}

String? _personLabel(Map<String, dynamic> row) {
  final Object? name = row['name'] ?? row['username'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  final Object? rawId = row['id'] ?? row['user_id'];
  if (rawId == null) return null;
  final String id = rawId.toString().trim();
  if (id.isEmpty) return null;
  return id;
}

class FollowingView {
  const FollowingView._(this.status, this.following, this.followers);

  const FollowingView.ready({
    required List<RadioPerson> following,
    required List<RadioPerson> followers,
  }) : this._(FollowingListStatus.ready, following, followers);

  const FollowingView.empty()
    : this._(
        FollowingListStatus.empty,
        const <RadioPerson>[],
        const <RadioPerson>[],
      );

  const FollowingView.error()
    : this._(
        FollowingListStatus.error,
        const <RadioPerson>[],
        const <RadioPerson>[],
      );

  const FollowingView.offline()
    : this._(
        FollowingListStatus.offline,
        const <RadioPerson>[],
        const <RadioPerson>[],
      );

  final FollowingListStatus status;
  final List<RadioPerson> following;
  final List<RadioPerson> followers;
}

/// Following and followers for Village Radio.
///
/// With no loader, the page is empty. A failed load clears both lists.
/// [guardianLocked] hides Speak and Host. The Village radio gate sets it.
class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key, this.load, this.guardianLocked = false})
    : live = false;

  const FollowingScreen.live({super.key, this.guardianLocked = false})
    : load = null,
      live = true;

  /// App route `/village/radio/following`. The map key drops the leading slash.
  static const String routePath = '/village/radio/following';

  static const String routeKey = 'village/radio/following';

  static const Key emptyKey = ValueKey<String>('radio-following-empty');

  static const Key errorKey = ValueKey<String>('radio-following-error');

  static const Key offlineKey = ValueKey<String>('radio-following-offline');

  static const Key listKey = ValueKey<String>('radio-following-list');

  static const Key speakKey = ValueKey<String>('radio-following-speak');

  static const Key hostKey = ValueKey<String>('radio-following-host');

  static const Key lockedKey = ValueKey<String>('radio-following-locked');

  final Future<FollowingView> Function()? load;

  /// Reads the signed-in learner's lists. An empty result stays empty.
  final bool live;

  final bool guardianLocked;

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  FollowingListStatus _status = FollowingListStatus.loading;
  List<RadioPerson> _following = const <RadioPerson>[];
  List<RadioPerson> _followers = const <RadioPerson>[];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null && !widget.live) {
      _status = FollowingListStatus.empty;
      return;
    }
    _schedule(_generation);
  }

  @override
  void didUpdateWidget(FollowingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.live == widget.live) {
      return;
    }
    _following = const <RadioPerson>[];
    _followers = const <RadioPerson>[];
    _generation += 1;
    if (widget.load == null && !widget.live) {
      _status = FollowingListStatus.empty;
      return;
    }
    _status = FollowingListStatus.loading;
    _schedule(_generation);
  }

  void _schedule(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _run(generation);
    });
  }

  Future<void> _run(int generation) async {
    final Future<FollowingView> Function() load = widget.load ?? _loadLive;
    try {
      final FollowingView view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = FollowingListStatus.error;
        _following = const <RadioPerson>[];
        _followers = const <RadioPerson>[];
      });
    }
  }

  Future<FollowingView> _loadLive() async {
    final ProviderContainer? container = _container();
    if (container == null) return const FollowingView.empty();
    final user = container.read(userProvider);
    final String? id = user?.id.toString();
    if (id == null || id.isEmpty) return const FollowingView.empty();
    final service = container.read(socialAudioServiceProvider);
    final List<Map<String, dynamic>> following = await service.getFollowingList(
      userId: id,
    );
    final List<Map<String, dynamic>> followers = await service.getFollowersList(
      userId: id,
    );
    return FollowingView.ready(
      following: radioPeopleFromRows(following),
      followers: radioPeopleFromRows(followers),
    );
  }

  ProviderContainer? _container() {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _apply(FollowingView view) {
    if (view.status == FollowingListStatus.ready &&
        (view.following.isNotEmpty || view.followers.isNotEmpty)) {
      _status = FollowingListStatus.ready;
      _following = List<RadioPerson>.unmodifiable(view.following);
      _followers = List<RadioPerson>.unmodifiable(view.followers);
      return;
    }
    _following = const <RadioPerson>[];
    _followers = const <RadioPerson>[];
    if (view.status == FollowingListStatus.offline) {
      _status = FollowingListStatus.offline;
    } else if (view.status == FollowingListStatus.error ||
        view.status == FollowingListStatus.loading) {
      _status = FollowingListStatus.error;
    } else {
      _status = FollowingListStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _following = const <RadioPerson>[];
      _followers = const <RadioPerson>[];
      _status = FollowingListStatus.loading;
      _generation += 1;
    });
    _schedule(_generation);
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  /// Visible for an adult. No room is selected, so this does not call the server.
  void _showAction() {}

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final Widget body = switch (_status) {
      FollowingListStatus.loading => _loading(context, l10n),
      FollowingListStatus.empty => LingEmptyState(
        key: FollowingScreen.emptyKey,
        title: l10n.revRvAudioFollowing,
        whatHappened: l10n.revRvAudioFollowingEmptyWhat,
        why: l10n.revRvAudioFollowingEmptyWhy,
        whatToDo: l10n.revRvAudioFollowingEmptyNext,
        actionLabel: l10n.revRvAudioBack,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _back,
      ),
      FollowingListStatus.error => LingErrorState(
        key: FollowingScreen.errorKey,
        whatHappened: l10n.revRvAudioFollowingFailWhat,
        why: l10n.revRvAudioFollowingFailWhy,
        whatToDo: l10n.revRvAudioFollowingFailNext,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      FollowingListStatus.offline => LingOfflineState(
        key: FollowingScreen.offlineKey,
        whatHappened: l10n.shellOfflineWhat,
        why: l10n.revRvAudioFollowingOfflineWhy,
        whatToDo: l10n.shellOfflineNext,
        queuedActions: 0,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      FollowingListStatus.ready => _list(context, l10n),
    };
    return _frame(context, l10n, body);
  }

  Widget _loading(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.loading,
      style: lingBody(LingPalette.of(Theme.of(context).brightness).onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _frame(BuildContext context, AppLocalizations l10n, Widget body) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool canLeave =
        _status == FollowingListStatus.loading ||
        _status == FollowingListStatus.ready;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.revRvAudioFollowing,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _actions(l10n, palette),
            const SizedBox(height: LingAfriqTokens.spacing16),
            body,
            if (canLeave) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.revRvAudioBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _back,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actions(AppLocalizations l10n, LingPalette palette) {
    if (widget.guardianLocked) {
      return Column(
        key: FollowingScreen.lockedKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.hubHVillageLocked,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing8),
          Text(
            l10n.hubHVillageGuardian,
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LingButton(
          key: FollowingScreen.speakKey,
          label: l10n.revRvAudioSpeak,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _showAction,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        LingButton(
          key: FollowingScreen.hostKey,
          label: l10n.revRvAudioHost,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _showAction,
          role: LingButtonRole.quiet,
        ),
      ],
    );
  }

  Widget _list(BuildContext context, AppLocalizations l10n) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Column(
      key: FollowingScreen.listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_following.isNotEmpty) ...<Widget>[
          Text(
            l10n.revRvAudioFollowing,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing8),
          for (final RadioPerson person in _following)
            _personLine(palette, person.label),
        ],
        if (_followers.isNotEmpty) ...<Widget>[
          if (_following.isNotEmpty)
            const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            l10n.revRvAudioFollowers,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing8),
          for (final RadioPerson person in _followers)
            _personLine(palette, person.label),
        ],
      ],
    );
  }

  Widget _personLine(LingPalette palette, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
      child: Text(
        label,
        style: lingBody(palette.onSurface),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
