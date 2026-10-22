import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/auth/passkey_prompt.dart';
import 'package:lingafriq/services/passkey_codec.dart';

void main() {
  test('server authentication options become a platform request', () {
    final request = authenticationRequest({
      'challenge': 'abc',
      'rpId': 'lingafriq.com',
      'userVerification': 'required',
      'allowCredentials': [
        {'type': 'public-key', 'id': 'cred-1', 'transports': ['internal']},
      ],
    });

    expect(request.challenge, 'abc');
    expect(request.relyingPartyId, 'lingafriq.com');
    expect(request.allowCredentials?.single.id, 'cred-1');
  });

  test('a passkey error name is taken from the server body', () {
    expect(
      passkeySummaries({
        'credentials': [
          {'id': 'cred-1', 'backedUp': true},
        ],
      }).single.id,
      'cred-1',
    );
  });

  testWidgets('an unsupported device offers Google, Apple, and email', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PasskeyPrompt(
        state: PasskeyPromptState.unsupported,
        credentials: const [],
        onSignIn: () {},
        onRegister: () {},
        onRemove: (_) {},
        onGoogle: () {},
        onApple: () {},
        onEmailLink: () {},
        onRetry: () {},
      ),
    ));

    expect(find.byKey(const Key('passkey.unsupported')), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Email me a link'), findsOneWidget);
  });

  testWidgets('a signed-in account lists its passkey', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PasskeyPrompt(
        state: PasskeyPromptState.success,
        canRegister: true,
        credentials: const [PasskeySummary(id: 'cred-1', backedUp: false)],
        onSignIn: () {},
        onRegister: () {},
        onRemove: (_) {},
        onGoogle: () {},
        onApple: () {},
        onEmailLink: () {},
        onRetry: () {},
      ),
    ));

    expect(find.text('cred-1'), findsOneWidget);
    expect(find.byKey(const Key('passkey.register')), findsOneWidget);
  });
}
