import 'package:flutter/material.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Design tokens: color.label.beta | expert | native (P5-010).
abstract final class ContentLabelColors {
  static const beta = Color(0xFFB45309);
  static const betaOn = Color(0xFFFFFFFF);
  static const expert = Color(0xFF1565C0);
  static const expertOn = Color(0xFFFFFFFF);
  static const native = Color(0xFF1B7340);
  static const nativeOn = Color(0xFFFFFFFF);
  static const synthetic = Color(0xFF5C5C5C);
  static const syntheticOn = Color(0xFFFFFFFF);
}

/// Whether curriculum audio should show the synthetic-voice tag (AC3).
bool audioKindShowsSyntheticTag(String? kind) {
  if (kind == null) {
    return false;
  }
  final normalized = kind.trim().toLowerCase();
  return normalized == 'tts' || normalized == 'tts_synthetic';
}

class ContentLabelBadgeSpec {
  const ContentLabelBadgeSpec({
    required this.background,
    required this.foreground,
    required this.visibleText,
    required this.semanticsLabel,
  });

  final Color background;
  final Color foreground;
  final String visibleText;
  final String semanticsLabel;
}

ContentLabelBadgeSpec? contentLabelBadgeSpec({
  required ContentQualityLabel label,
  required String betaCopy,
  required String nativeLabel,
  required String expertLabel,
}) {
  switch (label) {
    case ContentQualityLabel.beta:
      return ContentLabelBadgeSpec(
        background: ContentLabelColors.beta,
        foreground: ContentLabelColors.betaOn,
        visibleText: betaCopy,
        semanticsLabel: 'Beta content quality. $betaCopy',
      );
    case ContentQualityLabel.nativeVerified:
      return ContentLabelBadgeSpec(
        background: ContentLabelColors.native,
        foreground: ContentLabelColors.nativeOn,
        visibleText: nativeLabel,
        semanticsLabel: 'Native-verified content. $nativeLabel',
      );
    case ContentQualityLabel.expertReviewed:
      return ContentLabelBadgeSpec(
        background: ContentLabelColors.expert,
        foreground: ContentLabelColors.expertOn,
        visibleText: expertLabel,
        semanticsLabel: 'Expert-reviewed content. $expertLabel',
      );
  }
}

/// Quality label chip; tap opens [onReportMistake] (AC4).
class ContentLabelBadge extends StatelessWidget {
  const ContentLabelBadge({
    super.key,
    required this.label,
    required this.onReportMistake,
  });

  final ContentQualityLabel label;
  final VoidCallback onReportMistake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = contentLabelBadgeSpec(
      label: label,
      betaCopy: l10n.labelBetaCopy,
      nativeLabel: l10n.labelNative,
      expertLabel: l10n.labelExpert,
    );
    if (spec == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      button: true,
      label: '${spec.semanticsLabel}. Double tap to report a mistake.',
      child: Material(
        color: spec.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onReportMistake,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  spec.visibleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: spec.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visible when item audio is synthetic TTS (AC3).
class SyntheticVoiceTag extends StatelessWidget {
  const SyntheticVoiceTag({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!.audioSynthetic;
    return Semantics(
      label: 'Synthetic voice. $text',
      child: Material(
        color: ContentLabelColors.synthetic,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ContentLabelColors.syntheticOn,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

/// Label chip plus optional synthetic-voice tag for an item surface.
class ContentHonestyLabels extends StatelessWidget {
  const ContentHonestyLabels({
    super.key,
    required this.label,
    required this.audioKind,
    required this.onReportMistake,
  });

  final ContentQualityLabel label;
  final String? audioKind;
  final VoidCallback onReportMistake;

  @override
  Widget build(BuildContext context) {
    final showSynthetic = audioKindShowsSyntheticTag(audioKind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ContentLabelBadge(label: label, onReportMistake: onReportMistake),
        if (showSynthetic) ...[
          const SizedBox(height: 8),
          const SyntheticVoiceTag(),
        ],
      ],
    );
  }
}
