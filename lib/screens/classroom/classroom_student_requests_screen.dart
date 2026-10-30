import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';
import 'package:lingafriq/theme/guarded_theme.dart';

/// Teacher view: students waiting for a guardian, and per-student teacher-message approval
/// for school accounts. Reference pack: docs/design/references/teacher-requests
/// (recoloured, own copy). Turning messages on or off asks for confirmation.
class ClassroomStudentRequestsScreen extends StatefulWidget {
  const ClassroomStudentRequestsScreen({
    super.key,
    required this.tribeId,
    this.tribeName,
    this.service,
    this.now,
  });

  final String tribeId;
  final String? tribeName;

  /// Clock for "Expires in N days" (tests pin it).
  final DateTime Function()? now;
  final GuardedMessagingService? service;

  @override
  State<ClassroomStudentRequestsScreen> createState() =>
      _ClassroomStudentRequestsScreenState();
}

class _ClassroomStudentRequestsScreenState
    extends State<ClassroomStudentRequestsScreen> {
  late final GuardedMessagingService _service =
      widget.service ?? GuardedMessagingService();
  ClassroomStudentRequests? _data;
  int? _errorStatus;
  final Set<int> _busy = {};
  final Map<int, bool> _dm = {};
  final Map<int, DateTime?> _expiry = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _errorStatus = null;
      _data = null;
    });
    try {
      final d = await _service.studentRequests(widget.tribeId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _dm
          ..clear()
          ..addEntries(
            d.school.map((s) => MapEntry(s.studentUserId, s.teacherDmApproved)),
          );
        _expiry
          ..clear()
          ..addEntries(
            d.school.map(
              (s) => MapEntry(s.studentUserId, s.teacherDmExpiresAt),
            ),
          );
      });
    } on GuardedLoadException catch (e) {
      if (mounted) setState(() => _errorStatus = e.status);
    } catch (_) {
      if (mounted) setState(() => _errorStatus = 0);
    }
  }

  Future<void> _confirmDm(int id, String name, bool on) async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('gtp-dm-confirm'),
        title: Text(on ? l.gtpDmOnTitle(name) : l.gtpDmOffTitle(name)),
        content: Text(on ? l.gtpDmOnBody : l.gtpDmOffBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.gapCancel),
          ),
          FilledButton(
            key: const ValueKey('gtp-dm-confirm-yes'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(on ? l.gtpDmOnAction : l.gtpDmOffAction),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await _setDm(id, on);
  }

  Future<void> _setDm(int id, bool on) async {
    setState(() => _busy.add(id));
    final ok = await _service.setTeacherDm(widget.tribeId, id, approved: on);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (ok) {
        _dm[id] = on;
        // Server approvals last a year; show that until the next refresh.
        _expiry[id] = on ? DateTime.now().add(const Duration(days: 365)) : null;
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.gdmActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = guardedTheme(Theme.of(context));
    final loc = MaterialLocalizations.of(context);
    final now = widget.now?.call() ?? DateTime.now();
    Widget body;
    if (_errorStatus != null) {
      body = ListView(
        key: const ValueKey('gtp-error'),
        padding: const EdgeInsets.all(32),
        children: [
          // A real error badge: "not your class" is a lock, anything else is
          // a connection problem, never a neutral info icon.
          Center(
            child: Container(
              key: const ValueKey('gtp-error-icon'),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _errorStatus == 403
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _errorStatus == 403
                    ? Icons.lock_outline
                    : Icons.cloud_off_outlined,
                size: 40,
                color: _errorStatus == 403
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorStatus == 403 ? l.gtpNotTeacher : l.gtpError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (_errorStatus != 403) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(l.gdmRetry),
              ),
            ),
          ],
        ],
      );
    } else if (_data == null) {
      body = Semantics(
        key: const ValueKey('gtp-loading'),
        label: l.gtpLoading,
        liveRegion: true,
        child: ExcludeSemantics(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: List.generate(
              4,
              (_) => Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (_data!.waiting.isEmpty && _data!.school.isEmpty) {
      body = ListView(
        key: const ValueKey('gtp-empty'),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.group_add_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l.gtpEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.gtpEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    } else {
      final d = _data!;
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(title: l.gtpWaitingSection, help: l.gtpWaitingHelp),
            if (d.waiting.isEmpty)
              _EmptyLine(text: l.gtpWaitingEmpty)
            else
              ...d.waiting.map(
                (p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_top_outlined),
                    title: Text(p.name ?? l.gtpStudent(p.studentUserId)),
                    subtitle: p.submittedAt == null
                        ? null
                        : Text(
                            l.gtpSince(
                              loc.formatMediumDate(p.submittedAt!.toLocal()),
                            ),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _Header(title: l.gtpSchoolSection, help: l.gtpSchoolHelp),
            if (d.school.isEmpty)
              _EmptyLine(text: l.gtpSchoolEmpty)
            else
              ...d.school.map(
                (s) => Card(
                  child: SwitchListTile(
                    key: ValueKey('gtp-dm-${s.studentUserId}'),
                    // Locked rows keep full-contrast text; the lock icon and
                    // subtitle say why the switch is off.
                    secondary: Icon(
                      s.accountActive
                          ? Icons.school_outlined
                          : Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      s.name ?? l.gtpStudent(s.studentUserId),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: _SchoolRowDetails(
                      student: s,
                      on: _dm[s.studentUserId] ?? false,
                      expiry: _expiry[s.studentUserId],
                      now: now,
                      formatDate: (d) => loc.formatMediumDate(d.toLocal()),
                    ),
                    value: _dm[s.studentUserId] ?? false,
                    onChanged:
                        !s.accountActive || _busy.contains(s.studentUserId)
                        ? null
                        : (v) => _confirmDm(
                            s.studentUserId,
                            s.name ?? l.gtpStudent(s.studentUserId),
                            v,
                          ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // Title and class name live in the body so they wrap at 320dp, 200%
    // and in Arabic instead of being cut off in the app bar.
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GuardedHeadline(
                    l.gtpTitle,
                    key: const ValueKey('gtp-title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.tribeName != null)
                    Text(
                      widget.tribeName!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Status line plus chips: "Verified by school", "Allow until …",
/// "Expires in N days". Text stays full contrast even when the switch is off.
class _SchoolRowDetails extends StatelessWidget {
  const _SchoolRowDetails({
    required this.student,
    required this.on,
    required this.expiry,
    required this.now,
    required this.formatDate,
  });

  final SchoolStudent student;
  final bool on;
  final DateTime? expiry;
  final DateTime now;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final id = student.studentUserId;
    final days = expiry == null
        ? null
        : (expiry!.difference(now).inHours / 24).ceil().clamp(0, 9999);
    Widget chip(
      String key,
      IconData icon,
      String text, {
      bool strong = false,
    }) => Container(
      key: ValueKey('$key-$id'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strong
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: strong ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: strong ? scheme.onPrimaryContainer : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.accountActive ? l.gtpTeacherDm : l.gtpLocked,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (student.accountActive || (on && expiry != null)) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (student.accountActive)
                chip(
                  'gtp-verified',
                  Icons.verified_outlined,
                  l.gtpVerified,
                  strong: true,
                ),
              if (on && expiry != null) ...[
                chip(
                  'gtp-until',
                  Icons.event_available_outlined,
                  l.gtpAllowUntil(formatDate(expiry!)),
                ),
                chip(
                  'gtp-expires',
                  Icons.timer_outlined,
                  l.gtpExpiresIn(days!),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.help});
  final String title;
  final String help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            help,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
