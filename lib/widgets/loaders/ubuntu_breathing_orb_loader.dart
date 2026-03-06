import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UbuntuBreathingOrbLoader extends StatefulWidget {
  const UbuntuBreathingOrbLoader({super.key, this.size = 240});

  final double size;

  @override
  State<UbuntuBreathingOrbLoader> createState() =>
      _UbuntuBreathingOrbLoaderState();
}

class _UbuntuBreathingOrbLoaderState extends State<UbuntuBreathingOrbLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat(reverse: true);

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
        final t = Curves.easeInOut.transform(_controller.value);
        final breathScale = 0.9 + (0.2 * t);
        return Container(
          width: widget.size + 28,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C0F0A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: breathScale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ParticleField(
                        progress: _controller.value,
                        size: widget.size,
                      ),
                      _PeopleRing(
                        size: widget.size * 0.9,
                        iconCount: 10,
                        progress: _controller.value,
                        direction: 1,
                        color: const Color(0xFFF2E8D5).withValues(alpha: 0.85),
                      ),
                      _PeopleRing(
                        size: widget.size * 0.66,
                        iconCount: 8,
                        progress: _controller.value,
                        direction: -1,
                        color: const Color(0xFFD4880A).withValues(alpha: 0.8),
                      ),
                      _PeopleRing(
                        size: widget.size * 0.43,
                        iconCount: 6,
                        progress: _controller.value,
                        direction: 1,
                        color: const Color(0xFFC1440E).withValues(alpha: 0.9),
                      ),
                      Container(
                        width: widget.size * 0.2,
                        height: widget.size * 0.2,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0xFFE46B37), Color(0xFFC1440E)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66C1440E),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ubuntu · We Learn Together',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFF2E8D5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeopleRing extends StatelessWidget {
  const _PeopleRing({
    required this.size,
    required this.iconCount,
    required this.progress,
    required this.direction,
    required this.color,
  });

  final double size;
  final int iconCount;
  final double progress;
  final int direction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final angleOffset = progress * math.pi * 2 * 0.2 * direction;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: List.generate(iconCount, (index) {
          final theta = ((2 * math.pi) / iconCount) * index + angleOffset;
          final x = (size / 2) + (math.cos(theta) * (size * 0.4));
          final y = (size / 2) + (math.sin(theta) * (size * 0.4));
          return Positioned(
            left: x - 6,
            top: y - 6,
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 12,
              color: color,
            ),
          );
        }),
      ),
    );
  }
}

class _ParticleField extends StatelessWidget {
  const _ParticleField({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final particles = List.generate(18, (i) {
      final angle = (i / 18) * 2 * math.pi;
      final wave = ((progress + i * 0.07) % 1.0);
      final radius = (size * 0.06) + ((size * 0.42) * wave);
      final opacity = (1 - wave).clamp(0.0, 1.0) * 0.55;
      return Positioned(
        left: (size / 2) + (math.cos(angle) * radius),
        top: (size / 2) + (math.sin(angle) * radius),
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2E8D5).withValues(alpha: opacity),
          ),
        ),
      );
    });

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: particles),
    );
  }
}
