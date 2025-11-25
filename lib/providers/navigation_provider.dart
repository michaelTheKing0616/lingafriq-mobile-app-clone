import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigationProvider = Provider((ref) => NavigationProvider());

class NavigationProvider {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> naviateTo<T>(Widget child) async {
    return await navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) {
      return child;
    }));
  }

  Future<T?> naviateOffAll<T>(Widget child) async {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
    return await navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: (context) {
      return child;
    }));
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
