import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../avatar_engine.dart';
import '../emotion_system.dart';
import '../personality_system.dart';

/// Onboarding Avatar Widget - Animated guide for onboarding steps
///
/// Loads a Rive avatar if .riv assets exist; otherwise renders a polished
/// character portrait fallback with layered gradients, glow, and themed icons.
/// The entrance animation fires unconditionally so the widget is never invisible.
class OnboardingAvatarWidget extends StatefulWidget {
  final OnboardingStep step;
  final double size;
  final bool showDialogue;
  final String? dialogue;
  final bool animate;
  final VoidCallback? onDialogueComplete;

  const OnboardingAvatarWidget({
    super.key,
    required this.step,
    this.size = 180,
    this.showDialogue = false,
    this.dialogue,
    this.animate = true,
    this.onDialogueComplete,
  });

  @override
  State<OnboardingAvatarWidget> createState() => _OnboardingAvatarWidgetState();
}

class _OnboardingAvatarWidgetState extends State<OnboardingAvatarWidget>
    with TickerProviderStateMixin {
  AvatarController? _controller;
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  bool _hasRiveArtboard = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      _controller = await AvatarEngine().getOnboardingAvatar(widget.step);
      if (mounted) {
        final hasArtboard = _controller?.artboard != null;
        setState(() => _hasRiveArtboard = hasArtboard);
        _controller?.wave();
        if (widget.showDialogue && widget.dialogue != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _controller?.startSpeaking(text: widget.dialogue);
          });
        }
      }
    } catch (_) {
      // Rive load failed — fallback renders automatically
    }

    // CRITICAL: Always fire entrance animation so widget is never invisible
    if (mounted && widget.animate) {
      _entranceController.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _entranceController.reset();
      _loadAvatar();
    }
    if (oldWidget.dialogue != widget.dialogue && widget.dialogue != null) {
      _controller?.startSpeaking(text: widget.dialogue);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = OnboardingAvatarInfo.getForStep(widget.step);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with floating animation
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offset = 5.0 * _floatController.value;
            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: _buildAvatar(info),
        ),

        const SizedBox(height: 16),

        // Character name
        Text(
          info.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: info.primaryColor,
          ),
        ).animate().fadeIn(delay: 300.ms),

        // Title
        Text(
          info.title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(delay: 400.ms),

        // Dialogue box
        if (widget.showDialogue && widget.dialogue != null) ...[
          const SizedBox(height: 20),
          _buildDialogueBox(info),
        ],
      ],
    );
  }

  // ─── Avatar (Rive or Fallback) ────────────────────────────────────────
  Widget _buildAvatar(OnboardingAvatarInfo info) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      )),
      child: FadeTransition(
        opacity: _entranceController,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: _hasRiveArtboard
              ? _buildRiveAvatar(info)
              : _buildCharacterPortrait(info),
        ),
      ),
    );
  }

  Widget _buildRiveAvatar(OnboardingAvatarInfo info) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: info.primaryColor.withOpacity(0.3),
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

  /// Rich character portrait — multi-layer design:
  ///   1. Outer pulsing glow ring
  ///   2. Decorative dashed orbit
  ///   3. Gradient-filled circle
  ///   4. Character emoji at centre
  ///   5. Themed icon badge in bottom-right
  Widget _buildCharacterPortrait(OnboardingAvatarInfo info) {
    final innerSize = widget.size * 0.78;
    final badgeSize = widget.size * 0.28;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.92 + 0.08 * _pulseController.value;
        return Transform.scale(scale: pulse, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  info.primaryColor.withOpacity(0.25),
                  info.primaryColor.withOpacity(0.08),
                  Colors.transparent,
                ],
                stops: const [0.6, 0.85, 1.0],
              ),
            ),
          ),

          // Decorative ring
          CustomPaint(
            size: Size(widget.size * 0.92, widget.size * 0.92),
            painter: _OrbitRingPainter(
              color: info.primaryColor.withOpacity(0.3),
              dotCount: 12,
            ),
          ),

          // Main circle with gradient
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  info.primaryColor,
                  info.secondaryColor,
                  info.secondaryColor.withOpacity(0.85),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.35),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: info.primaryColor.withOpacity(0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: info.secondaryColor.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                info.characterEmoji,
                style: TextStyle(fontSize: innerSize * 0.42),
              ),
            ),
          ),

          // Inner highlight (top-left shine)
          Positioned(
            top: widget.size * 0.14,
            left: widget.size * 0.18,
            child: Container(
              width: innerSize * 0.22,
              height: innerSize * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.45),
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Icon badge (bottom-right)
          Positioned(
            bottom: widget.size * 0.02,
            right: widget.size * 0.06,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: info.primaryColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                info.icon,
                size: badgeSize * 0.55,
                color: info.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogue Box ─────────────────────────────────────────────────────
  Widget _buildDialogueBox(OnboardingAvatarInfo info) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: info.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _TypewriterText(
            text: widget.dialogue!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.5,
            ),
            onComplete: widget.onDialogueComplete,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Decorative orbit-ring painter
// ═══════════════════════════════════════════════════════════════════════════
class _OrbitRingPainter extends CustomPainter {
  final Color color;
  final int dotCount;

  _OrbitRingPainter({required this.color, this.dotCount = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dashed ring
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centre, radius, ringPaint);

    // Small dots around the ring
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < dotCount; i++) {
      final angle = (2 * pi * i) / dotCount;
      final dx = centre.dx + radius * cos(angle);
      final dy = centre.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Typewriter text animation
// ═══════════════════════════════════════════════════════════════════════════
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const _TypewriterText({
    required this.text,
    this.style,
    this.onComplete,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _displayedText = '';
      _currentIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    Future.doWhile(() async {
      if (_currentIndex >= widget.text.length) {
        widget.onComplete?.call();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      }
      return mounted && _currentIndex < widget.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Onboarding avatar info — per-step character data
// ═══════════════════════════════════════════════════════════════════════════
class OnboardingAvatarInfo {
  final OnboardingStep step;
  final String name;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  /// Rich emoji representing the character visually
  final String characterEmoji;
  final List<String> defaultDialogues;

  const OnboardingAvatarInfo({
    required this.step,
    required this.name,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.characterEmoji,
    this.defaultDialogues = const [],
  });

  static const Map<OnboardingStep, OnboardingAvatarInfo> _info = {
    OnboardingStep.welcome: OnboardingAvatarInfo(
      step: OnboardingStep.welcome,
      name: 'Pa LingAfriq',
      title: 'Village Elder',
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFFA67C00),
      icon: Icons.elderly,
      characterEmoji: '👴🏿',
      defaultDialogues: [
        'Welcome, young one, to our village of languages.',
        'I am Pa LingAfriq, guardian of our ancestral tongues.',
        'Your journey to connect with your roots begins here.',
      ],
    ),
    OnboardingStep.languageSelection: OnboardingAvatarInfo(
      step: OnboardingStep.languageSelection,
      name: 'Adisa',
      title: 'The Weaver',
      primaryColor: Color(0xFF00D4AA),
      secondaryColor: Color(0xFF00A88A),
      icon: Icons.language,
      characterEmoji: '🧑🏿‍🎨',
      defaultDialogues: [
        'I am Adisa, weaver of words and keeper of tongues.',
        'Each language is a thread in the tapestry of Africa.',
        'Which thread shall we weave into your story?',
      ],
    ),
    OnboardingStep.goals: OnboardingAvatarInfo(
      step: OnboardingStep.goals,
      name: 'Zuri',
      title: 'The Pathfinder',
      primaryColor: Color(0xFF9B59B6),
      secondaryColor: Color(0xFF7D3C98),
      icon: Icons.explore,
      characterEmoji: '🧭',
      defaultDialogues: [
        'Greetings, traveler! I am Zuri, your pathfinder.',
        'Every great journey needs a destination.',
        'What brings you to learn this beautiful language?',
      ],
    ),
    OnboardingStep.schedule: OnboardingAvatarInfo(
      step: OnboardingStep.schedule,
      name: 'Kofi',
      title: 'The Timekeeper',
      primaryColor: Color(0xFF3498DB),
      secondaryColor: Color(0xFF2980B9),
      icon: Icons.schedule,
      characterEmoji: '⏳',
      defaultDialogues: [
        'I am Kofi, keeper of time and rhythm.',
        'Consistency is the heartbeat of learning.',
        'How much time can you dedicate each day?',
      ],
    ),
    OnboardingStep.story: OnboardingAvatarInfo(
      step: OnboardingStep.story,
      name: 'Amara',
      title: 'The Griot',
      primaryColor: Color(0xFFE74C3C),
      secondaryColor: Color(0xFFC0392B),
      icon: Icons.auto_stories,
      characterEmoji: '📖',
      defaultDialogues: [
        'Ah, a new student! I am Amara, the griot.',
        'Let me tell you the story of our languages...',
        'For in every word lies the wisdom of generations.',
      ],
    ),
    OnboardingStep.learningStyle: OnboardingAvatarInfo(
      step: OnboardingStep.learningStyle,
      name: 'Nuru',
      title: 'The Rhythm Master',
      primaryColor: Color(0xFFFF6B35),
      secondaryColor: Color(0xFFE85D26),
      icon: Icons.music_note_rounded,
      characterEmoji: '🥁',
      defaultDialogues: [
        'Language is music, traveler!',
        'Each soul dances differently to the rhythm of words.',
        'How does your spirit best receive knowledge?',
      ],
    ),
    OnboardingStep.profile: OnboardingAvatarInfo(
      step: OnboardingStep.profile,
      name: 'Pa LingAfriq',
      title: 'Village Elder',
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFFA67C00),
      icon: Icons.person_add_rounded,
      characterEmoji: '🪪',
      defaultDialogues: [
        'Now it is time for your naming ceremony.',
        'Every villager must have a name.',
        'Choose wisely — it will be known across the village.',
      ],
    ),
    OnboardingStep.complete: OnboardingAvatarInfo(
      step: OnboardingStep.complete,
      name: 'Pa LingAfriq',
      title: 'Village Elder',
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFFA67C00),
      icon: Icons.celebration,
      characterEmoji: '🎉',
      defaultDialogues: [
        'You are now part of our village!',
        'May your journey be filled with discovery.',
        'The ancestors smile upon your dedication.',
      ],
    ),
  };

  static OnboardingAvatarInfo getForStep(OnboardingStep step) {
    return _info[step]!;
  }

  String getRandomDialogue() {
    if (defaultDialogues.isEmpty) return '';
    final index = DateTime.now().millisecondsSinceEpoch % defaultDialogues.length;
    return defaultDialogues[index];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Onboarding avatar sequence controller
// ═══════════════════════════════════════════════════════════════════════════
class OnboardingAvatarSequence {
  final List<OnboardingStep> steps;
  int _currentIndex = 0;

  OnboardingAvatarSequence({
    this.steps = const [
      OnboardingStep.welcome,
      OnboardingStep.languageSelection,
      OnboardingStep.goals,
      OnboardingStep.schedule,
      OnboardingStep.story,
      OnboardingStep.complete,
    ],
  });

  OnboardingStep get currentStep => steps[_currentIndex];
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == steps.length - 1;
  int get currentIndex => _currentIndex;
  int get totalSteps => steps.length;

  void next() {
    if (!isLast) _currentIndex++;
  }

  void previous() {
    if (!isFirst) _currentIndex--;
  }

  void goTo(int index) {
    if (index >= 0 && index < steps.length) _currentIndex = index;
  }

  void reset() => _currentIndex = 0;
}
