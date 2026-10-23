import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/auth/passkey_prompt.dart';
import 'package:lingafriq/screens/auth/save_progress_screen.dart';

void main() {
  testWidgets('creating a passkey links the anonymous progress id', (tester) async {
    var created = 0;
    await tester.pumpWidget(MaterialApp(
      home: SaveProgressScreen(
        anonymousProgressId: 'anon-9',
        state: PasskeyPromptState.prompt,
        onCreate: () => created += 1,
        onGoogle: () {},
        onApple: () {},
        onEmailLink: () {},
      ),
    ));
    await tester.tap(find.text('Add a passkey'));
    expect(created, 1);

    await tester.pumpWidget(MaterialApp(
      home: SaveProgressScreen(
        anonymousProgressId: 'anon-9',
        state: PasskeyPromptState.success,
        onCreate: () {},
        onGoogle: () {},
        onApple: () {},
        onEmailLink: () {},
      ),
    ));
    expect(find.text('Progress linked anon-9'), findsOneWidget);
  });

  testWidgets('a cancelled prompt offers Google, Apple, and email', (tester) async {
    var choice = '';
    await tester.pumpWidget(MaterialApp(
      home: SaveProgressScreen(
        anonymousProgressId: 'anon-9',
        state: PasskeyPromptState.cancelled,
        onCreate: () {},
        onGoogle: () => choice = 'google',
        onApple: () => choice = 'apple',
        onEmailLink: () => choice = 'email',
      ),
    ));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Email me a link'), findsOneWidget);
    await tester.tap(find.text('Email me a link'));
    expect(choice, 'email');
  });
}
