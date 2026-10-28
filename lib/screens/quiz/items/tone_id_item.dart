import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ToneChoice {
  const ToneChoice({required this.label, required this.pattern});

  final String label;
  final List<String> pattern;
}

class ToneIdItem extends StatefulWidget {
  const ToneIdItem({
    super.key,
    required this.prompt,
    required this.tonePattern,
    required this.choices,
  });

  final String prompt;
  final List<String> tonePattern;
  final List<ToneChoice> choices;

  @override
  State<ToneIdItem> createState() => _ToneIdItemState();
}

class _ToneIdItemState extends State<ToneIdItem> {
  String _phase = 'idle';
  ItemGrade? _grade;

  void _choose(ToneChoice choice) {
    if (_grade != null) return;
    final grade = gradeTone(chosen: choice.pattern, tonePattern: widget.tonePattern);
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.tone',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(ItemCopy.tone),
          Text(widget.prompt),
          if (_grade != null)
            Text(
              _grade!.correct ? ItemCopy.correct : ItemCopy.wrong,
              style: TextStyle(color: _grade!.correct ? PanAfricanColors.success : PanAfricanColors.error),
            ),
          for (final choice in widget.choices)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
              child: Semantics(
                button: true,
                label: choice.label,
                child: OutlinedButton(
                  onPressed: _grade == null ? () => _choose(choice) : null,
                  child: Text(choice.label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
