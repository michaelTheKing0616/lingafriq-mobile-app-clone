import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';
import 'package:lingafriq/theme/guarded_theme.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';

/// Bottom sheet: enter a class code -> preview the class
/// (POST /api/tribes/classrooms/preview) -> POST /api/tribes/classrooms/join.
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
  String? _className;
  bool _empty = false;
  ClassPreviewResult? _preview;
  String? _previewCode;

  /// New class codes are 6–8 letters/numbers. Older codes (e.g. CLS-1A2B3C,
  /// up to 16 with dashes) are still accepted so existing classes keep working.
  static final _codePattern = RegExp(r'^[A-Za-z0-9-]{4,16}$');
  bool get _valid => _codePattern.hasMatch(_controller.text.trim());

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () => setState(() {
        // Editing the code drops a stale class preview.
        if (_controller.text.trim() != _previewCode) _preview = null;
      }),
    );
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
    // Show which class the code opens before joining. If the preview is
    // unavailable (offline / older server) we join directly, as before.
    final p = await _service.previewClass(code);
    if (!mounted) return;
    if (p != null) {
      setState(() {
        _busy = false;
        if (!p.found) {
          _outcome = ClassJoinOutcome.notFound;
        } else if (p.isMember) {
          _outcome = ClassJoinOutcome.alreadyMember;
        } else {
          _preview = p;
          _previewCode = code;
        }
      });
      return;
    }
    await _join(code);
  }

  Future<void> _join(String code) async {
    setState(() => _busy = true);
    final r = await _service.joinClass(code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = r.outcome;
      _className = r.className;
    });
    if (r.outcome == ClassJoinOutcome.joined) widget.onJoined?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = guardedTheme(Theme.of(context));
    final preview = _preview;
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
    return Theme(
      data: theme,
      child: SingleChildScrollView(
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
                title: _className == null
                    ? l.gccJoined
                    : l.gccJoinedNamed(_className!),
                body: l.gccJoinedNext,
              )
            else if (preview != null) ...[
              _PreviewCard(
                key: const ValueKey('gcc-preview'),
                preview: preview,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const ValueKey('gcc-change'),
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _preview = null;
                          _previewCode = null;
                          _controller.clear();
                        }),
                  child: Text(l.gccPreviewChange),
                ),
              ),
            ] else ...[
              Text(l.gccHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              // Label sits above the field (no floating label), so it never
              // collides with the code at 320dp / 200% / RTL.
              Text(
                l.gccLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Codes are Latin letters/digits: always LTR, big and spaced so a
              // child can check each character (Kahoot / Classroom style).
              // Big code text is capped at 130% so the hint and an 8-character
              // code still fit at 320dp / 200% / RTL.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const ValueKey('gcc-field'),
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 16,
                    enabled: !_busy,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9-]'),
                      ),
                      _UpperCase(),
                    ],
                    style: LingAfriqFonts.displayStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ABC123',
                      hintStyle: LingAfriqFonts.displayStyle(
                        fontSize: 28,
                        letterSpacing: 4,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Row(
                    key: const ValueKey('gcc-error'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  l.gccFormatHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/family-hub'),
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
                      key: ValueKey(
                        preview != null ? 'gcc-join' : 'gcc-submit',
                      ),
                      onPressed: _busy || !_valid
                          ? null
                          : preview != null
                          ? () => _join(_previewCode!)
                          : _submit,
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
                          : Text(
                              preview != null ? l.gccSubmit : l.gccCheck,
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

/// "Is this your class?" card: name, teacher (if shareable), size, language.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({super.key, required this.preview});
  final ClassPreviewResult preview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = <(IconData, String)>[
      if (preview.teacherName != null)
        (Icons.person_outline, l.gccPreviewTeacher(preview.teacherName!)),
      (Icons.groups_outlined, l.gccPreviewMembers(preview.memberCount)),
    ];
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.gccPreviewTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    preview.className,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            for (final (icon, text) in lines) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _Tone { success, info }

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

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
