import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigationProvider = Provider((ref) => NavigationProvider());

class NavigationProvider {
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Deprecated misspelling kept for backward compatibility.
  /// Prefer [navigateTo] going forward.
  @deprecated
  Future<T?> naviateTo<T>(Widget child) => navigateTo(child);

  /// Deprecated misspelling kept for backward compatibility.
  /// Prefer [navigateOffAll] going forward.
  @deprecated
  Future<T?> naviateOffAll<T>(Widget child) => navigateOffAll(child);

  /// Correctly named navigation helper to push a new route.
  Future<T?> navigateTo<T>(Widget child) async {
    return await navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => child),
    );
  }

  /// Correctly named helper to clear the stack and replace with a new route.
  Future<T?> navigateOffAll<T>(Widget child) async {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
    return await navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (context) => child),
    );
  }

  Future<void> pop() async {
    HapticFeedback.selectionClick();
    navigatorKey.currentState!.pop();
  }

  Future<void> popToFirstRoute() async {
    HapticFeedback.selectionClick();
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
}
