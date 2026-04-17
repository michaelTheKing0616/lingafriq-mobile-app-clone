import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ClassroomAssignmentsScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;

  const ClassroomAssignmentsScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
  });

  @override
  ConsumerState<ClassroomAssignmentsScreen> createState() => _ClassroomAssignmentsScreenState();
}

class _ClassroomAssignmentsScreenState extends ConsumerState<ClassroomAssignmentsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _assignments = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(classroomServiceProvider).listAssignmentsV2(widget.tribeId);
      final raw = res['assignments'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) list.add(e.cast<String, dynamic>());
        }
      }
      if (!mounted) return;
      setState(() {
        _assignments = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error = 'Unable to load assignments right now.';
        _loading = false;
      });
    }
  }

  Future<void> _createAssignment() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateAssignmentDialog(
        onSubmit: (v) async {
          await ref.read(classroomServiceProvider).createAssignmentV2(
                widget.tribeId,
                title: v.title,
                description: v.description,
                type: v.type,
                dueAt: v.dueAt,
                payload: v.payload,
              );
        },
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignments: ${widget.tribeName}',
          style: PanAfricanTypography.titleLarge(context),
        ),
        actions: [
          IconButton(
            tooltip: 'New assignment',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _createAssignment();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: PanAfricanTypography.bodyLarge(context)),
                        SizedBox(height: PanAfricanSpacing.md),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: PanAfricanColors.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    itemCount: _assignments.length,
                    separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
                    itemBuilder: (context, i) {
                      final a = _assignments[i];
                      return _AssignmentCard(isDark: isDark, assignment: a);
                    },
                  ),
                ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.isDark, required this.assignment});

  final bool isDark;
  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final title = assignment['title']?.toString() ?? 'Assignment';
    final description = assignment['description']?.toString();
    final type = assignment['type']?.toString() ?? 'custom';
    final dueAtRaw = assignment['dueAt']?.toString();
    final mySubmission = assignment['mySubmission'];
    DateTime? dueAt;
    if (dueAtRaw != null && dueAtRaw.isNotEmpty) {
      dueAt = DateTime.tryParse(dueAtRaw);
    }
    final dueLabel = dueAt == null ? null : DateFormat.yMMMEd().add_Hm().format(dueAt.toLocal());

    final submitted = mySubmission is Map ? (mySubmission['status']?.toString() ?? '').isNotEmpty : false;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: PanAfricanTypography.titleSmall(context)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm, vertical: PanAfricanSpacing.xxxs),
                decoration: BoxDecoration(
                  color: PanAfricanColors.primaryContainer,
                  borderRadius: PanAfricanRadius.roundBR,
                ),
                child: Text(
                  type,
                  style: PanAfricanTypography.labelSmall(
                    context,
                    color: PanAfricanColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text(description, style: PanAfricanTypography.bodySmall(context)),
          ],
          if (dueLabel != null) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text('Due: $dueLabel', style: PanAfricanTypography.labelSmall(context)),
          ],
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Icon(
                submitted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: submitted ? PanAfricanColors.success : PanAfricanColors.neutralMedium,
                size: 18,
              ),
              SizedBox(width: PanAfricanSpacing.xs),
              Text(
                submitted ? 'Submitted' : 'Not submitted',
                style: PanAfricanTypography.labelSmall(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateAssignmentValue {
  final String title;
  final String? description;
  final String type;
  final DateTime? dueAt;
  final Map<String, dynamic>? payload;

  const _CreateAssignmentValue({
    required this.title,
    required this.type,
    this.description,
    this.dueAt,
    this.payload,
  });
}

class _CreateAssignmentDialog extends StatefulWidget {
  const _CreateAssignmentDialog({required this.onSubmit});
  final Future<void> Function(_CreateAssignmentValue value) onSubmit;

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _type = 'custom';
  DateTime? _dueAt;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (t == null) return;
    setState(() {
      _dueAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _CreateAssignmentValue(
          title: title,
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          type: _type,
          dueAt: _dueAt,
          payload: const {},
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueAt == null ? 'No due date' : DateFormat.yMMMEd().add_Hm().format(_dueAt!);
    return AlertDialog(
      title: const Text('New assignment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: 160,
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
              maxLength: 4000,
            ),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'custom', child: Text('Custom')),
                DropdownMenuItem(value: 'speaking_mission', child: Text('Speaking mission')),
                DropdownMenuItem(value: 'srs_review', child: Text('SRS review')),
                DropdownMenuItem(value: 'reading', child: Text('Reading')),
              ],
              onChanged: _saving ? null : (v) => setState(() => _type = v ?? 'custom'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(dueLabel)),
                TextButton(
                  onPressed: _saving ? null : _pickDueAt,
                  child: const Text('Set due'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Creating…' : 'Create'),
        ),
      ],
    );
  }
}

