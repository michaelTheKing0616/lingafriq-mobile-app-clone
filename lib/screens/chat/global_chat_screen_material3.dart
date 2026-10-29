import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lingafriq/features/global_chat/global_chat_controller.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:lingafriq/features/global_chat/global_chat_repository.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/chat/user_search_global_id_screen.dart';
import 'package:lingafriq/screens/feed/x_profile_screen.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';

const _navy = Color(0xFF2E3A87);
const _bg = Color(0xFFF4F5FA);
const _ink = Color(0xFF1B1F3B);
const _muted = Color(0xFF555B78);
const _line = Color(0xFFDADDEB);

bool _compact(BuildContext c) => MediaQuery.textScalerOf(c).scale(10) > 15;

/// Wraps Latin/user text so it keeps its own direction inside RTL copy.
String _iso(String s) => '\u2068$s\u2069';

String channelLabel(AppLocalizations l, String id) => id == 'general'
    ? l.gcChannelGeneral
    : '${id[0].toUpperCase()}${id.substring(1)}';

/// Channel identity: accent colour and a native greeting (content, not UI copy).
const _channelLook = <String, (Color, String)>{
  'general': (Color(0xFF2E3A87), 'Hello · Bonjour · مرحبا'),
  'yoruba': (Color(0xFF1B7F5A), 'Ẹ n lẹ́ o'),
  'hausa': (Color(0xFF8A4B08), 'Sannu'),
  'igbo': (Color(0xFF7A2E8A), 'Ndewo'),
  'pidgin': (Color(0xFF0F6E8C), 'How far?'),
  'swahili': (Color(0xFFB0372B), 'Habari'),
  'zulu': (Color(0xFF4A5A12), 'Sawubona'),
};
(Color, String) channelLook(String id) =>
    _channelLook[id] ?? _channelLook['general']!;

/// Content column cap so tablets read as a centred conversation.
const double kGlobalChatMaxWidth = 640;

/// Global chat. Access is decided by [globalChatAccessProvider]; every route
/// into this screen is guarded here, so hidden entries cannot be bypassed.
class GlobalChatScreenMaterial3 extends ConsumerWidget {
  const GlobalChatScreenMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(globalChatAccessProvider);
    if (access == GlobalChatAccess.allowed) return const _ChatView();
    return _LockedView(access: access);
  }
}

PreferredSizeWidget _bar(
  BuildContext context, {
  required Widget title,
  List<Widget> actions = const [],
}) => AppBar(
  backgroundColor: _navy,
  foregroundColor: Colors.white,
  elevation: 0,
  toolbarHeight: _compact(context) ? 84 : 64,
  leading: IconButton(
    key: const Key('gc-back'),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const BackButtonIcon(),
    onPressed: () => Navigator.maybePop(context),
  ),
  titleSpacing: 0,
  title: title,
  actions: actions,
);

