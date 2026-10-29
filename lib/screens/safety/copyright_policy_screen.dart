import 'package:flutter/material.dart';
import 'package:lingafriq/utils/api_service.dart';

typedef CopyrightSubmit = Future<String?> Function(Map<String, dynamic> body);

Future<String?> _defaultSubmit(Map<String, dynamic> body) async {
  final res = await ApiService.post('/safety/copyright-notices', data: body);
  final data = res.data;
  return data is Map ? data['referenceId']?.toString() : null;
}

/// Copyright takedown policy + notice / counter-notice form for user uploads
/// (17 USC 512(c)(3) / 512(g)(3); repeat-infringer policy).
class CopyrightPolicyScreen extends StatefulWidget {
  const CopyrightPolicyScreen({
    super.key,
    this.targetType = 'media',
    this.targetId = '',
    this.submit = _defaultSubmit,
  });

  final String targetType;
  final String targetId;
  final CopyrightSubmit submit;

  static const policy = <String>[
    'We respect copyright. If content uploaded to LingAfriq (snaps, clips, '
        'avatars, chat media or audio) infringes your copyright, send us a '
        'notice below.',
    'A notice must identify the work, the content on LingAfriq, your contact '
        'details, a good-faith statement, a statement that the notice is '
        'accurate and you are authorised to act, and your signature.',
    'We remove or disable the content promptly and tell the uploader.',
    'The uploader may send a counter-notice if they believe the removal was '
        'a mistake. Unless the claimant tells us they have filed a court '
        'action, we may restore the content in 10–14 business days.',
    'Repeat infringers: accounts with 3 upheld copyright notices are '
        'terminated.',
    'Knowingly false notices or counter-notices may create legal liability.',
  ];

  @override
  State<CopyrightPolicyScreen> createState() => _CopyrightPolicyScreenState();
}

class _CopyrightPolicyScreenState extends State<CopyrightPolicyScreen> {
  String _kind = 'notice';
  late final _targetId = TextEditingController(text: widget.targetId);
  final _work = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _sig = TextEditingController();
  final Set<String> _statements = {};
  String? _status;
  bool _busy = false;

  static const _stmts = {
    'notice': {
      'good_faith':
          'I believe in good faith this use is not authorised by the owner, its agent or the law.',
      'accurate_and_authorised':
          'This notice is accurate and, under penalty of perjury, I am the owner or authorised to act for the owner.',
    },
    'counter': {
      'mistake_or_misidentification':
          'Under penalty of perjury, I believe the content was removed by mistake or misidentification.',
      'consent_to_jurisdiction':
          'I consent to the jurisdiction of the appropriate court and accept service from the claimant.',
    },
  };

  @override
  void dispose() {
    for (final c in [_targetId, _work, _name, _email, _sig]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final need = _stmts[_kind]!.keys;
    if (_targetId.text.trim().isEmpty ||
        _work.text.trim().length < 10 ||
        _name.text.trim().isEmpty ||
        !_email.text.contains('@') ||
        _sig.text.trim().isEmpty ||
        !need.every(_statements.contains)) {
      setState(() => _status = 'Fill in every field and tick each statement.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ref = await widget.submit({
        'kind': _kind,
        'targetType': widget.targetType,
        'targetId': _targetId.text.trim(),
        'workDescription': _work.text.trim(),
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'signature': _sig.text.trim(),
        'statements': need.toList(),
      });
      if (mounted) {
        setState(() => _status = 'Sent. Reference: ${ref ?? 'pending'}.');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not send. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Copyright & takedown')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Takedown policy', style: t.titleMedium),
          for (final p in CopyrightPolicyScreen.policy)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• $p'),
            ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'notice', label: Text('Report copyright')),
              ButtonSegment(value: 'counter', label: Text('Counter-notice')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _statements.clear();
            }),
          ),
          const SizedBox(height: 12),
          _field(_targetId, 'Content ID or link on LingAfriq'),
          _field(
            _work,
            _kind == 'notice'
                ? 'Describe your copyrighted work'
                : 'Describe the removed content',
            lines: 3,
          ),
          _field(_name, 'Full legal name'),
          _field(_email, 'Email'),
          for (final e in _stmts[_kind]!.entries)
            CheckboxListTile(
              key: ValueKey('stmt-${e.key}'),
              value: _statements.contains(e.key),
              onChanged: (v) => setState(
                () => v == true
                    ? _statements.add(e.key)
                    : _statements.remove(e.key),
              ),
              title: Text(e.value),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          _field(_sig, 'Signature (type your full name)'),
          FilledButton(
            key: const ValueKey('copyright-send'),
            onPressed: _busy ? null : _send,
            child: const Text('Send'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_status!, key: const ValueKey('copyright-status')),
            ),
        ],
      ),
    );
  }
}
