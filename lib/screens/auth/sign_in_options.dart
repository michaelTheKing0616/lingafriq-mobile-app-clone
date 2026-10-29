import 'package:lingafriq/utils/structured_logger.dart';
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
import 'package:lingafriq/screens/auth/sign_in_errors.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/api.dart';

enum SignInOptionsState { options, sending, linkSent, error }

/// Provider to start immediately when arriving from a specific button
/// (for example onboarding's "Continue with Google").
enum SignInAutoStart { none, google, apple }

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
    this.errorCode,
  });

  final SignInOptionsState state;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onSendLink;
  final VoidCallback onUseToken;
  final TextEditingController emailController;
  final TextEditingController tokenController;

  /// A [signInErrorCodes] entry; shown as learner copy, never raw.
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final linkSent = state == SignInOptionsState.linkSent;
    final lang = Localizations.maybeLocaleOf(context)?.languageCode;
    final title = linkSent
        ? 'Check your email for a sign-in link'
        : 'Choose how to sign in';
    return Semantics(
      label: linkSent ? 'signin.link_sent' : 'signin.options',
      child: Material(
        color: ModernGriotColors.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/cast_still_PaLingAfriq.png',
                  height: 112,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox(height: 112),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  title,
                  key: Key(linkSent ? 'signin.link_sent' : 'signin.options'),
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.headlineSmall(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                linkSent
                    ? 'The link expires in 15 minutes and works once.'
                    : 'Your answers and first win are saved to this account.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodyMedium(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (state == SignInOptionsState.sending)
                const Center(
                  child: CircularProgressIndicator(
                    key: Key('signin.sending'),
                    color: ModernGriotColors.primary,
                  ),
                ),
              if (state == SignInOptionsState.error) ...[
                _SignInError(
                  text: signInErrorText(errorCode ?? 'unknown', lang),
                ),
                const SizedBox(height: 16),
              ],
              if (state == SignInOptionsState.options ||
                  state == SignInOptionsState.error) ...[
                _ProviderButton(
                  label: 'Continue with Google',
                  icon: Icons.account_circle_outlined,
                  background: ModernGriotColors.surfaceContainerLowest,
                  foreground: ModernGriotColors.onSurface,
                  border: ModernGriotColors.outlineVariant,
                  onPressed: onGoogle,
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  background: ModernGriotColors.onSurface,
                  foreground: ModernGriotColors.surfaceContainerLowest,
                  border: ModernGriotColors.onSurface,
                  onPressed: onApple,
                ),
                const SizedBox(height: 24),
                _OrDivider(),
                const SizedBox(height: 24),
                _GriotField(
                  controller: emailController,
                  label: 'Email for a sign-in link',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _GoldButton(label: 'Email me a link', onPressed: onSendLink),
              ],
              if (linkSent) ...[
                _GriotField(
                  controller: tokenController,
                  label: 'Paste the link token',
                ),
                const SizedBox(height: 12),
                _GoldButton(
                  label: 'Sign in with the link',
                  onPressed: onUseToken,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInError extends StatelessWidget {
  const _SignInError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('signin.error'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          border: Border.all(color: ModernGriotColors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: ModernGriotColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: ModernGriotTypography.bodyMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foreground, size: 24),
        label: Text(
          label,
          style: ModernGriotTypography.labelLarge(
            context: context,
            color: foreground,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          ),
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ModernGriotColors.brandGold,
          foregroundColor: ModernGriotColors.onBrandGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          ),
        ),
        child: Text(
          label,
          style: ModernGriotTypography.labelLarge(
            context: context,
            color: ModernGriotColors.onBrandGold,
          ),
        ),
      ),
    );
  }
}

class _GriotField extends StatelessWidget {
  const _GriotField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder edge(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: ModernGriotColors.primary,
      style: ModernGriotTypography.bodyLarge(
        context: context,
        color: ModernGriotColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ModernGriotTypography.bodyMedium(
          context: context,
          color: ModernGriotColors.onSurfaceVariant,
        ),
        floatingLabelStyle: ModernGriotTypography.bodyMedium(
          context: context,
          color: ModernGriotColors.primary,
        ),
        filled: true,
        fillColor: ModernGriotColors.surfaceContainerLowest,
        enabledBorder: edge(ModernGriotColors.outlineVariant, 1.5),
        focusedBorder: edge(ModernGriotColors.primary, 2),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: ModernGriotColors.outlineVariant),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class SignInOptionsScreen extends ConsumerStatefulWidget {
  const SignInOptionsScreen({
    super.key,
    this.googleIdToken,
    this.appleIdToken,
    this.autoStart = SignInAutoStart.none,
  });

  final Future<String?> Function()? googleIdToken;
  final Future<String?> Function()? appleIdToken;
  final SignInAutoStart autoStart;

  @override
  ConsumerState<SignInOptionsScreen> createState() =>
      _SignInOptionsScreenState();
}

class _SignInOptionsScreenState extends ConsumerState<SignInOptionsScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  SignInOptionsState _state = SignInOptionsState.options;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart == SignInAutoStart.none) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.autoStart == SignInAutoStart.google ? _google() : _apple();
    });
  }

  Future<void> _google() async {
    String? token;
    try {
      token = await widget.googleIdToken?.call();
    } catch (e) {
      // Cancelled sheet or provider unavailable: show the honest retry
      // state instead of an unhandled error.
      logger.warn('google sign-in did not return a token', error: e);
    }
    if (!mounted) return;
    if (token == null) {
      _show('provider_invalid');
      return;
    }
    await _exchange(Api.googleSignIn, token);
  }

  Future<void> _apple() async {
    String? token;
    try {
      token = await widget.appleIdToken?.call();
    } catch (e) {
      // Cancelled sheet or provider unavailable: show the honest retry
      // state instead of an unhandled error.
      logger.warn('apple sign-in did not return a token', error: e);
    }
    if (!mounted) return;
    if (token == null) {
      _show('provider_invalid');
      return;
    }
    await _exchange(Api.appleSignIn, token);
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _exchange(String path, String idToken) async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      final response = await ref
          .read(client)
          .post(path, data: {'idToken': idToken});
      await _enter(response.data);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _enter(Object? body) async {
    if (body is! Map) throw StateError('sign_in_invalid');
    final access = (body['access'] ?? body['token'])?.toString();
    final refresh = (body['refresh'] ?? body['refreshToken'])?.toString();
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
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
      ref
          .read(navigationProvider)
          .navigateOffAll(
            EmailVerificationScreen(
              email: user.email,
              firstName: user.first_name,
            ),
          );
      return;
    }
    final seen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
    ref
        .read(navigationProvider)
        .navigateOffAll(
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
      _error = signInErrorCode(error);
      _state = SignInOptionsState.error;
    });
  }

  Future<void> _sendLink() async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      await ref
          .read(client)
          .post(Api.magicLink, data: {'email': _email.text.trim()});
      if (!mounted) return;
      setState(() => _state = SignInOptionsState.linkSent);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _useToken() async {
    setState(() => _state = SignInOptionsState.sending);
    try {
      final response = await ref
          .read(client)
          .post(Api.magicLinkVerify, data: {'token': _token.text.trim()});
      await _enter(response.data);
    } catch (error) {
      _fail(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      appBar: AppBar(
        backgroundColor: ModernGriotColors.surface,
        surfaceTintColor: ModernGriotColors.surface,
        foregroundColor: ModernGriotColors.onSurface,
        elevation: 0,
        title: Text(
          'Sign in',
          style: ModernGriotTypography.titleMedium(
            context: context,
            color: ModernGriotColors.onSurface,
          ),
        ),
      ),
      body: SignInOptionsView(
        state: _state,
        emailController: _email,
        tokenController: _token,
        errorCode: _error,
        onGoogle: _google,
        onApple: _apple,
        onSendLink: _sendLink,
        onUseToken: _useToken,
      ),
    );
  }
}
