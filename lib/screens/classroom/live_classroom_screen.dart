import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../widgets/griot/griot_widgets.dart';
import 'class_code_join_sheet.dart';
import 'classroom_v2_route_args.dart';

/// How [LiveClassroomScreen] opens.
///
/// Catalog is the practice-room list. Session is the class check-in flow.
/// Room is the in-call layout.
enum LiveClassroomEntry { catalog, session, room }

/// Stand-ins for the tribe list, session list, and offline check-in queue.
/// Production leaves these null and calls the classroom services.
class LiveClassroomLoaders {
  const LiveClassroomLoaders({
    this.loadTribes,
    this.loadSessions,
    this.pendingOutboxCount,
    this.syncOutbox,
    this.startSession,
    this.checkIn,
    this.enqueueCheckIn,
  });

  final Future<List<Map<String, dynamic>>> Function()? loadTribes;
  final Future<Map<String, dynamic>> Function(String tribeId)? loadSessions;
  final Future<int> Function()? pendingOutboxCount;
  final Future<int> Function()? syncOutbox;
  final Future<void> Function(
    String tribeId, {
    String? agenda,
    List<String>? packLanguages,
  })? startSession;
  final Future<void> Function(
    String tribeId,
    String sessionId,
    DateTime checkedInAtClient,
  )? checkIn;
  final Future<void> Function({
    required String type,
    required Map<String, dynamic> payload,
  })? enqueueCheckIn;
}

/// Parsed route arguments for the live classroom.
class LiveClassroomRouteConfig {
  const LiveClassroomRouteConfig({
    required this.tribeId,
    required this.tribeName,
    required this.languageTag,
    required this.roomId,
    required this.roomName,
    required this.entry,
  });

  final String? tribeId;
  final String? tribeName;
  final String? languageTag;
  final String? roomId;
  final String? roomName;
  final LiveClassroomEntry entry;
}

String? _blankToNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// Room id or room name opens the in-call layout. A tribe id opens the session.
/// Anything else opens the practice-room catalog.
LiveClassroomEntry resolveLiveClassroomEntry({
  String? tribeId,
  String? roomId,
  String? roomName,
  LiveClassroomEntry? entry,
}) {
  if (entry != null) return entry;
  if (_blankToNull(roomId) != null || _blankToNull(roomName) != null) {
    return LiveClassroomEntry.room;
  }
  if (_blankToNull(tribeId) != null) return LiveClassroomEntry.session;
  return LiveClassroomEntry.catalog;
}

/// Uses [ClassroomV2RouteArgs.parse] for tribe id and tribe name.
/// A missing tribe id stays on the catalog. This screen does not require one.
LiveClassroomRouteConfig liveClassroomRouteConfig(Object? arguments) {
  if (arguments is! Map) {
    return const LiveClassroomRouteConfig(
      tribeId: null,
      tribeName: null,
      languageTag: null,
      roomId: null,
      roomName: null,
      entry: LiveClassroomEntry.catalog,
    );
  }
  final parsed = ClassroomV2RouteArgs.parse(arguments);
  final args = Map<String, dynamic>.from(arguments);
  final roomId = _blankToNull(args['roomId']?.toString());
  final roomName = _blankToNull(args['roomName']?.toString());
  final languageTag = _blankToNull(args['languageTag']?.toString());
  final tribeId = parsed.tribeId;
  final tribeName = tribeId == null ? null : parsed.tribeName;
  return LiveClassroomRouteConfig(
    tribeId: tribeId,
    tribeName: tribeName,
    languageTag: languageTag,
    roomId: roomId,
    roomName: roomName,
    entry: resolveLiveClassroomEntry(
      tribeId: tribeId,
      roomId: roomId,
      roomName: roomName,
    ),
  );
}

/// One classroom tribe row from the lobby catalog.
class ClassroomRoomSummary {
  const ClassroomRoomSummary({
    required this.title,
    required this.instructor,
    required this.language,
    required this.participants,
    required this.isLive,
    required this.isTrending,
    this.tribeId,
  });

