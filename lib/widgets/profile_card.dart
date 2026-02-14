import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
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
    return PanAfricanCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      hasGradientBorder: true,
      gradientStart: PanAfricanColors.primary,
      gradientEnd: PanAfricanColors.secondary,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PanAfricanColors.primary,
              PanAfricanColors.secondary,
              PanAfricanColors.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
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
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 4,
                    ),
                    boxShadow: PanAfricanShadows.md,
                  ),
                  child: ClipOval(
                    child: avatarPath != null
                        ? Image.asset(
                            avatarPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(context);
                            },
                          )
                        : _buildDefaultAvatar(context),
                  ),
                ),
                if (showEditIcon && onEditTap != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.xs),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary,
                          shape: BoxShape.circle,
                          boxShadow: PanAfricanShadows.sm,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: PanAfricanColors.primary,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: PanAfricanSpacing.md),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (username != null)
                    Text(
                      username!,
                      style: PanAfricanTypography.headlineSmall(context)
                          .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (email != null) ...[
                    SizedBox(height: PanAfricanSpacing.xxxs),
                    Text(
                      email!,
                      style: PanAfricanTypography.bodySmall(context)
                          .copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (rank != null) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.sm,
                        vertical: PanAfricanSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: PanAfricanColors.secondary,
                            size: 18.sp,
                          ),
                          SizedBox(width: PanAfricanSpacing.xxs),
                          Text(
                            'Rank #$rank',
                            style: PanAfricanTypography.labelLarge(context)
                                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
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

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PanAfricanColors.secondary,
            PanAfricanColors.tertiary,
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.onPrimary,
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
        (isDark ? PanAfricanColors.secondary : PanAfricanColors.primary);

    return PanAfricanCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.md,
      ),
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: defaultIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Icon(
              icon,
              color: defaultIconColor,
              size: 24,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Text(
              title,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? PanAfricanColors.textPrimaryDark
                    : PanAfricanColors.textPrimaryLight,
              ),
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? PanAfricanColors.textSecondaryDark
                    : PanAfricanColors.textSecondaryLight,
              ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 300.ms, delay: 50.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, delay: 50.ms);
  }
}

