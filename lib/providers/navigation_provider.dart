import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

final navigationProvider = Provider((ref) => NavigationProvider());

class NavigationProvider {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> navigateTo<T>(Widget child) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    return await state.push<T>(SmoothPageRoute(child: child));
  }

  @Deprecated('Use navigateTo instead')
  Future<T?> naviateTo<T>(Widget child) async => navigateTo<T>(child);

  /// Replaces the current route with [child], clearing the stack to the first route.
  Future<T?> navigateOffAll<T>(Widget child) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    state.popUntil((route) => route.isFirst);
    return await state.pushReplacement<T, void>(SmoothPageRoute(child: child));
  }

  @Deprecated('Use navigateOffAll instead')
  Future<T?> naviateOffAll<T>(Widget child) async => navigateOffAll<T>(child);

  /// Navigate using named routes (used by drawer/menus).
  /// Note: Requires the app's `MaterialApp` to have matching routes / onGenerateRoute.
  Future<T?> navigateToNamed<T>(String routeName, {Object? arguments}) async {
    HapticFeedback.selectionClick();
    final nav = navigatorKey.currentState;
    if (nav == null) return null;
    return await nav.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<void> pop() async {
    HapticFeedback.selectionClick();
    navigatorKey.currentState?.pop();
  }

  Future<void> popToFirstRoute() async {
    HapticFeedback.selectionClick();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
