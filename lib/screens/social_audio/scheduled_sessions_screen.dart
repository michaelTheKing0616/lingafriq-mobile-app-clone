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
import 'package:lingafriq/models/social_audio/social_audio_room_model.dart';
import 'package:lingafriq/providers/social_audio_provider.dart';
import 'package:lingafriq/screens/social_audio/room_detail_screen.dart';

/// What a scheduled-session load returned. [ready] is the only status with rooms.
enum ScheduledListStatus { loading, ready, empty, error, offline }

class ScheduledSessionsView {
  const ScheduledSessionsView._(this.status, this.rooms);

  const ScheduledSessionsView.ready(List<SocialAudioRoom> rooms)
    : this._(ScheduledListStatus.ready, rooms);

  const ScheduledSessionsView.empty()
    : this._(ScheduledListStatus.empty, const <SocialAudioRoom>[]);

  const ScheduledSessionsView.error()
    : this._(ScheduledListStatus.error, const <SocialAudioRoom>[]);

  const ScheduledSessionsView.offline()
    : this._(ScheduledListStatus.offline, const <SocialAudioRoom>[]);

  final ScheduledListStatus status;
  final List<SocialAudioRoom> rooms;
}

/// Title for a scheduled room. A blank name uses the room id.
/// A room with neither is omitted. No stand-in title is added.
String? scheduledRoomTitle(SocialAudioRoom room) {
  final String name = room.name.trim();
  if (name.isNotEmpty) return name;
  final String id = room.id.trim();
  if (id.isNotEmpty) return id;
  return null;
}

/// Scheduled Radio sessions.
///
/// With no loader, the page is empty. A failed load clears the rooms.
/// [guardianLocked] hides Speak and Host. The Village radio gate sets it.
class ScheduledSessionsScreen extends StatefulWidget {
  const ScheduledSessionsScreen({
    super.key,
    this.load,
    this.guardianLocked = false,
  }) : live = false;

  const ScheduledSessionsScreen.live({super.key, this.guardianLocked = false})
    : load = null,
      live = true;

  /// App route `/village/radio/scheduled`. The map key drops the leading slash.
  static const String routePath = '/village/radio/scheduled';

  static const String routeKey = 'village/radio/scheduled';

  static const Key emptyKey = ValueKey<String>('radio-scheduled-empty');

  static const Key errorKey = ValueKey<String>('radio-scheduled-error');

  static const Key offlineKey = ValueKey<String>('radio-scheduled-offline');

  static const Key listKey = ValueKey<String>('radio-scheduled-list');

  static const Key speakKey = ValueKey<String>('radio-scheduled-speak');

  static const Key hostKey = ValueKey<String>('radio-scheduled-host');

  static const Key lockedKey = ValueKey<String>('radio-scheduled-locked');

  final Future<ScheduledSessionsView> Function()? load;

  /// Reads scheduled rooms from the existing client. Cache is not reused
  /// after a failure, so a failed load cannot paint an older list.
  final bool live;

  final bool guardianLocked;

  @override
  State<ScheduledSessionsScreen> createState() =>
      _ScheduledSessionsScreenState();
}

