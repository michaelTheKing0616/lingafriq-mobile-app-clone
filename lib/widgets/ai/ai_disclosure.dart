import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// English fallback when no [AppLocalizations] is in scope.
const String kAiDisclosureFallback =
    'AI-generated: replies and voice come from an AI tutor and can be wrong.';

/// Persistent, non-dismissible AI transparency label (EU AI Act Art. 50).
///
/// The full required sentence always wraps; it is never ellipsized and the
/// bar grows with text scale. Tapping opens a sheet with the longer
/// explanation, so the whole bar is a ≥48dp target.
class AiDisclosureBar extends StatelessWidget {
  const AiDisclosureBar({super.key, this.label});

  /// Optional override (e.g. persona-specific copy); defaults to l10n text.
  final String? label;

  static Future<void> showDetails(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l?.aiDisclosureSheetTitle ?? 'About AI in LingAfriq',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l?.aiDisclosureSheetBody ?? kAiDisclosureFallback,
                style: Theme.of(ctx).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l?.aiDisclosureGotIt ?? 'Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = label ?? l?.aiDisclosureLabel ?? kAiDisclosureFallback;
    const fg = PanAfricanColors.onSecondaryContainer;
    // Icons grow with text (capped) so they stay legible beside large type.
    final iconSize = MediaQuery.textScalerOf(
      context,
    ).scale(18).clamp(18.0, 30.0);
    return Semantics(
      key: const ValueKey('ai-disclosure'),
      container: true,
      button: true,
      label: text,
      hint: l?.aiDisclosureMoreHint,
      excludeSemantics: true,
      child: Material(
        color: PanAfricanColors.secondaryContainer,
        child: InkWell(
          onTap: () => showDetails(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: iconSize, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: iconSize, color: fg),
                ],
              ),
            ),
          ),
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
        Material(
          color: PanAfricanColors.secondaryContainer,
          child: SafeArea(bottom: false, child: AiDisclosureBar(label: label)),
        ),
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
