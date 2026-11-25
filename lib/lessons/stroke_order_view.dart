/// Stroke-order animation for script characters (P5-084, ELEVATION §6.7).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// copy_keys: stroke.title
abstract final class StrokeOrderCopyKeys {
  static const strokeTitle = 'stroke.title';
  static const defaultStrokeTitle = 'Stroke order';
  static const unavailable =
      'Stroke-order guide is not available for this character yet.';
  static const animatingHint = 'Playing stroke order';
}

enum StrokeOrderUiState { idle, animating, unavailable }

/// Normalized polyline in unit square [0,1]×[0,1].
class StrokePolyline {
  const StrokePolyline({required this.points, required this.sourceId});

  final List<Offset> points;
  final String sourceId;

  static StrokePolyline fromJson(Map<String, dynamic> json) {
    final sourceId = json['source_id'] as String? ?? '';
    if (sourceId.trim().isEmpty) {
      throw const FormatException('stroke source_id is required');
    }
    final raw = json['points'] as List<dynamic>? ?? const [];
    if (raw.length < 2) {
      throw const FormatException('stroke needs at least two points');
    }
    final points = raw.map((p) {
      final pair = p as List<dynamic>;
      return Offset(
        (pair[0] as num).toDouble(),
        (pair[1] as num).toDouble(),
      );
    }).toList(growable: false);
    return StrokePolyline(points: points, sourceId: sourceId);
  }
}

class StrokeCharacterData {
  const StrokeCharacterData({
    required this.character,
    required this.strokes,
    required this.catalogSourceId,
    this.meaning = '',
  });

  final String character;
  final List<StrokePolyline> strokes;
  final String catalogSourceId;
  final String meaning;

  static StrokeCharacterData fromJson(Map<String, dynamic> json) {
    final character = json['character'] as String? ?? '';
    if (character.isEmpty) {
      throw const FormatException('character is required');
    }
    final catalogSourceId = json['catalog_source_id'] as String? ?? '';
    if (catalogSourceId.trim().isEmpty) {
      throw const FormatException('catalog_source_id is required');
    }
    final strokesRaw = json['strokes'] as List<dynamic>? ?? const [];
    if (strokesRaw.isEmpty) {
      throw const FormatException('strokes must be non-empty');
    }
    final strokes = strokesRaw
        .map((s) => StrokePolyline.fromJson(s as Map<String, dynamic>))
        .toList(growable: false);
    return StrokeCharacterData(
      character: character,
      strokes: strokes,
      catalogSourceId: catalogSourceId,
      meaning: json['meaning'] as String? ?? '',
    );
  }
}

class StrokeCatalog {
  const StrokeCatalog({required this.cardId, required this.byCharacter});

  final String cardId;
  final Map<String, StrokeCharacterData> byCharacter;

  StrokeCharacterData? dataFor(String character) => byCharacter[character];

  static StrokeCatalog fromJson(Map<String, dynamic> root) {
    final glyphs = root['glyphs'] as List<dynamic>? ?? const [];
    final map = <String, StrokeCharacterData>{};
    for (final item in glyphs) {
      final data = StrokeCharacterData.fromJson(item as Map<String, dynamic>);
      map[data.character] = data;
    }
    return StrokeCatalog(
      cardId: root['card'] as String? ?? 'P5-084',
      byCharacter: map,
    );
  }
}

/// Production catalog is empty until native-verified stroke fixtures ship.
const StrokeCatalog kDefaultStrokeCatalog = StrokeCatalog(
  cardId: 'P5-084',
  byCharacter: {},
);

StrokeOrderUiState resolveStrokeOrderState({
  required String character,
  required StrokeCatalog catalog,
  required bool animationPlaying,
}) {
  if (catalog.dataFor(character) == null) {
    return StrokeOrderUiState.unavailable;
  }
  if (animationPlaying) {
    return StrokeOrderUiState.animating;
  }
  return StrokeOrderUiState.idle;
}

String strokeOrderSemanticsLabel({
  required String character,
  required StrokeCharacterData? data,
  required StrokeOrderUiState state,
}) {
  if (data == null) {
    return '$character. ${StrokeOrderCopyKeys.unavailable}';
  }
  final meaning = data.meaning.trim();
  final meaningPart = meaning.isEmpty ? '' : ', $meaning';
  switch (state) {
    case StrokeOrderUiState.unavailable:
      return '$character$meaningPart. ${StrokeOrderCopyKeys.unavailable}';
    case StrokeOrderUiState.animating:
      return '$character$meaningPart. ${StrokeOrderCopyKeys.animatingHint}';
    case StrokeOrderUiState.idle:
      return '$character$meaningPart. ${StrokeOrderCopyKeys.defaultStrokeTitle}';
  }
}

