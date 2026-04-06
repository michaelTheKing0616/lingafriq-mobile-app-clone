import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;
import '../../widgets/griot/griot_widgets.dart';

class ContactInfoScreen extends ConsumerWidget {
  const ContactInfoScreen({
    super.key,
    required this.contactName,
    required this.contactId,
  });

  final String contactName;
  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(context, cs),
          SizedBox(height: PanAfricanSpacing.lg),
          _buildQuickActions(context, cs),
          SizedBox(height: PanAfricanSpacing.lg),
          _buildSharedMedia(context, cs),
          SizedBox(height: PanAfricanSpacing.lg),
          _buildSettingsSection(context, cs),
          SizedBox(height: PanAfricanSpacing.lg),
          _buildCommonGroups(context, cs),
          SizedBox(height: PanAfricanSpacing.lg),
          _buildDangerZone(context, cs),
          SizedBox(height: PanAfricanSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + PanAfricanSpacing.md,
        bottom: PanAfricanSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.sunsetWarm,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: PanAfricanSpacing.xs),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Container(
            width: 160.r,
            height: 160.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ModernGriotGradients.signatureGradient,
              boxShadow: ModernGriotShadows.glow(ModernGriotColors.primary),
            ),
            child: Center(
              child: Container(
                width: 150.r,
                height: 150.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHigh,
                ),
                child: Center(
                  child: Text(
                    contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                    style: ModernGriotTypography.displaySmall(
                      color: ModernGriotColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            contactName,
            style: ModernGriotTypography.headlineSmall(color: cs.onSurface),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          GriotBadgePill(
            label: 'Wolof Native',
            color: ModernGriotColors.secondaryContainer,
            textColor: ModernGriotColors.onSecondaryContainer,
            icon: Icons.language_rounded,
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            'Last seen today at 10:42 AM',
            style: ModernGriotTypography.bodySmall(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme cs) {
    final actions = [
      _QuickAction(icon: Icons.call_rounded, label: 'Call'),
      _QuickAction(icon: Icons.videocam_rounded, label: 'Video'),
      _QuickAction(icon: Icons.search_rounded, label: 'Search'),
      _QuickAction(icon: Icons.notifications_off_outlined, label: 'Mute'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((action) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xxs),
              child: GriotCard(
                surfaceLevel: 1,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                onTap: () => HapticFeedback.selectionClick(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.icon,
                      size: 24.sp,
                      color: ModernGriotColors.primary,
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      action.label,
                      style: ModernGriotTypography.labelSmall(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSharedMedia(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
          child: Row(
            children: [
              Text(
                'Shared Media',
                style: ModernGriotTypography.titleSmall(color: cs.onSurface),
              ),
              const Spacer(),
              Text(
                'See all',
                style: ModernGriotTypography.labelMedium(
                  color: ModernGriotColors.primary,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12.sp,
                color: ModernGriotColors.primary,
              ),
            ],
          ),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            itemCount: 6,
            separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.xs),
            itemBuilder: (context, index) {
              return Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: ModernGriotRadius.borderLg,
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 32.sp,
                    color: cs.onSurfaceVariant.withAlpha(100),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: GriotCard(
        surfaceLevel: 1,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildSettingsTile(
              context,
              cs,
              icon: Icons.lock_outline_rounded,
              iconColor: ModernGriotColors.secondary,
              title: 'Encryption',
              subtitle: 'Messages are end-to-end encrypted',
              trailing: Icon(
                Icons.verified_rounded,
                size: 20.sp,
                color: ModernGriotColors.secondary,
              ),
            ),
            Divider(
              height: 1,
              indent: 56.w,
              color: cs.outlineVariant.withAlpha(38),
            ),
            _buildSettingsTile(
              context,
              cs,
              icon: Icons.timer_outlined,
              iconColor: ModernGriotColors.primary,
              title: 'Disappearing Messages',
              subtitle: 'Off',
              trailing: Switch.adaptive(
                value: false,
                onChanged: (_) => HapticFeedback.selectionClick(),
                activeColor: ModernGriotColors.primary,
              ),
            ),
            Divider(
              height: 1,
              indent: 56.w,
              color: cs.outlineVariant.withAlpha(38),
            ),
            _buildSettingsTile(
              context,
              cs,
              icon: Icons.photo_outlined,
              iconColor: ModernGriotColors.tertiary,
              title: 'Media Visibility',
              subtitle: 'Default',
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: ModernGriotRadius.borderMd,
            ),
            child: Icon(icon, size: 20.sp, color: iconColor),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ModernGriotTypography.titleSmall(color: cs.onSurface),
                ),
                Text(
                  subtitle,
                  style: ModernGriotTypography.bodySmall(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCommonGroups(BuildContext context, ColorScheme cs) {
    final groups = [
      _GroupItem(name: 'Wolof Learners', members: 128, initial: 'W'),
      _GroupItem(name: 'West Africa Study Hub', members: 56, initial: 'W'),
      _GroupItem(name: 'LingAfriq Community', members: 342, initial: 'L'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
          child: Text(
            '${groups.length} groups in common',
            style: ModernGriotTypography.titleSmall(color: cs.onSurface),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        ...groups.map((group) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.xxxs,
              ),
              child: GriotCard(
                surfaceLevel: 1,
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.md,
                  vertical: PanAfricanSpacing.sm,
                ),
                onTap: () => HapticFeedback.selectionClick(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor:
                          ModernGriotColors.secondaryContainer.withAlpha(100),
                      child: Text(
                        group.initial,
                        style: ModernGriotTypography.titleSmall(
                          color: ModernGriotColors.secondary,
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: ModernGriotTypography.titleSmall(
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            '${group.members} members',
                            style: ModernGriotTypography.bodySmall(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: ModernGriotColors.errorContainer.withAlpha(40),
          borderRadius: ModernGriotRadius.borderXl,
        ),
        child: Column(
          children: [
            _buildDangerButton(
              context,
              cs,
              icon: Icons.block_rounded,
              label: 'Block $contactName',
              onTap: () => HapticFeedback.heavyImpact(),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            _buildDangerButton(
              context,
              cs,
              icon: Icons.thumb_down_alt_outlined,
              label: 'Report $contactName',
              onTap: () => HapticFeedback.heavyImpact(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: ModernGriotRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: ModernGriotRadius.borderLg,
        splashColor: ModernGriotColors.error.withAlpha(30),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22.sp, color: ModernGriotColors.error),
              SizedBox(width: PanAfricanSpacing.sm),
              Text(
                label,
                style: ModernGriotTypography.titleSmall(
                  color: ModernGriotColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});
}

class _GroupItem {
  final String name;
  final int members;
  final String initial;

  const _GroupItem({
    required this.name,
    required this.members,
    required this.initial,
  });
}
