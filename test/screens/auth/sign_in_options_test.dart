import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/screens/auth/sign_in_errors.dart';
import 'package:lingafriq/screens/auth/sign_in_options.dart';

void main() {
  testWidgets('sign-in options offer Google, Apple, and an email link', (
    tester,
  ) async {
    final email = TextEditingController();
    final token = TextEditingController();
    await tester.pumpWidget(
      _app(
        home: SignInOptionsView(
          state: SignInOptionsState.options,
          emailController: email,
          tokenController: token,
          onGoogle: () {},
          onApple: () {},
          onSendLink: () {},
          onUseToken: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('signin.options')), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Email me a link'), findsOneWidget);
    email.dispose();
    token.dispose();
  });

  testWidgets('a sent magic link tells the learner to check email', (
    tester,
  ) async {
    final email = TextEditingController();
    final token = TextEditingController();
    await tester.pumpWidget(
      _app(
        home: SignInOptionsView(
          state: SignInOptionsState.linkSent,
          emailController: email,
          tokenController: token,
          onGoogle: () {},
          onApple: () {},
          onSendLink: () {},
          onUseToken: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('signin.link_sent')), findsOneWidget);
    expect(
      find.text('The link expires in 15 minutes and works once.'),
      findsOneWidget,
    );
    email.dispose();
    token.dispose();
  });

  test('every sign-in error code has human copy in English and Arabic', () {
    for (final code in signInErrorCodes) {
      for (final lang in ['en', 'ar']) {
        final text = signInErrorText(code, lang);
        expect(text, isNot(contains('_')), reason: '$code/$lang');
        expect(text.length, greaterThan(15), reason: '$code/$lang');
      }
    }
    expect(signInErrorCode('provider_invalid'), 'provider_invalid');
    expect(signInErrorCode('nonsense_code'), 'unknown');
    expect(signInErrorCode(StateError('sign_in_invalid')), 'sign_in_invalid');
    final req = RequestOptions(path: '/x');
    expect(
      signInErrorCode(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionError,
        ),
      ),
      'network',
    );
    DioException status(int code, [Object? data]) => DioException(
      requestOptions: req,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: req, statusCode: code, data: data),
    );
    expect(signInErrorCode(status(429)), 'rate_limited');
    expect(signInErrorCode(status(503)), 'server');
    expect(
      signInErrorCode(
        status(400, {
          'error': {'code': 'link_expired'},
        }),
      ),
      'link_expired',
    );
  });

  testWidgets('the error state shows friendly copy, never the raw code', (
    tester,
  ) async {
    final email = TextEditingController();
    final token = TextEditingController();
    await tester.pumpWidget(
      _app(
        home: SignInOptionsView(
          state: SignInOptionsState.error,
          errorCode: 'provider_invalid',
          emailController: email,
          tokenController: token,
          onGoogle: () {},
          onApple: () {},
          onSendLink: () {},
          onUseToken: () {},
        ),
      ),
    );
    expect(find.byKey(const Key('signin.error')), findsOneWidget);
    expect(find.textContaining('provider_invalid'), findsNothing);
    expect(
      find.text(signInErrorText('provider_invalid', 'en')),
      findsOneWidget,
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    email.dispose();
    token.dispose();
  });
}

Widget _app({required Widget home}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(home: home),
);
