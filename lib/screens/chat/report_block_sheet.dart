import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Copy keys from P1-024: report.title, report.reasons, block.confirm.
abstract final class ReportCopy {
  static const title = 'Report';
  static const reasons = ['harassment', 'spam', 'hate', 'other'];
  static const reasonLabels = {
    'harassment': 'Harassment',
    'spam': 'Spam',
    'hate': 'Hate',
    'other': 'Other',
  };
  static const blockConfirm =
      'Block this person? You will not see their new messages or snaps.';
}

class BlockedPerson {
  const BlockedPerson({required this.id, required this.name});

  final String id;
  final String name;
}

class ReportBlockSheet extends StatefulWidget {
  const ReportBlockSheet({
    super.key,
    required this.onReport,
    required this.onBlock,
    this.onLoadBlocked,
    this.onUnblock,
  });

  final Future<String> Function(String reason) onReport;
  final Future<void> Function() onBlock;
  final Future<List<BlockedPerson>> Function()? onLoadBlocked;
  final Future<void> Function(String userId)? onUnblock;

  @override
  State<ReportBlockSheet> createState() => _ReportBlockSheetState();
}

class _ReportBlockSheetState extends State<ReportBlockSheet> {
  String _reason = ReportCopy.reasons.first;
  bool _submitting = false;
  bool _confirmingBlock = false;
  String? _referenceId;
  String? _error;
  String? _blockNote;

  Future<void> _submitReport() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final referenceId = await widget.onReport(_reason);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _referenceId = referenceId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not send that. Try again.';
      });
    }
  }

  Future<void> _confirmBlock() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onBlock();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _confirmingBlock = false;
        _blockNote = 'Blocked. You will not see their new messages.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not block this person. Try again.';
      });
    }
  }

  Future<void> _openBlocked() async {
    final load = widget.onLoadBlocked;
    final unblock = widget.onUnblock;
    if (load == null || unblock == null) return;
    final people = await load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => BlockedUsersSheet(people: people, onUnblock: unblock),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Semantics(
        namesRoute: true,
        label: ReportCopy.title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ReportCopy.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_referenceId != null)
                Text('Report received. Reference $_referenceId')
              else ...[
                Semantics(
                  container: true,
                  label: 'Report reasons',
                  child: Column(
                    children: [
                      for (final reason in ReportCopy.reasons)
                        RadioListTile<String>(
                          value: reason,
                          groupValue: _reason,
                          onChanged: _submitting
                              ? null
                              : (value) => setState(() => _reason = value ?? _reason),
                          title: Text(ReportCopy.reasonLabels[reason] ?? reason),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submitReport,
                  child: Text(_submitting ? 'Sending report' : 'Send report'),
                ),
              ],
              if (_submitting) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: PanAfricanColors.error)),
                ),
              if (_blockNote != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_blockNote!),
                ),
              const SizedBox(height: 8),
              if (_confirmingBlock)
                Semantics(
                  container: true,
                  label: ReportCopy.blockConfirm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(ReportCopy.blockConfirm),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _submitting ? null : _confirmBlock,
                        child: const Text('Confirm block'),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => _confirmingBlock = true),
                  child: const Text('Block user'),
                ),
              if (widget.onLoadBlocked != null)
                TextButton(
                  onPressed: _openBlocked,
                  child: const Text('Blocked people'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockedUsersSheet extends StatelessWidget {
  const BlockedUsersSheet({
    super.key,
    required this.people,
    required this.onUnblock,
  });

  final List<BlockedPerson> people;
  final Future<void> Function(String userId) onUnblock;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Semantics(
        namesRoute: true,
        label: 'Blocked people',
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 1 + (people.isEmpty ? 1 : people.length),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const ListTile(title: Text('Blocked people'));
            }
            if (people.isEmpty) {
              return const ListTile(title: Text('No blocked people'));
            }
            final person = people[index - 1];
            return ListTile(
              title: Text(person.name),
              trailing: TextButton(
                onPressed: () => onUnblock(person.id),
                child: const Text('Unblock'),
              ),
            );
          },
        ),
      ),
    );
  }
}
