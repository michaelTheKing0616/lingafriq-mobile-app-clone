/// Grammar "aha" cards from Pattern Library entries (P5-025, ELEVATION §6.2).
library;

import 'package:flutter/material.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/widgets/content_label_badge.dart';

/// copy_keys: aha.title, aha.practice
abstract final class GrammarAhaCopyKeys {
  static const title = 'aha.title';
  static const practice = 'aha.practice';

  static const defaultTitle = 'Grammar insight';
  static const defaultPractice = 'Now try it in a short sentence.';
}

abstract final class GrammarAhaCodes {
  static const patternContrastMissing = 'PatternContrastMissing';
  static const genericGrammarForbidden = 'GENERIC_GRAMMAR_FORBIDDEN';
}

/// Gap log for patterns that cannot render an aha card (AC2).
final List<GrammarAhaGap> grammarAhaGapLog = <GrammarAhaGap>[];

void clearGrammarAhaGapLog() => grammarAhaGapLog.clear();

class GrammarAhaGap {
  const GrammarAhaGap({
    required this.patternId,
    required this.code,
    required this.detail,
  });

  final String patternId;
  final String code;
  final String detail;
}

class PatternContrastMissing implements Exception {
  PatternContrastMissing(this.patternId)
      : code = GrammarAhaCodes.patternContrastMissing;

  final String patternId;
  final String code;

  @override
  String toString() => '$code: no contrast pair for pattern $patternId';
}

class GenericGrammarInAhaCard implements Exception {
  GenericGrammarInAhaCard(this.patternId, this.snippet)
      : code = GrammarAhaCodes.genericGrammarForbidden;

  final String patternId;
  final String snippet;
  final String code;

  @override
  String toString() => '$code: banned generic grammar in $patternId: $snippet';
}

/// Pattern Library row (schemas/v2/pattern.schema.json).
class GrammarPatternEntry {
  const GrammarPatternEntry({
    required this.id,
    required this.descriptionL1,
    required this.form,
    required this.examples,
    required this.contrasts,
    required this.commonErrors,
    required this.cefr,
    this.label,
  });

  final String id;
  final String descriptionL1;
  final String form;
  final List<String> examples;
  final List<String> contrasts;
  final List<String> commonErrors;
  final String cefr;
  final String? label;

  factory GrammarPatternEntry.fromJson(Map<String, dynamic> json) {
    return GrammarPatternEntry(
      id: json['id'] as String,
      descriptionL1: json['description_l1'] as String,
      form: json['form'] as String,
      examples: _stringList(json['examples']),
      contrasts: _stringList(json['contrasts']),
      commonErrors: _stringList(json['common_errors']),
      cefr: json['cefr'] as String,
      label: json['label'] as String?,
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.map((e) => '$e').toList();
  }
}

class GrammarAhaContrastRow {
  const GrammarAhaContrastRow({
    required this.example,
    required this.contrast,
  });

  final String example;
  final String contrast;
}

class GrammarAhaCardModel {
  const GrammarAhaCardModel({
    required this.patternId,
    required this.title,
    required this.form,
    required this.descriptionL1,
    required this.contrastRows,
    required this.practicePrompt,
    this.qualityLabel,
  });

  final String patternId;
  final String title;
  final String form;
  final String descriptionL1;
  final List<GrammarAhaContrastRow> contrastRows;
  final String practicePrompt;
  final ContentQualityLabel? qualityLabel;

