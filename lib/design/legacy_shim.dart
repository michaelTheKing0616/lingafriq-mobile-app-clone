import 'package:flutter/material.dart';

/// Counts reads of a retired design-system name.
///
/// The legacy files keep their public names, and each name is a
/// [LingAfriqTokens] constant. Call [read] when code still goes through a
/// legacy name so the deprecation count is visible in tests and logs.
abstract final class LegacyDesignShim {
  static final Map<String, int> reads = <String, int>{};

  static Color read(String source, Color token) {
    reads[source] = (reads[source] ?? 0) + 1;
    return token;
  }

  static int countFor(String source) => reads[source] ?? 0;
}
