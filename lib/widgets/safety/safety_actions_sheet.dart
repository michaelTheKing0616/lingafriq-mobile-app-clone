import 'package:lingafriq/l10n/l10n_of.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/screens/safety/copyright_policy_screen.dart';

/// Copy keys align with plan `safety.*` (P9-930).
abstract final class SafetyCopy {
  static const block = 'Block';
  static const mute = 'Mute';
  static const report = 'Report';
  static const reportedTitle = 'Report received';
  static const reportedBody = 'Thanks for helping keep Village safe. Case';
  static const confirmBlockTitle = 'Block this person?';
  static const confirmBlockBody =
      'They will not be able to message you or see when you are online.';
  static const confirmMuteTitle = 'Mute notifications?';
  static const confirmMuteBody =
      'You will not see their messages in shared spaces.';
  static const reportReasonTitle = 'Why are you reporting this?';
  static const offlineQueued =
      'Report saved. We will send it when you are back online.';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
}

enum SafetyTargetKind { message, profile, clip, room, comment }

class SafetyActionTarget {
  const SafetyActionTarget({
    required this.kind,
    required this.targetId,
    this.peerUserId,
    this.peerDisplayName,
    this.previewText,
  });

  final SafetyTargetKind kind;
  final String targetId;
  final String? peerUserId;
  final String? peerDisplayName;
  final String? previewText;

  String get apiTargetType {
    switch (kind) {
      case SafetyTargetKind.message:
        return 'message';
      case SafetyTargetKind.profile:
        return 'user';
      case SafetyTargetKind.clip:
        return 'clip';
      case SafetyTargetKind.room:
        return 'room';
      case SafetyTargetKind.comment:
        return 'comment';
    }
  }
}

/// Tap budget for AC1 (menu → action ≤2 taps after sheet open).
class SafetyTapLedger {
  int taps = 0;

  void recordTap() => taps += 1;
}

class SafetyReportOutbox {
  SafetyReportOutbox._();
  static const _key = 'safety_report_outbox_v1';

  static Future<void> enqueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = raw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    list.add({...payload, 'queuedAt': DateTime.now().toIso8601String()});
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> replaceAll(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(rows));
  }

  static Future<int> flush(
    Future<void> Function(Map<String, dynamic> row) send,
  ) async {
    final rows = await pending();
    if (rows.isEmpty) return 0;
    final remaining = <Map<String, dynamic>>[];
    var sent = 0;
    for (final row in rows) {
      try {
        await send(row);
        sent += 1;
      } catch (_) {
        remaining.add(row);
      }
    }
    await replaceAll(remaining);
    return sent;
  }
}

typedef SafetyConnectivityCheck = Future<bool> Function();

Future<void> showSafetyActionsSheet(
  BuildContext context, {
  required SafetyActionTarget target,
  SafetyTapLedger? tapLedger,
  SafetyConnectivityCheck? isOnline,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => SafetyActionsSheet(
      target: target,
      tapLedger: tapLedger,
      isOnline: isOnline ?? () async => true,
    ),
  );
}

class SafetyActionsSheet extends StatefulWidget {
  const SafetyActionsSheet({
    super.key,
    required this.target,
    this.tapLedger,
    required this.isOnline,
  });

  final SafetyActionTarget target;
  final SafetyTapLedger? tapLedger;
  final SafetyConnectivityCheck isOnline;

  @override
  State<SafetyActionsSheet> createState() => _SafetyActionsSheetState();
}

class _SafetyActionsSheetState extends State<SafetyActionsSheet> {
  bool _busy = false;
  String? _status;
  String? _caseId;

