import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/auth/email_verification_screen.dart';
import 'package:lingafriq/screens/auth/passkey_prompt.dart';
import 'package:lingafriq/screens/onboarding/onboarding_screen_material3.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/services/passkey_codec.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:passkeys/authenticator.dart';

class PasskeyApi {
  PasskeyApi({
    required Future<Response<dynamic>> Function(String path, {Object? data}) post,
    required Future<Response<dynamic>> Function(String path) get,
    required Future<Response<dynamic>> Function(String path) delete,
    required Future<void> Function(String access, String refresh) storeSession,
    PasskeyAuthenticator? authenticator,
  })  : _post = post,
        _get = get,
        _delete = delete,
        _storeSessionTokens = storeSession,
        authenticator = authenticator ?? PasskeyAuthenticator();

  final Future<Response<dynamic>> Function(String path, {Object? data}) _post;
  final Future<Response<dynamic>> Function(String path) _get;
  final Future<Response<dynamic>> Function(String path) _delete;
  final Future<void> Function(String access, String refresh) _storeSessionTokens;
  final PasskeyAuthenticator authenticator;

  Future<bool> canUse() async {
    try {
      return await authenticator.canAuthenticate();
    } catch (_) {
      return false;
    }
  }

  Future<void> signIn({String? email}) async {
    final started = await _post(
      Api.passkeyLoginOptions,
      data: {if (email != null && email.trim().isNotEmpty) 'email': email.trim()},
    );
    final assertion = await authenticator.authenticate(
      authenticationRequest(Map<String, dynamic>.from(started.data as Map)),
    );
    final verified = await _post(Api.passkeyLoginVerify, data: assertion.toJson());
    await _storeSession(verified.data);
  }

  Future<List<PasskeySummary>> register() async {
    final started = await _post(Api.passkeyRegisterOptions);
    final created = await authenticator.register(
      registrationRequest(Map<String, dynamic>.from(started.data as Map)),
    );
    final verified = await _post(Api.passkeyRegisterVerify, data: created.toJson());
    return passkeySummaries(verified.data);
  }

  Future<List<PasskeySummary>> list() async {
    final response = await _get(Api.passkeyCredentials);
    return passkeySummaries(response.data);
  }

  Future<List<PasskeySummary>> remove(String id) async {
    final response = await _delete(Api.passkeyCredential(id));
    return passkeySummaries(response.data);
  }

  Future<void> _storeSession(Object? body) async {
    if (body is! Map) throw StateError('passkey_invalid');
    final access = (body['access'] ?? body['token'])?.toString();
    final refresh = (body['refresh'] ?? body['refreshToken'])?.toString();
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      throw StateError('passkey_invalid');
    }
    await _storeSessionTokens(access, refresh);
  }
}

enum PasskeyMode { signIn, manage }

class PasskeyAccountScreen extends ConsumerStatefulWidget {
  const PasskeyAccountScreen({super.key, required this.mode, this.email});

  final PasskeyMode mode;
  final String? email;

  @override
  ConsumerState<PasskeyAccountScreen> createState() => _PasskeyAccountScreenState();
}

class _PasskeyAccountScreenState extends ConsumerState<PasskeyAccountScreen> {
  PasskeyPromptState _state = PasskeyPromptState.prompt;
  String? _error;
  List<PasskeySummary> _credentials = const [];

  PasskeyApi _api() {
    final dio = ref.read(client);
    return PasskeyApi(
      post: (path, {data}) => dio.post(path, data: data),
      get: (path) => dio.get(path),
      delete: (path) => dio.delete(path),
      storeSession: (access, refresh) async {
        final api = ref.read(apiProvider.notifier);
        api.token = access;
        api.refreshToken = refresh;
        await ref.read(sharedPreferencesProvider).storeAuthTokens(access, refresh);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final api = _api();
    final supported = await api.canUse();
    if (!mounted) return;
    if (!supported) {
      setState(() => _state = PasskeyPromptState.unsupported);
      return;
    }
    if (widget.mode == PasskeyMode.manage) {
      try {
        final rows = await api.list();
        if (!mounted) return;
        setState(() {
          _credentials = rows;
          _state = rows.isEmpty ? PasskeyPromptState.prompt : PasskeyPromptState.success;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _error = passkeyErrorText(error);
          _state = PasskeyPromptState.error;
        });
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _state = PasskeyPromptState.registering);
    try {
      await _api().signIn(email: widget.email);
      final userInfo = await ref.read(apiProvider.notifier).getUserInfo();
      final user = await ref.read(apiProvider.notifier).getProfileUser(userInfo.id);
      ref.read(userProvider.notifier).overrideUser(user);
      unawaited(ref.read(apiProvider.notifier).registerDevice());
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = passkeyErrorText(error);
        _state = PasskeyPromptState.error;
      });
    }
  }

  Future<void> _register() async {
    setState(() => _state = PasskeyPromptState.registering);
    try {
      final rows = await _api().register();
      if (!mounted) return;
      setState(() {
        _credentials = rows;
        _state = PasskeyPromptState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = passkeyErrorText(error);
        _state = PasskeyPromptState.error;
      });
    }
  }

  Future<void> _remove(String id) async {
    try {
      final rows = await _api().remove(id);
      if (!mounted) return;
      setState(() {
        _credentials = rows;
        _state = rows.isEmpty ? PasskeyPromptState.prompt : PasskeyPromptState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = passkeyErrorText(error);
        _state = PasskeyPromptState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passkey')),
      body: PasskeyPrompt(
        state: _state,
        credentials: _credentials,
        errorText: _error,
        canRegister: widget.mode == PasskeyMode.manage,
        onSignIn: _signIn,
        onRegister: _register,
        onRemove: _remove,
        onGoogle: () => Navigator.of(context).pop(),
        onApple: () => Navigator.of(context).pop(),
        onEmailLink: () => Navigator.of(context).pop(),
        onRetry: _prepare,
      ),
    );
  }
}
