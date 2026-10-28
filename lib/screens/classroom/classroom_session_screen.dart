import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:livekit_client/livekit_client.dart';

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

  /// P9-954 live session UI phases.
  ClassSessionLivePhase _livePhase = ClassSessionLivePhase.idle;
  Room? _liveRoom;
  Map<String, dynamic>? _liveState;
  bool _recordingActive = false;
  String? _consentStatus;
  String? _mediaState;
  bool _isTeacher = false;

  @override
  void dispose() {
    _disconnectLive();
    super.dispose();
  }

  Future<void> _disconnectLive() async {
    final room = _liveRoom;
    _liveRoom = null;
    if (room != null) {
      await room.disconnect();
    }
  }

  String _livePath(String sessionId, String suffix) =>
      '/api/v2/classroom/${widget.tribeId}/sessions/$sessionId/$suffix';

  Future<void> _enterLiveLobby(Map<String, dynamic> session) async {
    final sessionId = session['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) return;
    setState(() {
      _livePhase = ClassSessionLivePhase.lobby;
      _liveState = null;
    });
    try {
      final stateRes = await ApiService.get(_livePath(sessionId, 'live/state'));
      final data = stateRes.data as Map<String, dynamic>?;
      if (data?['success'] != true) throw Exception('live_state_failed');
      if (!mounted) return;
      setState(() {
        _liveState = Map<String, dynamic>.from(data!);
        _recordingActive = data['recordingActive'] == true;
        final me = data['me'];
        if (me is Map) {
          _consentStatus = me['consentStatus']?.toString();
          _mediaState = me['mediaState']?.toString();
        }
      });
      await _promptRecordingConsentIfNeeded(sessionId);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() => _livePhase = ClassSessionLivePhase.idle);
    }
  }

  Future<void> _promptRecordingConsentIfNeeded(String sessionId) async {
    if (_consentStatus == 'granted' || _consentStatus == 'declined') return;
    if (!mounted) return;
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(sessionConsentAskCopy),
        content: Text(
          'If the teacher records this class, your voice and video may be stored until the retention date. You can decline and still join without being recorded.',
          style: PanAfricanTypography.bodyMedium(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Agree'),
          ),
        ],
      ),
    );
    if (granted == null) return;
    try {
      final res = await ApiService.post(
        _livePath(sessionId, 'recording/consent'),
        data: {'granted': granted == true},
      );
      final data = res.data as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _consentStatus = data?['consentStatus']?.toString();
        _mediaState = data?['mediaState']?.toString();
        if (_consentStatus == 'declined') {
          _livePhase = ClassSessionLivePhase.declined;
        }
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _joinLive(Map<String, dynamic> session) async {
    final sessionId = session['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) return;
    try {
      final tokenRes = await ApiService.post(_livePath(sessionId, 'live/token'));
      final payload = tokenRes.data as Map<String, dynamic>?;
      if (payload?['success'] != true) throw Exception('live_token_failed');
      final token = payload!['token']?.toString() ?? '';
      final url = payload['url']?.toString() ?? AppConfig.liveKitUrl;
      _isTeacher = payload['canPublish'] == true;

      final room = Room();
      await room.connect(url, token);
      final local = room.localParticipant;
      if (local != null) {
        final recordMe = shouldPersistClassAv(_mediaState);
        await local.setCameraEnabled(recordMe && _isTeacher);
        await local.setMicrophoneEnabled(recordMe);
      }

      if (!mounted) return;
      setState(() {
        _liveRoom = room;
        _livePhase = _recordingActive
            ? ClassSessionLivePhase.recording
            : ClassSessionLivePhase.live;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _teacherStartRecording(String sessionId) async {
    try {
      final res = await ApiService.post(_livePath(sessionId, 'recording/start'));
      final data = res.data as Map<String, dynamic>?;
      if (data?['success'] == true) {
        if (!mounted) return;
        setState(() {
          _recordingActive = true;
          _livePhase = ClassSessionLivePhase.recording;
        });
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Waiting for everyone to consent before recording starts.',
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _leaveLive() async {
    await _disconnectLive();
    if (!mounted) return;
    setState(() {
      _livePhase = ClassSessionLivePhase.ended;
      _recordingActive = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _livePhase = ClassSessionLivePhase.idle);
  }

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

    if (_livePhase != ClassSessionLivePhase.idle && active != null) {
      return _LiveSessionScaffold(
        phase: _livePhase,
        recordingActive: _recordingActive,
        isTeacher: _isTeacher,
        sessionId: active['sessionId']?.toString() ?? '',
        tribeName: widget.tribeName,
        onJoin: () => _joinLive(active),
        onLeave: _leaveLive,
        onStartRecording: _isTeacher
            ? () => _teacherStartRecording(active['sessionId']?.toString() ?? '')
            : null,
        declined: _livePhase == ClassSessionLivePhase.declined,
        retentionDeleteAt: _liveState?['retentionDeleteAt']?.toString(),
      );
    }

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
                          onJoinLive: () => _enterLiveLobby(active),
                        ),
                      SizedBox(height: PanAfricanSpacing.md),
                      Text('Recent sessions',
                          style: PanAfricanTypography.titleMedium(context)),
                      SizedBox(height: PanAfricanSpacing.sm),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) => _SessionRow(
                          isDark: isDark,
                          session: _sessions[index],
                        ),
                      ),
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
    required this.onJoinLive,
  });

  final bool isDark;
  final Map<String, dynamic> session;
  final VoidCallback onCheckIn;
  final VoidCallback onJoinLive;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onJoinLive,
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Join live class'),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              FilledButton.icon(
                onPressed: meCheckedIn ? null : onCheckIn,
                icon: Icon(
                  meCheckedIn
                      ? Icons.check_circle_rounded
                      : Icons.how_to_reg_rounded,
                ),
                label: Text(meCheckedIn ? 'Checked in' : 'Check in'),
              ),
            ],
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

enum ClassSessionLivePhase { idle, lobby, live, recording, declined, ended }

const String sessionRecordingIndicatorCopy = 'Recording — class session in progress';
const String sessionConsentAskCopy = 'Record this live class?';

bool shouldPersistClassAv(String? mediaState) {
  return mediaState == 'recorded';
}

String classSessionPhaseLabel(ClassSessionLivePhase phase) {
  switch (phase) {
    case ClassSessionLivePhase.lobby:
      return 'Lobby';
    case ClassSessionLivePhase.live:
      return 'Live';
    case ClassSessionLivePhase.recording:
      return 'Recording';
    case ClassSessionLivePhase.declined:
      return 'Unrecorded';
    case ClassSessionLivePhase.ended:
      return 'Ended';
    case ClassSessionLivePhase.idle:
      return 'Idle';
  }
}

class _LiveSessionScaffold extends StatelessWidget {
  const _LiveSessionScaffold({
    required this.phase,
    required this.recordingActive,
    required this.isTeacher,
    required this.sessionId,
    required this.tribeName,
    required this.onJoin,
    required this.onLeave,
    required this.onStartRecording,
    required this.declined,
    this.retentionDeleteAt,
  });

  final ClassSessionLivePhase phase;
  final bool recordingActive;
  final bool isTeacher;
  final String sessionId;
  final String tribeName;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback? onStartRecording;
  final bool declined;
  final String? retentionDeleteAt;

  @override
  Widget build(BuildContext context) {
    final showRecordingBanner =
        recordingActive || phase == ClassSessionLivePhase.recording;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tribeName,
          style: PanAfricanTypography.titleLarge(context),
        ),
        actions: [
          Semantics(
            label: 'Leave live class session',
            button: true,
            child: IconButton(
              tooltip: 'Leave session',
              icon: const Icon(Icons.call_end_rounded),
              onPressed: onLeave,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showRecordingBanner)
              Semantics(
                label: sessionRecordingIndicatorCopy,
                liveRegion: true,
                child: Container(
                  color: PanAfricanColors.error.withValues(alpha: 0.92),
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: Text(
                          sessionRecordingIndicatorCopy,
                          style: PanAfricanTypography.labelLarge(
                            context,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classSessionPhaseLabel(phase),
                      style: PanAfricanTypography.headlineSmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      declined
                          ? 'You joined without being recorded. Your mic and camera stay off for this recording.'
                          : phase == ClassSessionLivePhase.lobby
                              ? 'Review consent, then connect to the live room.'
                              : 'Stay connected with your class. Teachers can start recording once everyone consents.',
                      style: PanAfricanTypography.bodyLarge(context),
                    ),
                    if (retentionDeleteAt != null && showRecordingBanner)
                      Padding(
                        padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                        child: Text(
                          'Stored until $retentionDeleteAt',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    const Spacer(),
                    if (phase == ClassSessionLivePhase.lobby)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: onJoin,
                          child: const Text('Connect to live room'),
                        ),
                      ),
                    if (isTeacher && onStartRecording != null && !declined)
                      Padding(
                        padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: onStartRecording,
                            icon: const Icon(Icons.radio_button_checked),
                            label: const Text('Start recording'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