  void _tap() => widget.tapLedger?.recordTap();

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final response = await ApiService.post(path, data: body);
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception('request_failed');
    }
  }

  Future<void> _runBlock() async {
    final peer = widget.target.peerUserId;
    if (peer == null) return;
    _tap();
    final confirmed = await _confirm(
      title: SafetyCopy.confirmBlockTitle,
      body: SafetyCopy.confirmBlockBody,
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await _post('/user-connections/block', {'targetUserId': peer});
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _status = 'Block failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runMute() async {
    final peer = widget.target.peerUserId;
    if (peer == null) return;
    _tap();
    final confirmed = await _confirm(
      title: SafetyCopy.confirmMuteTitle,
      body: SafetyCopy.confirmMuteBody,
      danger: false,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await _post('/safety/mute', {'targetUserId': peer});
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _status = 'Mute failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runReport() async {
    _tap();
    final reason = await _pickReason();
    if (reason == null) return;
    if (reason == 'copyright' && mounted) {
      final nav = Navigator.of(context);
      nav.pop();
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => CopyrightPolicyScreen(
            targetType: widget.target.apiTargetType,
            targetId: widget.target.targetId,
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final payload = {
      'targetType': widget.target.apiTargetType,
      'targetId': widget.target.targetId,
      'reason': reason,
      if (widget.target.previewText != null)
        'previewText': widget.target.previewText,
    };
    try {
      final online = await widget.isOnline();
      if (!online) {
        await SafetyReportOutbox.enqueue(payload);
        if (!mounted) return;
        setState(() {
          _status = SafetyCopy.offlineQueued;
          _busy = false;
        });
        return;
      }
      final response = await ApiService.post('/safety/reports', data: payload);
      final data = response.data as Map<String, dynamic>?;
      final caseId =
          data?['caseId']?.toString() ?? data?['referenceId']?.toString();
      if (!mounted) return;
      setState(() {
        _caseId = caseId;
        _status = '${SafetyCopy.reportedBody} $caseId';
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Report failed. Try again when online.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required bool danger,
  }) async {
    _tap();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () {
              _tap();
              Navigator.pop(ctx, false);
            },
            child: const Text(SafetyCopy.cancel),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.error,
                  )
                : null,
            onPressed: () {
              _tap();
              Navigator.pop(ctx, true);
            },
            child: const Text(SafetyCopy.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _pickReason() => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => ReportReasonPicker(
      onPicked: (r) {
        _tap();
        Navigator.pop(ctx, r);
      },
    ),
  );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: _busy ? null : onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.target.peerDisplayName ?? 'this content';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.lg,
                vertical: PanAfricanSpacing.sm,
              ),
              child: Text(
                name,
                style: PanAfricanTypography.titleSmall(context),
                textAlign: TextAlign.center,
              ),
            ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            _actionTile(
              icon: Icons.block,
              label: SafetyCopy.block,
              color: PanAfricanColors.error,
              onTap: _runBlock,
            ),
            _actionTile(
              icon: Icons.notifications_off_outlined,
              label: SafetyCopy.mute,
              onTap: _runMute,
            ),
            _actionTile(
              icon: Icons.flag_outlined,
              label: SafetyCopy.report,
              onTap: _runReport,
            ),
            if (_status != null)
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _caseId != null ? _status! : _status!,
                    style: PanAfricanTypography.bodySmall(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Report reasons, in the API's vocabulary (`POST /safety/reports`).
const reportReasons = ['harassment', 'spam', 'hate', 'copyright', 'other'];

/// Localised, human-readable reason list used by the report flow.
class ReportReasonPicker extends StatelessWidget {
  const ReportReasonPicker({super.key, required this.onPicked});

  final ValueChanged<String> onPicked;

  static (IconData, String, String?) describe(
    AppLocalizations l,
    String r,
  ) => switch (r) {
    'harassment' => (Icons.person_off_outlined, l.reportReasonHarassment, null),
    'spam' => (Icons.report_gmailerrorred_outlined, l.reportReasonSpam, null),
    'hate' => (Icons.do_not_disturb_on_outlined, l.reportReasonHate, null),
    'copyright' => (
      Icons.copyright_rounded,
      l.reportReasonCopyright,
      l.reportReasonCopyrightHint,
    ),
    _ => (Icons.more_horiz_rounded, l.reportReasonOther, null),
  };

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  l.reportReasonTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            for (final r in reportReasons)
              Builder(
                builder: (context) {
                  final (icon, title, hint) = describe(l, r);
                  return ListTile(
                    key: ValueKey('reason-$r'),
                    minVerticalPadding: 12,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(
                      icon,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(title),
                    subtitle: hint == null ? null : Text(hint),
                    trailing: r == 'copyright'
                        ? Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                          )
                        : null,
                    onTap: () => onPicked(r),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