  final String title;
  final String instructor;
  final String language;
  final int participants;
  final bool isLive;
  final bool isTrending;
  final String? tribeId;

  factory ClassroomRoomSummary.fromTribe(Map<String, dynamic> tribe) {
    final name = (tribe['name'] ?? 'Classroom').toString();
    final lang = (tribe['language_tag'] ?? '').toString();
    final rawCount = tribe['members_count'];
    final count = rawCount is int
        ? rawCount
        : (rawCount is num ? rawCount.toInt() : int.tryParse('$rawCount') ?? 0);
    final id = tribe['id']?.toString() ?? tribe['_id']?.toString();
    return ClassroomRoomSummary(
      title: name,
      instructor: 'Community classroom',
      language: lang,
      participants: count,
      isLive: false,
      isTrending: count > 20,
      tribeId: id,
    );
  }
}

/// Classroom tribes win. If the server returned none, the full tribe list is shown.
List<ClassroomRoomSummary> classroomRoomsFromTribes(
  List<Map<String, dynamic>> tribes,
) {
  final classrooms = tribes.where((t) => t['is_classroom'] == true).toList();
  final source = classrooms.isEmpty && tribes.isNotEmpty ? tribes : classrooms;
  return source.map(ClassroomRoomSummary.fromTribe).toList();
}

const List<String> classroomLobbyFilters = <String>[
  'All',
  'Starting Soon',
  'My Languages',
];

enum ClassSessionLivePhase { idle, lobby, live, recording, declined, ended }

const String sessionRecordingIndicatorCopy = 'Recording. Class session in progress';
const String sessionConsentAskCopy = 'Record this live class?';
const String sessionQueuedCheckInCopy = 'Checked in queued. Will sync when online.';
const String classroomAttendanceCheckInType = 'classroom_attendance_checkin';
const int classroomOutboxSyncBatchSize = 50;

bool shouldPersistClassAv(String? mediaState) {
  return mediaState == 'recorded';
}

bool classSessionCameraEnabled({
  required String? mediaState,
  required bool isTeacher,
}) {
  return shouldPersistClassAv(mediaState) && isTeacher;
}

bool classSessionNeedsConsentPrompt(String? consentStatus) {
  return consentStatus != 'granted' && consentStatus != 'declined';
}

ClassSessionLivePhase phaseAfterRecordingConsent(String? consentStatus) {
  if (consentStatus == 'declined') return ClassSessionLivePhase.declined;
  return ClassSessionLivePhase.lobby;
}

ClassSessionLivePhase phaseAfterLiveConnect({required bool recordingActive}) {
  return recordingActive
      ? ClassSessionLivePhase.recording
      : ClassSessionLivePhase.live;
}

bool classSessionShowsRecordingBanner({
  required bool recordingActive,
  required ClassSessionLivePhase phase,
}) {
  return recordingActive || phase == ClassSessionLivePhase.recording;
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

Map<String, dynamic>? activeClassSession(List<Map<String, dynamic>> sessions) {
  for (final session in sessions) {
    if (session['status']?.toString() == 'active') return session;
  }
  return null;
}

String classSessionDateLabel(String? startedAtRaw) {
  final startedAt = startedAtRaw == null
      ? null
      : DateTime.tryParse(startedAtRaw)?.toLocal();
  if (startedAt == null) return 'Session';
  final month = startedAt.month.toString().padLeft(2, '0');
  final day = startedAt.day.toString().padLeft(2, '0');
  return '${startedAt.year}-$month-$day';
}

/// Session screen the teacher dashboard opens. The body is the live classroom.
class ClassroomSessionScreen extends StatelessWidget {
  const ClassroomSessionScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
    required this.languageTag,
    this.loaders,
  });

  final String tribeId;
  final String tribeName;
  final String languageTag;
  final LiveClassroomLoaders? loaders;

  @override
  Widget build(BuildContext context) {
    return LiveClassroomScreen(
      tribeId: tribeId,
      tribeName: tribeName,
      languageTag: languageTag,
      entry: LiveClassroomEntry.session,
      loaders: loaders,
    );
  }
}

class ClassRecordingConsentDialog extends StatelessWidget {
  const ClassRecordingConsentDialog({super.key});