  Iterable<String> get allVisibleText => [
        title,
        form,
        descriptionL1,
        practicePrompt,
        ...contrastRows.expand((r) => [r.example, r.contrast]),
      ];
}

final RegExp _genericAffixClaim = RegExp(
  r'affixes carry tense and person',
  caseSensitive: false,
);
final RegExp _genericSvoTemplate = RegExp(
  r'pattern:\s*subject\s*(?:→|->)\s*verb\s*(?:→|->)',
  caseSensitive: false,
);

bool containsBannedGenericGrammar(String text) {
  if (text.trim().isEmpty) {
    return false;
  }
  return _genericAffixClaim.hasMatch(text) || _genericSvoTemplate.hasMatch(text);
}

void _assertNoBannedGenericGrammar(GrammarPatternEntry pattern, Iterable<String> texts) {
  for (final text in texts) {
    if (containsBannedGenericGrammar(text)) {
      throw GenericGrammarInAhaCard(pattern.id, text);
    }
  }
}

ContentQualityLabel? _labelFromStorage(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final normalized = raw.trim();
  if (normalized == 'expert_reviewed') {
    return ContentQualityLabel.expertReviewed;
  }
  return ContentQualityLabel.fromStorage(normalized);
}

/// Builds card content or records [PatternContrastMissing] in [grammarAhaGapLog].
GrammarAhaCardModel? tryBuildGrammarAhaCard(
  GrammarPatternEntry pattern, {
  String title = GrammarAhaCopyKeys.defaultTitle,
  String practiceLead = GrammarAhaCopyKeys.defaultPractice,
}) {
  if (pattern.examples.isEmpty || pattern.contrasts.isEmpty) {
    grammarAhaGapLog.add(
      GrammarAhaGap(
        patternId: pattern.id,
        code: GrammarAhaCodes.patternContrastMissing,
        detail: 'examples=${pattern.examples.length} contrasts=${pattern.contrasts.length}',
      ),
    );
    return null;
  }

  final pairCount = pattern.examples.length < pattern.contrasts.length
      ? pattern.examples.length
      : pattern.contrasts.length;
  final rows = <GrammarAhaContrastRow>[];
  for (var i = 0; i < pairCount; i++) {
    rows.add(
      GrammarAhaContrastRow(
        example: pattern.examples[i],
        contrast: pattern.contrasts[i],
      ),
    );
  }

  final practicePrompt = pattern.commonErrors.isNotEmpty
      ? '$practiceLead ${pattern.commonErrors.first}'
      : '$practiceLead (${pattern.form})';

  final model = GrammarAhaCardModel(
    patternId: pattern.id,
    title: title,
    form: pattern.form,
    descriptionL1: pattern.descriptionL1,
    contrastRows: rows,
    practicePrompt: practicePrompt,
    qualityLabel: _labelFromStorage(pattern.label),
  );

  _assertNoBannedGenericGrammar(pattern, model.allVisibleText);
  return model;
}

GrammarAhaCardModel buildGrammarAhaCard(
  GrammarPatternEntry pattern, {
  String title = GrammarAhaCopyKeys.defaultTitle,
  String practiceLead = GrammarAhaCopyKeys.defaultPractice,
}) {
  final built = tryBuildGrammarAhaCard(
    pattern,
    title: title,
    practiceLead: practiceLead,
  );
  if (built == null) {
    throw PatternContrastMissing(pattern.id);
  }
  return built;
}

/// Fails CI when legacy generic grammar appears on a built card (AC3).
void assertGrammarAhaCardCiClean(GrammarAhaCardModel model) {
  for (final text in model.allVisibleText) {
    if (containsBannedGenericGrammar(text)) {
      throw GenericGrammarInAhaCard(model.patternId, text);
    }
  }
}

enum GrammarAhaCardPhase { ready, practice }

/// Learner-facing aha card: contrasts first, then practice (AC1).
class GrammarAhaCard extends StatefulWidget {
  const GrammarAhaCard({
    super.key,
    required this.model,
    this.onPracticeComplete,
  });

  final GrammarAhaCardModel model;
  final VoidCallback? onPracticeComplete;

  @override
  State<GrammarAhaCard> createState() => _GrammarAhaCardState();
}

class _GrammarAhaCardState extends State<GrammarAhaCard> {
  GrammarAhaCardPhase _phase = GrammarAhaCardPhase.ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge;

    return Semantics(
      label:
          '${widget.model.title}. ${widget.model.descriptionL1}. ${widget.model.contrastRows.length} contrast pairs.',
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.model.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (widget.model.qualityLabel != null)
                    _LabelChip(label: widget.model.qualityLabel!),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.model.descriptionL1, style: bodyStyle),
              const SizedBox(height: 4),
              Text(
                widget.model.form,
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...widget.model.contrastRows.map(_contrastTile),
              const SizedBox(height: 16),
              if (_phase == GrammarAhaCardPhase.ready)
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _phase = GrammarAhaCardPhase.practice);
                    },
                    child: const Text(GrammarAhaCopyKeys.defaultPractice),
                  ),
                )
              else
                Semantics(
                  label: widget.model.practicePrompt,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(widget.model.practicePrompt, style: bodyStyle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contrastTile(GrammarAhaContrastRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Example: ${row.example}',
            child: Text(row.example, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Contrast: ${row.contrast}',
            child: Text(
              row.contrast,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

  final ContentQualityLabel label;

  @override
  Widget build(BuildContext context) {
    final spec = contentLabelBadgeSpec(
      label: label,
      betaCopy: 'Beta',
      nativeLabel: 'Native',
      expertLabel: 'Expert',
    );
    if (spec == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: spec.semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          spec.visibleText,
          style: TextStyle(color: spec.foreground, fontSize: 12),
        ),
      ),
    );
  }
}
