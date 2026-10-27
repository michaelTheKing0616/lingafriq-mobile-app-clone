import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// P10-912 AC4 — fail CI on unlabelled dark-pattern monetisation strings.
void main() {
  final repoRoot = Directory.current.path.endsWith('lingafriq-mobile-app-clone')
      ? Directory.current.path
      : p.join(Directory.current.path, 'lingafriq-mobile-app-clone');

  final libDir = Directory(p.join(repoRoot, 'lib'));
  final allowTag = 'monetisation-guard: allow';

  final bannedSubstrings = <String>[
    'loot box',
    'lootbox',
    'gacha',
    'mystery box',
    'randomReward',
    'random_reward',
    'random_outcome',
    'lootBox',
  ];

  test('lib has no unlabelled loot-box or random-reward patterns', () {
    expect(libDir.existsSync(), isTrue, reason: 'lib/ missing at $libDir');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(allowTag)) continue;
        for (final needle in bannedSubstrings) {
          if (line.toLowerCase().contains(needle.toLowerCase())) {
            violations.add('${entity.path}:${i + 1}: $needle');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Unlabelled monetisation anti-patterns:\n${violations.join('\n')}',
    );
  });

  test('sale countdown widgets reference server offer ends when present', () {
    final violations = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (!text.contains('countdown') && !text.contains('Countdown')) continue;
      if (!text.contains(RegExp(r'sale|offer|paywall', caseSensitive: false))) {
        continue;
      }
      if (text.contains('serverOfferEndsAt') ||
          text.contains(allowTag) ||
          text.contains('MonetisationOfferEndsAt')) {
        continue;
      }
      violations.add(entity.path);
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Sale/offer countdowns must use serverOfferEndsAt or $allowTag:\n${violations.join('\n')}',
    );
  });
}
