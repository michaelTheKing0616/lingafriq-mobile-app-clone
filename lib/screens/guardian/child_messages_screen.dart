import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';

/// Guardian view: who is messaging a linked learner. Metadata only, never message text.
/// Plain functional layout (no family/safety reference pack yet; see HANDOFF.md).
class GuardianChildMessagesScreen extends StatefulWidget {
  const GuardianChildMessagesScreen({super.key, required this.childUserId, this.service});

  final int childUserId;
  final GuardedMessagingService? service;

  @override
  State<GuardianChildMessagesScreen> createState() => _GuardianChildMessagesScreenState();
}

class _GuardianChildMessagesScreenState extends State<GuardianChildMessagesScreen> {
  late final GuardedMessagingService _service = widget.service ?? GuardedMessagingService();
  List<ChildDmThread>? _threads;
  bool _error = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _threads = null;
    });
    try {
      final t = await _service.childThreads(widget.childUserId);
      if (mounted) setState(() => _threads = t);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _toggle(ChildDmThread t) async {
    final l = AppLocalizations.of(context)!;
    final peer = t.peerUserId;
    if (peer == null) return;
    if (!t.revoked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.gdmStopConfirmTitle(t.peerName ?? l.gdmUnknownName)),
          content: Text(l.gdmStopConfirmBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.gdmCancel)),
            FilledButton(
              key: const ValueKey('gdm-confirm-stop'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.gdmStop),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy.add(peer));
    final done = await _service.setPeerStopped(widget.childUserId, peer, stopped: !t.revoked);
    if (!mounted) return;
    setState(() {
      _busy.remove(peer);
      if (done) {
        _threads = [for (final x in _threads!) x.peerUserId == peer ? x.copyWith(revoked: !t.revoked) : x];
      }
    });
    if (!done) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.gdmActionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget body;
    if (_error) {
      body = _Centered(
        icon: Icons.cloud_off_outlined,
        title: l.gdmError,
        action: OutlinedButton(onPressed: _load, child: Text(l.gdmRetry)),
      );
    } else if (_threads == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_threads!.isEmpty) {
      body = _Centered(icon: Icons.forum_outlined, title: l.gdmEmptyTitle, body: l.gdmEmptyBody);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _threads!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ThreadCard(
            thread: _threads![i],
            busy: _busy.contains(_threads![i].peerUserId),
            onToggle: () => _toggle(_threads![i]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.gdmTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.visibility_off_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l.gdmIntro, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.busy, required this.onToggle});

  final ChildDmThread thread;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final role = switch (thread.role) {
      PeerRole.teacher => l.gdmRoleTeacher,
      PeerRole.classmate => l.gdmRoleClassmate,
      PeerRole.contact => l.gdmRoleContact,
    };
    final when = thread.lastActivityAt == null
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(thread.lastActivityAt!.toLocal());
    final flagged = thread.reportCount > 0 || thread.blockedMessageCount > 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    thread.role == PeerRole.teacher ? Icons.school_outlined : Icons.person_outline,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.peerName ?? l.gdmUnknownName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(role, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(icon: Icons.chat_bubble_outline, text: l.gdmMessages(thread.messageCount)),
                _Pill(
                  icon: Icons.flag_outlined,
                  text: l.gdmReports(thread.reportCount),
                  warn: thread.reportCount > 0,
                ),
                if (thread.blockedMessageCount > 0)
                  _Pill(icon: Icons.shield_outlined, text: l.gdmBlocked(thread.blockedMessageCount), warn: true),
              ],
            ),
            if (when != null) ...[
              const SizedBox(height: 8),
              Text(l.gdmLastActive(when), style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: thread.revoked
                    ? OutlinedButton.icon(
                        key: ValueKey('gdm-allow-${thread.peerUserId}'),
                        onPressed: busy ? null : onToggle,
                        icon: const Icon(Icons.undo),
                        label: Text(l.gdmAllow),
                      )
                    : flagged
                        ? FilledButton.icon(
                            key: ValueKey('gdm-stop-${thread.peerUserId}'),
                            onPressed: busy ? null : onToggle,
                            icon: const Icon(Icons.block),
                            label: Text(l.gdmStop),
                          )
                        : OutlinedButton.icon(
                            key: ValueKey('gdm-stop-${thread.peerUserId}'),
                            onPressed: busy ? null : onToggle,
                            icon: const Icon(Icons.block),
                            label: Text(l.gdmStop),
                          ),
              ),
            ),
            if (thread.revoked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.gdmStopped,
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.warn = false});
  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = warn ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warn ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg))),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.title, this.body, this.action});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(body!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
        if (action != null) ...[const SizedBox(height: 16), Center(child: action!)],
      ],
    );
  }
}
