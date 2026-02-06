import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../avatar_engine.dart';
import '../emotion_system.dart';
import '../polie/polie_avatar.dart';

/// Gamification avatar overlay position
enum AvatarOverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter,
}

/// Gamification Avatar Overlay Widget
/// Persistent overlay that reacts to all gamification events
class GamificationAvatarOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final AvatarOverlayPosition position;
  final double avatarSize;
  final bool showOnStart;
  final bool allowMinimize;
  
  const GamificationAvatarOverlay({
    super.key,
    required this.child,
    this.position = AvatarOverlayPosition.bottomRight,
    this.avatarSize = 80,
    this.showOnStart = true,
    this.allowMinimize = true,
  });
  
  @override
  ConsumerState<GamificationAvatarOverlay> createState() => _GamificationAvatarOverlayState();
}

class _GamificationAvatarOverlayState extends ConsumerState<GamificationAvatarOverlay>
    with TickerProviderStateMixin {
  AvatarController? _controller;
  bool _isVisible = true;
  bool _isMinimized = false;
  bool _isExpanded = false;
  String? _currentMessage;
  late AnimationController _bounceController;
  late AnimationController _messageController;
  Timer? _messageTimer;
  
  @override
  void initState() {
    super.initState();
    _isVisible = widget.showOnStart;
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _initializeAvatar();
  }
  
  Future<void> _initializeAvatar() async {
    _controller = await AvatarEngine().getController(AvatarType.polie, instanceId: 'gamification_overlay');
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    _bounceController.dispose();
    _messageController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Avatar overlay
        if (_isVisible)
          Positioned(
            left: _getLeftPosition(),
            right: _getRightPosition(),
            top: _getTopPosition(),
            bottom: _getBottomPosition(),
            child: _buildAvatarOverlay(),
          ),
      ],
    );
  }
  
  Widget _buildAvatarOverlay() {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.allowMinimize ? _toggleMinimize : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message bubble
            if (_currentMessage != null && !_isMinimized)
              _buildMessageBubble(),
            
            // Avatar
            _buildAvatar(),
            
            // Quick stats when expanded
            if (_isExpanded && !_isMinimized)
              _buildQuickStats(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    final size = _isMinimized ? widget.avatarSize * 0.6 : widget.avatarSize;
    
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Curves.elasticOut,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: PolieAvatarColors.electricTeal.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: PolieAvatarCompact(
          size: size,
          controller: _controller,
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble() {
    return FadeTransition(
      opacity: _messageController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(_messageController),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: Colors.white,
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
            _currentMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(Icons.local_fire_department, '7 Day Streak', Colors.orange),
          const SizedBox(height: 8),
          _buildStatRow(Icons.bolt, '150 XP Today', PolieAvatarColors.electricTeal),
          const SizedBox(height: 8),
          _buildStatRow(Icons.emoji_events, 'Gold League', Colors.amber),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
  
  Widget _buildStatRow(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  // Position helpers
  double? _getLeftPosition() {
    switch (widget.position) {
      case AvatarOverlayPosition.topLeft:
      case AvatarOverlayPosition.bottomLeft:
        return 16;
      case AvatarOverlayPosition.topCenter:
      case AvatarOverlayPosition.bottomCenter:
        return null;
      default:
        return null;
    }
  }
  
  double? _getRightPosition() {
    switch (widget.position) {
      case AvatarOverlayPosition.topRight:
      case AvatarOverlayPosition.bottomRight:
        return 16;
      case AvatarOverlayPosition.topCenter:
      case AvatarOverlayPosition.bottomCenter:
        return null;
      default:
        return null;
    }
  }
  
  double? _getTopPosition() {
    switch (widget.position) {
      case AvatarOverlayPosition.topLeft:
      case AvatarOverlayPosition.topRight:
      case AvatarOverlayPosition.topCenter:
        return MediaQuery.of(context).padding.top + 16;
      default:
        return null;
    }
  }
  
  double? _getBottomPosition() {
    switch (widget.position) {
      case AvatarOverlayPosition.bottomLeft:
      case AvatarOverlayPosition.bottomRight:
      case AvatarOverlayPosition.bottomCenter:
        return MediaQuery.of(context).padding.bottom + 16;
      default:
        return null;
    }
  }
  
  // Interaction handlers
  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    _controller?.wave();
  }
  
  void _toggleMinimize() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMinimized = !_isMinimized;
      _isExpanded = false;
    });
  }
  
  // Public methods for external control
  
  void show() {
    setState(() => _isVisible = true);
  }
  
  void hide() {
    setState(() => _isVisible = false);
  }
  
  void showMessage(String message, {Duration duration = const Duration(seconds: 3)}) {
    setState(() => _currentMessage = message);
    _messageController.forward();
    
    _messageTimer?.cancel();
    _messageTimer = Timer(duration, () {
      if (mounted) {
        _messageController.reverse().then((_) {
          if (mounted) {
            setState(() => _currentMessage = null);
          }
        });
      }
    });
  }
  
  void reactToXPGain(int amount) {
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    if (amount >= 50) {
      _controller?.celebrate();
      showMessage('Amazing! +$amount XP!');
    } else {
      _controller?.setEmotion(AvatarEmotion.happy);
      showMessage('+$amount XP');
    }
  }
  
  void reactToLevelUp(int newLevel) {
    _controller?.playReactionSequence(AvatarReaction.levelUp);
    showMessage('Level $newLevel! You\'re growing stronger!', duration: const Duration(seconds: 5));
  }
  
  void reactToStreakMilestone(int streak) {
    _controller?.playReactionSequence(AvatarReaction.streakMilestone);
    showMessage('$streak day streak! Keep it up!', duration: const Duration(seconds: 4));
  }
  
  void reactToBadgeUnlock(String badgeName) {
    _controller?.celebrate();
    showMessage('Badge unlocked: $badgeName!', duration: const Duration(seconds: 4));
  }
  
  void reactToCorrectAnswer() {
    _controller?.setEmotion(AvatarEmotion.proud);
    _bounceController.forward().then((_) => _bounceController.reverse());
  }
  
  void reactToIncorrectAnswer() {
    _controller?.setEmotion(AvatarEmotion.empathetic);
    Future.delayed(const Duration(seconds: 2), () {
      _controller?.setEmotion(AvatarEmotion.encouraging);
    });
  }
}

/// Provider for gamification avatar overlay key
final gamificationAvatarKeyProvider = Provider<GlobalKey<_GamificationAvatarOverlayState>>((ref) {
  return GlobalKey<_GamificationAvatarOverlayState>();
});

/// Achievement presenter widget
class AchievementAvatarPresenter extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;
  
  const AchievementAvatarPresenter({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color = PolieAvatarColors.goldEmber,
    this.onDismiss,
  });
  
  @override
  State<AchievementAvatarPresenter> createState() => _AchievementAvatarPresenterState();
}

class _AchievementAvatarPresenterState extends State<AchievementAvatarPresenter> {
  @override
  void initState() {
    super.initState();
    
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Polie celebrating
          const PolieAvatar(
            size: 120,
            showParticles: true,
          ),
          
          const SizedBox(height: 20),
          
          // Achievement card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.1),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms)
            .fadeIn(),
          
          const SizedBox(height: 20),
          
          // Dismiss button
          TextButton(
            onPressed: widget.onDismiss,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
