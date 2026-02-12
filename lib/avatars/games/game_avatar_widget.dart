import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../avatar_engine.dart';
import '../emotion_system.dart';
import '../personality_system.dart';

/// Game Avatar Widget - Displays the appropriate avatar for each game category
class GameAvatarWidget extends StatefulWidget {
  final GameCategory category;
  final double size;
  final bool showSpeechBubble;
  final String? message;
  final VoidCallback? onTap;
  final bool isMinimized;
  
  const GameAvatarWidget({
    super.key,
    required this.category,
    this.size = 120,
    this.showSpeechBubble = false,
    this.message,
    this.onTap,
    this.isMinimized = false,
  });
  
  @override
  State<GameAvatarWidget> createState() => _GameAvatarWidgetState();
}

class _GameAvatarWidgetState extends State<GameAvatarWidget>
    with SingleTickerProviderStateMixin {
  AvatarController? _controller;
  late AnimationController _bounceController;
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAvatar();
  }
  
  Future<void> _loadAvatar() async {
    _controller = await AvatarEngine().getGameAvatar(widget.category);
    if (mounted) {
      setState(() => _isLoaded = true);
    }
  }
  
  @override
  void didUpdateWidget(GameAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadAvatar();
    }
  }
  
  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.isMinimized ? widget.size * 0.6 : widget.size;
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: effectiveSize,
        height: widget.showSpeechBubble ? effectiveSize + 60 : effectiveSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Avatar
            Positioned(
              bottom: widget.showSpeechBubble ? 0 : null,
              child: _buildAvatar(effectiveSize),
            ),
            
            // Speech bubble
            if (widget.showSpeechBubble && widget.message != null)
              Positioned(
                top: 0,
                child: _buildSpeechBubble(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatar(double size) {
    if (!_isLoaded || _controller?.artboard == null) {
      return _buildFallbackAvatar(size);
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
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
  
  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(),
            _getCategoryColor().withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds);
  }
  
  Widget _buildSpeechBubble() {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.size * 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.message!,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.2, end: 0);
  }
  
  Color _getCategoryColor() {
    switch (widget.category) {
      case GameCategory.vocabulary:
        return const Color(0xFF00D4AA); // Teal for Malaika
      case GameCategory.cultural:
        return const Color(0xFFD4AF37); // Gold for Baba
      case GameCategory.pronunciation:
        return const Color(0xFF9B59B6); // Purple for Okonkwo
      case GameCategory.grammar:
        return const Color(0xFF3498DB); // Blue for Nneka
    }
  }
  
  IconData _getCategoryIcon() {
    switch (widget.category) {
      case GameCategory.vocabulary:
        return Icons.auto_stories;
      case GameCategory.cultural:
        return Icons.public;
      case GameCategory.pronunciation:
        return Icons.record_voice_over;
      case GameCategory.grammar:
        return Icons.format_shapes;
    }
  }
  
  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward().then((_) => _bounceController.reverse());
    _controller?.wave();
    widget.onTap?.call();
  }
  
  /// Public methods to control the avatar
  
  void celebrate() => _controller?.celebrate();
  
  void showDisappointment() {
    _controller?.setEmotion(AvatarEmotion.disappointed);
    Future.delayed(const Duration(seconds: 2), () {
      _controller?.setEmotion(AvatarEmotion.encouraging);
    });
  }
  
  void showEncouragement() {
    _controller?.setEmotion(AvatarEmotion.encouraging, intensity: EmotionIntensity.strong);
  }
  
  void setThinking() => _controller?.setEmotion(AvatarEmotion.thinking);
  
  void setIdle() => _controller?.setEmotion(AvatarEmotion.idle);
}

/// Game avatar controller for external state management
class GameAvatarController {
  AvatarController? _avatarController;
  final GameCategory category;
  
  GameAvatarController(this.category);
  
  Future<void> initialize() async {
    _avatarController = await AvatarEngine().getGameAvatar(category);
  }
  
  void reactToCorrectAnswer({bool isPerfect = false}) {
    if (isPerfect) {
      _avatarController?.celebrate();
    } else {
      _avatarController?.setEmotion(AvatarEmotion.proud, intensity: EmotionIntensity.strong);
    }
  }
  
  void reactToIncorrectAnswer() {
    _avatarController?.setEmotion(AvatarEmotion.disappointed);
    Future.delayed(const Duration(milliseconds: 1500), () {
      _avatarController?.setEmotion(AvatarEmotion.encouraging);
    });
  }
  
  void showHint() {
    _avatarController?.setEmotion(AvatarEmotion.thinking);
    _avatarController?.startSpeaking(duration: const Duration(seconds: 2));
  }
  
  void setListening() => _avatarController?.startListening();
  void setIdle() => _avatarController?.setEmotion(AvatarEmotion.idle);
  
  String getEncouragement(String context) {
    return _avatarController?.getEncouragement(context) ?? 'Keep going!';
  }
  
  void dispose() {
    // Controller is managed by AvatarEngine
  }
}

/// Category avatar info for game selection screens
class CategoryAvatarInfo {
  final GameCategory category;
  final String name;
  final String title;
  final String description;
  final Color primaryColor;
  final IconData icon;
  
  const CategoryAvatarInfo({
    required this.category,
    required this.name,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.icon,
  });
  
  static const List<CategoryAvatarInfo> all = [
    CategoryAvatarInfo(
      category: GameCategory.vocabulary,
      name: 'Malaika',
      title: 'Vocabulary Guide',
      description: 'Playful word explorer',
      primaryColor: Color(0xFF00D4AA),
      icon: Icons.auto_stories,
    ),
    CategoryAvatarInfo(
      category: GameCategory.cultural,
      name: 'Baba',
      title: 'Cultural Elder',
      description: 'Wise keeper of traditions',
      primaryColor: Color(0xFFD4AF37),
      icon: Icons.public,
    ),
    CategoryAvatarInfo(
      category: GameCategory.pronunciation,
      name: 'Okonkwo',
      title: 'Tone Master',
      description: 'Precise pronunciation guide',
      primaryColor: Color(0xFF9B59B6),
      icon: Icons.record_voice_over,
    ),
    CategoryAvatarInfo(
      category: GameCategory.grammar,
      name: 'Nneka',
      title: 'Grammar Teacher',
      description: 'Methodical sentence builder',
      primaryColor: Color(0xFF3498DB),
      icon: Icons.format_shapes,
    ),
  ];
  
  static CategoryAvatarInfo getForCategory(GameCategory category) {
    return all.firstWhere((info) => info.category == category);
  }
}
