import 'package:flutter/material.dart';

class PasskeySummary {
  const PasskeySummary({required this.id, required this.backedUp});

  final String id;
  final bool backedUp;
}

enum PasskeyPromptState { prompt, registering, success, unsupported, error }

class PasskeyPrompt extends StatelessWidget {
  const PasskeyPrompt({
    super.key,
    required this.state,
    required this.credentials,
    required this.onSignIn,
    required this.onRegister,
    required this.onRemove,
    required this.onGoogle,
    required this.onApple,
    required this.onEmailLink,
    required this.onRetry,
    this.errorText,
    this.canRegister = false,
  });

  final PasskeyPromptState state;
  final List<PasskeySummary> credentials;
  final String? errorText;
  final bool canRegister;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final void Function(String id) onRemove;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onEmailLink;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: state == PasskeyPromptState.unsupported ? 'passkey.unsupported' : 'passkey.prompt',
      child: Material(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              state == PasskeyPromptState.unsupported
                  ? 'Passkeys are not available on this device'
                  : 'Use a passkey for this account',
              key: Key(state == PasskeyPromptState.unsupported ? 'passkey.unsupported' : 'passkey.prompt'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (state == PasskeyPromptState.registering)
              const Center(child: CircularProgressIndicator(key: Key('passkey.registering'))),
            if (state == PasskeyPromptState.error) ...[
              Text(errorText ?? 'The passkey could not be verified', key: const Key('passkey.error')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
            if (state == PasskeyPromptState.unsupported) ...[
              OutlinedButton(onPressed: onGoogle, child: const Text('Continue with Google')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onApple, child: const Text('Continue with Apple')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onEmailLink, child: const Text('Email me a link')),
            ],
            if (state == PasskeyPromptState.prompt || state == PasskeyPromptState.success) ...[
              if (canRegister)
                FilledButton(
                  key: const Key('passkey.register'),
                  onPressed: onRegister,
                  child: const Text('Add a passkey'),
                )
              else
                FilledButton(
                  key: const Key('passkey.sign-in'),
                  onPressed: onSignIn,
                  child: const Text('Sign in with a passkey'),
                ),
            ],
            if (credentials.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Passkeys on this account', key: const Key('passkey.success'), style: Theme.of(context).textTheme.titleMedium),
              for (final credential in credentials)
                ListTile(
                  title: Text(credential.id),
                  subtitle: Text(credential.backedUp ? 'Backed up' : 'This device'),
                  trailing: IconButton(
                    tooltip: 'Remove passkey',
                    onPressed: () => onRemove(credential.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
