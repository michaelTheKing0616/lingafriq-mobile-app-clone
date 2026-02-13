import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_avatar_customizer.dart';

/// Tribe information for avatars
class TribeInfo {
  final String id;
  final String name;
  final String emblem;
  final Color primaryColor;
  final Color secondaryColor;
  final String motto;
  
  const TribeInfo({
    required this.id,
    required this.name,
    required this.emblem,
    required this.primaryColor,
    required this.secondaryColor,
    this.motto = '',
  });
  
  static const List<TribeInfo> defaultTribes = [
    TribeInfo(
      id: 'lions',
      name: 'Lions of Sahara',
      emblem: '🦁',
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFFA67C00),
      motto: 'Strength in Unity',
    ),
    TribeInfo(
      id: 'eagles',
      name: 'Eagles of Kilimanjaro',
      emblem: '🦅',
      primaryColor: Color(0xFF3498DB),
      secondaryColor: Color(0xFF2980B9),
      motto: 'Soar Above All',
    ),
    TribeInfo(
      id: 'elephants',
      name: 'Elephants of Congo',
      emblem: '🐘',
      primaryColor: Color(0xFF9B59B6),
      secondaryColor: Color(0xFF7D3C98),
      motto: 'Memory of Ancestors',
    ),
    TribeInfo(
      id: 'leopards',
      name: 'Leopards of Serengeti',
      emblem: '🐆',
      primaryColor: Color(0xFFE67E22),
      secondaryColor: Color(0xFFD35400),
      motto: 'Swift and Silent',
    ),
    TribeInfo(
      id: 'gorillas',
      name: 'Gorillas of Rwanda',
      emblem: '🦍',
      primaryColor: Color(0xFF2ECC71),
      secondaryColor: Color(0xFF27AE60),
      motto: 'Wisdom in Power',
    ),
    TribeInfo(
      id: 'rhinos',
      name: 'Rhinos of Kruger',
      emblem: '🦏',
      primaryColor: Color(0xFF95A5A6),
      secondaryColor: Color(0xFF7F8C8D),
      motto: 'Unstoppable Force',
    ),
  ];
  
  static TribeInfo? getById(String id) {
    try {
      return defaultTribes.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Tribe Avatar Widget - Shows avatar with tribe emblem and colors
class TribeAvatarWidget extends StatelessWidget {
  final UserAvatarConfig userConfig;
  final TribeInfo tribe;
  final double size;
  final bool showEmblem;
  final bool showName;
  final bool isLeader;
  final int? rank;
  
  const TribeAvatarWidget({
    super.key,
    required this.userConfig,
    required this.tribe,
    this.size = 80,
    this.showEmblem = true,
    this.showName = false,
    this.isLeader = false,
    this.rank,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar with tribe border
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tribe.primaryColor, tribe.secondaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: tribe.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: UserAvatarDisplay(
                config: userConfig,
                size: size - 6,
                showBorder: false,
              ),
            ),
            
            // Tribe emblem
            if (showEmblem)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    tribe.emblem,
                    style: TextStyle(fontSize: size * 0.25),
                  ),
                ),
              ),
            
            // Leader badge
            if (isLeader)
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    size: size * 0.2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            
            // Rank badge
            if (rank != null)
              Positioned(
                left: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRankColor(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Name
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            tribe.name,
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.w600,
              color: tribe.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
  
  Color _getRankColor() {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[400]!;
    return Colors.blueGrey;
  }
}

/// Battle Avatar Widget - For tribe vs tribe competitions
class BattleAvatarWidget extends StatefulWidget {
  final UserAvatarConfig userConfig;
  final TribeInfo tribe;
  final double size;
  final BattleState state;
  final VoidCallback? onReady;
  
  const BattleAvatarWidget({
    super.key,
    required this.userConfig,
    required this.tribe,
    this.size = 100,
    this.state = BattleState.idle,
    this.onReady,
  });
  
  @override
  State<BattleAvatarWidget> createState() => _BattleAvatarWidgetState();
}

class _BattleAvatarWidgetState extends State<BattleAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }
  
  @override
  void didUpdateWidget(BattleAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _animController.forward(from: 0);
    }
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Battle state indicator
        _buildStateIndicator(),
        
        const SizedBox(height: 8),
        
        // Avatar with battle effects
        Stack(
          alignment: Alignment.center,
          children: [
            // Battle aura
            if (widget.state == BattleState.attacking || 
                widget.state == BattleState.victory)
              _buildBattleAura(),
            
            // Main avatar
            TribeAvatarWidget(
              userConfig: widget.userConfig,
              tribe: widget.tribe,
              size: widget.size,
              showEmblem: true,
            ),
            
            // Victory effect
            if (widget.state == BattleState.victory)
              _buildVictoryEffect(),
            
            // Defeat effect
            if (widget.state == BattleState.defeat)
              _buildDefeatEffect(),
          ],
        ),
        
        // Ready button
        if (widget.state == BattleState.waiting && widget.onReady != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ElevatedButton(
              onPressed: widget.onReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.tribe.primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Ready!'),
            ),
          ),
      ],
    );
  }
  
  Widget _buildStateIndicator() {
    IconData icon;
    Color color;
    String label;
    
    switch (widget.state) {
      case BattleState.idle:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
        label = 'Waiting';
        break;
      case BattleState.waiting:
        icon = Icons.timer;
        color = Colors.orange;
        label = 'Get Ready';
        break;
      case BattleState.ready:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Ready';
        break;
      case BattleState.attacking:
        icon = Icons.flash_on;
        color = widget.tribe.primaryColor;
        label = 'Attacking';
        break;
      case BattleState.defending:
        icon = Icons.shield;
        color = Colors.blue;
        label = 'Defending';
        break;
      case BattleState.victory:
        icon = Icons.emoji_events;
        color = Colors.amber;
        label = 'Victory!';
        break;
      case BattleState.defeat:
        icon = Icons.sentiment_dissatisfied;
        color = Colors.grey;
        label = 'Defeated';
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBattleAura() {
    return Container(
      width: widget.size * 1.3,
      height: widget.size * 1.3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.tribe.primaryColor.withOpacity(0.5),
            widget.tribe.primaryColor.withOpacity(0.0),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 500.ms);
  }
  
  Widget _buildVictoryEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(),
        ),
      ),
    ).animate().fadeIn();
  }
  
  Widget _buildDefeatEffect() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.5),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

