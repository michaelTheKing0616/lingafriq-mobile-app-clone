import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../avatar_providers.dart';

/// User avatar customization options
class UserAvatarConfig {
  final String baseStyle;
  final int skinTone;
  final int hairStyle;
  final int hairColor;
  final int outfit;
  final int accessory;
  final String? tribeEmblem;
  final int expressionStyle;
  
  const UserAvatarConfig({
    this.baseStyle = 'default',
    this.skinTone = 0,
    this.hairStyle = 0,
    this.hairColor = 0,
    this.outfit = 0,
    this.accessory = 0,
    this.tribeEmblem,
    this.expressionStyle = 0,
  });
  
  UserAvatarConfig copyWith({
    String? baseStyle,
    int? skinTone,
    int? hairStyle,
    int? hairColor,
    int? outfit,
    int? accessory,
    String? tribeEmblem,
    int? expressionStyle,
  }) {
    return UserAvatarConfig(
      baseStyle: baseStyle ?? this.baseStyle,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
      tribeEmblem: tribeEmblem ?? this.tribeEmblem,
      expressionStyle: expressionStyle ?? this.expressionStyle,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'baseStyle': baseStyle,
    'skinTone': skinTone,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
    'outfit': outfit,
    'accessory': accessory,
    'tribeEmblem': tribeEmblem,
    'expressionStyle': expressionStyle,
  };
  
  factory UserAvatarConfig.fromJson(Map<String, dynamic> json) {
    return UserAvatarConfig(
      baseStyle: json['baseStyle'] ?? 'default',
      skinTone: json['skinTone'] ?? 0,
      hairStyle: json['hairStyle'] ?? 0,
      hairColor: json['hairColor'] ?? 0,
      outfit: json['outfit'] ?? 0,
      accessory: json['accessory'] ?? 0,
      tribeEmblem: json['tribeEmblem'],
      expressionStyle: json['expressionStyle'] ?? 0,
    );
  }
}

/// Skin tone options
class SkinToneOption {
  final int id;
  final String name;
  final Color color;
  
  const SkinToneOption(this.id, this.name, this.color);
  
  static const List<SkinToneOption> options = [
    SkinToneOption(0, 'Ebony', Color(0xFF3D2314)),
    SkinToneOption(1, 'Mahogany', Color(0xFF5C4033)),
    SkinToneOption(2, 'Caramel', Color(0xFF8B6914)),
    SkinToneOption(3, 'Honey', Color(0xFFB8860B)),
    SkinToneOption(4, 'Almond', Color(0xFFD2B48C)),
    SkinToneOption(5, 'Sand', Color(0xFFE6C9A8)),
  ];
}

/// Hair style options
class HairStyleOption {
  final int id;
  final String name;
  final IconData icon;
  
  const HairStyleOption(this.id, this.name, this.icon);
  
  static const List<HairStyleOption> options = [
    HairStyleOption(0, 'Afro', Icons.circle),
    HairStyleOption(1, 'Braids', Icons.waves),
    HairStyleOption(2, 'Locs', Icons.linear_scale),
    HairStyleOption(3, 'Cornrows', Icons.view_headline),
    HairStyleOption(4, 'Twists', Icons.autorenew),
    HairStyleOption(5, 'Fade', Icons.gradient),
    HairStyleOption(6, 'Bantu Knots', Icons.blur_on),
    HairStyleOption(7, 'Natural', Icons.eco),
  ];
}

/// Outfit options representing African styles
class OutfitOption {
  final int id;
  final String name;
  final String region;
  final Color primaryColor;
  
  const OutfitOption(this.id, this.name, this.region, this.primaryColor);
  
