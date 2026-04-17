// Lazy Image Widget
// Efficiently loads and caches images
// 
// Features:
// - Automatic caching
// - Placeholder support
// - Error handling
// - Progressive loading
// - Memory-efficient

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LazyImage extends StatelessWidget {
  final String? imageUrl;
  final String? placeholder;
  final String? errorWidget;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholderWidget;
  final Widget? errorWidgetWidget;
  final Duration fadeInDuration;
  final bool useOldImageOnUrlChange;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderWidget,
    this.errorWidgetWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useOldImageOnUrlChange = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    // Check if it's a network URL
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: fadeInDuration,
        useOldImageOnUrlChange: useOldImageOnUrlChange,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      );
    } else {
      // Local asset image
      return Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: fadeInDuration,
            child: child,
          );
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }

    if (placeholder != null && placeholder!.isNotEmpty) {
      if (placeholder!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: placeholder!,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          placeholder: (context, url) => _defaultLoadingBox(),
          errorWidget: (context, url, error) => _defaultLoadingBox(),
        );
      } else {
        return Image.asset(
          placeholder!,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidgetWidget != null) {
      return errorWidgetWidget!;
    }

    if (errorWidget != null && errorWidget!.isNotEmpty) {
      if (errorWidget!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: errorWidget!,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          placeholder: (context, url) => _defaultErrorBox(),
          errorWidget: (context, url, error) => _defaultErrorBox(),
        );
      } else {
        return Image.asset(
          errorWidget!,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    return _defaultErrorBox();
  }

  Widget _defaultLoadingBox() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _defaultErrorBox() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        size: width != null && height != null
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 48,
        color: Colors.grey[400],
      ),
    );
  }
}

