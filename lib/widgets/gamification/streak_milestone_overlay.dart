import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/pan_african_design_system.dart';
import '../../services/sound_effects_service.dart';

/// Data class for a streak milestone celebration event.
class StreakMilestoneEvent {
  final int streakCount;
  final String milestoneName;
  final DateTime timestamp;

  StreakMilestoneEvent({
    required this.streakCount,
    required this.milestoneName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// State class for the streak milestone overlay.
class StreakMilestoneOverlayState {
  final List<StreakMilestoneEvent> events;

  StreakMilestoneOverlayState({List<StreakMilestoneEvent>? events})
      : events = events ?? [];

  StreakMilestoneOverlayState copyWith({List<StreakMilestoneEvent>? events}) {
    return StreakMilestoneOverlayState(events: events ?? this.events);
  }
}

/// Provider for managing streak milestone celebration events.
final streakMilestoneOverlayProvider =
    NotifierProvider<StreakMilestoneOverlayNotifier, StreakMilestoneOverlayState>(
        () {
  return StreakMilestoneOverlayNotifier();
});

class StreakMilestoneOverlayNotifier
    extends Notifier<StreakMilestoneOverlayState> {
  static const Map<int, String> _milestoneNames = {
    7: 'One Week Warrior',
    14: 'Two Week Champion',
    30: 'Monthly Master',
    60: 'Two Month Legend',
    100: 'Century Learner',
    365: 'Year of Mastery',
  };

  @override
  StreakMilestoneOverlayState build() {
    return StreakMilestoneOverlayState();
  }

  /// Show a streak milestone celebration overlay.
  void showMilestone({required int streakCount}) {
    final name = _milestoneNames[streakCount] ?? '$streakCount Day Streak';
    final event = StreakMilestoneEvent(
      streakCount: streakCount,
      milestoneName: name,
    );

    state = state.copyWith(events: [...state.events, event]);

    // Play level-up sound for milestone celebrations
    try {
      ref.read(soundEffectsProvider).playLevelUp();
    } catch (_) {
      // Sound service may not be available
    }

    // Auto-remove after animation completes
    Future.delayed(const Duration(seconds: 4), () {
      removeEvent(event);
    });
  }

  void removeEvent(StreakMilestoneEvent event) {
    state = state.copyWith(
        events: state.events.where((e) => e != event).toList());
  }

  void clearAll() {
    state = StreakMilestoneOverlayState();
  }
}

/// Overlay widget that shows streak milestone celebrations.
///
/// Place this at the root of your app (wrapping main content)
/// to show streak milestone animations anywhere in the app.
class StreakMilestoneOverlayWidget extends ConsumerWidget {
  final Widget child;

  const StreakMilestoneOverlayWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(streakMilestoneOverlayProvider);
    final events = overlayState.events;

    return Stack(
      children: [
        child,
        ...events.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          return Positioned(
            top: MediaQuery.of(context).padding.top + 60.h + (index * 100.h),
            left: 0,
            right: 0,
            child: Center(
              child: _StreakMilestoneAnimation(
                event: event,
                onComplete: () {
                  ref
                      .read(streakMilestoneOverlayProvider.notifier)
                      .removeEvent(event);
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StreakMilestoneAnimation extends StatefulWidget {
  final StreakMilestoneEvent event;
  final VoidCallback onComplete;

  const _StreakMilestoneAnimation({
    required this.event,
    required this.onComplete,
  });

  @override
  State<_StreakMilestoneAnimation> createState() =>
      _StreakMilestoneAnimationState();
}

class _StreakMilestoneAnimationState extends State<_StreakMilestoneAnimation>
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

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(_controller);

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    for (int i = 0; i < 16; i++) {
      _particles.add(_Particle(
        angle: (i / 16) * 2 * pi + _random.nextDouble() * 0.5,
        speed: 60 + _random.nextDouble() * 60,
        size: 4 + _random.nextDouble() * 5,
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
      const Color(0xFFFF6B35), // Fire orange
      const Color(0xFFFFD700), // Gold
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
                  ..._buildParticles(),
                  _buildMilestoneCard(),
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

  Widget _buildMilestoneCard() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xl,
        vertical: PanAfricanSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.kenteVibrant,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: [
          BoxShadow(
            color: PanAfricanColors.primaryLight.withOpacity(0.5),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥 STREAK MILESTONE 🔥',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Transform.scale(
            scale: _bounceAnimation.value,
            child: Text(
              '${widget.event.streakCount}',
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onPrimary,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'Day Streak!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.xs,
            ),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Text(
              widget.event.milestoneName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            'Keep it up!',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
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

/// Helper function to show streak milestone celebration from anywhere.
void showStreakMilestone(WidgetRef ref, {required int streakCount}) {
  ref
      .read(streakMilestoneOverlayProvider.notifier)
      .showMilestone(streakCount: streakCount);
}