  static const List<OutfitOption> options = [
    OutfitOption(0, 'Kente', 'Ghana', Color(0xFFFFD700)),
    OutfitOption(1, 'Dashiki', 'West Africa', Color(0xFFE74C3C)),
    OutfitOption(2, 'Kitenge', 'East Africa', Color(0xFF3498DB)),
    OutfitOption(3, 'Shweshwe', 'South Africa', Color(0xFF2C3E50)),
    OutfitOption(4, 'Boubou', 'Senegal', Color(0xFF9B59B6)),
    OutfitOption(5, 'Kaftan', 'North Africa', Color(0xFF1ABC9C)),
    OutfitOption(6, 'Agbada', 'Nigeria', Color(0xFFF39C12)),
    OutfitOption(7, 'Modern', 'Pan-African', Color(0xFF34495E)),
  ];
}

/// Accessory options
class AccessoryOption {
  final int id;
  final String name;
  final String description;
  final bool isPremium;
  final IconData? icon;
  
  const AccessoryOption(
    this.id,
    this.name,
    this.description, {
    this.isPremium = false,
    this.icon,
  });
  
  static const List<AccessoryOption> options = [
    AccessoryOption(0, 'None', 'No accessory'),
    AccessoryOption(1, 'Beads', 'Traditional beaded necklace', icon: Icons.circle),
    AccessoryOption(2, 'Gele', 'Head wrap', icon: Icons.checkroom),
    AccessoryOption(3, 'Kufi', 'Traditional cap', icon: Icons.emoji_people),
    AccessoryOption(4, 'Earrings', 'Gold earrings', icon: Icons.star_outline),
    AccessoryOption(5, 'Glasses', 'Modern glasses', icon: Icons.visibility),
    AccessoryOption(6, 'Crown', 'Tribal crown', isPremium: true, icon: Icons.emoji_events),
    AccessoryOption(7, 'Warrior Mark', 'Ceremonial marking', isPremium: true, icon: Icons.brush),
  ];
}

/// User Avatar Customizer Widget
class UserAvatarCustomizer extends StatefulWidget {
  final UserAvatarConfig initialConfig;
  final ValueChanged<UserAvatarConfig> onConfigChanged;
  final bool showPreview;
  
  const UserAvatarCustomizer({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    this.showPreview = true,
  });
  
