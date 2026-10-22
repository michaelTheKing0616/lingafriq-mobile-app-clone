import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/auth/email_verification_screen.dart';
import 'package:lingafriq/screens/onboarding/onboarding_screen_material3.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/services/passkey_codec.dart';
import 'package:lingafriq/utils/api.dart';

enum SignInOptionsState { options, sending, linkSent, error }

class SignInOptionsView extends StatelessWidget {
  const SignInOptionsView({
    super.key,
    required this.state,
    required this.onGoogle,
    required this.onApple,
    required this.onSendLink,
    required this.emailController,
    required this.tokenController,
    required this.onUseToken,
    this.errorText,
  });

  final SignInOptionsState state;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onSendLink;
  final VoidCallback onUseToken;
  final TextEditingController emailController;
  final TextEditingController tokenController;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: state == SignInOptionsState.linkSent ? 'signin.link_sent' : 'signin.options',
      child: Material(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              state == SignInOptionsState.linkSent
                  ? 'Check your email for a sign-in link'
                  : 'Choose how to sign in',
              key: Key(state == SignInOptionsState.linkSent ? 'signin.link_sent' : 'signin.options'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (state == SignInOptionsState.sending)
              const Center(child: CircularProgressIndicator(key: Key('signin.sending'))),
            if (state == SignInOptionsState.error)
              Text(errorText ?? 'Sign-in could not be completed', key: const Key('signin.error')),
            if (state == SignInOptionsState.options || state == SignInOptionsState.error) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onGoogle, child: const Text('Continue with Google')),
              const SizedBox(height: 8),
              FilledButton(onPressed: onApple, child: const Text('Continue with Apple')),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email for a sign-in link'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onSendLink, child: const Text('Email me a link')),
            ],
            if (state == SignInOptionsState.linkSent) ...[
              const SizedBox(height: 12),
              const Text('The link expires in 15 minutes and works once.'),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Paste the link token'),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: onUseToken, child: const Text('Sign in with the link')),
            ],
          ],
        ),
      ),
    );
  }
}

class SignInOptionsScreen extends ConsumerStatefulWidget {
  const SignInOptionsScreen({
    super.key,
    this.googleIdToken,
    this.appleIdToken,
  });

  final Future<String?> Function()? googleIdToken;
  final Future<String?> Function()? appleIdToken;

  @override
  ConsumerState<SignInOptionsScreen> createState() => _SignInOptionsScreenState();
}

class _SignInOptionsScreenState extends ConsumerState<SignInOptionsScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  SignInOptionsState _state = SignInOptionsState.options;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _exchange(String path, String idToken) async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      final response = await ref.read(client).post(path, data: {'idToken': idToken});
      await _enter(response.data);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _enter(Object? body) async {
    if (body is! Map) throw StateError('sign_in_invalid');
    final access = (body['access'] ?? body['token'])?.toString();
    final refresh = (body['refresh'] ?? body['refreshToken'])?.toString();
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      throw StateError('sign_in_invalid');
    }
    final api = ref.read(apiProvider.notifier);
    api.token = access;
    api.refreshToken = refresh;
    await ref.read(sharedPreferencesProvider).storeAuthTokens(access, refresh);
    final userInfo = await api.getUserInfo();
    final user = await api.getProfileUser(userInfo.id);
    ref.read(userProvider.notifier).overrideUser(user);
    if (!mounted) return;
    if (!user.emailVerified) {
      ref.read(navigationProvider).navigateOffAll(
        EmailVerificationScreen(email: user.email, firstName: user.first_name),
      );
      return;
    }
    final seen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
    ref.read(navigationProvider).navigateOffAll(
      seen ? const TabsViewMaterial3() : const OnboardingScreenMaterial3(),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _state = SignInOptionsState.error;
    });
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _error = passkeyErrorText(error);
      _state = SignInOptionsState.error;
    });
  }

  Future<void> _sendLink() async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      await ref.read(client).post(Api.magicLink, data: {'email': _email.text.trim()});
      if (!mounted) return;
      setState(() => _state = SignInOptionsState.linkSent);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _useToken() async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      final response = await ref.read(client).post(Api.magicLinkVerify, data: {'token': _token.text.trim()});
      await _enter(response.data);
    } catch (error) {
      _fail(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SignInOptionsView(
        state: _state,
        emailController: _email,
        tokenController: _token,
        errorText: _error,
        onGoogle: () async {
          final token = await widget.googleIdToken?.call();
          if (token == null) {
            _show('provider_invalid');
            return;
          }
          await _exchange(Api.googleSignIn, token);
        },
        onApple: () async {
          final token = await widget.appleIdToken?.call();
          if (token == null) {
            _show('provider_invalid');
            return;
          }
          await _exchange(Api.appleSignIn, token);
        },
        onSendLink: _sendLink,
        onUseToken: _useToken,
      ),
    );
  }
}
