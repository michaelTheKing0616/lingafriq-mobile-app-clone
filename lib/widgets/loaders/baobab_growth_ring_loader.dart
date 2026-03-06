import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BaobabGrowthRingLoader extends StatefulWidget {
  const BaobabGrowthRingLoader({
    super.key,
    this.size = 260,
    this.words = const ['mtu', 'ubuntu', 'rafiki', 'ndimi', 'maarifa'],
  });

  final double size;
  final List<String> words;

  @override
  State<BaobabGrowthRingLoader> createState() => _BaobabGrowthRingLoaderState();
}

class _BaobabGrowthRingLoaderState extends State<BaobabGrowthRingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size + 28,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0D2B), Color(0xFF0D0D2B), Color(0xFFFF6B35)],
              stops: [0, 0.68, 1],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _BaobabPainter(
                    progress: _controller.value,
                    words: widget.words,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Baobab · Rooted in Language',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  letterSpacing: 1.8,
                  color: const Color(0xFFF5F0E8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BaobabPainter extends CustomPainter {
  const _BaobabPainter({required this.progress, required this.words});

  final double progress;
  final List<String> words;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D0D2B), Color(0xFF0D0D2B), Color(0xFFFF6B35)],
        stops: [0, 0.68, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (int i = 0; i < 26; i++) {
      final x = (math.sin(i * 19.7) * 0.5 + 0.5) * size.width;
      final y = (math.cos(i * 11.1) * 0.5 + 0.5) * size.height * 0.62;
      canvas.drawCircle(Offset(x, y), 1, starPaint);
    }

    final rootPhase = ((progress - 0.0) / 0.18).clamp(0.0, 1.0);
    final trunkPhase = ((progress - 0.18) / 0.14).clamp(0.0, 1.0);
    final branchPhase = ((progress - 0.32) / 0.22).clamp(0.0, 1.0);
    final leavesPhase = ((progress - 0.54) / 0.2).clamp(0.0, 1.0);

    final treePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = const Color(0xFFA0522D);

    final rootPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.86,
        size.width * 0.28,
        size.height * 0.95,
      )
      ..moveTo(size.width * 0.5, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.88,
        size.width * 0.7,
        size.height * 0.95,
      )
      ..moveTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.49, size.height * 0.96);
    _drawPartial(canvas, rootPath, rootPhase, treePaint);

    final trunkPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.5, size.height * 0.42);
    treePaint.strokeWidth = 9;
    _drawPartial(canvas, trunkPath, trunkPhase, treePaint);

    treePaint.strokeWidth = 5;
    final leftBranch = Path()
      ..moveTo(size.width * 0.5, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.44,
        size.width * 0.26,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.32,
        size.width * 0.18,
        size.height * 0.25,
      );
    final rightBranch = Path()
      ..moveTo(size.width * 0.5, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.63,
        size.height * 0.45,
        size.width * 0.74,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.32,
        size.width * 0.82,
        size.height * 0.24,
      );
    final topBranch = Path()
      ..moveTo(size.width * 0.5, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.32,
        size.width * 0.5,
        size.height * 0.2,
      );
    _drawPartial(canvas, leftBranch, branchPhase, treePaint);
    _drawPartial(canvas, rightBranch, branchPhase, treePaint);
    _drawPartial(canvas, topBranch, branchPhase, treePaint);

    _drawLeaves(canvas, size, leavesPhase);
  }

  void _drawLeaves(Canvas canvas, Size size, double phase) {
    final leaves = [
      Offset(size.width * 0.16, size.height * 0.22),
      Offset(size.width * 0.28, size.height * 0.18),
      Offset(size.width * 0.41, size.height * 0.16),
      Offset(size.width * 0.5, size.height * 0.14),
      Offset(size.width * 0.6, size.height * 0.16),
      Offset(size.width * 0.72, size.height * 0.18),
      Offset(size.width * 0.84, size.height * 0.22),
    ];
    final leafPaint = Paint()..color = const Color(0xFF90EE60);
    final revealCount = (phase * leaves.length).clamp(0, leaves.length).toInt();

    for (int i = 0; i < revealCount; i++) {
      final leaf = leaves[i];
      canvas.drawCircle(leaf, 5.5, leafPaint);
      final word = words[i % words.length];
      final tp = TextPainter(
        text: TextSpan(
          text: word,
          style: GoogleFonts.cinzel(
            color: const Color(0xFFF5F0E8),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, leaf.translate(-tp.width / 2, -14));
    }
  }

  void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    final drawPath = Path();
    for (final metric in path.computeMetrics()) {
      drawPath.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant _BaobabPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.words != words;
  }
}