class _ScheduledSessionsScreenState extends State<ScheduledSessionsScreen> {
  ScheduledListStatus _status = ScheduledListStatus.loading;
  List<SocialAudioRoom> _rooms = const <SocialAudioRoom>[];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null && !widget.live) {
      _status = ScheduledListStatus.empty;
      return;
    }
    _schedule(_generation);
  }

  @override
  void didUpdateWidget(ScheduledSessionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.live == widget.live) {
      return;
    }
    _rooms = const <SocialAudioRoom>[];
    _generation += 1;
    if (widget.load == null && !widget.live) {
      _status = ScheduledListStatus.empty;
      return;
    }
    _status = ScheduledListStatus.loading;
    _schedule(_generation);
  }

  void _schedule(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _run(generation);
    });
  }

  Future<void> _run(int generation) async {
    final Future<ScheduledSessionsView> Function() load =
        widget.load ?? _loadLive;
    try {
      final ScheduledSessionsView view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = ScheduledListStatus.error;
        _rooms = const <SocialAudioRoom>[];
      });
    }
  }

  Future<ScheduledSessionsView> _loadLive() async {
    final ProviderContainer? container = _container();
    if (container == null) return const ScheduledSessionsView.empty();
    final service = container.read(socialAudioServiceProvider);
    final List<SocialAudioRoom> rooms = await service.getScheduledRooms(
      useCache: false,
    );
    return ScheduledSessionsView.ready(rooms);
  }

  ProviderContainer? _container() {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _apply(ScheduledSessionsView view) {
    final List<SocialAudioRoom> labeled = view.rooms
        .where((SocialAudioRoom room) => scheduledRoomTitle(room) != null)
        .toList(growable: false);
    if (view.status == ScheduledListStatus.ready && labeled.isNotEmpty) {
      _status = ScheduledListStatus.ready;
      _rooms = labeled;
      return;
    }
    _rooms = const <SocialAudioRoom>[];
    if (view.status == ScheduledListStatus.offline) {
      _status = ScheduledListStatus.offline;
    } else if (view.status == ScheduledListStatus.error ||
        view.status == ScheduledListStatus.loading) {
      _status = ScheduledListStatus.error;
    } else {
      _status = ScheduledListStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _rooms = const <SocialAudioRoom>[];
      _status = ScheduledListStatus.loading;
      _generation += 1;
    });
    _schedule(_generation);
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  /// Visible for an adult. With no selected room, this does not call the server.
  void _showAction() {}

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final Widget body = switch (_status) {
      ScheduledListStatus.loading => _loading(context, l10n),
      ScheduledListStatus.empty => LingEmptyState(
        key: ScheduledSessionsScreen.emptyKey,
        title: l10n.revRvAudioScheduled,
        whatHappened: l10n.revRvAudioScheduledEmptyWhat,
        why: l10n.revRvAudioScheduledEmptyWhy,
        whatToDo: l10n.revRvAudioScheduledEmptyNext,
        actionLabel: l10n.revRvAudioBack,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _back,
      ),
      ScheduledListStatus.error => LingErrorState(
        key: ScheduledSessionsScreen.errorKey,
        whatHappened: l10n.revRvAudioScheduledFailWhat,
        why: l10n.revRvAudioScheduledFailWhy,
        whatToDo: l10n.revRvAudioScheduledFailNext,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      ScheduledListStatus.offline => LingOfflineState(
        key: ScheduledSessionsScreen.offlineKey,
        whatHappened: l10n.shellOfflineWhat,
        why: l10n.revRvAudioScheduledOfflineWhy,
        whatToDo: l10n.shellOfflineNext,
        queuedActions: 0,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      ScheduledListStatus.ready => _list(context, l10n),
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
        _status == ScheduledListStatus.loading ||
        _status == ScheduledListStatus.ready;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.revRvAudioScheduled,
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
        key: ScheduledSessionsScreen.lockedKey,
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
          key: ScheduledSessionsScreen.speakKey,
          label: l10n.revRvAudioSpeak,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _showAction,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        LingButton(
          key: ScheduledSessionsScreen.hostKey,
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
      key: ScheduledSessionsScreen.listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final SocialAudioRoom room in _rooms)
          if (scheduledRoomTitle(room) != null)
            _roomCard(context, l10n, palette, room, scheduledRoomTitle(room)!),
      ],
    );
  }

  Widget _roomCard(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    SocialAudioRoom room,
    String title,
  ) {
    final DateTime? when = room.scheduledStartTime;
    final String host = room.hostName?.trim() ?? '';
    final String description = room.description.trim();
    final String language = room.language.trim();
    return Semantics(
      container: true,
      label: l10n.revRvAudioSessionSemantics(title),
      button: room.id.trim().isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing16),
        child: Material(
          color: palette.surfaceContainer,
          borderRadius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiussm),
          ),
          child: InkWell(
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(LingAfriqTokens.radiussm),
              ),
            ),
            onTap: room.id.trim().isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            RoomDetailScreen(roomId: room.id),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
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
                  if (when != null) ...<Widget>[
                    const SizedBox(height: LingAfriqTokens.spacing8),
                    Text(
                      _when(context, l10n, when),
                      style: lingBody(palette.onSurfaceVariant),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                  if (language.isNotEmpty) ...<Widget>[
                    const SizedBox(height: LingAfriqTokens.spacing8),
                    Text(
                      language,
                      style: lingBody(palette.onSurface),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                  if (host.isNotEmpty) ...<Widget>[
                    const SizedBox(height: LingAfriqTokens.spacing8),
                    Text(
                      l10n.revRvAudioHostedBy(host),
                      style: lingBody(palette.onSurfaceVariant),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _when(BuildContext context, AppLocalizations l10n, DateTime time) {
    final MaterialLocalizations local = MaterialLocalizations.of(context);
    final DateTime shown = time.toLocal();
    return l10n.revRvAudioSessionWhen(
      local.formatShortDate(shown),
      local.formatTimeOfDay(TimeOfDay.fromDateTime(shown)),
    );
  }
}
