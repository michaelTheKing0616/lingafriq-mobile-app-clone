import 'package:flutter/material.dart';
import 'package:lingafriq/config/copyright_agent.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

typedef CopyrightSubmit = Future<String?> Function(Map<String, dynamic> body);

Future<String?> _defaultSubmit(Map<String, dynamic> body) async {
  final res = await ApiService.post('/safety/copyright-notices', data: body);
  final data = res.data;
  return data is Map ? data['referenceId']?.toString() : null;
}

enum _SendState { idle, sending, error, sent }

/// Copyright takedown policy + notice / counter-notice form for user uploads
/// (17 USC 512(c)(3) / 512(g)(3); repeat-infringer policy).
class CopyrightPolicyScreen extends StatefulWidget {
  const CopyrightPolicyScreen({
    super.key,
    this.targetType = 'media',
    this.targetId = '',
    this.submit = _defaultSubmit,
    this.agent = CopyrightAgent.fromEnvironment,
  });

  final String targetType;
  final String targetId;
  final CopyrightSubmit submit;
  final CopyrightAgent agent;

  @override
  State<CopyrightPolicyScreen> createState() => _CopyrightPolicyScreenState();
}

class _CopyrightPolicyScreenState extends State<CopyrightPolicyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _kind = 'notice';
  late final _targetId = TextEditingController(text: widget.targetId);
  final _work = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _sig = TextEditingController();
  final Set<String> _statements = {};
  bool _statementsError = false;
  _SendState _state = _SendState.idle;
  String? _reference;

  static const _stmtKeys = {
    'notice': ['good_faith', 'accurate_and_authorised'],
    'counter': ['mistake_or_misidentification', 'consent_to_jurisdiction'],
  };

  String _stmtText(AppLocalizations l, String k) => switch (k) {
    'good_faith' => l.cpStmtGoodFaith,
    'accurate_and_authorised' => l.cpStmtAccurate,
    'mistake_or_misidentification' => l.cpStmtMistake,
    _ => l.cpStmtJurisdiction,
  };

  @override
  void dispose() {
    for (final c in [_targetId, _work, _name, _email, _sig]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final need = _stmtKeys[_kind]!;
    final formOk = _formKey.currentState!.validate();
    final stmtsOk = need.every(_statements.contains);
    setState(() => _statementsError = !stmtsOk);
    if (!formOk || !stmtsOk) return;
    setState(() => _state = _SendState.sending);
    try {
      final ref = await widget.submit({
        'kind': _kind,
        'targetType': widget.targetType,
        'targetId': _targetId.text.trim(),
        'workDescription': _work.text.trim(),
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'signature': _sig.text.trim(),
        'statements': need,
      });
      if (mounted) {
        setState(() {
          _reference = ref ?? '—';
          _state = _SendState.sent;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = _SendState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.cpTitle)),
      body: SafeArea(
        top: false,
        child: _state == _SendState.sent
            ? _SuccessPanel(reference: _reference!)
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _Callout(
                      icon: Icons.copyright_rounded,
                      color: PanAfricanColors.primaryContainer,
                      onColor: PanAfricanColors.onPrimaryContainer,
                      body: l.cpIntro,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(l.cpHowTitle),
                    for (final (i, step) in [
                      l.cpStep1,
                      l.cpStep2,
                      l.cpStep3,
                    ].indexed)
                      _Step(number: i + 1, text: step),
                    const SizedBox(height: 16),
                    _Callout(
                      icon: Icons.gavel_rounded,
                      color: PanAfricanColors.tertiaryContainer,
                      onColor: PanAfricanColors.onTertiaryContainer,
                      title: l.cpRepeatTitle,
                      body: l.cpRepeatBody,
                    ),
                    const SizedBox(height: 16),
                    _AgentCard(agent: widget.agent),
                    const SizedBox(height: 24),
                    _SectionTitle(l.cpFormTitle),
                    _kindPicker(l),
                    const SizedBox(height: 16),
                    ..._fields(l),
                    _statementsBlock(l),
                    const SizedBox(height: 16),
                    _LabelledField(
                      fieldKey: const ValueKey('cp-signature'),
                      label: l.cpFieldSignature,
                      controller: _sig,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.cpRequired : null,
                    ),
                    if (_state == _SendState.error) ...[
                      const SizedBox(height: 8),
                      _ErrorBanner(onRetry: _send),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('copyright-send'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: PanAfricanColors.primary,
                      ),
                      onPressed: _state == _SendState.sending ? null : _send,
                      child: _state == _SendState.sending
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(child: Text(l.cpSending)),
                              ],
                            )
                          : Text(l.cpSend, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _kindPicker(AppLocalizations l) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (k, label) in [
        ('notice', l.cpKindNotice),
        ('counter', l.cpKindCounter),
      ])
        ChoiceChip(
          key: ValueKey('cp-kind-$k'),
          label: Text(label),
          selected: _kind == k,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => setState(() {
            _kind = k;
            _statements.clear();
            _statementsError = false;
          }),
        ),
    ],
  );

  List<Widget> _fields(AppLocalizations l) {
    String? req(String? v) => (v ?? '').trim().isEmpty ? l.cpRequired : null;
    return [
      _LabelledField(
        fieldKey: const ValueKey('cp-target'),
        label: l.cpFieldTarget,
        controller: _targetId,
        validator: req,
      ),
      _LabelledField(
        fieldKey: const ValueKey('cp-work'),
        label: _kind == 'notice' ? l.cpFieldWork : l.cpFieldWorkCounter,
        helper: l.cpFieldWorkHelp,
        controller: _work,
        maxLines: 4,
        validator: (v) => (v ?? '').trim().isEmpty
            ? l.cpRequired
            : (v!.trim().length < 10 ? l.cpWorkTooShort : null),
      ),
      _LabelledField(
        fieldKey: const ValueKey('cp-name'),
        label: l.cpFieldName,
        controller: _name,
        validator: req,
        autofill: AutofillHints.name,
      ),
      _LabelledField(
        fieldKey: const ValueKey('cp-email'),
        label: l.cpFieldEmail,
        controller: _email,
        keyboard: TextInputType.emailAddress,
        autofill: AutofillHints.email,
        validator: (v) =>
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null
            : l.cpEmailInvalid,
      ),
    ];
  }

  Widget _statementsBlock(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.cpStatementsTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: _statementsError ? scheme.error : scheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (final k in _stmtKeys[_kind]!)
                CheckboxListTile(
                  key: ValueKey('stmt-$k'),
                  value: _statements.contains(k),
                  onChanged: (v) => setState(() {
                    v == true ? _statements.add(k) : _statements.remove(k);
                    if (_stmtKeys[_kind]!.every(_statements.contains)) {
                      _statementsError = false;
                    }
                  }),
                  title: Text(
                    _stmtText(l, k),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
        if (_statementsError)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
            child: Text(
              l.cpStatementsMissing,
              key: const ValueKey('cp-statements-error'),
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.color,
    required this.onColor,
    required this.body,
    this.title,
  });
  final IconData icon;
  final Color color;
  final Color onColor;
  final String body;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: t.titleSmall?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(body, style: t.bodyMedium?.copyWith(color: onColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 14,
              backgroundColor: PanAfricanColors.primary,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: t.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent});
  final CopyrightAgent agent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('cp-agent'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cpAgentTitle,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (agent.isRegistered) ...[
            SelectableText(agent.name, style: t.bodyMedium),
            SelectableText(agent.email, style: t.bodyMedium),
            if (agent.address.isNotEmpty)
              SelectableText(agent.address, style: t.bodyMedium),
          ] else
            Text(
              l.cpAgentPending,
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.validator,
    this.helper,
    this.maxLines = 1,
    this.keyboard,
    this.autofill,
  });
  final Key fieldKey;
  final String label;
  final String? helper;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final int maxLines;
  final TextInputType? keyboard;
  final String? autofill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: label,
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              maxLines: maxLines,
              minLines: 1,
              keyboardType: keyboard,
              autofillHints: autofill == null ? null : [autofill!],
              validator: validator,
              decoration: InputDecoration(
                helperText: helper,
                helperMaxLines: 3,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('copyright-error'),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.cpErrorTitle,
                    style: t.titleSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32, top: 4),
              child: Text(
                l.cpErrorBody,
                style: t.bodyMedium?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(l.cpRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.reference});
  final String reference;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: ListView(
        key: const ValueKey('copyright-success'),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: PanAfricanColors.primaryContainer,
              child: Icon(
                Icons.check_rounded,
                size: 40,
                color: PanAfricanColors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.cpSuccessTitle,
            textAlign: TextAlign.center,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l.cpSuccessBody(reference),
            textAlign: TextAlign.center,
            style: t.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: PanAfricanColors.primary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l.cpDone),
          ),
        ],
      ),
    );
  }
}
