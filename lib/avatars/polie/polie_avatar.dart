import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart';
import '../avatar_engine.dart';
import '../emotion_system.dart';
import '../lip_sync_engine.dart';

/// Polie Avatar Colors - Afro-futurist palette
class PolieAvatarColors {
  static const Color electricTeal = Color(0xFF00D4AA);
  static const Color goldEmber = Color(0xFFFFB800);
  static const Color royalAmethyst = Color(0xFF9B59B6);
  static const Color cosmicBlue = Color(0xFF3498DB);
  static const Color ancestralGold = Color(0xFFD4AF37);
  static const Color deepSpace = Color(0xFF1A1A2E);
  static const Color nebulaPurple = Color(0xFF6B5B95);
  
  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricTeal, cosmicBlue, royalAmethyst],
  );
  
  static const LinearGradient auraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x4000D4AA),
      Color(0x209B59B6),
      Color(0x00000000),
    ],
  );
}

/// Polie Avatar Widget - Main AI companion avatar
class PolieAvatar extends StatefulWidget {
  final double size;
  final bool showAura;
  final bool showParticles;
  final bool interactive;
  final VoidCallback? onTap;
  final AvatarController? controller;
  
  const PolieAvatar({
    super.key,
    this.size = 200,
    this.showAura = true,
    this.showParticles = true,
    this.interactive = true,
    this.onTap,
    this.controller,
  });
  
  @override
  State<PolieAvatar> createState() => _PolieAvatarState();
}

class _PolieAvatarState extends State<PolieAvatar> 
    with TickerProviderStateMixin {
  AvatarController? _controller;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    
    _initializeController();
  }
  
  Future<void> _initializeController() async {
    if (widget.controller != null) {
      _controller = widget.controller;
    } else {
      _controller = await AvatarEngine().getController(AvatarType.polie);
    }
    
    if (mounted) {
      setState(() => _isLoaded = true);
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.interactive ? _handleTap : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Aura effect
            if (widget.showAura) _buildAura(),
            
            // Particles
            if (widget.showParticles) _buildParticles(),
            
            // Main avatar
            _buildAvatar(),
            
            // Glow ring
            _buildGlowRing(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAura() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size * 1.4,
            height: widget.size * 1.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: PolieAvatarColors.auraGradient,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size * 1.5, widget.size * 1.5),
          painter: _ParticlePainter(
            progress: _particleController.value,
            color: PolieAvatarColors.electricTeal,
          ),
        );
      },
    );
  }
  
  Widget _buildAvatar() {
    if (!_isLoaded || _controller?.artboard == null) {
      return _buildFallbackAvatar();
    }
    
    return Container(
      width: widget.size * 0.8,
      height: widget.size * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PolieAvatarColors.electricTeal.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Rive(
          artboard: _controller!.artboard!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  
  Widget _buildFallbackAvatar() {
    return Container(
      width: widget.size * 0.8,
      height: widget.size * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PolieAvatarColors.glowGradient,
        boxShadow: [
          BoxShadow(
            color: PolieAvatarColors.electricTeal.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: widget.size * 0.4,
          color: Colors.white,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .shimmer(duration: 2.seconds, color: Colors.white24);
  }
  
  Widget _buildGlowRing() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final opacity = 0.3 + (_glowController.value * 0.3);
        return Container(
          width: widget.size * 0.9,
          height: widget.size * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PolieAvatarColors.electricTeal.withOpacity(opacity),
              width: 2,
            ),
          ),
        );
      },
    );
  }
  
  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller?.wave();
    widget.onTap?.call();
  }
}

/// Particle painter for ambient effect
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _ParticlePainter({
    required this.progress,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw orbiting particles
    for (int i = 0; i < 8; i++) {
      final angle = (progress * 2 * 3.14159) + (i * 3.14159 / 4);
      final particleRadius = radius * (0.7 + (i % 3) * 0.1);
      final x = center.dx + particleRadius * _cos(angle);
      final y = center.dy + particleRadius * _sin(angle);
      
      final particleSize = 2.0 + (i % 3);
      final opacity = 0.3 + ((i % 4) * 0.15);
      
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }
  
  double _cos(double angle) => _cosApprox(angle);
  double _sin(double angle) => _sinApprox(angle);
  
  // Simple approximations to avoid importing dart:math
  double _cosApprox(double x) {
    x = x % (2 * 3.14159);
    return 1 - (x * x / 2) + (x * x * x * x / 24);
  }
  
  double _sinApprox(double x) {
    x = x % (2 * 3.14159);
    return x - (x * x * x / 6) + (x * x * x * x * x / 120);
  }
  
  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Compact Polie avatar for inline use
class PolieAvatarCompact extends StatelessWidget {
  final double size;
  final AvatarController? controller;
  
  const PolieAvatarCompact({
    super.key,
    this.size = 48,
    this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return PolieAvatar(
      size: size,
      showAura: false,
      showParticles: false,
      interactive: false,
      controller: controller,
    );
  }
}

/// Polie speaking indicator
class PolieSpeakingIndicator extends StatefulWidget {
  final bool isSpeaking;
  final Color color;
  
  const PolieSpeakingIndicator({
    super.key,
    required this.isSpeaking,
    this.color = PolieAvatarColors.electricTeal,
  });
  
  @override
  State<PolieSpeakingIndicator> createState() => _PolieSpeakingIndicatorState();
}

class _PolieSpeakingIndicatorState extends State<PolieSpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(PolieSpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
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
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final value = ((_controller.value + delay) % 1.0);
            final height = 4 + (value * 12);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
