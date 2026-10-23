import 'dart:math' as math;

/// One item the placement engine is allowed to see.
///
/// [calibrated] is the P2-049 flag. An item with [calibrated] false is ignored,
/// whatever [a] and [b] say.
class CatItem {
  const CatItem({
    required this.id,
    required this.a,
    required this.b,
    required this.calibrated,
  });

  final String id;
  final double a;
  final double b;
  final bool calibrated;

  bool get usable => calibrated && a > 0 && b.isFinite;
}

/// A finished placement. A provisional result has no ability and no interval.
class CatPlacement {
  const CatPlacement({
    required this.provisional,
    required this.label,
    required this.ability,
    required this.intervalLow,
    required this.intervalHigh,
    required this.administered,
    required this.itemIds,
  });

  const CatPlacement.unsure()
      : provisional = true,
        label = 'unsure',
        ability = null,
        intervalLow = null,
        intervalHigh = null,
        administered = 0,
        itemIds = const [];

  final bool provisional;
  final String label;
  final double? ability;
  final double? intervalLow;
  final double? intervalHigh;
  final int administered;
  final List<String> itemIds;
}

/// Adaptive placement on calibrated 2PL items.
///
/// The test gives between 8 and 15 items. It stops after 8 once the standard
/// error is at or below 0.45, and it never continues past 15. The reported
/// interval is the ability plus or minus 1.96 standard errors. Ties take the
/// lower item id. Nothing in the selection or the score is random.
class CatEngine {
  const CatEngine();

  static const minimumLength = 8;
  static const maximumLength = 15;
  static const minimumBank = 8;
  static const stopStandardError = 0.45;
  static const confidenceZ = 1.96;

  CatPlacement run({
    required List<CatItem> bank,
    required bool Function(CatItem item) respond,
  }) {
    final usable = [
      for (final item in bank)
        if (item.usable) item,
    ]..sort((left, right) => left.id.compareTo(right.id));
    if (usable.length < minimumBank) return const CatPlacement.unsure();

    final remaining = [...usable];
    final given = <CatItem>[];
    final answers = <bool>[];
    while (given.length < maximumLength && remaining.isNotEmpty) {
      if (given.length >= minimumLength &&
          _standardError(_estimate(given, answers), given) <= stopStandardError) {
        break;
      }
      final next = _select(_estimate(given, answers), remaining);
      remaining.remove(next);
      answers.add(respond(next));
      given.add(next);
    }
    if (given.length < minimumLength) return const CatPlacement.unsure();

    final ability = _estimate(given, answers);
    final error = _standardError(ability, given);
    final margin = confidenceZ * error;
    return CatPlacement(
      provisional: false,
      label: _band(ability),
      ability: ability,
      intervalLow: ability - margin,
      intervalHigh: ability + margin,
      administered: given.length,
      itemIds: [for (final item in given) item.id],
    );
  }

  static String _band(double ability) {
    if (ability < -1.5) return 'A1';
    if (ability < -0.5) return 'A2';
    if (ability < 0.5) return 'B1';
    if (ability < 1.5) return 'B2';
    if (ability < 2.5) return 'C1';
    return 'C2';
  }

  static CatItem _select(double ability, List<CatItem> remaining) {
    CatItem? best;
    var bestInfo = -1.0;
    for (final item in remaining) {
      final info = _information(ability, item);
      if (best == null || info > bestInfo) {
        best = item;
        bestInfo = info;
      }
    }
    return best!;
  }

  static double _estimate(List<CatItem> items, List<bool> answers) {
    var ability = 0.0;
    for (var step = 0; step < 20; step++) {
      var slope = -ability;
      var info = 1.0;
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final p = _probability(ability, item).clamp(1e-12, 1 - 1e-12);
        slope += ((answers[index] ? 1.0 : 0.0) - p) * item.a;
        info += item.a * item.a * p * (1 - p);
      }
      final delta = slope / info;
      ability = (ability + delta).clamp(-4.0, 4.0);
      if (delta.abs() < 1e-4) break;
    }
    return ability;
  }

  static double _standardError(double ability, List<CatItem> items) {
    var info = 1.0;
    for (final item in items) {
      info += _information(ability, item);
    }
    return 1 / math.sqrt(info);
  }

  static double _information(double ability, CatItem item) {
    final p = _probability(ability, item);
    return item.a * item.a * p * (1 - p);
  }

  static double _probability(double ability, CatItem item) {
    final eta = item.a * (ability - item.b);
    if (eta >= 0) {
      final z = math.exp(-eta);
      return 1 / (1 + z);
    }
    final z = math.exp(eta);
    return z / (1 + z);
  }
}