  @override
  State<UserAvatarCustomizer> createState() => _UserAvatarCustomizerState();
}

class _UserAvatarCustomizerState extends State<UserAvatarCustomizer>
    with SingleTickerProviderStateMixin {
  late UserAvatarConfig _config;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview
        if (widget.showPreview)
          _buildPreview(),
        
        const SizedBox(height: 20),
        
        // Customization tabs
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.face), text: 'Skin'),
            Tab(icon: Icon(Icons.content_cut), text: 'Hair'),
            Tab(icon: Icon(Icons.checkroom), text: 'Outfit'),
            Tab(icon: Icon(Icons.diamond), text: 'Extras'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSkinToneTab(),
              _buildHairStyleTab(),
              _buildOutfitTab(),
              _buildAccessoryTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SkinToneOption.options[_config.skinTone].color,
        boxShadow: [
          BoxShadow(
            color: OutfitOption.options[_config.outfit].primaryColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base avatar
          Icon(
            Icons.person,
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
          
          // Outfit indicator
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: OutfitOption.options[_config.outfit].primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                OutfitOption.options[_config.outfit].name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Accessory indicator
          if (_config.accessory > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
            ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds);
  }
  
  Widget _buildSkinToneTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: SkinToneOption.options.length,
      itemBuilder: (context, index) {
        final option = SkinToneOption.options[index];
        final isSelected = _config.skinTone == option.id;
        
        return GestureDetector(
          onTap: () => _updateConfig(_config.copyWith(skinTone: option.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: option.color.withOpacity(0.5), blurRadius: 10)]
                  : null,
            ),
            child: Center(
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHairStyleTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: HairStyleOption.options.length,
      itemBuilder: (context, index) {
        final option = HairStyleOption.options[index];
        final isSelected = _config.hairStyle == option.id;
        
        return GestureDetector(
          onTap: () => _updateConfig(_config.copyWith(hairStyle: option.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOutfitTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: OutfitOption.options.length,
      itemBuilder: (context, index) {
        final option = OutfitOption.options[index];
        final isSelected = _config.outfit == option.id;
        
        return GestureDetector(
          onTap: () => _updateConfig(_config.copyWith(outfit: option.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  option.primaryColor,
                  option.primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: option.primaryColor.withOpacity(0.5), blurRadius: 10)]
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 8,
                  top: 8,
                  child: Text(
                    option.region,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAccessoryTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: AccessoryOption.options.length,
      itemBuilder: (context, index) {
        final option = AccessoryOption.options[index];
        final isSelected = _config.accessory == option.id;
        
        return GestureDetector(
          onTap: () {
            if (option.isPremium) {
              _showPremiumDialog(option.name);
            } else {
              _updateConfig(_config.copyWith(accessory: option.id));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: option.isPremium
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                if (option.isPremium)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(Icons.lock, size: 16, color: Colors.amber[700]),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _updateConfig(UserAvatarConfig newConfig) {
    HapticFeedback.selectionClick();
    setState(() => _config = newConfig);
    widget.onConfigChanged(newConfig);
  }
  
  void _showPremiumDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Item'),
        content: Text('$itemName is a premium accessory. Upgrade to unlock!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium screen
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

/// Simple user avatar display widget
class UserAvatarDisplay extends StatelessWidget {
  final UserAvatarConfig config;
  final double size;
  final bool showBorder;
  
  const UserAvatarDisplay({
    super.key,
    required this.config,
    this.size = 60,
    this.showBorder = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final skinColor = config.skinTone < SkinToneOption.options.length
        ? SkinToneOption.options[config.skinTone].color
        : SkinToneOption.options[0].color;
    final outfitColor = config.outfit < OutfitOption.options.length
        ? OutfitOption.options[config.outfit].primaryColor
        : OutfitOption.options[0].primaryColor;
    final hairIcon = config.hairStyle < HairStyleOption.options.length
        ? HairStyleOption.options[config.hairStyle].icon
        : Icons.person;
    final accessoryIcon = config.accessory > 0 && config.accessory < AccessoryOption.options.length
        ? AccessoryOption.options[config.accessory].icon
        : null;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: skinColor,
        border: showBorder
            ? Border.all(color: outfitColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: outfitColor.withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base person icon with hair style icon
          Icon(
            hairIcon,
            size: size * 0.5,
            color: Colors.white.withOpacity(0.9),
          ),
          // Accessory badge (small, positioned at bottom-right)
          if (accessoryIcon != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: outfitColor,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  accessoryIcon,
                  size: size * 0.17,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Drop-in avatar widget that auto-reads from Riverpod provider.
/// Use this anywhere you would use CircleAvatar for the current user.
/// 
/// For other users (chat messages from others), use [UserAvatarDisplay] 
/// with their config, or [LingAfriqAvatar.fromInitials] as a fallback.
class LingAfriqAvatar extends ConsumerWidget {
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;
  
  const LingAfriqAvatar({
    super.key,
    this.size = 40,
    this.showBorder = true,
    this.onTap,
  });
  
  /// Fallback avatar for other users (when we don't have their config).
  /// Shows initials with a color derived from their username.
  static Widget fromInitials({
    required String username,
    double size = 40,
    Color? backgroundColor,
  }) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    // Deterministic color from username
    final hash = username.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final colors = [
      const Color(0xFF2D5F2D), // forest
      const Color(0xFFD4AF37), // gold
      const Color(0xFF8B4513), // earth
      const Color(0xFF1A6B6B), // teal
      const Color(0xFF6B3FA0), // amethyst
      const Color(0xFFCC5500), // sunset
      const Color(0xFF4A7C59), // sage
      const Color(0xFFB8860B), // amber
    ];
    final color = backgroundColor ?? colors[hash % colors.length];
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(userAvatarConfigProvider);
    
    final avatar = UserAvatarDisplay(
      config: config,
      size: size,
      showBorder: showBorder,
    );
    
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
