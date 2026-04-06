import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-bleed hero image with gradient overlay and metadata.
///
/// Used in magazine articles and collection overviews to create an immersive
/// editorial header. Renders a full-width image with a gradient that fades
/// from transparent to the surface color at the bottom, with title, subtitle,
/// and metadata positioned at the bottom-left.
class EditorialHero extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? category;
  final String? date;
  final double height;
  final Widget? overlay;

  const EditorialHero({
    super.key,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.category,
    this.date,
    this.height = 400,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(colors),
          _buildGradientOverlay(colors),
          if (overlay != null) overlay!,
          _buildMetadata(context, colors),
        ],
      ),
    );
  }

  Widget _buildImage(ColorScheme colors) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(colors),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(colors);
        },
      );
    }
    return _buildPlaceholder(colors);
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: Icon(
          Icons.article_rounded,
          size: 48.sp,
          color: colors.onPrimaryContainer.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(ColorScheme colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colors.surface.withOpacity(0.05),
            colors.surface.withOpacity(0.6),
            colors.surface.withOpacity(0.95),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, ColorScheme colors) {
    final hasCategory = category != null && category!.isNotEmpty;
    final hasDate = date != null && date!.isNotEmpty;
    final hasTitle = title != null && title!.isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    if (!hasCategory && !hasDate && !hasTitle && !hasSubtitle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: 16.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCategory || hasDate)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  if (hasCategory)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        category!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  if (hasCategory && hasDate) SizedBox(width: 8.w),
                  if (hasDate)
                    Text(
                      date!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          if (hasTitle)
            Text(
              title!,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: colors.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasSubtitle)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: colors.onSurface.withOpacity(0.75),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
