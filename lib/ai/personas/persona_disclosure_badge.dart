import 'package:flutter/material.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// copy_keys: persona.badge.ai_recreation | badge.surface | badge.text (P11-007).
abstract final class PersonaDisclosureBadgeColors {
  static const surface = PanAfricanColors.secondaryContainer;
  static const text = PanAfricanColors.onSecondaryContainer;
  static const synthSurface = PanAfricanColors.neutralLight;
  static const synthText = PanAfricanColors.textSecondaryLight;
}

enum PersonaDisclosureBadgeLayout { chat, bust, shareCard }

/// Facts for the session-opening “how built” line (AC2).
@immutable
class PersonaHowBuiltFacts {
  const PersonaHowBuiltFacts({
    required this.personaName,
    required this.sourceSummary,
    this.deliveryMode,
  });

  final String personaName;
  final String sourceSummary;
  final PersonaDeliveryMode? deliveryMode;

  factory PersonaHowBuiltFacts.fromPersona(HistoricalPersona persona) {
    final sources = persona.primarySources
        .take(3)
        .map((s) => s.title.trim())
        .where((t) => t.isNotEmpty)
        .join('; ');
    final summary = sources.isEmpty
        ? 'licensed dossier records'
        : sources;
    return PersonaHowBuiltFacts(
      personaName: persona.displayName,
      sourceSummary: summary,
      deliveryMode: DossierBackedPersonaRoster.deliveryModeFor(persona.id),
    );
  }
}

String personaHowBuiltMessage(AppLocalizations l10n, PersonaHowBuiltFacts facts) {
  return l10n.personaOpeningHowBuilt(
    facts.personaName,
    facts.sourceSummary,
  );
}

/// Phrases that must never appear in persona system prompts (AC4).
const personaPromptDenyAiForbiddenSubstrings = [
  'do not reference being an ai',
  'deny being an ai',
  'deny you are an ai',
  'pretend you are human',
  'hide that you are an ai',
  'hide being an ai',
  'never admit you are an ai',
  'must not mention being an ai',
];

/// Returns the first forbidden substring found, or null when clean.
String? scanPersonaPromptTextForDenyAi(String promptText) {
  final lower = promptText.toLowerCase();
  for (final phrase in personaPromptDenyAiForbiddenSubstrings) {
    if (lower.contains(phrase)) {
      return phrase;
    }
  }
  return null;
}

/// Persistent, non-dismissible AI recreation badge (AC1).
class PersonaDisclosureBadge extends StatelessWidget {
  const PersonaDisclosureBadge({
    super.key,
    this.layout = PersonaDisclosureBadgeLayout.chat,
  });

  final PersonaDisclosureBadgeLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.personaBadgeAiRecreation;
    final padding = switch (layout) {
      PersonaDisclosureBadgeLayout.chat => EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.xs),
      PersonaDisclosureBadgeLayout.bust => EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm, vertical: PanAfricanSpacing.xs),
      PersonaDisclosureBadgeLayout.shareCard =>
        EdgeInsets.all(PanAfricanSpacing.xs),
    };

    return Semantics(
      label: label,
      container: true,
      child: Material(
        color: PersonaDisclosureBadgeColors.surface,
        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
        child: Padding(
          padding: padding,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: PersonaDisclosureBadgeColors.text,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Shown while synthesised persona audio plays (AC3).
class PersonaSynthVoiceLabel extends StatelessWidget {
  const PersonaSynthVoiceLabel({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.personaVoiceSynthesised;
    return Semantics(
      label: label,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: PersonaDisclosureBadgeColors.synthSurface,
          borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: PersonaDisclosureBadgeColors.synthText,
              ),
        ),
      ),
    );
  }
}

/// Session-opening disclosure block: how-built preamble before in-character speech (AC2).
class PersonaSessionOpeningDisclosure extends StatelessWidget {
  const PersonaSessionOpeningDisclosure({
    super.key,
    required this.facts,
    this.showSynthLabel = false,
    this.layout = PersonaDisclosureBadgeLayout.chat,
  });

  final PersonaHowBuiltFacts facts;
  final bool showSynthLabel;
  final PersonaDisclosureBadgeLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preamble = personaHowBuiltMessage(l10n, facts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonaDisclosureBadge(layout: layout),
        SizedBox(height: PanAfricanSpacing.xs),
        Semantics(
          label: preamble,
          child: Text(
            preamble,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        if (showSynthLabel) ...[
          SizedBox(height: PanAfricanSpacing.xs),
          const PersonaSynthVoiceLabel(),
        ],
      ],
    );
  }
}
