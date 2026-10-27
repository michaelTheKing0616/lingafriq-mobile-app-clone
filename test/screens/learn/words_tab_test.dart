import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/screens/learn/words_tab.dart';
import 'package:lingafriq/screens/lens/lens_results_lexicon_link.dart';
import 'package:lingafriq/screens/village/contribute_hub.dart';
import 'package:lingafriq/screens/village/verify_queue_screen.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

VerifiedLexeme _fixtureLexeme() {
  final fixturePath =
      File('test/content/fixtures/lexeme_yo_oko.json').absolute.path;
  final fixture =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': fixture['id'],
    'language': 'yo',
    'verification_status': 'expert_reviewed',
    'entry': fixture,
  });
}

Future<Widget> _app(Widget home) async {
  SharedPreferences.setMockInitialValues({'learning_language': 'yoruba'});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider
          .overrideWithValue(SharedPreferencesProvider(prefs)),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordsTab', () {
    testWidgets('My Words entry invokes navigation hook', (tester) async {
      var openedMyWords = false;
      await tester.pumpWidget(
        await _app(
          WordsTab(
            dueWordsCount: (_) => 0,
            onMyWordsTap: () => openedMyWords = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('learn_words_my_words')));
      expect(openedMyWords, isTrue);
    });

    testWidgets('Review shows snackbar when nothing due', (tester) async {
      await tester.pumpWidget(
        await _app(
          WordsTab(
            languageCode: 'yo',
            dueWordsCount: (_) => 0,
            dueWordsForReview: (_) => const [],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('learn_words_review')));
      await tester.pumpAndSettle();
      expect(find.text(kLearnWordsReviewEmpty), findsWidgets);
    });
  });

  group('LensResultsLexiconLink', () {
    testWidgets('opens word card sheet when lexeme resolves', (tester) async {
      final lexeme = _fixtureLexeme();
      await tester.pumpWidget(
        await _app(
          Scaffold(
            body: LensResultsLexiconLink(
              lexemeId: lexeme.lexemeId,
              displayWord: 'ọkọ̀',
              fetchLexeme: (_) async => lexeme,
            ),
          ),
        ),
      );
      await tester.tap(find.text('ọkọ̀'));
      await tester.pumpAndSettle();
      expect(find.byType(WordCardSheet), findsOneWidget);
    });
  });

  group('ContributeHubScreen', () {
    testWidgets('Verify opens queue from Contribute hub', (tester) async {
      await tester.pumpWidget(
        await _app(const ContributeHubScreen(canApproveVerifications: false)),
      );
      await tester.tap(find.text(kVillageVerifyTileLabel));
      await tester.pumpAndSettle();
      expect(find.byType(VerifyQueueScreen), findsOneWidget);
    });

    testWidgets('non-native sees suggest-only copy on Verify', (tester) async {
      await tester.pumpWidget(
        await _app(const ContributeHubScreen(canApproveVerifications: false)),
      );
      expect(find.text(kVillageSuggestOnlyNotice), findsOneWidget);
      await tester.tap(find.text(kVillageVerifyTileLabel));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Native validators can review community word suggestions here.',
        ),
        findsOneWidget,
      );
    });
  });
}
