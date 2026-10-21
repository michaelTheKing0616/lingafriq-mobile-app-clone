// P1-029 Spec-Test (Mode A): AC4. Source-level contract checks (no UI impl read).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _copyKey = 'content.coming_soon';

List<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
    .toList();

void main() {
  test('P1-029_AC4_unverified_language_shows_coming_soon_with_copy_key', () {
    final owners = _dartFiles()
        .where((f) => f.readAsStringSync().contains("'$_copyKey'") ||
            f.readAsStringSync().contains('"$_copyKey"'))
        .toList();
    expect(owners, isNotEmpty,
        reason: 'no widget references copy key $_copyKey');
  });

  test('P1-029_AC4_coming_soon_state_is_announced_to_screen_readers', () {
    final owners = _dartFiles()
        .where((f) => f.readAsStringSync().contains(_copyKey))
        .toList();
    expect(owners, isNotEmpty);
    expect(
        owners.any((f) {
          final s = f.readAsStringSync();
          return s.contains('liveRegion') || s.contains('SemanticsService.announce');
        }),
        isTrue,
        reason: 'coming-soon state must set liveRegion or announce');
  });

  test('P1-029_AC4_copy_key_defined_in_localisation_resources', () {
    final arb = File('lib/l10n/app_en.arb');
    expect(arb.existsSync(), isTrue);
    final s = arb.readAsStringSync();
    expect(s.contains(_copyKey) || s.contains('content_coming_soon'), isTrue,
        reason: 'app_en.arb lacks $_copyKey');
  });
}
