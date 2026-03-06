import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KenteLoomWeaveLoader extends StatefulWidget {
  const KenteLoomWeaveLoader({super.key, this.width = 280, this.height = 180});

  final double width;
  final double height;

  @override
  State<KenteLoomWeaveLoader> createState() => _KenteLoomWeaveLoaderState();
}

class _KenteLoomWeaveLoaderState extends State<KenteLoomWeaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
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
          width: widget.width + 24,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: _KenteWeavePainter(progress: _controller.value),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kente · Weaving Words',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KenteWeavePainter extends CustomPainter {
  const _KenteWeavePainter({required this.progress});

  final double progress;

  static const _palette = <Color>[
    Color(0xFF003F91),
    Color(0xFFFFD700),
    Color(0xFF228B22),
    Color(0xFFCC0000),
    Color(0xFF111111),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const stripHeight = 18.0;
    final stripCount = (size.height / stripHeight).floor().clamp(8, 10);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF111111),
    );

    final warp = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warp);
    }

    for (int i = 0; i < stripCount; i++) {
      final y = i * stripHeight;
      final phase = (progress * (stripCount + 2) - i).clamp(0.0, 1.0);
      final reverseFactor = progress > 0.78
          ? ((progress - 0.78) / 0.22).clamp(0.0, 1.0)
          : 0.0;
      final visible = (phase * (1 - reverseFactor)).clamp(0.0, 1.0);
      if (visible <= 0) continue;

      final fromLeft = i.isEven;
      final width = size.width * visible;
      final left = fromLeft ? 0.0 : size.width - width;
      final rect = Rect.fromLTWH(left, y, width, stripHeight);
      final color = _palette[i % _palette.length];
      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black,
      );
    }

    if (progress > 0.68 && progress < 0.8) {
      final shimmer = (progress - 0.68) / 0.12;
      final x = (size.width + 80) * shimmer - 80;
      final shimmerRect = Rect.fromLTWH(x, 0, 80, size.height);
      canvas.drawRect(
        shimmerRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(shimmerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KenteWeavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