class _LockedView extends StatelessWidget {
  const _LockedView({required this.access});
  final GlobalChatAccess access;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final checking = access == GlobalChatAccess.checking;
    final (title, body) = switch (access) {
      GlobalChatAccess.deniedChild => (
        l.gcLockedChildTitle,
        l.gcLockedChildBody,
      ),
      GlobalChatAccess.deniedTeen => (l.gcLockedTeenTitle, l.gcLockedTeenBody),
      _ => (l.gcLockedUnknownTitle, l.gcLockedUnknownBody),
    };
    return Scaffold(
      key: const Key('gc-locked'),
      backgroundColor: _bg,
      appBar: _bar(
        context,
        title: Text(
          l.gcTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: checking
          ? Center(
              key: const Key('gc-checking'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: _navy),
                  const SizedBox(height: 12),
                  Text(l.gcChecking, style: const TextStyle(color: _muted)),
                ],
              ),
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6E8F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 42,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          key: const Key('gc-locked-title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const Key('gc-locked-polie'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _navy,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, 'lingchat_ai'),
                          icon: const Icon(Icons.smart_toy_outlined),
                          label: Text(l.gcPracticePolie),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView();
  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _precached = <String>{};

  /// Message ids already on screen; only later arrivals animate in.
  final _seen = <String>{};
  String? _seededChannel;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  GlobalChatController get _c =>
      ref.read(globalChatControllerProvider.notifier);

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// Warm the image cache so avatars appear with their bubble, not after.
  void _preload(List<ChatMessage> ms) {
    for (final m in ms) {
      final url = m.avatarUrl;
      if (url == null || !_precached.add(url)) continue;
      precacheImage(NetworkImage(url), context, onError: (_, _) {});
    }
  }

  Future<void> _send([String? preset]) async {
    final l = l10nOf(context);
    final text = preset ?? _input.text;
    if (preset == null) _input.clear();
    HapticFeedback.lightImpact();
    final r = await _c.send(text);
    if (!mounted) return;
    switch (r) {
      case SendResult.failed:
        _input.text = text;
        _snack(
          l.gcSendFailed,
          action: SnackBarAction(label: l.gcRetry, onPressed: _send),
        );
      case SendResult.signedOut:
        _input.text = text;
        _snack(l.gcSignIn);
      case SendResult.polieBusy:
        _snack(l.gcPolieBusy);
      case SendResult.sent || SendResult.empty:
        break;
    }
  }

  Future<void> _pickChannel(String current) async {
    final l = l10nOf(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l.gcSwitchChannel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              for (final id in kGlobalChatChannels)
                ListTile(
                  key: Key('gc-ch-$id'),
                  leading: const Icon(Icons.tag_rounded, color: _navy),
                  title: Text(
                    channelLabel(l, id),
                    style: const TextStyle(color: _ink),
                  ),
                  trailing: id == current
                      ? const Icon(Icons.check_circle, color: _navy)
                      : null,
                  selected: id == current,
                  onTap: () => Navigator.pop(c, id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _c.selectChannel(picked);
  }

  void _openProfile(ChatMessage m) {
    if (m.isPolie || m.senderId.isEmpty) {
      _snack(l10nOf(context).gcProfileUnavailable);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => XProfileScreen(viewUserId: m.senderId),
      ),
    );
  }

  Future<void> _actions(ChatMessage m, bool isMuted) async {
    final l = l10nOf(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          key: const Key('gc-actions'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l.gcActionsFor(_iso(m.senderName)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              ListTile(
                key: const Key('gc-act-mute'),
                leading: Icon(
                  isMuted
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  color: _navy,
                ),
                title: Text(isMuted ? l.gcUnmute : l.gcMute),
                subtitle: Text(l.gcMuteSub),
                onTap: () => Navigator.pop(c, 'mute'),
              ),
              ListTile(
                key: const Key('gc-act-report'),
                leading: const Icon(Icons.flag_outlined, color: _navy),
                title: Text(l.gcReport),
                subtitle: Text(l.gcReportSub),
                onTap: () => Navigator.pop(c, 'report'),
              ),
              ListTile(
                key: const Key('gc-act-block'),
                leading: const Icon(Icons.block, color: Color(0xFFB3261E)),
                title: Text(
                  l.gcBlock,
                  style: const TextStyle(color: Color(0xFFB3261E)),
                ),
                subtitle: Text(l.gcBlockSub),
                onTap: () => Navigator.pop(c, 'block'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final who = _iso(m.senderName);
    switch (choice) {
      case 'mute':
        if (isMuted) {
          await _c.unmute(m.senderId);
        } else {
          await _c.mute(m.senderId);
          if (mounted) _snack(l.gcMutedNote(who));
        }
      case 'report':
        await _report(m);
      case 'block':
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l.gcBlockConfirm(who)),
            content: Text(l.gcBlockConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l.gcCancel),
              ),
              FilledButton(
                key: const Key('gc-block-confirm'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E),
                ),
                onPressed: () => Navigator.pop(c, true),
                child: Text(l.gcBlock),
              ),
            ],
          ),
        );
        if (ok != true) return;
        try {
          await _c.block(m.senderId);
          if (mounted) _snack(l.gcBlockedNote(who));
        } catch (_) {
          if (mounted) _snack(l.gcBlockFailed);
        }
    }
  }

  Future<void> _report(ChatMessage m) async {
    final l = l10nOf(context);
    final reasons = {
      'harassment': l.gcReasonHarassment,
      'spam': l.gcReasonSpam,
      'hate': l.gcReasonHate,
      'other': l.gcReasonOther,
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l.gcReasonTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              for (final e in reasons.entries)
                ListTile(
                  key: Key('gc-reason-${e.key}'),
                  title: Text(e.value),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(c, e.key),
                ),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;
    try {
      final refId = await _c.report(m.id, reason);
      if (mounted) _snack(l.gcReportSent(_iso(refId)));
    } catch (_) {
      if (mounted) _snack(l.gcReportFailed);
    }
  }

  void _findUser() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => UserSearchGlobalIdScreen(
        currentChatType: 'global',
        onUserSelected: (u) =>
            _input.text = '@${u['global_id'] ?? u['username']} ',
      ),
    ),
  );

  Future<void> _manage(GlobalChatState s) async {
    final names = {for (final m in s.messages) m.senderId: m.senderName};
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (c) => _ManageSheet(names: names),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final s = ref.watch(globalChatControllerProvider);
    final me = ref.watch(globalChatMeProvider);
    final visible = s.visible;
    _preload(visible);
    if (_seededChannel != s.channel && s.load != ChatLoad.loading) {
      _seededChannel = s.channel;
      _seen.addAll(visible.map((m) => m.id));
    }
    final compact = _compact(context);

    return Scaffold(
      key: const Key('gc-screen'),
      backgroundColor: _bg,
      appBar: _bar(
        context,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.gcTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            InkWell(
              key: const Key('gc-channel'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickChannel(s.channel),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    Flexible(
                      child: Text(
                        channelLabel(l, s.channel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!compact)
            IconButton(
              key: const Key('gc-find'),
              tooltip: l.gcFindUser,
              icon: const Icon(Icons.person_search_outlined),
              onPressed: _findUser,
            ),
          PopupMenuButton<String>(
            key: const Key('gc-more'),
            tooltip: l.gcMore,
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'find':
                  _findUser();
                case 'refresh':
                  _c.refresh();
                case 'manage':
                  _manage(s);
                case 'rules':
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunityGuidelinesScreen(),
                    ),
                  );
              }
            },
            itemBuilder: (_) => [
              if (compact)
                PopupMenuItem(value: 'find', child: Text(l.gcFindUser)),
              PopupMenuItem(value: 'refresh', child: Text(l.gcRefresh)),
              PopupMenuItem(value: 'manage', child: Text(l.gcMutedBlocked)),
              PopupMenuItem(value: 'rules', child: Text(l.gcGuidelines)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (s.load == ChatLoad.loading)
            const LinearProgressIndicator(
              key: Key('gc-syncing'),
              minHeight: 3,
              color: _navy,
              backgroundColor: Color(0xFFE6E8F5),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                key: const Key('gc-column'),
                constraints: const BoxConstraints(
                  maxWidth: kGlobalChatMaxWidth,
                ),
                child: Column(
                  children: [
                    if (s.fromCache)
                      _Banner(
                        key: const Key('gc-offline'),
                        icon: Icons.cloud_off_rounded,
                        text: l.gcOffline,
                        action: l.gcRetry,
                        onAction: _c.refresh,
                      ),
                    if (!compact) _PolieTile(l: l),
                    if (s.hiddenCount > 0)
                      _Banner(
                        key: const Key('gc-hidden'),
                        icon: Icons.visibility_off_outlined,
                        text: l.gcHidden(s.hiddenCount),
                        action: l.gcManage,
                        onAction: () => _manage(s),
                      ),
                    Expanded(child: _body(l, s, visible, me)),
                  ],
                ),
              ),
            ),
          ),
          _Composer(
            compact: compact,
            controller: _input,
            sending: s.sending,
            onSend: () => _send(),
            l: l,
          ),
        ],
      ),
    );
  }

  Widget _body(
    AppLocalizations l,
    GlobalChatState s,
    List<ChatMessage> visible,
    ChatMe? me,
  ) {
    if (s.load == ChatLoad.loading && s.messages.isEmpty) {
      return ListView(
        key: const Key('gc-loading'),
        padding: const EdgeInsets.all(16),
        children: [for (var i = 0; i < 5; i++) _Skeleton(mine: i.isOdd)],
      );
    }
    if (s.load == ChatLoad.error) {
      return _Center(
        key: const Key('gc-error'),
        icon: Icons.wifi_off_rounded,
        title: l.gcErrorTitle,
        body: l.gcErrorBody,
        action: l.gcRetry,
        onAction: _c.refresh,
      );
    }
    if (visible.isEmpty) {
      return _Center(
        key: const Key('gc-empty'),
        icon: Icons.forum_outlined,
        title: l.gcEmptyTitle,
        body: l.gcEmptyBody,
        action: l.gcSayHello,
        onAction: () => _send(l.gcHelloText),
      );
    }
    return Semantics(
      label: l.gcMessagesLabel(visible.length),
      child: ListView.builder(
        key: const Key('gc-list'),
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        itemCount: visible.length + 1,
        itemBuilder: (c, i) {
          // Reversed list: the last index is the top, where the channel starts.
          if (i == visible.length) {
            return _ChannelHero(channel: s.channel, l: l);
          }
          final m = visible[visible.length - 1 - i];
          final mine = me != null && m.senderId == me.id;
          final enter = _seen.add(m.id);
          return _Enter(
            key: ValueKey('gc-enter-${m.id}'),
            animate: enter,
            child: _Bubble(
              key: ValueKey('gc-msg-${m.id}'),
              m: m,
              mine: mine,
              onProfile: () => _openProfile(m),
              onActions: mine || m.isPolie
                  ? null
                  : () => _actions(m, s.muted.contains(m.senderId)),
            ),
          );
        },
      ),
    );
  }
}

class _ManageSheet extends ConsumerStatefulWidget {
  const _ManageSheet({required this.names});
  final Map<String, String> names;
  @override
  ConsumerState<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends ConsumerState<_ManageSheet> {
  late Future<List<BlockedChatPerson>> _blocked = ref
      .read(globalChatControllerProvider.notifier)
      .loadBlocked();

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final c = ref.read(globalChatControllerProvider.notifier);
    final muted = ref.watch(globalChatControllerProvider).muted;
    Widget head(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    );
    Widget none() => ListTile(
      title: Text(l.gcNobody, style: const TextStyle(color: _muted)),
    );
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('gc-manage'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            head(l.gcMutedTitle),
            if (muted.isEmpty) none(),
            for (final id in muted)
              ListTile(
                title: Text(widget.names[id] ?? id),
                trailing: TextButton(
                  key: Key('gc-unmute-$id'),
                  onPressed: () => c.unmute(id),
                  child: Text(l.gcUnmute),
                ),
              ),
            head(l.gcBlockedTitle),
            FutureBuilder<List<BlockedChatPerson>>(
              future: _blocked,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rows = snap.data ?? const <BlockedChatPerson>[];
                if (rows.isEmpty) return none();
                return Column(
                  children: [
                    for (final p in rows)
                      ListTile(
                        title: Text(p.name.isEmpty ? p.id : p.name),
                        trailing: TextButton(
                          key: Key('gc-unblock-${p.id}'),
                          onPressed: () async {
                            await c.unblock(p.id);
                            setState(() => _blocked = c.loadBlocked());
                          },
                          child: Text(l.gcUnblock),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Channel start, as in group-chat references: identity badge, welcome and
/// a native greeting. Sits at the top of the conversation.
class _ChannelHero extends StatelessWidget {
  const _ChannelHero({required this.channel, required this.l});
  final String channel;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final (accent, greeting) = channelLook(channel);
    final name = '\u2068${channelLabel(l, channel)}\u2069';
    return Padding(
      key: const Key('gc-hero'),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: const Icon(Icons.tag_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            l.gcHeroTitle(name),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(l.gcHeroBody(name), style: const TextStyle(color: _muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.gcGreetingIn('\u2068$greeting\u2069'),
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: _line, height: 1),
        ],
      ),
    );
  }
}

/// New messages fade and rise in; skipped entirely when reduce motion is on.
class _Enter extends StatefulWidget {
  const _Enter({super.key, required this.animate, required this.child});
  final bool animate;
  final Widget child;
  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_a.isAnimating || _a.isCompleted) return;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (widget.animate && !reduce) {
      _a.forward();
    } else {
      _a.value = 1;
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _a, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

class _PolieTile extends StatelessWidget {
  const _PolieTile({required this.l});
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _line),
      ),
      child: ListTile(
        key: const Key('gc-polie'),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE6E8F5),
          child: Icon(Icons.smart_toy_outlined, color: _navy),
        ),
        title: Text(
          l.gcPolieTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        subtitle: Text(l.gcPolieSub, style: const TextStyle(color: _muted)),
        trailing: const Icon(Icons.chevron_right, color: _navy),
        onTap: () => Navigator.pushNamed(context, 'lingchat_ai'),
      ),
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B4E00)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF4A3600), fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: _navy),
          child: Text(action),
        ),
      ],
    ),
  );
}

class _Center extends StatelessWidget {
  const _Center({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String title, body, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: _navy),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              minimumSize: const Size(48, 48),
            ),
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.mine});
  final bool mine;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: mine ? 160 : 220,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

