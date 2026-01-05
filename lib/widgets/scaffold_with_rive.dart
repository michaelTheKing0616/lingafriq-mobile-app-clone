import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'rive_global_guide.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Scaffold wrapper that includes Rive guide
/// Use this instead of Scaffold to automatically show the guide character
class ScaffoldWithRive extends ConsumerWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final bool showRiveGuide;
  final Alignment riveAlignment;
  final bool riveInCorner;

  const ScaffoldWithRive({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.showRiveGuide = true,
    this.riveAlignment = Alignment.topRight,
    this.riveInCorner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          body,
          if (showRiveGuide)
            Positioned(
              top: 16,
              right: 16,
              child: RiveGlobalGuide(
                width: 100.w,
                height: 100.h,
                showInCorner: riveInCorner,
              ),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

