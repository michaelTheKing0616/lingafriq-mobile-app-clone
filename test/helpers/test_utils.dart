import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Wraps a widget in MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Wraps a widget in MaterialApp with ScreenUtilInit (for widgets using .w, .sp, etc.)
Widget createTestableWidgetWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Creates a mock BuildContext with theme data
Widget createTestableWidgetWithTheme(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(body: child),
  );
}

/// Helper to pump widget with MaterialApp wrapper
Future<void> pumpWidgetWithMaterial(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(createTestableWidget(widget));
}

/// Helper to pump widget with MaterialApp and ScreenUtilInit (for ScreenUtil-dependent widgets)
Future<void> pumpWidgetWithScreenUtil(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(createTestableWidgetWithScreenUtil(widget));
}

/// Helper to pump widget with theme
Future<void> pumpWidgetWithTheme(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(createTestableWidgetWithTheme(widget, theme: theme));
}

/// Creates a mock BuildContext for testing
BuildContext createMockContext() {
  return _MockBuildContext();
}

class _MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
