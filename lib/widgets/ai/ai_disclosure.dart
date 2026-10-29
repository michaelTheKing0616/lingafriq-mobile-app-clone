import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Fallback copy when no [AppLocalizations] is in scope (tests, early boot).
const String kAiDisclosureFallback =
    'AI-generated: replies and voice come from an AI tutor and can be wrong.';

/// Persistent, non-dismissible transparency label (EU AI Act Art. 50 style)
/// shown wherever learners interact with AI-generated text, voice or personas.
class AiDisclosureBar extends StatelessWidget implements PreferredSizeWidget {
  const AiDisclosureBar({super.key, this.label});

  /// Optional override (e.g. persona-specific copy); defaults to l10n text.
  final String? label;

  static const double height = 28;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final text =
        label ??
        AppLocalizations.of(context)?.aiDisclosureLabel ??
        kAiDisclosureFallback;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: const ValueKey('ai-disclosure'),
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        height: height,
        width: double.infinity,
        color: scheme.secondaryContainer,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a Scaffold body that has no AppBar with a top [AiDisclosureBar].
class AiDisclosed extends StatelessWidget {
  const AiDisclosed({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(bottom: false, child: AiDisclosureBar(label: label)),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
