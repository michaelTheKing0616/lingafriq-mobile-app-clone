import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TalkingDrumPulseLoader extends StatefulWidget {
  const TalkingDrumPulseLoader({super.key, this.size = 220, this.bpm = 100});

  final double size;
  final int bpm;

  @override
  State<TalkingDrumPulseLoader> createState() => _TalkingDrumPulseLoaderState();
}

class _TalkingDrumPulseLoaderState extends State<TalkingDrumPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _loopMs;
  late double _beatMs;

  @override
  void initState() {
    super.initState();
    _configureController();
  }

  @override
  void didUpdateWidget(covariant TalkingDrumPulseLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _controller.dispose();
      _configureController();
    }
  }

  void _configureController() {
    final safeBpm = widget.bpm.clamp(40, 220);
    _beatMs = 60000 / safeBpm;
    _loopMs = (_beatMs * 4).round();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _loopMs),
    )..repeat();
  }

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
        final nowMs = _controller.value * _loopMs;
        return Container(
          width: widget.size + 28,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141010),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._buildRings(nowMs),
                    CustomPaint(
                      size: Size.square(widget.size * 0.34),
                      painter: const _DjembePainter(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Talking Drum · Every Beat, a Word',
                style: GoogleFonts.libreBaskerville(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
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

  List<Widget> _buildRings(double nowMs) {
    const ringColors = <Color>[
      Color(0xFF6B2FA0), // Bantu
      Color(0xFFE8660A), // Kwa
      Color(0xFF0A9396), // Afroasiatic
      Color(0xFF9B1D20), // Nilotic
    ];
    const waveDuration = 1200.0;
    const stagger = 150.0;

    return List.generate(ringColors.length, (i) {
      double shifted = (nowMs - (i * stagger)) % _beatMs;
      if (shifted < 0) shifted += _beatMs;
      final active = shifted <= waveDuration;
      final p = active ? (shifted / waveDuration).clamp(0.0, 1.0) : 1.0;
      final scale = 1 + (2 * p);
      final opacity = active ? (0.8 * (1 - p)) : 0.0;
      return Transform.scale(
        scale: scale,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColors[i].withValues(alpha: opacity),
              width: 2.2,
            ),
          ),
        ),
      );
    });
  }
}

class _DjembePainter extends CustomPainter {
  const _DjembePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final wood = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD09B67), Color(0xFF8E5B3A)],
      ).createShader(Offset.zero & size);
    final rope = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE9DCCB);
    final body = Path()
      ..moveTo(center.dx - size.width * 0.18, center.dy - size.height * 0.38)
      ..quadraticBezierTo(
        center.dx - size.width * 0.32,
        center.dy - size.height * 0.04,
        center.dx - size.width * 0.11,
        center.dy + size.height * 0.42,
      )
      ..lineTo(center.dx + size.width * 0.11, center.dy + size.height * 0.42)
      ..quadraticBezierTo(
        center.dx + size.width * 0.32,
        center.dy - size.height * 0.04,
        center.dx + size.width * 0.18,
        center.dy - size.height * 0.38,
      )
      ..close();
    canvas.drawPath(body, wood);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -size.height * 0.38),
        width: size.width * 0.52,
        height: size.height * 0.18,
      ),
      Paint()..color = const Color(0xFFF0DAC0),
    );

    for (int i = 0; i < 7; i++) {
      final dx = (i - 3) * size.width * 0.06;
      canvas.drawLine(
        Offset(
          center.dx + dx - size.width * 0.1,
          center.dy - size.height * 0.3,
        ),
        Offset(center.dx + dx * 0.3, center.dy + size.height * 0.38),
        rope,
      );
      canvas.drawLine(
        Offset(
          center.dx + dx + size.width * 0.1,
          center.dy - size.height * 0.3,
        ),
        Offset(center.dx + dx * 0.3, center.dy + size.height * 0.38),
        rope,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
