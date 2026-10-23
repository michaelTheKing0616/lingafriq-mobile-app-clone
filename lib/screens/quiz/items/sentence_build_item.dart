import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class SentenceBuildItem extends StatefulWidget {
  const SentenceBuildItem({
    super.key,
    required this.tiles,
    required this.accepted,
  });

  final List<String> tiles;
  final List<List<String>> accepted;

  @override
  State<SentenceBuildItem> createState() => _SentenceBuildItemState();
}

class _SentenceBuildItemState extends State<SentenceBuildItem> {
  final _built = <int>[];
  String _phase = 'idle';
  bool? _passed;

  void _add(int index) {
    if (_passed != null || _built.contains(index)) return;
    setState(() {
      _built.add(index);
      _phase = 'typing';
    });
  }

  void _remove(int index) {
    if (_passed != null) return;
    setState(() {
      _built.remove(index);
      _phase = _built.isEmpty ? 'idle' : 'typing';
    });
  }

  void _check() {
    final order = [for (final index in _built) widget.tiles[index]];
    final passed = sentenceAccepted(order, widget.accepted);
    setState(() {
      _passed = passed;
      _phase = passed ? 'correct' : 'wrong';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.build',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ItemBuildCopy.build),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            children: [
              for (var index = 0; index < widget.tiles.length; index++)
                if (!_built.contains(index))
                  Semantics(
                    button: true,
                    label: widget.tiles[index],
                    child: OutlinedButton(
                      onPressed: _passed == null ? () => _add(index) : null,
                      child: Text(widget.tiles[index]),
                    ),
                  ),
            ],
          ),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            children: [
              for (final index in _built)
                Semantics(
                  button: true,
                  label: 'Remove ${widget.tiles[index]}',
                  child: TextButton(
                    onPressed: _passed == null ? () => _remove(index) : null,
                    child: Text(widget.tiles[index]),
                  ),
                ),
            ],
          ),
          TextButton(onPressed: _passed == null ? _check : null, child: const Text('Check')),
          if (_passed != null)
            Text(
              _passed! ? ItemBuildCopy.correct : ItemBuildCopy.wrong,
              style: TextStyle(color: _passed! ? PanAfricanColors.success : PanAfricanColors.error),
            ),
        ],
      ),
    );
  }
}
