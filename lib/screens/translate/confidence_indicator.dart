import 'package:flutter/material.dart';

import 'live_translate_confidence.dart';

/// Visible confidence indicator for live translate results (P6-030).
class LiveTranslateConfidenceIndicator extends StatelessWidget {
  const LiveTranslateConfidenceIndicator({
    super.key,
    required this.confidence,
  });

  final LiveTranslateConfidenceView confidence;

  Color _bandColor(ColorScheme scheme) {
    switch (confidence.band) {
      case LiveTranslateConfidenceBand.high:
        return scheme.primary;
      case LiveTranslateConfidenceBand.medium:
        return scheme.tertiary;
      case LiveTranslateConfidenceBand.low:
        return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _bandColor(scheme);
    final label = confidenceDisplayLabel(confidence.band);
    final percent = (confidence.score * 100).round();

    return Semantics(
      label: '$label ($percent percent)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                confidence.band == LiveTranslateConfidenceBand.low
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence.score.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
