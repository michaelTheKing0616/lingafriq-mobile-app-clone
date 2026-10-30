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
  State<ClassroomStudentRequestsScreen> createState() => _ClassroomStudentRequestsScreenState();
}

class _ClassroomStudentRequestsScreenState extends State<ClassroomStudentRequestsScreen> {
  late final GuardedMessagingService _service = widget.service ?? GuardedMessagingService();
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
          ..addEntries(d.school.map((s) => MapEntry(s.studentUserId, s.teacherDmApproved)));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.gdmActionFailed)));
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
            Center(child: OutlinedButton(onPressed: _load, child: Text(l.gdmRetry))),
          ],
        ],
      );
    } else if (_data == null) {
      body = const Center(child: CircularProgressIndicator());
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
                        : Text(l.gtpSince(loc.formatMediumDate(p.submittedAt!.toLocal()))),
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
                    secondary: const Icon(Icons.school_outlined),
                    title: Text(s.name ?? l.gtpStudent(s.studentUserId)),
                    subtitle: Text(s.accountActive ? l.gtpTeacherDm : l.gtpPendingConsent),
                    value: _dm[s.studentUserId] ?? false,
                    onChanged: !s.accountActive || _busy.contains(s.studentUserId)
                        ? null
                        : (v) => _setDm(s.studentUserId, v),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.tribeName == null ? l.gtpTitle : '${l.gtpTitle} · ${widget.tribeName}')),
      body: body,
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
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(help, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