class StrokeOrderPainter extends CustomPainter {
  StrokeOrderPainter({
    required this.strokes,
    required this.progress,
    required this.completedStrokeCount,
    required this.color,
  });

  final List<StrokePolyline> strokes;
  final double progress;
  final int completedStrokeCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(2, size.shortestSide * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final path = Path();
      final first = _scale(stroke.points.first, size);
      path.moveTo(first.dx, first.dy);
      for (var j = 1; j < stroke.points.length; j++) {
        final pt = _scale(stroke.points[j], size);
        path.lineTo(pt.dx, pt.dy);
      }
      if (i < completedStrokeCount) {
        canvas.drawPath(path, paint);
      } else if (i == completedStrokeCount) {
        final metrics = path.computeMetrics().first;
        final excerpt = metrics.extractPath(0, metrics.length * progress);
        canvas.drawPath(excerpt, paint);
      }
    }
  }

  Offset _scale(Offset unit, Size size) {
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    return Offset(pad + unit.dx * w, pad + unit.dy * h);
  }

  @override
  bool shouldRepaint(covariant StrokeOrderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.completedStrokeCount != completedStrokeCount ||
        oldDelegate.strokes != strokes ||
        oldDelegate.color != color;
  }
}

/// Plays sourced stroke-order polylines; honest unavailable when missing data.
class StrokeOrderView extends StatefulWidget {
  const StrokeOrderView({
    super.key,
    required this.character,
    this.catalog = kDefaultStrokeCatalog,
    this.romanization = '',
    this.onAnimationComplete,
  });

  final String character;
  final StrokeCatalog catalog;
  final String romanization;
  final VoidCallback? onAnimationComplete;

  @override
  State<StrokeOrderView> createState() => _StrokeOrderViewState();
}

class _StrokeOrderViewState extends State<StrokeOrderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _completedStrokes = 0;
  double _strokeProgress = 0;

  StrokeCharacterData? get _data => widget.catalog.dataFor(widget.character);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    _schedulePlay();
  }

  @override
  void didUpdateWidget(covariant StrokeOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _resetAnimation();
      _schedulePlay();
    }
  }

  void _resetAnimation() {
    _controller.reset();
    _completedStrokes = 0;
    _strokeProgress = 0;
  }

  void _schedulePlay() {
    final data = _data;
    if (data == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _play(data);
    });
  }

  void _play(StrokeCharacterData data) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      setState(() {
        _completedStrokes = data.strokes.length;
        _strokeProgress = 1;
      });
      widget.onAnimationComplete?.call();
      return;
    }
    _controller.forward(from: 0);
  }

  void _onTick() {
    final data = _data;
    if (data == null || data.strokes.isEmpty) {
      return;
    }
    final t = _controller.value;
    final perStroke = 1 / data.strokes.length;
    final index = (t / perStroke).floor().clamp(0, data.strokes.length - 1);
    final local = ((t - index * perStroke) / perStroke).clamp(0.0, 1.0);
    setState(() {
      _completedStrokes = index;
      _strokeProgress = local;
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    final data = _data;
    if (data != null) {
      setState(() {
        _completedStrokes = data.strokes.length;
        _strokeProgress = 1;
      });
    }
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final playing = _controller.isAnimating;
    final state = resolveStrokeOrderState(
      character: widget.character,
      catalog: widget.catalog,
      animationPlaying: playing,
    );
    final semantics = strokeOrderSemanticsLabel(
      character: widget.character,
      data: data,
      state: state,
    );
    final color = Theme.of(context).colorScheme.onSurface;

    if (data == null) {
      return Semantics(
        label: semantics,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.character,
                style: const TextStyle(fontSize: 48),
              ),
              if (widget.romanization.isNotEmpty)
                Text(widget.romanization, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              Text(
                StrokeOrderCopyKeys.unavailable,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StrokeOrderCopyKeys.defaultStrokeTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: StrokeOrderPainter(
                strokes: data.strokes,
                progress: _strokeProgress,
                completedStrokeCount: _completedStrokes,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.character,
            style: const TextStyle(fontSize: 32),
          ),
          if (widget.romanization.isNotEmpty)
            Text(widget.romanization, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
