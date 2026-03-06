import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NsibidiScriptTracerLoader extends StatefulWidget {
  const NsibidiScriptTracerLoader({super.key, this.size = 220, this.language});

  final double size;
  final String? language;

  @override
  State<NsibidiScriptTracerLoader> createState() =>
      _NsibidiScriptTracerLoaderState();
}

class _NsibidiScriptTracerLoaderState extends State<NsibidiScriptTracerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageText = widget.language?.trim().isNotEmpty == true
        ? 'Loading ${widget.language} lesson...'
        : 'Loading lesson...';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size + 28,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.4,
              colors: [Color(0xFF2A1F14), Color(0xFF1A1208)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _NsibidiPainter(progress: _controller.value),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nsibidi · Ancient Voices',
                style: GoogleFonts.imFellEnglish(
                  color: const Color(0xFFF5E9D5),
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                languageText,
                style: GoogleFonts.imFellEnglish(
                  color: const Color(0xFFF5E9D5).withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NsibidiPainter extends CustomPainter {
  const _NsibidiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topLeft,
        radius: 1.4,
        colors: [Color(0xFF2A1F14), Color(0xFF1A1208)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final speck = Paint()..color = const Color(0x66F5E9D5);
    for (int i = 0; i < 80; i++) {
      final x = (math.sin(i * 11.3) * 0.5 + 0.5) * size.width;
      final y = (math.cos(i * 17.7) * 0.5 + 0.5) * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, speck);
    }

    final paths = _paths(size);
    final phase = progress * paths.length;
    final pathIndex = phase.floor().clamp(0, paths.length - 1);
    final local = phase - pathIndex.floorToDouble();

    for (int i = 0; i < paths.length; i++) {
      final draw = i < pathIndex ? 1.0 : (i == pathIndex ? local : 0.0);
      if (draw <= 0) continue;
      _drawPathPortion(canvas, paths[i], draw, i == pathIndex && local > 0.85);
    }
  }

  void _drawPathPortion(Canvas canvas, Path path, double t, bool glow) {
    final drawPath = Path();
    for (final metric in path.computeMetrics()) {
      drawPath.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    final color = const Color(0xFFF0A500);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.95);
    if (glow) {
      stroke.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    }
    canvas.drawPath(drawPath, stroke);
  }

  List<Path> _paths(Size size) {
    final w = size.width;
    final h = size.height;
    return [
      Path()
        ..moveTo(w * 0.18, h * 0.56)
        ..quadraticBezierTo(w * 0.34, h * 0.22, w * 0.52, h * 0.44)
        ..quadraticBezierTo(w * 0.68, h * 0.64, w * 0.84, h * 0.36),
      Path()
        ..moveTo(w * 0.2, h * 0.75)
        ..quadraticBezierTo(w * 0.38, h * 0.62, w * 0.5, h * 0.82)
        ..quadraticBezierTo(w * 0.61, h * 0.98, w * 0.77, h * 0.72)
        ..moveTo(w * 0.5, h * 0.82)
        ..lineTo(w * 0.5, h * 0.26),
      Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.35),
            width: w * 0.26,
            height: h * 0.15,
          ),
        )
        ..moveTo(w * 0.37, h * 0.35)
        ..lineTo(w * 0.63, h * 0.35),
    ];
  }

  @override
  bool shouldRepaint(covariant _NsibidiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
