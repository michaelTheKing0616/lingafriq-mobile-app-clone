// Performance Tracked Widget
// Wraps widgets to automatically track performance metrics
// 
// Features:
// - Automatic build time tracking
// - Render time measurement
// - Memory usage monitoring

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/performance/performance_monitor_integrated.dart';
/// Widget that automatically tracks its performance
class PerformanceTrackedWidget extends StatefulWidget {
  final Widget child;
  final String identifier;
  final bool trackBuildTime;
  final bool trackRenderTime;
  final Map<String, dynamic>? metadata;

  const PerformanceTrackedWidget({
    super.key,
    required this.child,
    required this.identifier,
    this.trackBuildTime = true,
    this.trackRenderTime = false,
    this.metadata,
  });

  @override
  State<PerformanceTrackedWidget> createState() => _PerformanceTrackedWidgetState();
}

class _PerformanceTrackedWidgetState extends State<PerformanceTrackedWidget> {
  final PerformanceMonitorIntegrated _monitor = PerformanceMonitorIntegrated();
  Stopwatch? _buildTimer;

  @override
  void initState() {
    super.initState();
    if (widget.trackBuildTime) {
      _buildTimer = Stopwatch()..start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trackBuildTime && _buildTimer != null) {
      _buildTimer!.stop();
      _monitor.recordMetric(
        type: MetricType.widgetBuild,
        identifier: widget.identifier,
        value: _buildTimer!.elapsedMilliseconds.toDouble(),
        metadata: widget.metadata,
      );
      _buildTimer = null;
    }

    Widget result = widget.child;

    if (widget.trackRenderTime) {
      result = _TrackRenderTime(
        identifier: widget.identifier,
        metadata: widget.metadata,
        child: result,
      );
    }

    return result;
  }
}

/// Tracks render time for a widget
class _TrackRenderTime extends StatefulWidget {
  final Widget child;
  final String identifier;
  final Map<String, dynamic>? metadata;

  const _TrackRenderTime({
    required this.child,
    required this.identifier,
    this.metadata,
  });

  @override
  State<_TrackRenderTime> createState() => _TrackRenderTimeState();
}

class _TrackRenderTimeState extends State<_TrackRenderTime> {
  final PerformanceMonitorIntegrated _monitor = PerformanceMonitorIntegrated();
  DateTime? _renderStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_renderStart != null) {
        final renderTime = DateTime.now().difference(_renderStart!);
        _monitor.recordMetric(
          type: MetricType.widgetBuild,
          identifier: '${widget.identifier}_render',
          value: renderTime.inMilliseconds.toDouble(),
          metadata: widget.metadata,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _renderStart = DateTime.now();
    return widget.child;
  }
}

/// Performance tracked list view
class PerformanceTrackedListView extends StatelessWidget {
  final String identifier;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;

  const PerformanceTrackedListView({
    super.key,
    required this.identifier,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.itemExtent,
  });

  @override
  Widget build(BuildContext context) {
    final monitor = PerformanceMonitorIntegrated();
    final stopwatch = Stopwatch()..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      monitor.trackListRender(
        identifier,
        itemCount,
        stopwatch.elapsed,
      );
    });

    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemExtent: itemExtent,
      itemBuilder: itemBuilder,
      cacheExtent: 250.0,
    );
  }
}

/// Performance tracked image
class PerformanceTrackedImage extends StatelessWidget {
  final String identifier;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PerformanceTrackedImage({
    super.key,
    required this.identifier,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final monitor = PerformanceMonitorIntegrated();
    final loadStart = DateTime.now();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => _trackedPlaceholder(monitor, loadStart, cached: false),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      imageBuilder: (context, provider) {
        final loadTime = DateTime.now().difference(loadStart);
        monitor.trackImageLoad(identifier, loadTime, cached: false);
        return Image(
          image: provider,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }

  Widget _trackedPlaceholder(
    PerformanceMonitorIntegrated monitor,
    DateTime loadStart, {
    required bool cached,
  }) {
    final loadTime = DateTime.now().difference(loadStart);
    monitor.trackImageLoad(identifier, loadTime, cached: cached);
    return SizedBox(
      width: width,
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

