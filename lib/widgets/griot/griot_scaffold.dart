import 'package:flutter/material.dart';

/// Base scaffold for the Modern Griot design system.
///
/// Uses the theme's surface color as background. Optionally displays a
/// glassmorphic bottom navigation bar via [bottomNavigationBar].
///
/// ```dart
/// GriotScaffold(
///   appBar: GriotAppBar(...),
///   bottomNavigationBar: GriotBottomNav(...),
///   body: ListView(...),
/// )
/// ```
class GriotScaffold extends StatelessWidget {
  const GriotScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
