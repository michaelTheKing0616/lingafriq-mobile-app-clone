import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/staff/micro_mentor_moderation_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

final microMentorModerationServiceProvider = Provider<MicroMentorModerationService>(
  (ref) => MicroMentorModerationService(),
);

/// Staff/admin queue for micro-mentor safety reports.
class StaffMicroMentorReportsScreen extends ConsumerStatefulWidget {
  const StaffMicroMentorReportsScreen({super.key});

  @override
  ConsumerState<StaffMicroMentorReportsScreen> createState() => _StaffMicroMentorReportsScreenState();
}

class _StaffMicroMentorReportsScreenState extends ConsumerState<StaffMicroMentorReportsScreen> {
  static const _statusFilters = ['', 'open', 'reviewed', 'closed'];

  String _statusFilter = 'open';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int _total = 0;
  static const _pageSize = 40;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final profile = ref.read(userProvider);
    if (profile == null || !profile.isStaffOrAdmin) {
      setState(() {
        _loading = false;
        _error = 'Staff or admin access required.';
      });
      return;
    }
    await ref.read(userProvider.notifier).refreshUser();
    if (!mounted) return;
    final after = ref.read(userProvider);
    if (after == null || !after.isStaffOrAdmin) {
      setState(() {
        _loading = false;
        _error = 'Staff or admin access required.';
      });
      return;
    }
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _rows = [];
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = ref.read(microMentorModerationServiceProvider);
      final r = await svc.listReports(
        status: _statusFilter.isEmpty ? null : _statusFilter,
        limit: _pageSize,
        offset: reset ? 0 : _rows.length,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _rows = r.rows;
        } else {
          _rows = [..._rows, ...r.rows];
        }
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _reportId(Map<String, dynamic> row) {
    final id = row['_id'] ?? row['id'];
    return id?.toString() ?? '';
  }

  String _statusLabel(Map<String, dynamic> row) {
    final s = row['status']?.toString();
    if (s == null || s.isEmpty) return 'open';
    return s;
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final id = _reportId(row);
    if (id.isEmpty) return;
    final noteCtrl = TextEditingController(text: row['reviewNote']?.toString() ?? '');
    final session = row['sessionId'];
    Map<String, dynamic>? sessionMap;
    if (session is Map) sessionMap = Map<String, dynamic>.from(session);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.lg,
            right: PanAfricanSpacing.lg,
            top: PanAfricanSpacing.sm,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + PanAfricanSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Report', style: PanAfricanTypography.titleLarge(context)),
                SizedBox(height: PanAfricanSpacing.sm),
                Text('Category: ${row['category']}', style: PanAfricanTypography.bodyMedium(context)),
                Text('Status: ${_statusLabel(row)}', style: PanAfricanTypography.bodyMedium(context)),
                Text('Reporter: ${row['reporterUserId']}', style: PanAfricanTypography.bodySmall(context)),
                Text('Session: ${sessionMap?['_id'] ?? row['sessionId']}', style: PanAfricanTypography.bodySmall(context)),
                if (sessionMap != null) ...[
                  Text('Session language: ${sessionMap['language']}', style: PanAfricanTypography.bodySmall(context)),
                  Text('Session status: ${sessionMap['status']}', style: PanAfricanTypography.bodySmall(context)),
                ],
                SizedBox(height: PanAfricanSpacing.sm),
                Text('Details', style: PanAfricanTypography.titleSmall(context)),
                Text(row['details']?.toString() ?? '—', style: PanAfricanTypography.bodyMedium(context)),
                SizedBox(height: PanAfricanSpacing.md),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Internal note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Wrap(
                  spacing: PanAfricanSpacing.sm,
                  runSpacing: PanAfricanSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _patch(id, 'reviewed', noteCtrl.text.trim());
                      },
                      child: const Text('Mark reviewed'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _patch(id, 'closed', noteCtrl.text.trim());
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _patch(id, 'open', noteCtrl.text.trim());
                      },
                      child: const Text('Reopen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    noteCtrl.dispose();
  }

  Future<void> _patch(String reportId, String status, String reviewNote) async {
    try {
      await ref.read(microMentorModerationServiceProvider).patchReport(
            reportId: reportId,
            status: status,
            reviewNote: reviewNote.isEmpty ? null : reviewNote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated to $status')));
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocked = _error == 'Staff or admin access required.';

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Micro-mentor reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: blocked
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodyLarge(context),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.sm),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _statusFilters)
                          Padding(
                            padding: EdgeInsets.only(right: PanAfricanSpacing.xs),
                            child: FilterChip(
                              label: Text(s.isEmpty ? 'All' : s),
                              selected: _statusFilter == s,
                              onSelected: (_) {
                                setState(() => _statusFilter = s);
                                _load(reset: true);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_error != null && !blocked)
                  Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Expanded(
                  child: _loading && _rows.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => _load(reset: true),
                          child: ListView.builder(
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            itemCount: _rows.length + (_rows.length < _total ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == _rows.length) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () async {
                                              setState(() => _loading = true);
                                              try {
                                                final svc = ref.read(microMentorModerationServiceProvider);
                                                final r = await svc.listReports(
                                                  status: _statusFilter.isEmpty ? null : _statusFilter,
                                                  limit: _pageSize,
                                                  offset: _rows.length,
                                                );
                                                if (!mounted) return;
                                                setState(() {
                                                  _rows = [..._rows, ...r.rows];
                                                  _total = r.total;
                                                  _loading = false;
                                                });
                                              } catch (e) {
                                                if (!mounted) return;
                                                setState(() {
                                                  _error = e.toString();
                                                  _loading = false;
                                                });
                                              }
                                            },
                                      child: const Text('Load more'),
                                    ),
                                  ),
                                );
                              }
                              final row = _rows[i];
                              final cat = row['category']?.toString() ?? '';
                              final st = _statusLabel(row);
                              return Card(
                                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                                child: ListTile(
                                  title: Text(cat, style: PanAfricanTypography.titleSmall(context)),
                                  subtitle: Text(
                                    () {
                                      final d = row['details']?.toString() ?? '';
                                      return d.length > 120 ? '${d.substring(0, 120)}…' : d;
                                    }(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Chip(label: Text(st)),
                                  onTap: () => _openDetail(row),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                if (_total > 0)
                  Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.sm),
                    child: Text(
                      'Showing ${_rows.length} of $_total',
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ),
              ],
            ),
    );
  }
}
