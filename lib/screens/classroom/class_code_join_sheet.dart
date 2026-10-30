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
      showDragHandle: true,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _empty = true);
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
    String? error;
    if (_empty) error = l.gccEmpty;
    error ??= switch (_outcome) {
      ClassJoinOutcome.needsGuardianLink => l.gccNeedLink,
      ClassJoinOutcome.needsAgeCheck => l.gccNeedAge,
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
          Text(
            l.gccTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
                border: const OutlineInputBorder(),
                errorText: error,
                errorMaxLines: 4,
                counterText: '',
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
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.gccSubmit),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    super.key,
    required this.icon,
    required this.title,
    this.body,
  });
  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
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
