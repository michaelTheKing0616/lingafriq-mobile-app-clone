import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/screens/auth/sign_in_errors.dart';
import 'package:lingafriq/screens/auth/sign_in_options.dart';

import '../../onboarding/onboarding_art.dart';

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

  testWidgets('Arabic: sign-in is translated and mirrored', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final e = TextEditingController(), t = TextEditingController();
    await tester.pumpWidget(
      _app(home: _options(e, t), locale: const Locale('ar')),
    );
    for (final ar in [
      'اختر طريقة تسجيل الدخول',
      'المتابعة باستخدام Google',
      'المتابعة باستخدام Apple',
      'أو',
      'أرسل لي رابطًا',
    ]) {
      expect(find.text(ar), findsOneWidget, reason: ar);
    }
    for (final en in ['Choose how', 'Continue with', 'Email me', 'or']) {
      expect(find.text(en), findsNothing, reason: en);
    }
    expect(find.text('البريد الإلكتروني لرابط الدخول'), findsOneWidget);
    // Mirrored: the Apple icon sits at the right of its label.
    final icon = tester.getCenter(find.byIcon(Icons.apple));
    final text = tester.getCenter(find.text('المتابعة باستخدام Apple'));
    expect(icon.dx, greaterThan(text.dx));
    e.dispose();
    t.dispose();
  });

  testWidgets('200% text: fade cue shows and every button is reachable', (
    tester,
  ) async {
    // iPhone SE height: the smallest phone we support.
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final e = TextEditingController(), t = TextEditingController();
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await tester.pumpWidget(
        _app(home: _options(e, t), locale: locale, textScale: 2),
      );
      await tester.pump();
      expect(find.byKey(const Key('signin-scroll-fade')), findsOneWidget);
      await expectLastButtonReachable(
        tester,
        'sign-in $locale',
        bodyKey: const Key('signin-body'),
      );
      expect(find.byKey(const Key('signin-scroll-fade')), findsNothing);
    }
    e.dispose();
    t.dispose();
  });
}

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);

Widget _options(TextEditingController e, TextEditingController t) =>
    SignInOptionsView(
      state: SignInOptionsState.options,
      emailController: e,
      tokenController: t,
      onGoogle: () {},
      onApple: () {},
      onSendLink: () {},
      onUseToken: () {},
    );
