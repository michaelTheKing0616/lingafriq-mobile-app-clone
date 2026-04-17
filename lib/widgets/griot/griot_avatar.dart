import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Rounded avatar with optional status ring and badge overlay.
///
/// ```dart
/// GriotAvatar(
///   imageUrl: user.avatarUrl,
///   size: 48,
///   status: GriotAvatarStatus.online,
///   badge: GriotBadgeOverlay(icon: Icons.star, color: Colors.amber),
/// )
/// ```
class GriotAvatar extends StatelessWidget {
  const GriotAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.status,
    this.badge,
    this.placeholder,
    this.onTap,
  });

  final String? imageUrl;

  /// Diameter in logical pixels.
  final double size;

  /// If non-null, renders a colored ring around the avatar.
  final GriotAvatarStatus? status;

  /// Optional overlay widget positioned at bottom-right (e.g. level badge).
  final Widget? badge;

  /// Fallback widget when no image is available.
  final Widget? placeholder;

  final VoidCallback? onTap;

  Color _statusColor(ColorScheme cs) {
    switch (status) {
      case GriotAvatarStatus.online:
        return cs.secondary;
      case GriotAvatarStatus.offline:
        return cs.outlineVariant;
      case GriotAvatarStatus.busy:
        return cs.error;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarSize = size.r;
    final ringWidth = status != null ? 3.0.r : 0.0;
    final totalSize = avatarSize + ringWidth * 2;

    Widget avatar = Container(
      width: totalSize,
      height: totalSize,
      decoration: status != null
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _statusColor(cs),
                width: ringWidth,
              ),
            )
          : null,
      child: Center(
        child: ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: _buildImage(cs),
          ),
        ),
      ),
    );

    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildImage(ColorScheme cs) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => _fallback(cs),
        errorWidget: (_, __, ___) => _fallback(cs),
        memCacheWidth: size.toInt(),
        memCacheHeight: size.toInt(),
      );
    }
    return _fallback(cs);
  }

  Widget _fallback(ColorScheme cs) {
    return placeholder ??
        Container(
          color: cs.surfaceContainerHigh,
          child: Icon(
            Icons.person_rounded,
            size: (size * 0.5).sp,
            color: cs.onSurfaceVariant,
          ),
        );
  }
}

/// Status indicator for [GriotAvatar].
enum GriotAvatarStatus { online, offline, busy }
