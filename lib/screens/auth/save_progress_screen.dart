import 'package:flutter/material.dart';
import 'package:lingafriq/screens/auth/passkey_prompt.dart';

/// Save anonymous progress by creating a passkey on this device.
class SaveProgressScreen extends StatelessWidget {
  const SaveProgressScreen({
    super.key,
    required this.anonymousProgressId,
    required this.state,
    required this.onCreate,
    required this.onGoogle,
    required this.onApple,
    required this.onEmailLink,
    this.errorText,
  });

  final String anonymousProgressId;
  final PasskeyPromptState state;
  final VoidCallback onCreate;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onEmailLink;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (state == PasskeyPromptState.success)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Progress linked $anonymousProgressId',
                key: const Key('save_progress.linked'),
              ),
            ),
          Expanded(
            child: PasskeyPrompt(
              state: state,
              credentials: const [],
              canRegister: true,
              errorText: errorText,
              onSignIn: onCreate,
              onRegister: onCreate,
              onRemove: (_) {},
              onGoogle: onGoogle,
              onApple: onApple,
              onEmailLink: onEmailLink,
              onRetry: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
