import 'package:flutter/material.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/modern_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern profile card component
class ProfileCard extends StatelessWidget {
  final String? username;
  final String? email;
  final String? avatarPath;
  final int? rank;
  final VoidCallback? onEditTap;
  final bool showEditIcon;

  const ProfileCard({
    Key? key,
    this.username,
    this.email,
    this.avatarPath,
    this.rank,
    this.onEditTap,
    this.showEditIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return ModernCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryGreen,
          AppColors.accentGold,
          AppColors.accentOrange,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 0.25.sw,
                  height: 0.25.sw,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarPath != null
                        ? Image.asset(
                            avatarPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                if (showEditIcon && onEditTap != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppColors.primaryGreen,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (username != null)
                    Text(
                      username!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      email!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (rank != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: AppColors.accentGold,
                            size: 18.sp,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rank #$rank',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold,
            AppColors.accentOrange,
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}

/// Modern profile menu item
class ProfileMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileMenuItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultIconColor = iconColor ?? 
        (isDark ? AppColors.accentGold : AppColors.primaryGreen);

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: defaultIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: defaultIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.textSecondary,
              ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 300.ms, delay: 50.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, delay: 50.ms);
  }
}