  static const String body =
      'If the teacher records this class, your voice and video may be stored until the retention date. You can decline and still join without being recorded.';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(sessionConsentAskCopy),
      content: Text(
        body,
        style: PanAfricanTypography.bodyMedium(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Agree'),
        ),
      ],
    );
  }
}

class ClassSessionLiveView extends StatelessWidget {
  const ClassSessionLiveView({
    super.key,
    required this.phase,
    required this.recordingActive,
    required this.isTeacher,
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
  final String tribeName;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback? onStartRecording;
  final bool declined;
  final String? retentionDeleteAt;

  @override
  Widget build(BuildContext context) {
    final showRecordingBanner = classSessionShowsRecordingBanner(
      recordingActive: recordingActive,
      phase: phase,
    );

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
                      const Icon(
                        Icons.fiber_manual_record_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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
              child: SingleChildScrollView(
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
                    SizedBox(height: PanAfricanSpacing.lg),
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

class LiveClassroomScreen extends ConsumerStatefulWidget {
  const LiveClassroomScreen({
    super.key,
    this.tribeId,
    this.tribeName,
    this.languageTag,
    this.roomId,
    this.roomName,
    this.entry,
    this.loaders,
  });

  factory LiveClassroomScreen.fromRouteArguments(Object? arguments) {
    final config = liveClassroomRouteConfig(arguments);
    return LiveClassroomScreen(
      tribeId: config.tribeId,
      tribeName: config.tribeName,
      languageTag: config.languageTag,
      roomId: config.roomId,
      roomName: config.roomName,
      entry: config.entry,
    );
  }

  final String? tribeId;
  final String? tribeName;
  final String? languageTag;
  final String? roomId;
  final String? roomName;
  final LiveClassroomEntry? entry;
  final LiveClassroomLoaders? loaders;

  @override
  ConsumerState<LiveClassroomScreen> createState() =>
      _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen>
    with TickerProviderStateMixin {
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;
  AnimationController? _micPulse;
  final List<_FloatingEmoji> _floatingEmojis = [];
  int _activeSpeaker = 0;
  bool _isMuted = false;

  List<ClassroomRoomSummary> _rooms = const [];
  bool _catalogLoading = true;
  String? _catalogError;

  bool _sessionLoading = true;
  String? _sessionError;
  List<Map<String, dynamic>> _sessions = const [];
  int _pendingOutbox = 0;
  ClassSessionLivePhase _livePhase = ClassSessionLivePhase.idle;
  Room? _liveRoom;
  Map<String, dynamic>? _liveState;
  bool _recordingActive = false;
  String? _consentStatus;
  String? _mediaState;
  bool _isTeacher = false;

  static const _speakers = [
    _Speaker('Adeola K.', 'Host', true),
    _Speaker('Chidi O.', 'Speaker', false),
    _Speaker('Amina N.', 'Speaker', false),
  ];

  static const _listeners = [
    _Listener('Fatima B.', true),
    _Listener('Sipho M.', false),
    _Listener('Selam T.', true),
    _Listener('Kofi A.', false),
    _Listener('Ngozi E.', true),
    _Listener('Yaw M.', false),
    _Listener('Zainab K.', true),
    _Listener('Thabo R.', false),
  ];

  static const _vocabCards = [
    _VocabCard('Bawo ni', 'How are you', 'Yoruba'),
    _VocabCard('Ẹ kú àárọ̀', 'Good morning', 'Yoruba'),
    _VocabCard('Ẹ ṣé', 'Thank you', 'Yoruba'),
    _VocabCard('Ọdún ló', 'Goodbye', 'Yoruba'),
    _VocabCard('Ẹ kú ilé', 'Welcome home', 'Yoruba'),
  ];

  static const _labeledReactions = [
    ('🔥', 'Lit'),
    ('🤝', 'Tribe'),
    ('✊', 'Respect'),
    ('💡', 'Aha'),
  ];

  static const _extraReactions = ['🎉', '👏'];

  LiveClassroomEntry get _entry => resolveLiveClassroomEntry(
        tribeId: widget.tribeId,
        roomId: widget.roomId,
        roomName: widget.roomName,
        entry: widget.entry,
      );

  @override
  void initState() {
    super.initState();
    if (_entry == LiveClassroomEntry.room) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
      );
      _micPulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    }
    if (_entry == LiveClassroomEntry.catalog) {
      _loadCatalog();
    } else if (_entry == LiveClassroomEntry.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
    } else {
      _catalogLoading = false;
      _sessionLoading = false;
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    _micPulse?.dispose();
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

  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final tribes = widget.loaders?.loadTribes != null
          ? await widget.loaders!.loadTribes!()
          : await ref
              .read(tribesServiceProvider)
              .getAllTribes(includeClassrooms: true);
      if (!mounted) return;
      setState(() {
        _rooms = classroomRoomsFromTribes(tribes);
        _catalogLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = 'Could not load classrooms. Pull to retry.';
        _rooms = const [];
      });
    }
  }

  Future<int> _readPendingOutbox() async {
    final loader = widget.loaders?.pendingOutboxCount;
    if (loader != null) return loader();
    await PersistedOutboxService.instance.ensureOpen();
    return PersistedOutboxService.instance.pendingCount;
  }

  Future<void> _loadSessions() async {
    final tribeId = widget.tribeId ?? '';
    setState(() {
      _sessionLoading = true;
      _sessionError = null;
    });
    try {
      final pending = await _readPendingOutbox();
      final res = widget.loaders?.loadSessions != null
          ? await widget.loaders!.loadSessions!(tribeId)
          : await ref.read(classroomServiceProvider).listSessionsV2(tribeId);
      final raw = res['sessions'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) list.add(item.cast<String, dynamic>());
        }
      }
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _pendingOutbox = pending;
        _sessionLoading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      if (!mounted) return;
      setState(() {
        _sessionError = 'Unable to load sessions right now.';
        _sessionLoading = false;
      });
    }
  }

  Future<void> _syncNow() async {
    HapticFeedback.mediumImpact();
    final removed = widget.loaders?.syncOutbox != null
        ? await widget.loaders!.syncOutbox!()
        : await PersistedOutboxService.instance.flushPending(
            batchSize: classroomOutboxSyncBatchSize,
          );
    if (!mounted) return;
    if (widget.loaders?.pendingOutboxCount != null) {
      _pendingOutbox = await widget.loaders!.pendingOutboxCount!();
    } else {
      _pendingOutbox = PersistedOutboxService.instance.pendingCount;
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed > 0
              ? 'Synced $removed queued actions.'
              : 'No queued actions synced yet.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
      ),
    );
    await _loadSessions();
  }

  Future<void> _startSession() async {
    final tribeId = widget.tribeId ?? '';
    try {
      final agenda = await showDialog<String>(
        context: context,
        builder: (_) => const _StartSessionDialog(),
      );
      if (!mounted || agenda == null) return;
      final trimmed = agenda.isEmpty ? null : agenda;
      final packLanguages = widget.languageTag == null
          ? null
          : <String>[widget.languageTag!];
      if (widget.loaders?.startSession != null) {
        await widget.loaders!.startSession!(
          tribeId,
          agenda: trimmed,
          packLanguages: packLanguages,
        );
      } else {
        await ref.read(classroomServiceProvider).startSessionV2(
              tribeId,
              agenda: trimmed,
              packLanguages: packLanguages,
            );
      }
      await _loadSessions();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _checkIn(Map<String, dynamic> session) async {
    final tribeId = widget.tribeId ?? '';
    final sessionId = session['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) return;
    final checkedInAt = DateTime.now();
    try {
      if (widget.loaders?.checkIn != null) {
        await widget.loaders!.checkIn!(tribeId, sessionId, checkedInAt);
      } else {
        await ref.read(classroomServiceProvider).checkInV2(
              tribeId,
              sessionId,
              checkedInAtClient: checkedInAt,
            );
      }
      await _loadSessions();
      return;
    } catch (_) {
      // Offline-first: enqueue check-in for sync when the server is reachable.
    }

    try {
      final payload = <String, dynamic>{
        'tribeId': tribeId,
        'sessionId': sessionId,
        'checkedInAtClient': checkedInAt.toUtc().toIso8601String(),
      };
      if (widget.loaders?.enqueueCheckIn != null) {
        await widget.loaders!.enqueueCheckIn!(
          type: classroomAttendanceCheckInType,
          payload: payload,
        );
      } else {
        await PersistedOutboxService.instance.enqueue(
          type: classroomAttendanceCheckInType,
          payload: payload,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sessionQueuedCheckInCopy,
            style: PanAfricanTypography.bodyMedium(context),
          ),
        ),
      );
      await _loadSessions();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
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
      if (mounted) setState(() => _livePhase = ClassSessionLivePhase.idle);
    }
  }

  Future<void> _promptRecordingConsentIfNeeded(String sessionId) async {
    if (!classSessionNeedsConsentPrompt(_consentStatus)) return;
    if (!mounted) return;
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ClassRecordingConsentDialog(),
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
        _livePhase = phaseAfterRecordingConsent(_consentStatus);
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
        await local.setCameraEnabled(
          classSessionCameraEnabled(
            mediaState: _mediaState,
            isTeacher: _isTeacher,
          ),
        );
        await local.setMicrophoneEnabled(recordMe);
      }

      if (!mounted) return;
      setState(() {
        _liveRoom = room;
        _livePhase = phaseAfterLiveConnect(recordingActive: _recordingActive);
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

  void _addReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      _floatingEmojis.add(
        _FloatingEmoji(
          emoji: emoji,
          id: DateTime.now().microsecondsSinceEpoch,
          x: 0.3 + Random().nextDouble() * 0.4,
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _floatingEmojis.removeWhere(
            (e) => DateTime.now().microsecondsSinceEpoch - e.id > 1800000,
          );
        });
      }
    });
  }

  void _openNotes(ClassroomRoomSummary room) {
    Navigator.of(context).pushNamed(
      '/classroom-notes',
      arguments: <String, dynamic>{
        'tribeId': room.tribeId,
        'roomName': room.title,
      },
    );
  }

  void _openSpeakerQueue(ClassroomRoomSummary room) {
    Navigator.of(context).pushNamed(
      '/speaker-queue',
      arguments: <String, dynamic>{
        'tribeId': room.tribeId,
        'roomName': room.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_entry) {
      case LiveClassroomEntry.catalog:
        return _buildCatalog(context);
      case LiveClassroomEntry.session:
        return _buildSession(context);
      case LiveClassroomEntry.room:
        return _buildRoom(context);
    }
  }

  Widget _buildCatalog(BuildContext context) {
    return GriotScaffold(
      appBar: AppBar(title: const Text('Practice rooms')),
      floatingActionButton: GriotFab(
        icon: Icons.mic_rounded,
        heroTag: 'host_room',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LiveClassroomScreen(
                roomName: 'Yoruba Conversations',
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCatalog,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Rooms',
                        style: ModernGriotTypography.headlineMedium(
                          context: context,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Classrooms from your tribe catalog (server-backed)',
                        style: ModernGriotTypography.bodyMedium(
                          context: context,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: FilledButton.tonalIcon(
                            key: const ValueKey('lobby-enter-class-code'),
                            onPressed: () => ClassCodeJoinSheet.show(
                              context,
                              onJoined: _loadCatalog,
                            ),
                            icon: const Icon(Icons.vpn_key_outlined),
                            label: Text(
                              AppLocalizations.of(context)!.gccJoinButton,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      const _FilterRow(filters: classroomLobbyFilters),
                      SizedBox(height: 16.h),
                      if (_catalogError != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Text(
                            _catalogError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_catalogLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_rooms.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      'No classroom sessions yet. Create a classroom tribe on the server or use Live Classroom to host.',
                      style: ModernGriotTypography.bodyMedium(context: context),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _RoomCard(
                        room: _rooms[index],
                        onOpen: () {
                          final room = _rooms[index];
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LiveClassroomScreen(
                                tribeId: room.tribeId,
                                tribeName: room.title,
                                roomId: room.tribeId,
                                roomName: room.title,
                                loaders: widget.loaders,
                              ),
                            ),
                          );
                        },
                        onNotes: () => _openNotes(_rooms[index]),
                        onQueue: () => _openSpeakerQueue(_rooms[index]),
                      ),
                      childCount: _rooms.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 80.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeClassSession(_sessions);
    final tribeName = widget.tribeName ?? 'Classroom';

    if (_livePhase != ClassSessionLivePhase.idle && active != null) {
      return ClassSessionLiveView(
        phase: _livePhase,
        recordingActive: _recordingActive,
        isTeacher: _isTeacher,
        tribeName: tribeName,
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
          'Session: $tribeName',
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
      body: _sessionLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionError != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _sessionError!,
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        FilledButton(
                          onPressed: _loadSessions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: PanAfricanColors.primary,
                  onRefresh: _loadSessions,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    children: [
                      if (_pendingOutbox > 0)
                        Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
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
                              Text(
                                'No active session',
                                style: PanAfricanTypography.titleMedium(context),
                              ),
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
                          session: active,
                          onCheckIn: () => _checkIn(active),
                          onJoinLive: () => _enterLiveLobby(active),
                        ),
                      SizedBox(height: PanAfricanSpacing.md),
                      Text(
                        'Recent sessions',
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      for (final session in _sessions)
                        _SessionRow(session: session),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRoom(BuildContext context) {
    final darkScheme = ModernGriotColorScheme.dark;
    final title = widget.roomName ?? widget.tribeName ?? 'Yoruba Conversations';
    final speaker = _speakers[_activeSpeaker];

    return Theme(
      data: ThemeData.dark().copyWith(colorScheme: darkScheme),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, darkScheme, title),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: 12.h),
                      children: [
                        SizedBox(height: 12.h),
                        _buildActiveSpeaker(darkScheme, speaker),
                        SizedBox(height: 16.h),
                        _buildLessonCard(darkScheme),
                        SizedBox(height: 16.h),
                        _buildSpeakerGrid(darkScheme),
                        SizedBox(height: 16.h),
                        _buildListenerGrid(darkScheme),
                        SizedBox(height: 12.h),
                        _buildReactionBar(darkScheme),
                        SizedBox(height: 12.h),
                        _buildVocabScroll(darkScheme),
                      ],
                    ),
                  ),
                  _buildBottomBar(darkScheme),
                  SizedBox(height: 8.h),
                ],
              ),
              ..._floatingEmojis.map((e) => _FloatingEmojiWidget(data: e)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 22.sp),
            onPressed: () => Navigator.maybePop(context),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: ModernGriotTypography.titleMedium(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, size: 14.sp, color: cs.onSurface),
                SizedBox(width: 4.w),
                Text(
                  '${_speakers.length + _listeners.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSpeaker(ColorScheme cs, _Speaker speaker) {
    final pulse = _micPulse;
    return Column(
      children: [
        if (pulse == null)
          _speakerDisc(cs)
        else
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final scale = 1.0 + (pulse.value * 0.15);
              return Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ModernGriotColorsDark.primary.withAlpha(
                      (120 + (135 * (scale - 1) / 0.15)).round().clamp(0, 255),
                    ),
                    width: (3 + 2 * (scale - 1)).r,
                  ),
                ),
                child: child,
              );
            },
            child: _speakerDisc(cs),
          ),
        SizedBox(height: 12.h),
        Text(
          speaker.name,
          key: const ValueKey('active-speaker-name'),
          style: ModernGriotTypography.titleMedium(color: cs.onSurface),
        ),
        SizedBox(height: 2.h),
        Text(
          speaker.isHost ? 'Host · Speaking' : speaker.role,
          style: TextStyle(
            fontSize: 12.sp,
            color: ModernGriotColorsDark.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _speakerDisc(ColorScheme cs) {
    return Center(
      child: Container(
        width: 100.r,
        height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHigh,
        ),
        child: Icon(
          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          key: const ValueKey('active-speaker-mic'),
          size: 40.sp,
          color: _isMuted ? cs.onSurfaceVariant : ModernGriotColorsDark.primary,
        ),
      ),
    );
  }

  Widget _buildLessonCard(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        key: const ValueKey('live-classroom-lesson'),
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: ModernGriotRadius.borderXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 16.sp,
                  color: ModernGriotColorsDark.primary,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Active Lesson',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: ModernGriotColorsDark.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Greetings & Introductions',
              style: ModernGriotTypography.titleSmall(color: cs.onSurface),
            ),
            SizedBox(height: 4.h),
            Text(
              'Practice everyday Yoruba greetings with proper tonal pronunciation',
              style: ModernGriotTypography.bodySmall(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_speakers.length, (i) {
          final speaker = _speakers[i];
          final isHost = i == 0;
          final isActive = i == _activeSpeaker;
          final size = isHost ? 80.0 : 64.0;
          final pulse = _pulseAnim;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _activeSpeaker = i),
              child: Column(
                children: [
                  if (pulse == null)
                    _speakerRing(cs, isActive, size, 0)
                  else
                    AnimatedBuilder(
                      animation: pulse,
                      builder: (context, child) {
                        return _speakerRing(cs, isActive, size, pulse.value);
                      },
                    ),
                  SizedBox(height: 6.h),
                  Text(
                    speaker.name,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    speaker.role,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _speakerRing(ColorScheme cs, bool isActive, double size, double pulse) {
    final ringScale = isActive ? 1.0 + pulse * 0.08 : 1.0;
    return Transform.scale(
      scale: ringScale,
      child: Container(
        width: (size + 8).r,
        height: (size + 8).r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? ModernGriotColorsDark.primary
                    .withAlpha((180 + 75 * pulse).round())
                : cs.surfaceContainerHigh,
            width: isActive ? 3.r : 2.r,
          ),
        ),
        child: Center(child: GriotAvatar(size: size)),
      ),
    );
  }

  Widget _buildListenerGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Listeners',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: Text(
                  '${_listeners.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75,
            ),
            itemCount: _listeners.length,
            itemBuilder: (context, i) {
              final listener = _listeners[i];
              return Column(
                children: [
                  Stack(
                    children: [
                      const GriotAvatar(size: 40),
                      if (listener.online)
                        Positioned(
                          key: ValueKey('listener-online-${listener.name}'),
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: ModernGriotColorsDark.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    listener.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          for (final reaction in _labeledReactions)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: GestureDetector(
                onTap: () => _addReaction(reaction.$1),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(reaction.$1, style: TextStyle(fontSize: 16.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        reaction.$2,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final emoji in _extraReactions)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => _addReaction(emoji),
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVocabScroll(ColorScheme cs) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _vocabCards.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final card = _vocabCards[i];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.word,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ModernGriotColorsDark.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  card.translation,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    final muteLabel = _isMuted ? 'Unmute' : 'Mute';
    final muteIcon = _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded;
    final controls = <(IconData, String, VoidCallback)>[
      (muteIcon, muteLabel, () => setState(() => _isMuted = !_isMuted)),
      (
        Icons.back_hand_rounded,
        'Raise',
        () => HapticFeedback.mediumImpact(),
      ),
      (
        Icons.emoji_emotions_rounded,
        'React',
        () => HapticFeedback.lightImpact(),
      ),
      (
        Icons.share_rounded,
        'Share',
        () => HapticFeedback.lightImpact(),
      ),
      (
        Icons.chat_bubble_rounded,
        'Chat',
        () => HapticFeedback.lightImpact(),
      ),
      (
        Icons.call_end_rounded,
        'Leave',
        () => HapticFeedback.heavyImpact(),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withAlpha(200),
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(color: cs.outlineVariant.withAlpha(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: controls.map((control) {
                final isLeave = control.$2 == 'Leave';
                return GestureDetector(
                  key: ValueKey('live-control-${control.$2}'),
                  onTap: control.$3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42.r,
                        height: 42.r,
                        decoration: BoxDecoration(
                          color: isLeave
                              ? const Color(0xFFE53935)
                              : cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          control.$1,
                          size: 20.sp,
                          color: isLeave ? Colors.white : cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        control.$2,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: isLeave
                              ? const Color(0xFFE53935)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartSessionDialog extends StatefulWidget {
  const _StartSessionDialog();

  @override
  State<_StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<_StartSessionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start class session'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Agenda (optional)'),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _FilterRow extends StatefulWidget {
  const _FilterRow({required this.filters});
  final List<String> filters;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.filters.length, (i) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GriotChip(
              label: widget.filters[i],
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
          );
        }),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onOpen,
    required this.onNotes,
    required this.onQueue,
  });

  final ClassroomRoomSummary room;
  final VoidCallback onOpen;
  final VoidCallback onNotes;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      surfaceLevel: 1,
      onTap: room.tribeId == null ? null : onOpen,
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (room.isLive) ...[
                const _LivePulseBadge(),
                SizedBox(width: 6.w),
              ],
              if (room.isTrending)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.secondaryContainer,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 12.sp,
                        color: ModernGriotColors.onSecondaryContainer,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'HOT',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: ModernGriotColors.onSecondaryContainer,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          if (room.language.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(25),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(
                room.language,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          Text(
            room.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ModernGriotTypography.titleSmall(context: context),
          ),
          SizedBox(height: 4.h),
          Text(
            room.instructor,
            style: ModernGriotTypography.bodySmall(context: context),
          ),
          const Spacer(),
          Row(
            children: [
              _OverlappingAvatars(count: min(room.participants, 4)),
              SizedBox(width: 6.w),
              Text(
                '${room.participants}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (room.tribeId != null) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onNotes,
                    child: Text('Notes', style: TextStyle(fontSize: 11.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onQueue,
                    child: Text('Queue', style: TextStyle(fontSize: 11.sp)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LivePulseBadge extends StatefulWidget {
  const _LivePulseBadge();

  @override
  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<_LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1.0 + _ctrl.value * 0.3;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withAlpha((200 + 55 * _ctrl.value).round()),
            borderRadius: ModernGriotRadius.borderPill,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withAlpha((40 * scale).round()),
                blurRadius: 8 * scale,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.count});
  final int count;

  static const _colors = [
    Color(0xFFE8A87C),
    Color(0xFF85DCB0),
    Color(0xFF8BBEE8),
    Color(0xFFE088A8),
  ];

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final avatarSize = 22.r;
    final overlap = 8.w;
    return SizedBox(
      width: avatarSize + (count - 1) * (avatarSize - overlap),
      height: avatarSize,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: _colors[i % _colors.length],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 12.sp,
                color: Colors.white.withAlpha(200),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.onCheckIn,
    required this.onJoinLive,
  });

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
          Wrap(
            alignment: WrapAlignment.end,
            spacing: PanAfricanSpacing.sm,
            runSpacing: PanAfricanSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onJoinLive,
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Join live class'),
              ),
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
  const _SessionRow({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = session['status']?.toString() ?? '';
    final label = classSessionDateLabel(session['startedAt']?.toString());
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
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
            child: Text(label, style: PanAfricanTypography.bodyMedium(context)),
          ),
          Text(status, style: PanAfricanTypography.labelSmall(context)),
        ],
      ),
    );
  }
}

class _Speaker {
  final String name;
  final String role;
  final bool isHost;
  const _Speaker(this.name, this.role, this.isHost);
}

class _Listener {
  final String name;
  final bool online;
  const _Listener(this.name, this.online);
}

class _VocabCard {
  final String word;
  final String translation;
  final String language;
  const _VocabCard(this.word, this.translation, this.language);
}

class _FloatingEmoji {
  final String emoji;
  final int id;
  final double x;
  const _FloatingEmoji({
    required this.emoji,
    required this.id,
    required this.x,
  });
}

class _FloatingEmojiWidget extends StatefulWidget {
  const _FloatingEmojiWidget({required this.data});
  final _FloatingEmoji data;

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)),
    );
    _translateY = Tween<double>(begin: 0, end: -160).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: widget.data.x * screenWidth,
          bottom: 140.h + (-_translateY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              widget.data.emoji,
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        );
      },
    );
  }
}
