import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/auth/sign_in_options.dart';

void main() {
  testWidgets('sign-in options offer Google, Apple, and an email link', (tester) async {
    final email = TextEditingController();
    final token = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: SignInOptionsView(
        state: SignInOptionsState.options,
        emailController: email,
        tokenController: token,
        onGoogle: () {},
        onApple: () {},
        onSendLink: () {},
        onUseToken: () {},
      ),
    ));

    expect(find.byKey(const Key('signin.options')), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Email me a link'), findsOneWidget);
    email.dispose();
    token.dispose();
  });

  testWidgets('a sent magic link tells the learner to check email', (tester) async {
    final email = TextEditingController();
    final token = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: SignInOptionsView(
        state: SignInOptionsState.linkSent,
        emailController: email,
        tokenController: token,
        onGoogle: () {},
        onApple: () {},
        onSendLink: () {},
        onUseToken: () {},
      ),
    ));

    expect(find.byKey(const Key('signin.link_sent')), findsOneWidget);
    expect(find.text('The link expires in 15 minutes and works once.'), findsOneWidget);
    email.dispose();
    token.dispose();
  });
}
