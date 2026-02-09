import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../avatar_engine.dart';
import '../emotion_system.dart';
import '../personality_system.dart';

/// Onboarding Avatar Widget - Animated guide for onboarding steps
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
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _loadAvatar();
  }
  
  Future<void> _loadAvatar() async {
    _controller = await AvatarEngine().getOnboardingAvatar(widget.step);
    
    if (mounted) {
      setState(() => _isLoaded = true);
      
      // Play entrance animation
      if (widget.animate) {
        _entranceController.forward();
        _controller?.wave();
      }
      
      // If dialogue is provided, start speaking
      if (widget.showDialogue && widget.dialogue != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _controller?.startSpeaking(text: widget.dialogue);
        });
      }
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final avatarInfo = _getAvatarInfo();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with floating animation
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offset = 5 * _floatController.value;
            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: _buildAvatar(),
        ),
        
        const SizedBox(height: 16),
        
        // Character name and title
        Text(
          avatarInfo.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: avatarInfo.primaryColor,
          ),
        ).animate().fadeIn(delay: 300.ms),
        
        Text(
          avatarInfo.title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(delay: 400.ms),
        
        // Dialogue box
        if (widget.showDialogue && widget.dialogue != null) ...[
          const SizedBox(height: 20),
          _buildDialogueBox(),
        ],
      ],
    );
  }
  
  Widget _buildAvatar() {
    final avatarInfo = _getAvatarInfo();
    
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
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                avatarInfo.primaryColor.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.85,
              height: widget.size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarInfo.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isLoaded && _controller?.artboard != null
                  ? ClipOval(
                      child: Rive(
                        artboard: _controller!.artboard!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _buildFallbackAvatar(avatarInfo),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFallbackAvatar(OnboardingAvatarInfo info) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            info.primaryColor,
            info.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          info.icon,
          size: widget.size * 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildDialogueBox() {
    final avatarInfo = _getAvatarInfo();
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: avatarInfo.primaryColor.withOpacity(0.3),
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
          // Dialogue text with typing animation
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
  
  OnboardingAvatarInfo _getAvatarInfo() {
    return OnboardingAvatarInfo.getForStep(widget.step);
  }
}

/// Typewriter text animation
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

/// Onboarding avatar info
class OnboardingAvatarInfo {
  final OnboardingStep step;
  final String name;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final List<String> defaultDialogues;
  
  const OnboardingAvatarInfo({
    required this.step,
    required this.name,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
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

/// Onboarding avatar sequence controller
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
    if (!isLast) {
      _currentIndex++;
    }
  }
  
  void previous() {
    if (!isFirst) {
      _currentIndex--;
    }
  }
  
  void goTo(int index) {
    if (index >= 0 && index < steps.length) {
      _currentIndex = index;
    }
  }
  
  void reset() {
    _currentIndex = 0;
  }
}
