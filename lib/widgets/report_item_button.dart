import 'package:flutter/material.dart';
import 'package:lingafriq/services/content/item_report_service.dart';

/// copy_keys: item.report.cta, item.report.reason, item.report.sent, item.report.queued
class ReportItemButton extends StatefulWidget {
  const ReportItemButton({
    super.key,
    required this.itemId,
    required this.packVersion,
    required this.service,
  });

  final String itemId;
  final String packVersion;
  final ItemReportService service;

  @override
  State<ReportItemButton> createState() => _ReportItemButtonState();
}

class _ReportItemButtonState extends State<ReportItemButton> {
  ItemReportSubmitState _state = ItemReportSubmitState.idle;
  String? _statusMessage;

  static const _ctaLabel = 'This is wrong';
  static const _semanticsLabel = 'Report a problem with this exercise item';

  Future<void> _openReportSheet() async {
    final reasonController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What is wrong?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Send report'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (submitted != true) {
      return;
    }
    setState(() {
      _state = ItemReportSubmitState.submitting;
      _statusMessage = null;
    });
    final result = await widget.service.submitReport(
      itemId: widget.itemId,
      packVersion: widget.packVersion,
      reason: reasonController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _state = result;
      switch (result) {
        case ItemReportSubmitState.sent:
          _statusMessage = 'Report sent to reviewers.';
        case ItemReportSubmitState.queuedOffline:
          _statusMessage = 'Report saved offline. It will send when you are back online.';
        case ItemReportSubmitState.error:
          _statusMessage = 'Could not send report. Try again.';
        case ItemReportSubmitState.submitting:
        case ItemReportSubmitState.idle:
          _statusMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.errorContainer;
    final onDanger = theme.colorScheme.onErrorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: _semanticsLabel,
          child: Material(
            color: danger,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _state == ItemReportSubmitState.submitting ? null : _openReportSheet,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: ExcludeSemantics(
                    child: _state == ItemReportSubmitState.submitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onDanger,
                            ),
                          )
                        : Text(
                            _ctaLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: onDanger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
