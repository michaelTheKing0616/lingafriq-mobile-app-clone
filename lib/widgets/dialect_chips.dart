import 'package:flutter/material.dart';
import 'package:lingafriq/models/lens_word_card.dart';

/// Selectable dialect tags for Word Card sheet (P7-922 AC4).
class DialectChips extends StatelessWidget {
  const DialectChips({
    super.key,
    required this.standardLabel,
    required this.variants,
    required this.selectedTag,
    required this.onSelected,
  });

  final String standardLabel;
  final List<LensDialectVariant> variants;
  final String selectedTag;
  final ValueChanged<String> onSelected;

  static const String standardTag = 'standard';

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[
      _DialectChip(
        label: standardLabel,
        tag: standardTag,
        selected: selectedTag == standardTag,
        onTap: () => onSelected(standardTag),
      ),
      for (final variant in variants)
        _DialectChip(
          label: variant.dialectTag,
          tag: variant.dialectTag,
          selected: selectedTag == variant.dialectTag,
          onTap: () => onSelected(variant.dialectTag),
        ),
    ];

    return Semantics(
      label: 'Dialect variants',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }
}

class _DialectChip extends StatelessWidget {
  const _DialectChip({
    required this.label,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Dialect $label',
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

String wordCardSurfaceForDialect({
  required String standardWord,
  required List<LensDialectVariant> variants,
  required String selectedTag,
}) {
  if (selectedTag == DialectChips.standardTag) {
    return standardWord;
  }
  for (final variant in variants) {
    if (variant.dialectTag == selectedTag) {
      return variant.text;
    }
  }
  return standardWord;
}