/// Battle states
enum BattleState {
  idle,
  waiting,
  ready,
  attacking,
  defending,
  victory,
  defeat,
}

/// Simple confetti painter
class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [Colors.amber, Colors.orange, Colors.yellow, Colors.red];
    
    for (int i = 0; i < 20; i++) {
      paint.color = colors[i % colors.length];
      final x = (i * 17) % size.width;
      final y = (i * 23) % size.height;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Voice room avatar with speaking indicator
class VoiceRoomAvatar extends StatelessWidget {
  final UserAvatarConfig userConfig;
  final TribeInfo? tribe;
  final double size;
  final bool isSpeaking;
  final bool isMuted;
  final String? username;
  
  const VoiceRoomAvatar({
    super.key,
    required this.userConfig,
    this.tribe,
    this.size = 70,
    this.isSpeaking = false,
    this.isMuted = false,
    this.username,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Speaking ring animation
            if (isSpeaking)
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green,
                    width: 3,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 500.ms),
            
            // Avatar
            Padding(
              padding: const EdgeInsets.all(4),
              child: tribe != null
                  ? TribeAvatarWidget(
                      userConfig: userConfig,
                      tribe: tribe!,
                      size: size,
                      showEmblem: false,
                    )
                  : UserAvatarDisplay(
                      config: userConfig,
                      size: size,
                    ),
            ),
            
            // Muted indicator
            if (isMuted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_off,
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        
        if (username != null) ...[
          const SizedBox(height: 4),
          Text(
            username!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSpeaking ? FontWeight.bold : FontWeight.normal,
              color: isSpeaking ? Colors.green : Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
