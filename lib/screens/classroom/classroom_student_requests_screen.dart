import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';

/// Teacher view: students waiting for a guardian, and per-student teacher-message approval
/// for school accounts. Plain functional layout (no family/safety reference pack yet).
class ClassroomStudentRequestsScreen extends StatefulWidget {
  const ClassroomStudentRequestsScreen({
    super.key,
    required this.tribeId,
    this.tribeName,
    this.service,
  });

  final String tribeId;
  final String? tribeName;
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
      });
    } on GuardedLoadException catch (e) {
      if (mounted) setState(() => _errorStatus = e.status);
    } catch (_) {
      if (mounted) setState(() => _errorStatus = 0);
    }
  }

  Future<void> _setDm(int id, bool on) async {
    setState(() => _busy.add(id));
    final ok = await _service.setTeacherDm(widget.tribeId, id, approved: on);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (ok) _dm[id] = on;
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
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    Widget body;
    if (_errorStatus != null) {
      body = ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(Icons.info_outline, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            _errorStatus == 403 ? l.gtpNotTeacher : l.gtpError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (_errorStatus != 403) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(onPressed: _load, child: Text(l.gdmRetry)),
            ),
          ],
        ],
      );
    } else if (_data == null) {
      body = const Center(child: CircularProgressIndicator());
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
                    subtitle: Text(
                      s.accountActive ? l.gtpTeacherDm : l.gtpLocked,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: _dm[s.studentUserId] ?? false,
                    onChanged:
                        !s.accountActive || _busy.contains(s.studentUserId)
                        ? null
                        : (v) => _setDm(s.studentUserId, v),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // Title and class name live in the body so they wrap at 320dp, 200%
    // and in Arabic instead of being cut off in the app bar.
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.gtpTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
