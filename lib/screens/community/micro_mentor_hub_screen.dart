import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/community/micro_mentor_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

import 'micro_mentor_session_detail_screen.dart';

class MicroMentorHubScreen extends ConsumerStatefulWidget {
  const MicroMentorHubScreen({super.key});

  @override
  ConsumerState<MicroMentorHubScreen> createState() => _MicroMentorHubScreenState();
}

class _MicroMentorHubScreenState extends ConsumerState<MicroMentorHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _langCtrl = TextEditingController(text: 'yoruba');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestSession({
    required String mentorUserId,
    required String language,
  }) async {
    final now = DateTime.now().add(const Duration(minutes: 10));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;

    final start = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      final id = await ref.read(microMentorServiceProvider).requestSession(
            mentorUserId: mentorUserId,
            language: language,
            scheduledStartTime: start,
            durationMinutes: 10,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == 'queued' ? 'Queued offline. Will sync automatically.' : 'Requested session: $id'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Micro‑Mentors'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Find mentors'),
            Tab(text: 'My sessions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nameCtrl = TextEditingController();
          final bioCtrl = TextEditingController();
          final langsCtrl = TextEditingController(text: 'yoruba');
          await showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (ctx) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Become a mentor', style: PanAfricanTypography.titleMedium(ctx)),
                    const SizedBox(height: 12),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
                    const SizedBox(height: 10),
                    TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: langsCtrl,
                      decoration: const InputDecoration(labelText: 'Languages (comma-separated)'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final langs = langsCtrl.text
                            .split(',')
                            .map((s) => s.trim().toLowerCase())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        try {
                          await ref.read(microMentorServiceProvider).upsertMyProfile({
                            'displayName': nameCtrl.text.trim(),
                            'bio': bioCtrl.text.trim(),
                            'languages': langs,
                            'isActive': true,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mentor profile saved')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.volunteer_activism_rounded),
        label: const Text('Become a mentor'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BrowseTab(langCtrl: _langCtrl, onRequest: _requestSession),
          const _SessionsTab(),
        ],
      ),
    );
  }
}

class _BrowseTab extends ConsumerStatefulWidget {
  final TextEditingController langCtrl;
  final Future<void> Function({required String mentorUserId, required String language}) onRequest;

  const _BrowseTab({required this.langCtrl, required this.onRequest});

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _mentors = const [];

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
      final rows = await ref.read(microMentorServiceProvider).listMentors(language: widget.langCtrl.text.trim());
      setState(() => _mentors = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      children: [
        Text(
          'Short, structured 1:1 practice with a community mentor. Sessions are scheduled and can include optional consented recordings.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text('Filter language', style: PanAfricanTypography.titleSmall(context)),
        SizedBox(height: PanAfricanSpacing.xxs),
        TextField(
          controller: widget.langCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'yoruba / swahili / hausa ...',
          ),
          onSubmitted: (_) => _load(),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search'),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: PanAfricanSpacing.sm),
          Text(_error!, style: PanAfricanTypography.bodySmall(context).copyWith(color: PanAfricanColors.error)),
        ],
        SizedBox(height: PanAfricanSpacing.md),
        if (_loading) const LinearProgressIndicator(minHeight: 3),
        ..._mentors.map((m) {
          final name = m['displayName']?.toString() ?? 'Mentor';
          final langs = (m['languages'] as List?)?.map((e) => e.toString()).join(', ') ?? '';
          final userId = m['userId']?.toString() ?? '';
          return Card(
            child: ListTile(
              title: Text(name, style: PanAfricanTypography.titleSmall(context)),
              subtitle: Text(langs, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: userId.isEmpty
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      await widget.onRequest(mentorUserId: userId, language: widget.langCtrl.text.trim());
                    },
            ),
          );
        }),
      ],
    );
  }
}

class _SessionsTab extends ConsumerStatefulWidget {
  const _SessionsTab();

  @override
  ConsumerState<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<_SessionsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref.read(microMentorServiceProvider).listSessions(role: 'any');
      setState(() => _rows = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: EdgeInsets.all(PanAfricanSpacing.lg), child: Text(_error!)));
    }
    if (_rows.isEmpty) {
      return Center(child: Text('No sessions yet', style: PanAfricanTypography.bodyLarge(context)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
        itemBuilder: (context, i) {
          final s = _rows[i];
          final id = s['_id']?.toString() ?? '';
          final status = s['status']?.toString() ?? '';
          final lang = s['language']?.toString() ?? '';
          final when = s['scheduledStartTime']?.toString() ?? '';
          return ListTile(
            tileColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
            title: Text('$lang • $status', style: PanAfricanTypography.titleSmall(context)),
            subtitle: Text(when, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: id.isEmpty
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        child: MicroMentorSessionDetailScreen(sessionId: id),
                      ),
                    );
                  },
          );
        },
      ),
    );
  }
}
