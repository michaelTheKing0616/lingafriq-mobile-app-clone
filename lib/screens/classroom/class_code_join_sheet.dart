import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';

/// Bottom sheet: enter a class code -> POST /api/tribes/classrooms/join.
/// 202 shows "waiting for guardian"; guardian_link_required / age_verification_required get clear copy.
class ClassCodeJoinSheet extends StatefulWidget {
  const ClassCodeJoinSheet({super.key, this.service, this.onJoined});

  final GuardedMessagingService? service;
  final VoidCallback? onJoined;

  static Future<void> show(
    BuildContext context, {
    GuardedMessagingService? service,
    VoidCallback? onJoined,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClassCodeJoinSheet(service: service, onJoined: onJoined),
    );
  }

  @override
  State<ClassCodeJoinSheet> createState() => _ClassCodeJoinSheetState();
}

class _ClassCodeJoinSheetState extends State<ClassCodeJoinSheet> {
  late final GuardedMessagingService _service =
      widget.service ?? GuardedMessagingService();
  final _controller = TextEditingController();
  bool _busy = false;
  ClassJoinOutcome? _outcome;
  bool _empty = false;

  /// Class codes are 4–16 letters, numbers or dashes (no spaces or symbols).
  static final _codePattern = RegExp(r'^[A-Za-z0-9-]{4,16}$');
  bool get _valid => _codePattern.hasMatch(_controller.text.trim());

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty || !_valid) {
      setState(() => _empty = code.isEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _empty = false;
      _outcome = null;
    });
    final r = await _service.joinClassByCode(code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = r;
    });
    if (r == ClassJoinOutcome.joined) widget.onJoined?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final done =
        _outcome == ClassJoinOutcome.joined ||
        _outcome == ClassJoinOutcome.waitingForGuardian;
    // Guardian / age guidance is a next step, not a mistake: shown as a calm
    // info panel. Only real problems with the code use the field error style.
    final guidance = switch (_outcome) {
      ClassJoinOutcome.needsGuardianLink => l.gccNeedLink,
      ClassJoinOutcome.needsAgeCheck => l.gccNeedAge,
      _ => null,
    };
    String? error;
    if (_empty) error = l.gccEmpty;
    error ??= switch (_outcome) {
      ClassJoinOutcome.notFound => l.gccNotFound,
      ClassJoinOutcome.alreadyMember => l.gccAlready,
      ClassJoinOutcome.error => l.gccError,
      _ => null,
    };
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              key: const ValueKey('gcc-handle'),
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.gccTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('gcc-close'),
                tooltip: l.gccClose,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_outcome == ClassJoinOutcome.waitingForGuardian)
            _Status(
              key: const ValueKey('gcc-waiting'),
              icon: Icons.hourglass_top_outlined,
              title: l.gccWaitingTitle,
              body: l.gccWaitingBody,
            )
          else if (_outcome == ClassJoinOutcome.joined)
            _Status(
              key: const ValueKey('gcc-joined'),
              icon: Icons.check_circle_outline,
              title: l.gccJoined,
            )
          else ...[
            Text(l.gccHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('gcc-field'),
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              maxLength: 40,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l.gccLabel,
                helperText: l.gccFormatHint,
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
                errorText: error,
                errorMaxLines: 4,
                counterText: '',
              ),
            ),
            if (guidance != null) ...[
              const SizedBox(height: 12),
              _Status(
                key: const ValueKey('gcc-guidance'),
                icon: Icons.info_outline,
                title: guidance,
                tone: _Tone.info,
              ),
            ],
          ],
          if (_outcome == ClassJoinOutcome.needsGuardianLink) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                key: const ValueKey('gcc-family-hub'),
                onPressed: () => Navigator.of(context).pushNamed('/family-hub'),
                icon: const Icon(Icons.family_restroom_outlined),
                label: Text(l.gccOpenFamilyHub),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: done
                ? FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l.gccDone),
                  )
                : FilledButton(
                    key: const ValueKey('gcc-submit'),
                    onPressed: _busy || !_valid ? null : _submit,
                    child: _busy
                        ? Row(
                            key: const ValueKey('gcc-checking'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(child: Text(l.gccChecking)),
                            ],
                          )
                        : Text(l.gccSubmit),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { success, info }

class _Status extends StatelessWidget {
  const _Status({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = _Tone.success,
  });
  final IconData icon;
  final String title;
  final String? body;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = tone == _Tone.info
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final fg = tone == _Tone.info
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      body!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
