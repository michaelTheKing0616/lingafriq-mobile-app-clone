import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/gamification_services_provider.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

/// Personal study notes for a **classroom tribe** (`GET/POST /api/classroom/:tribeId/notes`).
class ClassroomNotesScreen extends ConsumerStatefulWidget {
  const ClassroomNotesScreen({
    super.key,
    this.initialTribeId,
    this.initialRoomName,
  });

  final String? initialTribeId;
  final String? initialRoomName;

  @override
  ConsumerState<ClassroomNotesScreen> createState() => _ClassroomNotesScreenState();
}

class _ClassroomNotesScreenState extends ConsumerState<ClassroomNotesScreen> {
  String? _tribeId;
  String? _roomName;
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  bool _loadingClassrooms = false;
  String? _error;
  List<Map<String, dynamic>> _classrooms = [];
  bool _routeResolved = false;

  @override
  void initState() {
    super.initState();
    _tribeId = widget.initialTribeId;
    _roomName = widget.initialRoomName;
    if (_tribeId == null || _tribeId!.isEmpty) {
      _loading = false;
      _loadingClassrooms = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeResolved) return;
    _routeResolved = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final tid = args['tribeId']?.toString();
      final name = args['roomName']?.toString();
      if (tid != null && tid.isNotEmpty) {
        _tribeId = tid;
        if (name != null && name.isNotEmpty) _roomName = name;
      }
    }
    if (_tribeId != null && _tribeId!.isNotEmpty) {
      _loadNotes();
    } else {
      _loadClassroomPicker();
    }
  }

  Future<void> _loadClassroomPicker() async {
    setState(() {
      _loadingClassrooms = true;
      _error = null;
    });
    try {
      final tribes =
          await ref.read(tribesServiceProvider).getAllTribes(includeClassrooms: true);
      final rooms = tribes.where((t) => t['is_classroom'] == true).toList();
      setState(() {
        _classrooms = rooms;
        _loadingClassrooms = false;
      });
    } catch (e) {
      setState(() {
        _loadingClassrooms = false;
        _error = e is DioException ? (e.message ?? 'Network error') : '$e';
      });
    }
  }

  Future<void> _loadNotes() async {
    final id = _tribeId;
    if (id == null || id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(classroomServiceProvider).listNotes(id);
      setState(() {
        _notes = result.notes;
        final meta = result.meta;
        if (meta != null) {
          _roomName = meta['tribe_name']?.toString() ?? _roomName;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e is DioException ? (e.message ?? 'Could not load notes') : '$e';
      });
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final id = _tribeId;
    if (id == null) return;
    await ref.read(classroomServiceProvider).deleteNote(id, noteId);
    await _loadNotes();
  }

  Future<void> _togglePin(Map<String, dynamic> note) async {
    final id = _tribeId;
    if (id == null) return;
    final noteId = _noteId(note);
    await ref.read(classroomServiceProvider).updateNote(
          id,
          noteId,
          pinned: !(note['pinned'] == true),
        );
    await _loadNotes();
  }

  String _noteId(Map<String, dynamic> note) =>
      note['id']?.toString() ?? note['_id']?.toString() ?? '';

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final id = _tribeId;
    if (id == null) return;
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final bodyCtrl = TextEditingController(text: existing?['body']?.toString() ?? '');
    final tagsCtrl = TextEditingController(
      text: (existing?['tags'] is List)
          ? (existing!['tags'] as List).whereType<String>().join(', ')
          : '',
    );
    var pinned = existing?['pinned'] == true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'New note' : 'Edit note',
                      style: ModernGriotTypography.titleMedium(),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: bodyCtrl,
                      minLines: 5,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: tagsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SwitchListTile(
                      title: const Text('Pin to top'),
                      value: pinned,
                      onChanged: (v) => setModal(() => pinned = v),
                    ),
                    SizedBox(height: 16.h),
                    FilledButton(
                      onPressed: () async {
                        final tags = tagsCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        try {
                          if (existing == null) {
                            await ref.read(classroomServiceProvider).createNote(
                                  id,
                                  title: titleCtrl.text.trim(),
                                  body: bodyCtrl.text,
                                  tags: tags,
                                  pinned: pinned,
                                );
                          } else {
                            await ref.read(classroomServiceProvider).updateNote(
                                  id,
                                  _noteId(existing),
                                  title: titleCtrl.text.trim(),
                                  body: bodyCtrl.text,
                                  tags: tags,
                                  pinned: pinned,
                                );
                          }
                          if (context.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                      child: Text(existing == null ? 'Save note' : 'Update note'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (saved == true) await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_tribeId == null || _tribeId!.isEmpty) {
      return _buildPickerScaffold(cs);
    }

    return GriotScaffold(
      appBar: AppBar(
        title: Text(_roomName ?? 'Classroom notes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add note'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(color: cs.outline)),
          ),
          RefreshIndicator(
            onRefresh: _loadNotes,
            child: _buildBody(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded, size: 48.sp, color: cs.error),
                SizedBox(height: 12.h),
                Text(_error!, textAlign: TextAlign.center),
                SizedBox(height: 16.h),
                FilledButton(onPressed: _loadNotes, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }
    if (_notes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              children: [
                Icon(Icons.note_alt_outlined, size: 56.sp, color: cs.outline),
                SizedBox(height: 16.h),
                Text(
                  'No notes yet',
                  style: ModernGriotTypography.titleMedium(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Capture vocabulary, grammar, and ideas from this classroom. '
                  'Everything is private to your account.',
                  style: ModernGriotTypography.bodySmall(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
      itemCount: _notes.length,
      itemBuilder: (context, i) {
        final n = _notes[i];
        final title = n['title']?.toString() ?? '';
        final body = n['body']?.toString() ?? '';
        final pinned = n['pinned'] == true;
        final updated = n['updated_at'] ?? n['created_at'];
        DateTime? dt;
        if (updated != null) {
          dt = DateTime.tryParse(updated.toString());
        }
        final subtitle = dt != null
            ? DateFormat.yMMMd().add_jm().format(dt.toLocal())
            : '';

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GriotCard(
            surfaceLevel: pinned ? 2 : 1,
            onTap: () => _openEditor(existing: n),
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pinned) ...[
                      Icon(Icons.push_pin_rounded,
                          size: 18.sp, color: ModernGriotColors.primary),
                      SizedBox(width: 6.w),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: ModernGriotTypography.titleSmall(context: context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        pinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 20.sp,
                      ),
                      onPressed: () => _togglePin(n),
                      tooltip: pinned ? 'Unpin' : 'Pin',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 20.sp, color: cs.error),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete note?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await _deleteNote(_noteId(n));
                      },
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(subtitle, style: ModernGriotTypography.labelSmall()),
                ],
                SizedBox(height: 8.h),
                Text(
                  body.length > 220 ? '${body.substring(0, 220)}…' : body,
                  style: ModernGriotTypography.bodySmall(context: context),
                ),
                if (n['tags'] is List && (n['tags'] as List).isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      for (final t in (n['tags'] as List).whereType<String>())
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(28),
                            borderRadius: ModernGriotRadius.borderPill,
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerScaffold(ColorScheme cs) {
    return GriotScaffold(
      appBar: AppBar(title: const Text('Choose a classroom')),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(color: cs.outline)),
          ),
          if (_loadingClassrooms)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    FilledButton(
                      onPressed: _loadClassroomPicker,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_classrooms.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'No classroom tribes found. Create one from Tribes or join with a code.',
                  style: ModernGriotTypography.bodyMedium(),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: _classrooms.length,
              itemBuilder: (context, i) {
                final t = _classrooms[i];
                final tid = t['id']?.toString() ?? '';
                final name = t['name']?.toString() ?? 'Classroom';
                final lang = t['language_tag']?.toString() ?? '';
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: GriotCard(
                    surfaceLevel: 1,
                    onTap: () {
                      setState(() {
                        _tribeId = tid;
                        _roomName = name;
                      });
                      _loadNotes();
                    },
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(30),
                            borderRadius: ModernGriotRadius.borderLg,
                          ),
                          child: Icon(Icons.school_rounded, color: cs.primary, size: 28.sp),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: ModernGriotTypography.titleSmall(context: context)),
                              SizedBox(height: 4.h),
                              Text(
                                lang.toUpperCase(),
                                style: ModernGriotTypography.labelSmall().copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withAlpha(40);
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
