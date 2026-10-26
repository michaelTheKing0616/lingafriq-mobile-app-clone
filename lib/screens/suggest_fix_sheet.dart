import 'package:flutter/material.dart';
import 'package:lingafriq/utils/api_service.dart';

/// POST `/api/v2/verify-queue/suggestions` (P5-057).
const String suggestFixApiPath = '/api/v2/verify-queue/suggestions';

/// copy_keys: fix.title
const String suggestFixTitleKey = 'fix.title';

enum SuggestFixOutcome {
  idle,
  sending,
  submitted,
  error,
}

typedef SuggestFixPost = Future<void> Function(Map<String, Object?> body);

class SuggestFixSubmitter {
  SuggestFixSubmitter({
    SuggestFixPost? post,
  }) : _post = post ?? _defaultPost;

  final SuggestFixPost _post;

  static Future<void> _defaultPost(Map<String, Object?> body) async {
    await ApiService.initialize();
    await ApiService.post(suggestFixApiPath, data: body);
  }

  Future<SuggestFixOutcome> submit({
    required String itemId,
    required String packVersion,
    required String proposedValue,
    bool heritageLearner = true,
    bool villageContribute = true,
  }) async {
    final trimmed = proposedValue.trim();
    if (trimmed.isEmpty) {
      return SuggestFixOutcome.error;
    }

    final body = <String, Object?>{
      'item_id': itemId,
      'pack_version': packVersion,
      'field': 'target_text',
      'proposed_value': trimmed,
      'proposer_kind': heritageLearner ? 'heritage_learner' : 'learner',
      'source': villageContribute ? 'village_contribute' : 'lesson_item',
    };

    try {
      await _post(body);
      return SuggestFixOutcome.submitted;
    } catch (_) {
      return SuggestFixOutcome.error;
    }
  }
}

Future<SuggestFixOutcome?> showSuggestFixSheet({
  required BuildContext context,
  required String itemId,
  required String packVersion,
  SuggestFixSubmitter? submitter,
}) {
  return showModalBottomSheet<SuggestFixOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SuggestFixSheet(
        itemId: itemId,
        packVersion: packVersion,
        submitter: submitter ?? SuggestFixSubmitter(),
      );
    },
  );
}

class SuggestFixSheet extends StatefulWidget {
  const SuggestFixSheet({
    super.key,
    required this.itemId,
    required this.packVersion,
    required this.submitter,
  });

  final String itemId;
  final String packVersion;
  final SuggestFixSubmitter submitter;

  @override
  State<SuggestFixSheet> createState() => _SuggestFixSheetState();
}

class _SuggestFixSheetState extends State<SuggestFixSheet> {
  final _controller = TextEditingController();
  SuggestFixOutcome _outcome = SuggestFixOutcome.idle;
  String? _statusMessage;

  static const _title = 'Suggest a fix';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _outcome = SuggestFixOutcome.sending;
      _statusMessage = null;
    });
    final result = await widget.submitter.submit(
      itemId: widget.itemId,
      packVersion: widget.packVersion,
      proposedValue: _controller.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _outcome = result;
      switch (result) {
        case SuggestFixOutcome.submitted:
          _statusMessage =
              'Your suggestion is in the Verify queue. The lesson stays as-is until validators review it.';
        case SuggestFixOutcome.error:
          _statusMessage = 'Could not send your suggestion. Try again.';
        case SuggestFixOutcome.sending:
        case SuggestFixOutcome.idle:
          _statusMessage = null;
      }
    });
    if (result == SuggestFixOutcome.submitted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canSend = _controller.text.trim().isNotEmpty && _outcome != SuggestFixOutcome.sending;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: _title,
            child: Text(_title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Free contribution — Village → Contribute',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: _outcome != SuggestFixOutcome.sending,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Proposed correction',
              hintText: 'Enter the wording you would use',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            enabled: canSend,
            label: 'Send suggestion to Verify queue',
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: canSend ? _submit : null,
                child: _outcome == SuggestFixOutcome.sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send to Verify queue'),
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
