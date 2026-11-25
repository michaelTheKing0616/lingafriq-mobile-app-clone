import 'package:flutter/material.dart';

import '../../utils/pan_african_design_system.dart';
import '../talking_drum/contour_overlay.dart';

/// Scrolling lyric strip with target pitch line and optional live learner overlay (P8-929).
class PitchLineView extends StatelessWidget {
  const PitchLineView({
    super.key,
    required this.lyrics,
    required this.targetContour,
    this.learnerContour,
    this.liveSamples,
    this.progress = 0,
    this.unsure = false,
    this.reduceMotion = false,
    this.height = 140,
  });

  final String lyrics;
  final List<double> targetContour;
  final List<double>? learnerContour;
  final List<double>? liveSamples;
  final double progress;
  final bool unsure;
  final bool reduceMotion;
  final double height;

  @override
  Widget build(BuildContext context) {
    final words = lyrics
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    final active = words.isEmpty
        ? 0
        : (progress.clamp(0.0, 1.0) * (words.length - 1)).round().clamp(
              0,
              words.length - 1,
            );

    final learnerLine = learnerContour ??
        (liveSamples != null && liveSamples!.isNotEmpty && !unsure
            ? resampleForOverlay(liveSamples!, targetContour.length)
            : null);

    return Semantics(
      label: unsure
          ? 'Pitch line unavailable — practice mode'
          : 'Karaoke pitch line with lyrics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TalkingDrumContourOverlay(
                      nativeContour: targetContour,
                      learnerContour: learnerLine,
                      unsure: unsure,
                      height: height,
                    ),
                    if (!reduceMotion && progress > 0 && progress < 1)
                      Positioned(
                        left: progress.clamp(0.0, 1.0) *
                            MediaQuery.sizeOf(context).width *
                            0.85,
                        top: 0,
                        bottom: 0,
                        child: VerticalDivider(
                          width: 2,
                          color: PanAfricanColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < words.length; i++) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
                    child: Text(
                      words[i],
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontSize: i == active ? 22 : 16,
                        fontWeight: i == active ? FontWeight.w700 : FontWeight.w500,
                        color: i < active
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)
                            : i == active
                                ? PanAfricanColors.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> resampleForOverlay(List<double> samples, int length) {
    if (length <= 0) return const [];
    if (samples.length == length) return samples;
    final out = <double>[];
    for (var i = 0; i < length; i++) {
      final t = length == 1 ? 0.0 : i / (length - 1);
      final idx = (t * (samples.length - 1)).round().clamp(0, samples.length - 1);
      out.add(samples[idx].clamp(0.0, 1.0));
    }
    return out;
  }
}
