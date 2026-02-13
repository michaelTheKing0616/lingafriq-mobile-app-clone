import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/pan_african_design_system.dart';
import '../../services/sound_effects_service.dart';

/// Global XP Gain data for overlay display
class XPGainEvent {
  final int amount;
  final String source;
  final DateTime timestamp;
  final String? bonusText;
  final bool isLevelUp;
  final int? newLevel;
  final String? newTitle;

  XPGainEvent({
    required this.amount,
    required this.source,
    DateTime? timestamp,
    this.bonusText,
    this.isLevelUp = false,
    this.newLevel,
    this.newTitle,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// State class for XP Gain Overlay
class XPGainOverlayState {
  final List<XPGainEvent> events;
  
  XPGainOverlayState({List<XPGainEvent>? events}) : events = events ?? [];
  
  XPGainOverlayState copyWith({List<XPGainEvent>? events}) {
    return XPGainOverlayState(events: events ?? this.events);
  }
}

/// Provider for managing XP gain events
final xpGainOverlayProvider = NotifierProvider<XPGainOverlayNotifier, XPGainOverlayState>(() {
  return XPGainOverlayNotifier();
});

class XPGainOverlayNotifier extends Notifier<XPGainOverlayState> {
  @override
  XPGainOverlayState build() {
    return XPGainOverlayState();
  }
  
  /// Show XP gain overlay
  void showXPGain({
    required int amount,
    required String source,
    String? bonusText,
    bool isLevelUp = false,
    int? newLevel,
    String? newTitle,
  }) {
    final event = XPGainEvent(
      amount: amount,
      source: source,
      bonusText: bonusText,
      isLevelUp: isLevelUp,
      newLevel: newLevel,
      newTitle: newTitle,
    );
    
    state = state.copyWith(events: [...state.events, event]);
    
    // Play sound
    if (isLevelUp) {
      ref.read(soundEffectsProvider).playLevelUp();
    } else {
      ref.read(soundEffectsProvider).playXPGain(amount);
    }
    
    // Auto-remove after animation
    Future.delayed(const Duration(seconds: 3), () {
      removeEvent(event);
    });
  }
  
  void removeEvent(XPGainEvent event) {
    state = state.copyWith(events: state.events.where((e) => e != event).toList());
  }
  
  void clearAll() {
    state = XPGainOverlayState();
  }
}

/// Global XP Gain Overlay Widget
/// 
/// Place this at the root of your app (above your main content)
/// to show XP gain animations anywhere in the app
class XPGainOverlayWidget extends ConsumerWidget {
  final Widget child;

  const XPGainOverlayWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(xpGainOverlayProvider);
    final events = overlayState.events;

    return Stack(
      children: [
        child,
        // XP Gain animations
        ...events.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          return Positioned(
            top: MediaQuery.of(context).padding.top + 60.h + (index * 80.h),
            left: 0,
            right: 0,
            child: Center(
              child: _XPGainAnimation(
                event: event,
                onComplete: () {
                  ref.read(xpGainOverlayProvider.notifier).removeEvent(event);
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _XPGainAnimation extends StatefulWidget {
  final XPGainEvent event;
  final VoidCallback onComplete;

  const _XPGainAnimation({
    required this.event,
    required this.onComplete,
  });

  @override
  State<_XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<_XPGainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Scale in with bounce
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Fade animation
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Bounce for the number
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(_controller);

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Generate particles
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        angle: (i / 12) * 2 * pi + _random.nextDouble() * 0.5,
        speed: 50 + _random.nextDouble() * 50,
        size: 4 + _random.nextDouble() * 4,
        color: _getParticleColor(i),
      ));
    }

    _controller.forward();
    _particleController.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  Color _getParticleColor(int index) {
    final colors = [
      PanAfricanColors.secondary,
      PanAfricanColors.tertiary,
      PanAfricanColors.primaryLight,
      PanAfricanColors.kenteBlue,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _particleController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Particles
                  ..._buildParticles(),
                  // Main XP card
                  _buildXPCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      final progress = _particleController.value;
      final distance = particle.speed * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      return Positioned(
        left: cos(particle.angle) * distance,
        top: sin(particle.angle) * distance,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: particle.color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildXPCard() {
    final isLarge = widget.event.amount >= 100;
    final isLevelUp = widget.event.isLevelUp;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: isLevelUp
            ? PanAfricanGradients.kenteVibrant
            : PanAfricanGradients.celebration,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: [
          BoxShadow(
            color: (isLevelUp ? PanAfricanColors.primaryLight : PanAfricanColors.secondary)
                .withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLevelUp) ...[
            Text(
              '🎉 LEVEL UP! 🎉',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star icon with glow
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: isLarge ? 28.sp : 24.sp,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              // XP amount with bounce
              Transform.scale(
                scale: _bounceAnimation.value,
                child: Text(
                  '+${widget.event.amount}',
                  style: TextStyle(
                    fontSize: isLarge ? 36.sp : 28.sp,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onPrimary,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.xxs),
              Text(
                'XP',
                style: TextStyle(
                  fontSize: isLarge ? 20.sp : 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ),
          if (widget.event.bonusText != null) ...[
            SizedBox(height: PanAfricanSpacing.xxs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Text(
                widget.event.bonusText!,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
          if (isLevelUp && widget.event.newLevel != null) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Level ${widget.event.newLevel}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            if (widget.event.newTitle != null)
              Text(
                '"${widget.event.newTitle}"',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

/// Helper function to show XP gain from anywhere
void showXPGain(
  WidgetRef ref, {
  required int amount,
  required String source,
  String? bonusText,
  bool isLevelUp = false,
  int? newLevel,
  String? newTitle,
}) {
  ref.read(xpGainOverlayProvider.notifier).showXPGain(
    amount: amount,
    source: source,
    bonusText: bonusText,
    isLevelUp: isLevelUp,
    newLevel: newLevel,
    newTitle: newTitle,
  );
}

