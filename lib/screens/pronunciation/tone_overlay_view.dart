import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/pitch_contour_painter.dart';

/// copy_keys: tone.unsure_syllable (P6-039)
abstract final class ToneOverlayCopyKeys {
  static const unsureSyllable = 'tone.unsure_syllable';
  static const defaultUnsureSyllable = 'Tone unclear for this syllable.';
  static const loading = 'Loading pronunciation score…';
  static const error = 'Could not load tone overlay.';
  static const nativeLegend = 'Native contour';
  static const learnerLegend = 'Your contour';
}

class SyllableToneOverlayRow {
  const SyllableToneOverlayRow({
    required this.label,
    required this.expectedToneLabel,
    this.toneLabel,
    this.correct,
    this.confidence,
    this.reason,
    required this.nativeContour,
    required this.learnerContour,
  });

  final String label;
  final String? toneLabel;
  final String expectedToneLabel;
  final bool? correct;
  final double? confidence;
  final String? reason;
  final List<double> nativeContour;
  final List<double> learnerContour;

  bool get isUnsure =>
      correct == null || (reason != null && reason!.toLowerCase() == 'unsure');

  factory SyllableToneOverlayRow.fromJson(Map<String, dynamic> json) {
    return SyllableToneOverlayRow(
      label: json['label'] as String? ?? '',
      toneLabel: json['tone_label'] as String?,
      expectedToneLabel: json['expected_tone_label'] as String? ?? '',
      correct: json['correct'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      nativeContour: _finiteList(json['native_contour']),
      learnerContour: _finiteList(json['learner_contour']),
    );
  }
}

List<double> _finiteList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<num>()
      .map((n) => n.toDouble())
      .where((d) => d.isFinite)
      .toList();
}

List<SyllableContourSegment> segmentsFromRows(List<SyllableToneOverlayRow> rows) {
  return rows
      .map(
        (r) => SyllableContourSegment(
          label: r.label,
          nativeSemitones: r.nativeContour,
          learnerSemitones: r.learnerContour,
          unsure: r.isUnsure,
        ),
      )
      .toList();
}

/// Screen-reader summary of per-syllable tone results (AC3).
String buildToneOverlayAccessibilitySummary(List<SyllableToneOverlayRow> rows) {
  if (rows.isEmpty) return 'No syllable tone results.';
  final parts = <String>[];
  for (final row in rows) {
    final name = row.label.isEmpty ? 'syllable' : row.label;
    if (row.isUnsure) {
      parts.add('$name: ${ToneOverlayCopyKeys.defaultUnsureSyllable}');
      continue;
    }
    if (row.correct == true) {
      parts.add('$name: correct, expected ${row.expectedToneLabel}');
    } else if (row.correct == false) {
      final heard = row.toneLabel ?? 'unknown';
      parts.add('$name: incorrect, expected ${row.expectedToneLabel}, heard $heard');
    } else {
      parts.add('$name: ${ToneOverlayCopyKeys.defaultUnsureSyllable}');
    }
  }
  return parts.join('. ');
}

enum ToneOverlayStatus { loading, scored, unsure, error }

class ToneOverlayView extends StatelessWidget {
  const ToneOverlayView({
    super.key,
    required this.status,
    this.syllables = const [],
    this.errorMessage,
    this.height,
  });

  final ToneOverlayStatus status;
  final List<SyllableToneOverlayRow> syllables;
  final String? errorMessage;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final summary = buildToneOverlayAccessibilitySummary(syllables);
    final effectiveStatus = status == ToneOverlayStatus.scored &&
            syllables.isNotEmpty &&
            syllables.every((s) => s.isUnsure)
        ? ToneOverlayStatus.unsure
        : status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: _legend(context)),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: summary,
          child: SizedBox(
            height: height ?? 180,
            child: _body(context, effectiveStatus),
          ),
        ),
      ],
    );
  }

  Widget _legend(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Row(
      children: [
        _legendDot(PitchContourColors.pitchNative, ToneOverlayCopyKeys.nativeLegend, style),
        const SizedBox(width: 16),
        _legendDot(PitchContourColors.pitchLearner, ToneOverlayCopyKeys.learnerLegend, style),
      ],
    );
  }

  Widget _legendDot(Color color, String label, TextStyle? style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }

  Widget _body(BuildContext context, ToneOverlayStatus effectiveStatus) {
    switch (effectiveStatus) {
      case ToneOverlayStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ToneOverlayStatus.error:
        return Center(
          child: Text(errorMessage ?? ToneOverlayCopyKeys.error),
        );
      case ToneOverlayStatus.unsure:
      case ToneOverlayStatus.scored:
        final segments = segmentsFromRows(syllables);
        if (segments.every((s) => s.nativeSemitones.isEmpty && s.learnerSemitones.isEmpty)) {
          return const Center(child: Text(ToneOverlayCopyKeys.error));
        }
        return CustomPaint(
          painter: PitchContourPainter(segments: segments),
          child: const SizedBox.expand(),
        );
    }
  }
}
