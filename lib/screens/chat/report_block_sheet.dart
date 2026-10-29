import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';
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

/// Localised strings; falls back to English where no delegate is installed.
AppLocalizations _l(BuildContext c) =>
    Localizations.of<AppLocalizations>(c, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

String _reasonLabel(AppLocalizations l, String r) => switch (r) {
  'harassment' => l.gcReasonHarassment,
  'spam' => l.gcReasonSpam,
  'hate' => l.rbHate,
  _ => l.rbOther,
};

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
        _error = _l(context).rbSendFailed;
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
        _blockNote = _l(context).rbBlockedNote;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _l(context).rbBlockFailed;
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
      builder: (context) =>
          BlockedUsersSheet(people: people, onUnblock: unblock),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    return SafeArea(
      child: Semantics(
        namesRoute: true,
        label: l.gcReport,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.gcReport, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_referenceId != null)
                Text(l.rbReceived('\u2068$_referenceId\u2069'))
              else ...[
                Semantics(
                  container: true,
                  label: l.rbReasons,
                  child: RadioGroup<String>(
                    groupValue: _reason,
                    onChanged: (value) {
                      if (!_submitting)
                        setState(() => _reason = value ?? _reason);
                    },
                    child: Column(
                      children: [
                        for (final reason in ReportCopy.reasons)
                          RadioListTile<String>(
                            value: reason,
                            enabled: !_submitting,
                            title: Text(_reasonLabel(l, reason)),
                          ),
                      ],
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final clauseId =
                        CommunityGuidelinesCatalog.socialReportClauseId(
                          _reason,
                        );
                    if (clauseId == null) {
                      return const SizedBox.shrink();
                    }
                    return CommunityGuidelinesRuleLink(clauseId: clauseId);
                  },
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submitReport,
                  child: Text(_submitting ? l.rbSending : l.rbSendReport),
                ),
              ],
              if (_submitting) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: PanAfricanColors.error),
                  ),
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
                  label: l.rbBlockConfirm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.rbBlockConfirm),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _submitting ? null : _confirmBlock,
                        child: Text(l.rbConfirmBlock),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _confirmingBlock = true),
                  child: Text(l.rbBlockUser),
                ),
              if (widget.onLoadBlocked != null)
                TextButton(
                  onPressed: _openBlocked,
                  child: Text(l.rbBlockedPeople),
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
    final l = _l(context);
    return SafeArea(
      child: Semantics(
        namesRoute: true,
        label: l.rbBlockedPeople,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 1 + (people.isEmpty ? 1 : people.length),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(title: Text(l.rbBlockedPeople));
            }
            if (people.isEmpty) {
              return ListTile(title: Text(l.rbNoBlocked));
            }
            final person = people[index - 1];
            return ListTile(
              title: Text('\u2068${person.name}\u2069'),
              trailing: TextButton(
                onPressed: () => onUnblock(person.id),
                child: Text(l.gcUnblock),
              ),
            );
          },
        ),
      ),
    );
  }
}
