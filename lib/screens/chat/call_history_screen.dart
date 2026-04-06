import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/api_contract.dart';
import '../../utils/api_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;
import '../../widgets/animations/smooth_transitions.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'global_chat_screen_material3.dart';
import 'live_classroom_screen_material3.dart';

/// Call log: **GET /api/calls/history** with CTAs to real voice/video surfaces.
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key, this.embedInTab = false});

  final bool embedInTab;

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

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
      final res = await ApiService.get(
        ApiContract.url(ApiContract.calls.history),
        queryParameters: {'limit': '50'},
      );
      final raw = res.data;
      List<Map<String, dynamic>> list;
      if (raw is Map && raw['data'] is List) {
        list = (raw['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (raw is List) {
        list = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        list = [];
      }
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load call history.';
      });
    }
  }

  static String _label(Map<String, dynamic> row) {
    final t = (row['title'] ?? '').toString().trim();
    if (t.isNotEmpty) return t;
    final st = (row['session_type'] ?? row['sessionType'] ?? 'other').toString();
    switch (st) {
      case 'live_classroom':
        return 'Live Classroom';
      case 'voice_chat':
        return 'Voice chat';
      case 'wa_voice':
        return 'WhatsApp-style voice';
      case 'global_chat':
        return 'Global chat';
      default:
        return 'Call';
    }
  }

  static String? _peerName(Map<String, dynamic> row) {
    final p = row['peer_user_id'] ?? row['peerUserId'];
    if (p is! Map) return null;
    final m = Map<String, dynamic>.from(p);
    final fn = (m['first_name'] ?? m['firstName'] ?? '').toString().trim();
    final ln = (m['last_name'] ?? m['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    final u = (m['username'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    if (u.isNotEmpty) return '@$u';
    return null;
  }

  static String _when(Map<String, dynamic> row) {
    final s = row['started_at'] ?? row['startedAt'];
    final dt = DateTime.tryParse(s?.toString() ?? '');
    if (dt == null) return '';
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  }

  IconData _iconFor(Map<String, dynamic> row) {
    final st = (row['session_type'] ?? '').toString();
    switch (st) {
      case 'live_classroom':
        return Icons.school_outlined;
      case 'global_chat':
        return Icons.public;
      case 'wa_voice':
        return Icons.chat_rounded;
      default:
        return Icons.call_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.lg,
                vertical: PanAfricanSpacing.lg,
              ),
              children: [
                if (_error != null)
                  Material(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                if (_error != null) SizedBox(height: PanAfricanSpacing.md),
                if (!_loading && _rows.isEmpty) ...[
                  Icon(Icons.phone_in_talk_rounded,
                      size: 56.sp, color: cs.onSurfaceVariant),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    'No call history yet',
                    style: ModernGriotTypography.titleMedium(context: context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'Start a session in Live Classroom or Global Chat. When you finish, the app can log it to this list (POST /api/calls/log).',
                    style: ModernGriotTypography.bodyMedium(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                ],
                ..._rows.map((row) {
                  final peer = _peerName(row);
                  final dur = row['duration_seconds'] ?? row['durationSeconds'];
                  final durStr = dur is num && dur > 0
                      ? '${dur.toInt()}s'
                      : '';
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: GriotCard(
                      surfaceLevel: 0,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_iconFor(row), color: cs.primary),
                        title: Text(
                          _label(row),
                          style: ModernGriotTypography.titleSmall(context: context),
                        ),
                        subtitle: Text(
                          [
                            if (peer != null) peer,
                            _when(row),
                            if (durStr.isNotEmpty) durStr,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: PanAfricanSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      SmoothPageRoute(child: LiveClassroomScreenMaterial3()),
                    );
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Open Live Classroom'),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      SmoothPageRoute(child: const GlobalChatScreenMaterial3()),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Open Global Chat'),
                ),
              ],
            ),
          );

    if (widget.embedInTab) {
      return body;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: GriotAppBar(
        title: 'Calls',
        showBranding: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: body,
    );
  }
}
