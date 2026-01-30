import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';

/// Shared tab index and scaffold key for Material 3 tabs view.
/// Used by TabsViewMaterial3, DashboardScreenMaterial3, and tab screens
/// to avoid circular imports and ensure a single source of truth.
class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

final tabIndexProvider =
    NotifierProvider.autoDispose<TabIndexNotifier, int>(() {
  return TabIndexNotifier();
});

final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});
