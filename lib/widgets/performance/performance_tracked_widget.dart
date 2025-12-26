/// Performance Tracked Widget
/// Wraps widgets to automatically track performance metrics
/// 
/// Features:
/// - Automatic build time tracking
/// - Render time measurement
/// - Memory usage monitoring

import 'package:flutter/material.dart';
import '../../services/performance/performance_monitor_integrated.dart';
import 'dart:async';

/// Widget that automatically tracks its performance
class PerformanceTrackedWidget extends StatefulWidget {
  final Widget child;
  final String identifier;
  final bool trackBuildTime;
  final bool trackRenderTime;
  final Map<String, dynamic>? metadata;

  const PerformanceTrackedWidget({
    Key? key,
    required this.child,
    required this.identifier,
    this.trackBuildTime = true,
    this.trackRenderTime = false,
    this.metadata,
  }) : super(key: key);

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
        child: result,
        metadata: widget.metadata,
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
    Key? key,
    required this.child,
    required this.identifier,
    this.metadata,
  }) : super(key: key);

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
    Key? key,
    required this.identifier,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.itemExtent,
  }) : super(key: key);

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
    Key? key,
    required this.identifier,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monitor = PerformanceMonitorIntegrated();
    final loadStart = DateTime.now();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          final loadTime = DateTime.now().difference(loadStart);
          monitor.trackImageLoad(
            identifier,
            loadTime,
            cached: wasSynchronouslyLoaded,
          );
        }
        return child;
      },
    );
  }
}

