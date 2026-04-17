import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ClassroomSessionScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;
  final String languageTag;

  const ClassroomSessionScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
    required this.languageTag,
  });

  @override
  ConsumerState<ClassroomSessionScreen> createState() => _ClassroomSessionScreenState();
}

class _ClassroomSessionScreenState extends ConsumerState<ClassroomSessionScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = const [];
  int _pendingOutbox = 0;

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
      await PersistedOutboxService.instance.ensureOpen();
      final pending = PersistedOutboxService.instance.pendingCount;
      final res =
          await ref.read(classroomServiceProvider).listSessionsV2(widget.tribeId);
      final raw = res['sessions'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) list.add(e.cast<String, dynamic>());
        }
      }
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _pendingOutbox = pending;
        _loading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error = 'Unable to load sessions right now.';
        _loading = false;
      });
    }
  }

  Future<void> _syncNow() async {
    HapticFeedback.mediumImpact();
    await PersistedOutboxService.instance.ensureOpen();
    final removed = await PersistedOutboxService.instance.flushPending(batchSize: 50);
    if (!mounted) return;
    setState(() => _pendingOutbox = PersistedOutboxService.instance.pendingCount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed > 0 ? 'Synced $removed queued actions.' : 'No queued actions synced yet.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
      ),
    );
    await _load();
  }

  Future<void> _startSession() async {
    final agendaController = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Start class session'),
          content: TextField(
            controller: agendaController,
            decoration: const InputDecoration(labelText: 'Agenda (optional)'),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(classroomServiceProvider).startSessionV2(
            widget.tribeId,
            agenda: agendaController.text.trim().isEmpty
                ? null
                : agendaController.text.trim(),
            packLanguages: [widget.languageTag],
          );
      await _load();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      agendaController.dispose();
    }
  }

  Map<String, dynamic>? get _activeSession {
    for (final s in _sessions) {
      if (s['status']?.toString() == 'active') return s;
    }
    return null;
  }

  Future<void> _checkIn(Map<String, dynamic> session) async {
    final sessionId = session['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) return;

    try {
      await ref.read(classroomServiceProvider).checkInV2(
            widget.tribeId,
            sessionId,
            checkedInAtClient: DateTime.now(),
          );
      await _load();
      return;
    } catch (_) {
      // Offline-first: enqueue check-in for sync v2 (server will accept when online).
    }

    try {
      await PersistedOutboxService.instance.enqueue(
        type: 'classroom_attendance_checkin',
        payload: {
          'tribeId': widget.tribeId,
          'sessionId': sessionId,
          'checkedInAtClient': DateTime.now().toUtc().toIso8601String(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checked in queued — will sync when online.',
            style: PanAfricanTypography.bodyMedium(context),
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activeSession;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Session: ${widget.tribeName}',
          style: PanAfricanTypography.titleLarge(context),
        ),
        actions: [
          if (_pendingOutbox > 0)
            IconButton(
              tooltip: 'Sync queued actions ($_pendingOutbox)',
              icon: const Icon(Icons.sync_rounded),
              onPressed: _syncNow,
            ),
          IconButton(
            tooltip: 'Start session',
            icon: const Icon(Icons.play_circle_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _startSession();
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
                        Text(_error!,
                            style: PanAfricanTypography.bodyLarge(context)),
                        SizedBox(height: PanAfricanSpacing.md),
                        FilledButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: PanAfricanColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    children: [
                      if (_pendingOutbox > 0)
                        Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                            borderRadius: PanAfricanRadius.lgBR,
                            border: Border.all(
                              color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_upload_rounded),
                              SizedBox(width: PanAfricanSpacing.sm),
                              Expanded(
                                child: Text(
                                  '$_pendingOutbox action(s) queued for sync (offline).',
                                  style: PanAfricanTypography.bodyMedium(context),
                                ),
                              ),
                              FilledButton(
                                onPressed: _syncNow,
                                child: const Text('Sync now'),
                              ),
                            ],
                          ),
                        ),
                      if (active == null)
                        Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark
                                ? PanAfricanColors.cardDark
                                : PanAfricanColors.cardLight,
                            borderRadius: PanAfricanRadius.lgBR,
                            border: Border.all(
                              color: isDark
                                  ? PanAfricanColors.borderDark
                                  : PanAfricanColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No active session',
                                  style:
                                      PanAfricanTypography.titleMedium(context)),
                              SizedBox(height: PanAfricanSpacing.xs),
                              Text(
                                'If you are the teacher, start today’s session so learners can check in (offline-ready).',
                                style: PanAfricanTypography.bodySmall(context),
                              ),
                            ],
                          ),
                        )
                      else
                        _ActiveSessionCard(
                          isDark: isDark,
                          session: active,
                          onCheckIn: () => _checkIn(active),
                        ),
                      SizedBox(height: PanAfricanSpacing.md),
                      Text('Recent sessions',
                          style: PanAfricanTypography.titleMedium(context)),
                      SizedBox(height: PanAfricanSpacing.sm),
                      ..._sessions
                          .map((s) => _SessionRow(isDark: isDark, session: s))
                          ,
                    ],
                  ),
                ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.isDark,
    required this.session,
    required this.onCheckIn,
  });

  final bool isDark;
  final Map<String, dynamic> session;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final agenda = session['agenda']?.toString();
    final meCheckedIn = session['meCheckedIn'] == true;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.celebration,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active now',
            style: PanAfricanTypography.titleLarge(
              context,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          if (agenda != null && agenda.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              agenda,
              style: PanAfricanTypography.bodySmall(
                context,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: meCheckedIn ? null : onCheckIn,
              icon: Icon(
                meCheckedIn
                    ? Icons.check_circle_rounded
                    : Icons.how_to_reg_rounded,
              ),
              label: Text(meCheckedIn ? 'Checked in' : 'Check in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.isDark, required this.session});

  final bool isDark;
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final status = session['status']?.toString() ?? '';
    final startedAtRaw = session['startedAt']?.toString();
    final startedAt =
        startedAtRaw == null ? null : DateTime.tryParse(startedAtRaw)?.toLocal();
    final label = startedAt == null
        ? 'Session'
        : '${startedAt.year}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            status == 'active'
                ? Icons.radio_button_checked_rounded
                : Icons.history_rounded,
            color: status == 'active'
                ? PanAfricanColors.success
                : PanAfricanColors.neutralMedium,
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
              child: Text(label, style: PanAfricanTypography.bodyMedium(context))),
          Text(status, style: PanAfricanTypography.labelSmall(context)),
        ],
      ),
    );
  }
}

