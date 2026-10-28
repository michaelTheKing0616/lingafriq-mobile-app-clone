import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';

const _enArb = 'lib/l10n/community_guidelines_en.arb';

List<String> get _requiredRuleKeys => [
  for (var i = 1; i <= kCommunityGuidelineRuleCount; i++) ...[
    'guidelines.rule.$i.title',
    'guidelines.rule.$i.body',
    'guidelines.rule.$i.example',
  ],
];

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('P9-933 AC2: every supported UI locale has full guidelines ARB keys', () {
    final en = jsonDecode(File(_enArb).readAsStringSync()) as Map<String, dynamic>;
    final enKeys = _messageKeys(en);
    for (final key in _requiredRuleKeys) {
      expect(enKeys, contains(key), reason: 'English template missing $key');
    }
    for (final locale in AppLocalizations.supportedLocales) {
      final path = 'lib/l10n/community_guidelines_${locale.languageCode}.arb';
      expect(File(path).existsSync(), isTrue, reason: 'missing $path');
      final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final keys = _messageKeys(arb);
      for (final key in enKeys) {
        if (key == '@@locale') continue;
        expect(keys, contains(key), reason: '${locale.languageCode} missing $key');
      }
    }
  });

  test('P9-933 AC3: report reasons map to guideline clauses', () {
    for (final reason in ['harassment', 'hate', 'spam', 'other']) {
      expect(CommunityGuidelinesCatalog.socialReportClauseId(reason), isNotNull);
    }
    for (final cat in ['wrong_meaning', 'tone_spelling', 'audio', 'unnatural', 'offensive']) {
      expect(CommunityGuidelinesCatalog.contentFlagClauseId(cat), isNotNull);
    }
  });
}
