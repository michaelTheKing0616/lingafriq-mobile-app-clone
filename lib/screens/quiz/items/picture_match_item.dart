import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class PictureChoice {
  const PictureChoice({
    required this.id,
    required this.imageRef,
    required this.altText,
  });

  final String id;
  final String imageRef;
  final String altText;
}

class PictureMatchItem extends StatefulWidget {
  PictureMatchItem({
    super.key,
    required this.choices,
    required this.spec,
  }) {
    for (final choice in choices) {
      if (choice.altText.trim().isEmpty) {
        throw ArgumentError('each picture needs alt text');
      }
    }
  }

  final List<PictureChoice> choices;
  final AnswerSpec spec;

  @override
  State<PictureMatchItem> createState() => _PictureMatchItemState();
}

class _PictureMatchItemState extends State<PictureMatchItem> {
  String _phase = 'idle';
  ItemGrade? _grade;

  void _choose(PictureChoice choice) {
    if (_grade != null) return;
    final grade = gradePicture(chosenId: choice.id, spec: widget.spec);
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  bool _isRemote(String ref) => ref.startsWith('http://') || ref.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.picture',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(ItemCopy.picture),
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
                image: true,
                label: choice.altText,
                child: OutlinedButton(
                  onPressed: _grade == null ? () => _choose(choice) : null,
                  child: Column(
                    children: [
                      if (_isRemote(choice.imageRef))
                        Image.network(
                          choice.imageRef,
                          height: PanAfricanSpacing.xxl,
                          width: PanAfricanSpacing.xxl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        )
                      else
                        SizedBox(
                          height: PanAfricanSpacing.xxl,
                          width: PanAfricanSpacing.xxl,
                        ),
                      ExcludeSemantics(child: Text(choice.altText)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
