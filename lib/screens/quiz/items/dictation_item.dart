import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class DictationItem extends StatefulWidget {
  const DictationItem({
    super.key,
    required this.correct,
    required this.asciiVariants,
  });

  final String correct;
  final List<String> asciiVariants;

  @override
  State<DictationItem> createState() => _DictationItemState();
}

class _DictationItemState extends State<DictationItem> {
  final _controller = TextEditingController();
  String _phase = 'idle';
  DictationGrade? _grade;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(String mark) {
    if (_grade != null) return;
    _controller.text = '${_controller.text}$mark';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _phase = 'typing');
  }

  void _submit() {
    final grade = gradeDictation(
      response: _controller.text,
      correct: widget.correct,
      asciiVariants: widget.asciiVariants,
    );
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hint = _grade == null
        ? null
        : _grade!.full
            ? ItemBuildCopy.correct
            : _grade!.passed
                ? ItemBuildCopy.variantHint
                : _grade!.lettersMatch
                    ? ItemBuildCopy.diacriticHint
                    : ItemBuildCopy.wrong;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.dictation',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(ItemBuildCopy.dictation),
          TextField(
            controller: _controller,
            enabled: _grade == null,
            decoration: const InputDecoration(labelText: ItemBuildCopy.dictation),
            onChanged: (value) {
              if (_grade != null) return;
              setState(() => _phase = value.isEmpty ? 'idle' : 'typing');
            },
          ),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            children: [
              for (final mark in const [
                (ItemBuildCopy.lowTone, '\u0300'),
                (ItemBuildCopy.highTone, '\u0301'),
                (ItemBuildCopy.midTone, '\u0304'),
                (ItemBuildCopy.dotBelow, '\u0323'),
              ])
                Semantics(
                  button: true,
                  label: mark.$1,
                  child: OutlinedButton(onPressed: () => _insert(mark.$2), child: Text(mark.$1)),
                ),
            ],
          ),
          TextButton(onPressed: _grade == null ? _submit : null, child: const Text('Check')),
          if (hint != null)
            Text(
              hint,
              style: TextStyle(
                color: _grade!.full
                    ? PanAfricanColors.success
                    : _grade!.phase == 'wrong'
                        ? PanAfricanColors.error
                        : PanAfricanColors.warning,
              ),
            ),
        ],
      ),
    );
  }
}