String _ago(BuildContext context, DateTime? t) {
  if (t == null) return '';
  final l = l10nOf(context);
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.gcNow;
  if (d.inHours < 1) return l.gcMinAgo(d.inMinutes);
  if (d.inDays < 1) return l.gcHourAgo(d.inHours);
  return intl.DateFormat.MMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(t.toLocal());
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.m});
  final ChatMessage m;
  @override
  Widget build(BuildContext context) {
    final initial = m.senderName.isEmpty
        ? '?'
        : m.senderName.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: m.isPolie ? const Color(0xFFE6E8F5) : _navy,
      foregroundImage: m.avatarUrl == null ? null : NetworkImage(m.avatarUrl!),
      onForegroundImageError: m.avatarUrl == null ? null : (_, _) {},
      child: m.isPolie
          ? const Icon(Icons.smart_toy_outlined, size: 18, color: _navy)
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    super.key,
    required this.m,
    required this.mine,
    required this.onProfile,
    this.onActions,
  });
  final ChatMessage m;
  final bool mine;
  final VoidCallback onProfile;
  final VoidCallback? onActions;
  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final m = widget.m;
    final mine = widget.mine;
    final pending = m.sendState == ChatSendState.pending;
    final hide = m.flagged && !_reveal;
    final time = _ago(context, m.createdAt);
    final name = mine ? l.gcYou : m.senderName;

    final head = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            m.handle == null || mine || m.isPolie
                ? name
                : '$name · ${_iso('@${m.handle}')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
        if (time.isNotEmpty || pending) ...[
          const SizedBox(width: 6),
          Text(
            pending ? l.gcSending : time,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ],
    );

    final body = hide
        ? Wrap(
            key: const Key('gc-flagged'),
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: _muted),
              Text(
                l.gcFlagged,
                style: const TextStyle(
                  color: _muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _reveal = true),
                style: TextButton.styleFrom(foregroundColor: _navy),
                child: Text(l.gcShow),
              ),
            ],
          )
        : Text(
            m.text,
            // Each message keeps its own direction (Latin text in an Arabic UI
            // must not have its punctuation flipped, and vice versa).
            textDirection: intl.Bidi.detectRtlDirectionality(m.text)
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: mine ? Colors.white : _ink,
            ),
          );

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? _navy : Colors.white,
        border: mine ? null : Border.all(color: _line),
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(18),
          topEnd: const Radius.circular(18),
          bottomStart: Radius.circular(mine ? 18 : 4),
          bottomEnd: Radius.circular(mine ? 4 : 18),
        ),
      ),
      child: body,
    );

    return Opacity(
      opacity: pending ? 0.7 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              Semantics(
                button: true,
                label: l.gcOpenProfile(m.senderName),
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onProfile,
                  child: _Avatar(m: m),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GestureDetector(
                  onLongPress: widget.onActions,
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [head, const SizedBox(height: 4), bubble],
                  ),
                ),
              ),
            ),
            if (widget.onActions != null)
              IconButton(
                key: Key('gc-actions-${m.id}'),
                tooltip: l.gcMore,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_horiz, color: _muted),
                onPressed: widget.onActions,
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.l,
    required this.compact,
  });
  final bool compact;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _line)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kGlobalChatMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('gc-input'),
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(color: _ink),
                    decoration: InputDecoration(
                      // Large text: the short hint fits instead of being cut.
                      hintText: compact ? l.gcHintShort : l.gcHint,
                      hintMaxLines: 2,
                      hintStyle: const TextStyle(color: _muted),
                      filled: true,
                      fillColor: _bg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: sending
                      ? const Padding(
                          key: Key('gc-sending'),
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _navy,
                          ),
                        )
                      : IconButton.filled(
                          key: const Key('gc-send'),
                          tooltip: l.gcSend,
                          style: IconButton.styleFrom(backgroundColor: _navy),
                          onPressed: onSend,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
