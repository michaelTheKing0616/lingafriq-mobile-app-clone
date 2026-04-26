import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// App-wide [Scaffold] with consistent safe areas using [ResponsiveSafeArea].
///
/// For screens that already have an [AppBar], set [applyTopSafeArea] to false so
/// the toolbar owns the top inset. Tab shells with a [bottomNavigationBar]
/// often set [applyBottomSafeArea] to false on the body so the bar + system
/// insets are handled by the platform.
class LingafriqScaffold extends StatelessWidget {
  const LingafriqScaffold({
    super.key,
    this.scaffoldKey,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.applyTopSafeArea = true,
    this.applyBottomSafeArea = true,
  });

  /// When set, must be attached to the inner [Scaffold] (e.g. for [ScaffoldState.openDrawer]).
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool applyTopSafeArea;
  final bool applyBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget child = body;
    if (applyTopSafeArea || applyBottomSafeArea) {
      child = ResponsiveSafeArea(
        top: applyTopSafeArea,
        bottom: applyBottomSafeArea,
        child: child,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}
