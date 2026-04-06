import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Editorial article card with a 4:5 aspect-ratio image and metadata below.
///
/// Used in article grids and content feeds. The image area uses a 4:5
/// aspect ratio to match magazine-style editorial layouts. Tapping the
/// card triggers [onTap].
class EditorialArticleCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? author;
  final String? readTime;
  final String? category;
  final VoidCallback? onTap;

  const EditorialArticleCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.author,
    this.readTime,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(colors),
          SizedBox(height: 10.h),
          _buildBody(context, colors),
        ],
      ),
    );
  }

  Widget _buildImage(ColorScheme colors) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageContent(colors),
            if (category != null && category!.isNotEmpty)
              Positioned(
                top: 10.h,
                left: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    category!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(ColorScheme colors) {
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
      color: colors.primaryContainer.withOpacity(0.4),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 32.sp,
          color: colors.onSurface.withOpacity(0.15),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colors) {
    final hasAuthor = author != null && author!.isNotEmpty;
    final hasReadTime = readTime != null && readTime!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: colors.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasAuthor || hasReadTime)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Row(
              children: [
                if (hasAuthor)
                  Flexible(
                    child: Text(
                      author!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (hasAuthor && hasReadTime)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Text(
                      '\u2022',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: colors.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ),
                if (hasReadTime)
                  Text(
                    readTime!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
