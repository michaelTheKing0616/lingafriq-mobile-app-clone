import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/tone_contour_line.dart';

/// Tone Lens contour block for Word Card sheet (P7-922 AC2).
class ToneLensContour extends StatelessWidget {
  const ToneLensContour({
    super.key,
    required this.tonePattern,
    this.syllables,
    this.verified = true,
  });

  final List<String> tonePattern;
  final List<String>? syllables;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (tonePattern.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ToneContourLine(
        tonePattern: tonePattern,
        syllables: syllables,
        verified: verified,
        height: 40,
      ),
    );
  }
}
