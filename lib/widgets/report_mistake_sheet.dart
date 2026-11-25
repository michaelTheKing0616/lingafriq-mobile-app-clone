import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';
import 'package:lingafriq/utils/api_service.dart';

/// POST `/api/v2/content-flags` (P5-012).
const String contentFlagApiPath = '/api/v2/content-flags';

const String contentFlagPendingPrefsKey = 'content_flag_pending_v1';

/// copy_keys: report.title, report.cat.meaning, report.cat.tone_spelling, report.cat.audio,
/// report.cat.unnatural, report.cat.offensive
enum ReportMistakeCategory {
  wrongMeaning('wrong_meaning', 'Wrong meaning'),
  toneSpelling('tone_spelling', 'Tone/spelling'),
  audio('audio', 'Audio'),
  unnatural('unnatural', 'Unnatural'),
  offensive('offensive', 'Offensive');

  const ReportMistakeCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Fixed category order (AC2).
const List<ReportMistakeCategory> reportMistakeCategories = [
  ReportMistakeCategory.wrongMeaning,
  ReportMistakeCategory.toneSpelling,
  ReportMistakeCategory.audio,
  ReportMistakeCategory.unnatural,
  ReportMistakeCategory.offensive,
];

enum ReportMistakeOutcome {
  idle,
  sending,
  sent,
  queued,
  error,
}

typedef ContentFlagPost = Future<void> Function(Map<String, Object?> body);

class ReportMistakeSubmitter {
  ReportMistakeSubmitter({
    ContentFlagPost? post,
    Future<List<Map<String, Object?>>> Function()? loadPending,
    Future<void> Function(List<Map<String, Object?>> pending)? savePending,
    Future<bool> Function()? isOnline,
  })  : _post = post ?? _defaultPost,
        _loadPending = loadPending ?? _defaultLoadPending,
        _savePending = savePending ?? _defaultSavePending,
        _isOnline = isOnline ?? (() async => true);

  final ContentFlagPost _post;
  final Future<List<Map<String, Object?>>> Function() _loadPending;
  final Future<void> Function(List<Map<String, Object?>> pending) _savePending;
  final Future<bool> Function() _isOnline;

  static Future<void> _defaultPost(Map<String, Object?> body) async {
    await ApiService.initialize();
    await ApiService.post(contentFlagApiPath, data: body);
  }

  static Future<List<Map<String, Object?>>> _defaultLoadPending() async => [];

  static Future<void> _defaultSavePending(List<Map<String, Object?>> pending) async {}

  Future<ReportMistakeOutcome> submit({
    required String itemId,
    required String packVersion,
    required ReportMistakeCategory category,
  }) async {
    final body = <String, Object?>{
      'item_id': itemId,
      'pack_version': packVersion,
      'category': category.apiValue,
    };

    if (!await _isOnline()) {
      await _enqueuePending(body);
      return ReportMistakeOutcome.queued;
    }

    try {
      await _post(body);
      return ReportMistakeOutcome.sent;
    } catch (_) {
      return ReportMistakeOutcome.error;
    }
  }

  Future<void> _enqueuePending(Map<String, Object?> body) async {
    final pending = await _loadPending();
    pending.add(body);
    await _savePending(pending);
  }
}

class InMemoryContentFlagPendingStore {
  final List<Map<String, Object?>> _rows = [];

  Future<List<Map<String, Object?>>> load() async =>
      _rows.map((e) => Map<String, Object?>.from(e)).toList();

  Future<void> save(List<Map<String, Object?>> pending) async {
    _rows
      ..clear()
      ..addAll(pending.map((e) => Map<String, Object?>.from(e)));
  }

  String encode() => jsonEncode(_rows);
}

/// Opens the report sheet; returns final outcome when dismissed after submit attempt.
Future<ReportMistakeOutcome?> showReportMistakeSheet({
  required BuildContext context,
  required String itemId,
  required String packVersion,
  ReportMistakeSubmitter? submitter,
}) {
  return showModalBottomSheet<ReportMistakeOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return ReportMistakeSheet(
        itemId: itemId,
        packVersion: packVersion,
        submitter: submitter ?? ReportMistakeSubmitter(),
      );
    },
  );
}

class ReportMistakeSheet extends StatefulWidget {
  const ReportMistakeSheet({
    super.key,
    required this.itemId,
    required this.packVersion,
    required this.submitter,
  });

  final String itemId;
  final String packVersion;
  final ReportMistakeSubmitter submitter;

  @override
  State<ReportMistakeSheet> createState() => _ReportMistakeSheetState();
}

class _ReportMistakeSheetState extends State<ReportMistakeSheet> {
  ReportMistakeCategory? _selected;
  ReportMistakeOutcome _outcome = ReportMistakeOutcome.idle;
  String? _statusMessage;

  static const _title = 'Report a mistake';

  Future<void> _submit() async {
    final category = _selected;
    if (category == null) {
      return;
    }
    setState(() {
      _outcome = ReportMistakeOutcome.sending;
      _statusMessage = null;
    });
    final result = await widget.submitter.submit(
      itemId: widget.itemId,
      packVersion: widget.packVersion,
      category: category,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _outcome = result;
      switch (result) {
        case ReportMistakeOutcome.sent:
          _statusMessage = 'Report sent. Thank you.';
        case ReportMistakeOutcome.queued:
          _statusMessage = 'Report queued. It will send when you are back online.';
        case ReportMistakeOutcome.error:
          _statusMessage = 'Could not send report. Try again.';
        case ReportMistakeOutcome.sending:
        case ReportMistakeOutcome.idle:
          _statusMessage = null;
      }
    });
    if (result == ReportMistakeOutcome.sent || result == ReportMistakeOutcome.queued) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < reportMistakeCategories.length; i++)
                  FocusTraversalOrder(
                    order: NumericFocusOrder(i.toDouble()),
                    child: _CategoryChip(
                      category: reportMistakeCategories[i],
                      selected: _selected == reportMistakeCategories[i],
                      enabled: _outcome != ReportMistakeOutcome.sending,
                      onSelected: () {
                        setState(() => _selected = reportMistakeCategories[i]);
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_selected != null)
            Builder(
              builder: (context) {
                final clauseId =
                    CommunityGuidelinesCatalog.contentFlagClauseId(_selected!.apiValue);
                if (clauseId == null) {
                  return const SizedBox.shrink();
                }
                return CommunityGuidelinesRuleLink(clauseId: clauseId);
              },
            ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            enabled: _selected != null && _outcome != ReportMistakeOutcome.sending,
            label: 'Send mistake report',
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _selected == null || _outcome == ReportMistakeOutcome.sending
                    ? null
                    : _submit,
                child: _outcome == ReportMistakeOutcome.sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send report'),
              ),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ReportMistakeCategory category;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      enabled: enabled,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onSelected : null,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(
                child: Text(
                  category.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
