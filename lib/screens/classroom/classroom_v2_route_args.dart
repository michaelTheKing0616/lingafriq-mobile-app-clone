import 'package:flutter/material.dart';

/// Shared [Navigator] `arguments` for classroom v2 roster, assignments, and privacy routes
/// (Stitch hub, `Navigator.pushNamed`, dashboards).
final class ClassroomV2RouteArgs {
  ClassroomV2RouteArgs._();

  static const String defaultTribeName = 'Classroom';

  /// [tribeId] is null when missing or blank — show [missingTribeIdScaffold].
  static ({String? tribeId, String tribeName}) parse(Object? arguments) {
    if (arguments is! Map) {
      return (tribeId: null, tribeName: defaultTribeName);
    }
    final args = Map<String, dynamic>.from(arguments as Map);
    final rawId = args['tribeId']?.toString().trim() ?? '';
    final name = args['tribeName']?.toString().trim() ?? defaultTribeName;
    if (rawId.isEmpty) return (tribeId: null, tribeName: name);
    return (tribeId: rawId, tribeName: name);
  }

  /// Shown when [parse] returns a null `tribeId`. [pushNamedRoute] is the exact string passed to
  /// `Navigator.pushNamed` (e.g. `/classroom-roster-v2`).
  static Widget missingTribeIdScaffold(String pushNamedRoute) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Missing tribeId.\n\n'
              'Use: Navigator.pushNamed(context, "$pushNamedRoute", '
              'arguments: {"tribeId": "<classroom tribe id>", "tribeName": "My class"});',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
