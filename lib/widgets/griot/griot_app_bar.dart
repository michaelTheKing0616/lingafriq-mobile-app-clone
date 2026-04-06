import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Branded app bar: avatar on left, branding center, action icons right.
///
/// Transparent background to blend with the page's surface color.
///
/// ```dart
/// GriotAppBar(
///   avatar: GriotAvatar(imageUrl: user.avatar, size: 32),
///   actions: [
///     IconButton(icon: Icon(Icons.notifications_outlined), onPressed: () {}),
///   ],
/// )
/// ```
class GriotAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GriotAppBar({
    super.key,
    this.avatar,
    this.title,
    this.actions,
    this.onAvatarTap,
    this.showBranding = true,
    this.centerTitle = true,
    this.leading,
    this.elevation = 0,
    this.backgroundColor,
  });

  /// Leading avatar widget (typically a [GriotAvatar]).
  final Widget? avatar;

  /// Override for the center title. If null and [showBranding] is true,
  /// displays "LingAfriq" branding.
  final String? title;

  final List<Widget>? actions;
  final VoidCallback? onAvatarTap;
  final bool showBranding;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && avatar != null) {
      leadingWidget = Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: GestureDetector(
          onTap: onAvatarTap,
          child: Center(child: avatar),
        ),
      );
    }

    final titleText = title ?? (showBranding ? 'LingAfriq' : null);

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: leadingWidget,
      centerTitle: centerTitle,
      title: titleText != null
          ? Text(
              titleText,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            )
          : null,
      actions: [
        if (actions != null) ...actions!,
        SizedBox(width: 8.w),
      ],
    );
  }
}
