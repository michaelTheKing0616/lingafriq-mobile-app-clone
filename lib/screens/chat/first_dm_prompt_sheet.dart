import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Copy for first-DM friction (P9-929); keys mirror `firstdm.*` in plan.
abstract final class FirstDmCopy {
  static const requestTitle = 'Message request';
  static const requestBody =
      'They want to start a chat. You can accept, report, or block in one tap.';
  static const introHint =
      'Introduce yourself in one short note. They need to accept before you can chat freely.';
  static const limitedTitle = 'Give it a moment';
  static const acceptLabel = 'Accept';
  static const declineLabel = 'Not now';
  static const reportLabel = 'Report';
  static const blockLabel = 'Block';
  static const sendIntroLabel = 'Send request';
}

enum FirstDmSheetMode { outboundIntro, inboundRequest, limited }

class FirstDmPromptSheet extends StatefulWidget {
  const FirstDmPromptSheet({
    super.key,
    required this.mode,
    required this.peerDisplayName,
    this.inboundIntro,
    this.limitedResetLabel,
    this.onSendIntro,
    this.onAccept,
    this.onDecline,
    this.onReport,
    this.onBlock,
  });

  final FirstDmSheetMode mode;
  final String peerDisplayName;
  final String? inboundIntro;
  final String? limitedResetLabel;
  final Future<void> Function(String message)? onSendIntro;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onDecline;
  final Future<void> Function()? onReport;
  final Future<void> Function()? onBlock;

  @override
  State<FirstDmPromptSheet> createState() => _FirstDmPromptSheetState();
}

class _FirstDmPromptSheetState extends State<FirstDmPromptSheet> {
  final TextEditingController _introController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function()? action) async {
    if (action == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Try again.';
        _busy = false;
      });
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
    String? semanticsHint,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: semanticsHint,
      child: SizedBox(
        width: double.infinity,
        height: AdaptiveLayout.minTouchTarget,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
          ),
          onPressed: _busy ? null : onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = PanAfricanSpacing.md;

    if (widget.mode == FirstDmSheetMode.limited) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                FirstDmCopy.limitedTitle,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: spacing),
              Text(
                widget.limitedResetLabel ??
                    'Your account is still new. You can try again when the limit resets.',
                style: theme.textTheme.bodyLarge,
              ),
              if (_error != null) ...[
                SizedBox(height: spacing),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      );
    }

    if (widget.mode == FirstDmSheetMode.inboundRequest) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(FirstDmCopy.requestTitle, style: theme.textTheme.titleLarge),
              SizedBox(height: spacing),
              Text(
                '${widget.peerDisplayName} · ${FirstDmCopy.requestBody}',
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.inboundIntro != null && widget.inboundIntro!.trim().isNotEmpty) ...[
                SizedBox(height: spacing),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(PanAfricanSpacing.sm),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Text(
                      widget.inboundIntro!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.lg),
              _actionButton(
                label: FirstDmCopy.acceptLabel,
                background: theme.colorScheme.primary,
                foreground: theme.colorScheme.onPrimary,
                onPressed: () => _run(widget.onAccept),
              ),
              SizedBox(height: spacing),
              _actionButton(
                label: FirstDmCopy.reportLabel,
                background: theme.colorScheme.secondaryContainer,
                foreground: theme.colorScheme.onSecondaryContainer,
                onPressed: () => _run(widget.onReport),
              ),
              SizedBox(height: spacing),
              _actionButton(
                label: FirstDmCopy.blockLabel,
                background: theme.colorScheme.errorContainer,
                foreground: theme.colorScheme.onErrorContainer,
                onPressed: () => _run(widget.onBlock),
              ),
              SizedBox(height: spacing),
              TextButton(
                onPressed: _busy ? null : () => _run(widget.onDecline),
                child: Text(FirstDmCopy.declineLabel),
              ),
              if (_error != null) ...[
                SizedBox(height: spacing),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Say hello to ${widget.peerDisplayName}',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: spacing),
            Text(FirstDmCopy.introHint, style: theme.textTheme.bodyMedium),
            SizedBox(height: spacing),
            TextField(
              controller: _introController,
              maxLines: 3,
              maxLength: 240,
              decoration: InputDecoration(
                hintText: 'Hi, I am…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanSpacing.sm),
                ),
              ),
            ),
            SizedBox(height: spacing),
            _actionButton(
              label: FirstDmCopy.sendIntroLabel,
              background: theme.colorScheme.primary,
              foreground: theme.colorScheme.onPrimary,
              onPressed: () {
                final text = _introController.text.trim();
                if (text.isEmpty) {
                  setState(() => _error = 'Write a short note first.');
                  return;
                }
                _run(() => widget.onSendIntro!(text));
              },
            ),
            if (_error != null) ...[
              SizedBox(height: spacing),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

Future<T?> showFirstDmPromptSheet<T>({
  required BuildContext context,
  required FirstDmPromptSheet sheet,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => sheet,
  );
}
