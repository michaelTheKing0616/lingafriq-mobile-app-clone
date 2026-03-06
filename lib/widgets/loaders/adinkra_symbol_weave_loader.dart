import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdinkraSymbolWeaveLoader extends StatefulWidget {
  const AdinkraSymbolWeaveLoader({super.key, this.size = 200, this.message});

  final double size;
  final String? message;

  @override
  State<AdinkraSymbolWeaveLoader> createState() =>
      _AdinkraSymbolWeaveLoaderState();
}

class _AdinkraSymbolWeaveLoaderState extends State<AdinkraSymbolWeaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  static const _symbols = <({String name, String meaning, _AdinkraType type})>[
    (name: 'Sankofa', meaning: 'Return & Learn', type: _AdinkraType.sankofa),
    (
      name: 'Gye Nyame',
      meaning: 'Supremacy & Protection',
      type: _AdinkraType.gyeNyame,
    ),
    (
      name: 'Dwennimmen',
      meaning: 'Strength & Humility',
      type: _AdinkraType.dwennimmen,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fgColors = [
      const Color(0xFFD4AF37),
      const Color(0xFFE2703A),
      const Color(0xFFF5F0E8),
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * _symbols.length;
        final index = phase.floor() % _symbols.length;
        final local = phase - phase.floorToDouble();
        final opacity = 1.0 - ((local - 0.5).abs() * 1.6).clamp(0.0, 1.0);
        final symbol = _symbols[index];
        final color = fgColors[index % fgColors.length];

        return Container(
          width: widget.size + 32,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _KenteTexturePainter()),
                    Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: local * math.pi * 2,
                        child: CustomPaint(
                          painter: _AdinkraPainter(
                            type: symbol.type,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${symbol.name} · ${symbol.meaning}',
                style: GoogleFonts.philosopher(
                  fontSize: 14,
                  color: const Color(0xFFF5F0E8),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.message!,
                  style: GoogleFonts.philosopher(
                    fontSize: 12,
                    color: const Color(0xFFF5F0E8).withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum _AdinkraType { sankofa, gyeNyame, dwennimmen }

class _AdinkraPainter extends CustomPainter {
  const _AdinkraPainter({required this.type, required this.color});

  final _AdinkraType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.16);

    switch (type) {
      case _AdinkraType.sankofa:
        final body = Path()
          ..addOval(Rect.fromCircle(center: center, radius: size.width * 0.18));
        canvas.drawPath(body, fill);
        canvas.drawPath(body, stroke);
        canvas.drawArc(
          Rect.fromCircle(
            center: center.translate(-size.width * 0.12, -size.height * 0.08),
            radius: size.width * 0.25,
          ),
          math.pi * 0.12,
          math.pi * 1.2,
          false,
          stroke,
        );
        canvas.drawCircle(
          center.translate(size.width * 0.22, -size.height * 0.2),
          size.width * 0.04,
          stroke,
        );
        canvas.drawLine(
          center.translate(0, size.height * 0.12),
          center.translate(size.width * 0.1, size.height * 0.3),
          stroke,
        );
        canvas.drawLine(
          center.translate(0, size.height * 0.12),
          center.translate(-size.width * 0.1, size.height * 0.3),
          stroke,
        );
      case _AdinkraType.gyeNyame:
        final outer = Rect.fromCircle(
          center: center,
          radius: size.width * 0.27,
        );
        canvas.drawArc(outer, 0, math.pi * 0.65, false, stroke);
        canvas.drawArc(outer, math.pi, math.pi * 0.65, false, stroke);
        canvas.drawArc(outer, math.pi * 0.5, math.pi * 0.65, false, stroke);
        canvas.drawArc(outer, math.pi * 1.5, math.pi * 0.65, false, stroke);
        canvas.drawCircle(center, size.width * 0.07, fill);
        canvas.drawCircle(center, size.width * 0.07, stroke);
      case _AdinkraType.dwennimmen:
        final left = Path()
          ..moveTo(center.dx - size.width * 0.3, center.dy + size.height * 0.12)
          ..quadraticBezierTo(
            center.dx - size.width * 0.45,
            center.dy - size.height * 0.1,
            center.dx - size.width * 0.18,
            center.dy - size.height * 0.12,
          )
          ..quadraticBezierTo(
            center.dx - size.width * 0.36,
            center.dy - size.height * 0.24,
            center.dx - size.width * 0.1,
            center.dy - size.height * 0.3,
          );
        final right = Path()
          ..moveTo(center.dx + size.width * 0.3, center.dy + size.height * 0.12)
          ..quadraticBezierTo(
            center.dx + size.width * 0.45,
            center.dy - size.height * 0.1,
            center.dx + size.width * 0.18,
            center.dy - size.height * 0.12,
          )
          ..quadraticBezierTo(
            center.dx + size.width * 0.36,
            center.dy - size.height * 0.24,
            center.dx + size.width * 0.1,
            center.dy - size.height * 0.3,
          );
        canvas.drawPath(left, stroke);
        canvas.drawPath(right, stroke);
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, size.height * 0.06),
            width: size.width * 0.24,
            height: size.height * 0.18,
          ),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _AdinkraPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

class _KenteTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F0E8).withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const gap = 16.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
