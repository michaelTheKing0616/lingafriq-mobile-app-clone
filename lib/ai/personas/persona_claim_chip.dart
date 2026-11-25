import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// P11-003 claim support levels (parity with server `ClaimSupport`).
enum PersonaClaimSupport {
  documented,
  inferred,
  legend,
}

PersonaClaimSupport? personaClaimSupportFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'documented':
      return PersonaClaimSupport.documented;
    case 'inferred':
      return PersonaClaimSupport.inferred;
    case 'legend':
      return PersonaClaimSupport.legend;
    default:
      return null;
  }
}

/// Design tokens: chip.surface | chip.text (P11-005).
abstract final class PersonaClaimChipColors {
  static const documentedSurface = PanAfricanColors.primaryContainer;
  static const documentedText = PanAfricanColors.onPrimaryContainer;
  static const inferredSurface = Color(0xFFE3F2FD);
  static const inferredText = Color(0xFF1565C0);
  static const legendSurface = PanAfricanColors.tertiaryContainer;
  static const legendText = PanAfricanColors.onTertiaryContainer;
  static const mutedSurface = PanAfricanColors.neutralLight;
  static const mutedText = PanAfricanColors.textSecondaryLight;
}

enum PersonaClaimChipVariant {
  source,
  inferred,
  legend,
  loading,
  noSource,
}

/// Maps support to chip variant for tests and layout.
PersonaClaimChipVariant personaClaimChipVariant({
  required PersonaClaimSupport? support,
  required bool loading,
  required List<String> sourceIds,
}) {
  if (loading) {
    return PersonaClaimChipVariant.loading;
  }
  switch (support) {
    case PersonaClaimSupport.documented:
      if (sourceIds.isEmpty) {
        return PersonaClaimChipVariant.noSource;
      }
      return PersonaClaimChipVariant.source;
    case PersonaClaimSupport.inferred:
      return PersonaClaimChipVariant.inferred;
    case PersonaClaimSupport.legend:
      return PersonaClaimChipVariant.legend;
    case null:
      return PersonaClaimChipVariant.noSource;
  }
}

@immutable
class PersonaClaimChipSpec {
  const PersonaClaimChipSpec({
    required this.variant,
    required this.visibleText,
    required this.semanticsLabel,
    required this.surface,
    required this.textColor,
    required this.isButton,
  });

  final PersonaClaimChipVariant variant;
  final String visibleText;
  final String semanticsLabel;
  final Color surface;
  final Color textColor;
  final bool isButton;
}

PersonaClaimChipSpec personaClaimChipSpec({
  required AppLocalizations l10n,
  required PersonaClaimChipVariant variant,
}) {
  switch (variant) {
    case PersonaClaimChipVariant.source:
      return PersonaClaimChipSpec(
        variant: variant,
        visibleText: l10n.personaChipSource,
        semanticsLabel: l10n.personaChipSourceSemantics,
        surface: PersonaClaimChipColors.documentedSurface,
        textColor: PersonaClaimChipColors.documentedText,
        isButton: true,
      );
    case PersonaClaimChipVariant.inferred:
      return PersonaClaimChipSpec(
        variant: variant,
        visibleText: l10n.personaChipInferred,
        semanticsLabel: l10n.personaChipInferredSemantics,
        surface: PersonaClaimChipColors.inferredSurface,
        textColor: PersonaClaimChipColors.inferredText,
        isButton: false,
      );
    case PersonaClaimChipVariant.legend:
      return PersonaClaimChipSpec(
        variant: variant,
        visibleText: l10n.personaChipLegend,
        semanticsLabel: l10n.personaChipLegendSemantics,
        surface: PersonaClaimChipColors.legendSurface,
        textColor: PersonaClaimChipColors.legendText,
        isButton: false,
      );
    case PersonaClaimChipVariant.loading:
      return PersonaClaimChipSpec(
        variant: variant,
        visibleText: l10n.personaChipLoading,
        semanticsLabel: l10n.personaChipLoading,
        surface: PersonaClaimChipColors.mutedSurface,
        textColor: PersonaClaimChipColors.mutedText,
        isButton: false,
      );
    case PersonaClaimChipVariant.noSource:
      return PersonaClaimChipSpec(
        variant: variant,
        visibleText: l10n.personaChipNoSource,
        semanticsLabel: l10n.personaChipNoSourceSemantics,
        surface: PersonaClaimChipColors.mutedSurface,
        textColor: PersonaClaimChipColors.mutedText,
        isButton: false,
      );
  }
}

/// Small support chip (Source opens cited card; Inferred/Legend are labels).
class PersonaClaimChip extends StatelessWidget {
  const PersonaClaimChip({
    super.key,
    required this.variant,
    this.onPressed,
  });

  final PersonaClaimChipVariant variant;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = personaClaimChipSpec(l10n: l10n, variant: variant);

    if (variant == PersonaClaimChipVariant.loading) {
      return Semantics(
        label: spec.semanticsLabel,
        child: _ChipBody(
          spec: spec,
          child: SizedBox(
            width: 56,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: spec.textColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
    }

    final chip = _ChipBody(
      spec: spec,
      child: Text(
        spec.visibleText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: spec.textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );

    if (spec.isButton && onPressed != null) {
      return Semantics(
        button: true,
        label: spec.semanticsLabel,
        child: Material(
          color: spec.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: chip,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: spec.semanticsLabel,
      child: chip,
    );
  }
}

class _ChipBody extends StatelessWidget {
  const _ChipBody({required this.spec, required this.child});

  final PersonaClaimChipSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: spec.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

/// Claim text with support chip (documented / inferred / legend).
class PersonaClaimRow extends StatelessWidget {
  const PersonaClaimRow({
    super.key,
    required this.claimText,
    this.support,
    this.sourceIds = const [],
    this.loading = false,
    this.onOpenSource,
  });

  final String claimText;
  final PersonaClaimSupport? support;
  final List<String> sourceIds;
  final bool loading;
  final void Function(String sourceId)? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final variant = personaClaimChipVariant(
      support: support,
      loading: loading,
      sourceIds: sourceIds,
    );
    final chipSpec = personaClaimChipSpec(l10n: l10n, variant: variant);
    final rowSemantics = '${claimText.trim()}. ${chipSpec.semanticsLabel}';

    VoidCallback? openFirst;
    if (variant == PersonaClaimChipVariant.source &&
        sourceIds.isNotEmpty &&
        onOpenSource != null) {
      openFirst = () => onOpenSource!(sourceIds.first);
    }

    return Semantics(
      container: true,
      label: rowSemantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claimText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          PersonaClaimChip(
            variant: variant,
            onPressed: openFirst,
          ),
        ],
      ),
    );
  }
}
