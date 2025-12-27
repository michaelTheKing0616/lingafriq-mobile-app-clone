/// Optimized ListView Widget
/// Provides performance optimizations for large lists
/// 
/// Features:
/// - Lazy loading
/// - Viewport-based rendering
/// - Memory-efficient item recycling
/// - Configurable item extent

import 'package:flutter/material.dart';

class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final double? itemExtent;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double cacheExtent;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.itemExtent,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent = 250.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (itemExtent != null) {
      // Use ListView.builder with itemExtent for better performance
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        controller: controller,
        itemExtent: itemExtent,
        shrinkWrap: shrinkWrap,
        physics: physics,
        cacheExtent: cacheExtent,
      );
    } else {
      // Use regular ListView.builder
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        cacheExtent: cacheExtent,
      );
    }
  }

  /// Factory constructor for builder pattern (backward compatibility)
  factory OptimizedListView.builder({
    Key? key,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    double? itemExtent,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    double cacheExtent = 250.0,
    SliverGridDelegate? gridDelegate,
  }) {
    // If gridDelegate is provided, return a GridView instead
    if (gridDelegate != null) {
      return _OptimizedGridView(
        key: key,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        gridDelegate: gridDelegate,
      );
    }
    
    return OptimizedListView(
      key: key,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      controller: controller,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      physics: physics,
      cacheExtent: cacheExtent,
    );
  }
}

/// Internal GridView wrapper for OptimizedListView.builder with gridDelegate
class _OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final SliverGridDelegate gridDelegate;

  const _OptimizedGridView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    required this.gridDelegate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
    );
  }
}

/// Optimized ListView with separators
class OptimizedListViewWithSeparators extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final double? itemExtent;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListViewWithSeparators({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding,
    this.controller,
    this.itemExtent,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      separatorBuilder: separatorBuilder,
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      cacheExtent: 250.0,
    );
  }
}

