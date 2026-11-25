import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/chat/report_block_sheet.dart';

void main() {
  testWidgets('P1-024 report sheet stores a reference and confirms a block', (
    tester,
  ) async {
    String? reported;
    var blocked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportBlockSheet(
            onReport: (reason) async {
              reported = reason;
              return 'ref-24';
            },
            onBlock: () async {
              blocked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Report'), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(reported, 'harassment');
    expect(
      find.text('Report received. Reference \u2068ref-24\u2069'),
      findsOneWidget,
    );

    await tester.tap(find.text('Block user'));
    await tester.pumpAndSettle();
    expect(find.text(ReportCopy.blockConfirm), findsWidgets);
    await tester.tap(find.text('Confirm block'));
    await tester.pumpAndSettle();
    expect(blocked, isTrue);
    expect(
      find.text('Blocked. You will not see their new messages.'),
      findsOneWidget,
    );
  });

  testWidgets('P1-024 report failure stays on the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportBlockSheet(
            onReport: (_) async => throw StateError('down'),
            onBlock: () async {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Could not send that. Try again.'), findsOneWidget);
    expect(find.text('Send report'), findsOneWidget);
  });

  testWidgets('P1-024 unblock is available from the blocked list', (
    tester,
  ) async {
    String? unblocked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportBlockSheet(
            onReport: (_) async => 'ref',
            onBlock: () async {},
            onLoadBlocked: () async => const [
              BlockedPerson(id: 'user-b', name: 'Bayo'),
            ],
            onUnblock: (id) async {
              unblocked = id;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Blocked people'));
    await tester.pumpAndSettle();
    expect(find.text('\u2068Bayo\u2069'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(unblocked, 'user-b');
  });

  for (final (loc, send, hate) in [
    ('fr', 'Envoyer le signalement', 'Haine'),
    ('ar', 'إرسال البلاغ', 'كراهية'),
  ]) {
    testWidgets('sheet is localised ($loc)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(loc),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReportBlockSheet(
              onReport: (_) async => 'r1',
              onBlock: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(send), findsOneWidget);
      expect(find.text(hate), findsOneWidget);
      expect(find.text('Send report'), findsNothing);
    });
  }
}
