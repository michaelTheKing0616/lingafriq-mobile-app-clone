import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/gamification_services_provider.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

/// Live speaker queue for a classroom tribe (`/api/classroom/:tribeId/speaker-queue`).
class SpeakerQueueScreen extends ConsumerStatefulWidget {
  const SpeakerQueueScreen({
    super.key,
    this.initialTribeId,
    this.initialRoomName,
  });

  final String? initialTribeId;
  final String? initialRoomName;

  @override
  ConsumerState<SpeakerQueueScreen> createState() => _SpeakerQueueScreenState();
}

class _SpeakerQueueScreenState extends ConsumerState<SpeakerQueueScreen> {
  String? _tribeId;
  String? _roomName;
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _loadingClassrooms = false;
  String? _error;
  List<Map<String, dynamic>> _classrooms = [];
  bool _routeResolved = false;
  bool _busy = false;

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _tribeId = widget.initialTribeId;
    _roomName = widget.initialRoomName;
    if (_tribeId == null || _tribeId!.isEmpty) {
      _loadingClassrooms = true;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
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
      _startPolling();
    } else {
      _loadClassroomPicker();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  Future<void> _load() async {
    final id = _tribeId;
    if (id == null || id.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ref.read(classroomServiceProvider).getSpeakerQueue(id);
      if (!mounted) return;
      setState(() {
        _data = d;
        _roomName = d['tribe_name']?.toString() ?? _roomName;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is DioException ? (e.message ?? 'Could not load queue') : '$e';
      });
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

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final d = await action();
      if (!mounted) return;
      setState(() {
        _data = d;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_tribeId == null || _tribeId!.isEmpty) {
      return _buildPicker(cs);
    }

    final data = _data;
    final host = data?['is_host'] == true;
    final speaking = data?['speaking'] is Map<String, dynamic>
        ? data!['speaking'] as Map<String, dynamic>
        : null;
    final waiting = <Map<String, dynamic>>[];
    if (data?['waiting'] is List) {
      for (final e in data!['waiting'] as List) {
        if (e is Map<String, dynamic>) waiting.add(e);
      }
    }
    final me = data?['me'] is Map<String, dynamic> ? data!['me'] as Map<String, dynamic> : null;
    final queueTotal = data?['queue_total'];
    final lang = data?['language_tag']?.toString() ?? '';

    return GriotScaffold(
      appBar: AppBar(
        title: Text(_roomName ?? 'Speaker queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(color: cs.outline)),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: _loading && data == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120.h),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _error != null && data == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80.h),
                          Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 48.sp, color: cs.error),
                                SizedBox(height: 12.h),
                                Text(_error!, textAlign: TextAlign.center),
                                SizedBox(height: 16.h),
                                FilledButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
                        children: [
                          _buildLiveHeader(cs, lang),
                          SizedBox(height: 16.h),
                          _buildStatsRow(cs, queueTotal, waiting.length),
                          SizedBox(height: 20.h),
                          Text('Now speaking', style: ModernGriotTypography.titleSmall()),
                          SizedBox(height: 10.h),
                          if (speaking != null)
                            _SpeakingCard(
                              entry: speaking,
                              host: host,
                              busy: _busy,
                              onFinish: () => _run(
                                () => ref
                                    .read(classroomServiceProvider)
                                    .nextSpeaker(_tribeId!),
                              ),
                              onRemove: () => _run(
                                () => ref.read(classroomServiceProvider).removeQueueEntry(
                                      _tribeId!,
                                      speaking['id']?.toString() ?? '',
                                    ),
                              ),
                            )
                          else
                            GriotCard(
                              surfaceLevel: 0,
                              padding: EdgeInsets.all(16.r),
                              child: Text(
                                'No one is on the mic. Invite someone from the queue or join yourself.',
                                style: ModernGriotTypography.bodySmall(context: context),
                              ),
                            ),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Text('Waiting', style: ModernGriotTypography.titleSmall()),
                              const Spacer(),
                              if (host && waiting.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                            () => ref
                                                .read(classroomServiceProvider)
                                                .clearWaiting(_tribeId!),
                                          ),
                                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                                  label: const Text('Clear'),
                                ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          ...waiting.asMap().entries.map(
                                (e) => Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: _WaitingTile(
                                    index: e.key + 1,
                                    entry: e.value,
                                    host: host,
                                    busy: _busy,
                                    onRemove: () => _run(
                                      () => ref.read(classroomServiceProvider).removeQueueEntry(
                                            _tribeId!,
                                            e.value['id']?.toString() ?? '',
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          if (waiting.isEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Queue is empty — learners can tap “Raise hand” below.',
                              style: ModernGriotTypography.bodySmall(context: context),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: _buildBottomActions(cs, me, host),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme cs, Map<String, dynamic>? me, bool host) {
    final id = _tribeId;
    if (id == null) return const SizedBox.shrink();

    final status = me?['status']?.toString();
    final canLeave = status == 'waiting';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (host)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'Host: finish the current turn, remove a learner, or clear the waiting list.',
              style: ModernGriotTypography.labelSmall(),
              textAlign: TextAlign.center,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy || canLeave || status == 'speaking'
                    ? null
                    : () => _run(
                          () => ref.read(classroomServiceProvider).joinSpeakerQueue(id),
                        ),
                icon: Icon(Icons.front_hand_rounded, size: 20.sp),
                label: const Text('Raise hand'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy || !canLeave
                    ? null
                    : () => _run(
                          () => ref.read(classroomServiceProvider).leaveSpeakerQueue(id),
                        ),
                icon: Icon(Icons.do_not_touch_rounded, size: 20.sp),
                label: const Text('Leave queue'),
              ),
            ),
          ],
        ),
        if (status == 'speaking') ...[
          SizedBox(height: 8.h),
          Text(
            'You are live. The host will press “Finish turn” when you are done.',
            style: ModernGriotTypography.labelSmall().copyWith(color: cs.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLiveHeader(ColorScheme cs, String lang) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Speaker queue',
            style: ModernGriotTypography.headlineSmall(),
          ),
        ),
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
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              SizedBox(width: 5.w),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        if (lang.isNotEmpty) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(28),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text(
              lang.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme cs, dynamic queueTotal, int waitingLen) {
    final total = queueTotal is int ? queueTotal : (queueTotal is num ? queueTotal.toInt() : waitingLen);
    return Row(
      children: [
        _StatPill(
          icon: Icons.queue_rounded,
          label: '$total in queue',
          color: ModernGriotColors.primary.withAlpha(25),
          textColor: ModernGriotColors.primary,
        ),
        SizedBox(width: 8.w),
        _StatPill(
          icon: Icons.hourglass_bottom_rounded,
          label: '$waitingLen waiting',
          color: cs.surfaceContainerHigh,
          textColor: cs.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildPicker(ColorScheme cs) {
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
                  'No classroom tribes found.',
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
                      _startPolling();
                    },
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: cs.secondary.withAlpha(40),
                            borderRadius: ModernGriotRadius.borderLg,
                          ),
                          child: Icon(Icons.mic_rounded, color: cs.secondary, size: 28.sp),
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
                                  color: cs.secondary,
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

class _SpeakingCard extends StatelessWidget {
  const _SpeakingCard({
    required this.entry,
    required this.host,
    required this.busy,
    required this.onFinish,
    required this.onRemove,
  });

  final Map<String, dynamic> entry;
  final bool host;
  final bool busy;
  final VoidCallback onFinish;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = entry['display_name']?.toString() ?? 'Learner';
    final subtitle = entry['subtitle']?.toString() ?? '';
    final since = entry['speaking_since'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.fab,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GriotAvatar(size: 52, status: GriotAvatarStatus.online),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: ModernGriotColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ModernGriotColors.onPrimary.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
              if (since != null)
                _ElapsedBadge(startedIso: since.toString())
              else
                Icon(Icons.mic_rounded, color: ModernGriotColors.onPrimary, size: 28.sp),
            ],
          ),
          if (host) ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(230),
                      foregroundColor: ModernGriotColors.primary,
                    ),
                    onPressed: busy ? null : onFinish,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Finish turn'),
                  ),
                ),
                SizedBox(width: 10.w),
                IconButton.filledTonal(
                  onPressed: busy ? null : onRemove,
                  icon: const Icon(Icons.person_remove_rounded),
                  tooltip: 'Remove from queue',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ElapsedBadge extends StatefulWidget {
  const _ElapsedBadge({required this.startedIso});
  final String startedIso;

  @override
  State<_ElapsedBadge> createState() => _ElapsedBadgeState();
}

class _ElapsedBadgeState extends State<_ElapsedBadge> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(widget.startedIso);
    if (start == null) return const SizedBox.shrink();
    final d = DateTime.now().difference(start.toLocal());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    final label = h > 0 ? '${h}:$m:$s' : '$m:$s';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _WaitingTile extends StatelessWidget {
  const _WaitingTile({
    required this.index,
    required this.entry,
    required this.host,
    required this.busy,
    required this.onRemove,
  });

  final int index;
  final Map<String, dynamic> entry;
  final bool host;
  final bool busy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = entry['display_name']?.toString() ?? 'Learner';
    final subtitle = entry['subtitle']?.toString() ?? '';

    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withAlpha(40),
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ModernGriotTypography.titleSmall(context: context)),
                Text(subtitle, style: ModernGriotTypography.bodySmall(context: context)),
              ],
            ),
          ),
          if (host)
            IconButton(
              onPressed: busy ? null : onRemove,
              icon: Icon(Icons.close_rounded, color: cs.error),
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: ModernGriotRadius.borderLg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: textColor),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
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
