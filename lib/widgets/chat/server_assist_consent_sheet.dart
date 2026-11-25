import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

enum ServerAssistFeature {
  aiGloss,
  aiToneExplain,
}

/// Keys: `overlay.serverassist.title`, `overlay.serverassist.body`.
abstract final class ServerAssistConsentCopy {
  static const title = 'Send this message to LingAfriq AI?';
  static const body =
      'Only this message goes to our server for a richer gloss or tone explanation. It is not stored in your chat history on the server.';
  static const allowOnceLabel = 'Allow for this message';
  static const declineLabel = 'Keep on device only';
  static const previewLabel = 'Message excerpt';
}

enum ServerAssistConsentChoice {
  allowOnce,
  declined,
  dismissed,
}

class ServerAssistConsentSheet extends StatelessWidget {
  const ServerAssistConsentSheet({
    super.key,
    required this.messagePreview,
    required this.feature,
    this.onAllowOnce,
    this.onDecline,
  });

  final String messagePreview;
  final ServerAssistFeature feature;
  final VoidCallback? onAllowOnce;
  final VoidCallback? onDecline;

  String get _featureLine {
    switch (feature) {
      case ServerAssistFeature.aiGloss:
        return 'AI word gloss';
      case ServerAssistFeature.aiToneExplain:
        return 'AI tone explanation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = PanAfricanSpacing.md;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ServerAssistConsentCopy.title,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: spacing),
            Text(
              ServerAssistConsentCopy.body,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: spacing),
            Text(
              _featureLine,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: spacing),
            Semantics(
              label: ServerAssistConsentCopy.previewLabel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(PanAfricanSpacing.sm),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Text(
                    messagePreview,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Semantics(
              button: true,
              label: ServerAssistConsentCopy.allowOnceLabel,
              child: SizedBox(
                width: double.infinity,
                height: AdaptiveLayout.minTouchTarget,
                child: FilledButton(
                  onPressed: () {
                    onAllowOnce?.call();
                    Navigator.of(context).pop(ServerAssistConsentChoice.allowOnce);
                  },
                  child: const Text(ServerAssistConsentCopy.allowOnceLabel),
                ),
              ),
            ),
            SizedBox(height: spacing),
            Semantics(
              button: true,
              label: ServerAssistConsentCopy.declineLabel,
              child: SizedBox(
                width: double.infinity,
                height: AdaptiveLayout.minTouchTarget,
                child: OutlinedButton(
                  onPressed: () {
                    onDecline?.call();
                    Navigator.of(context).pop(ServerAssistConsentChoice.declined);
                  },
                  child: const Text(ServerAssistConsentCopy.declineLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ServerAssistConsentChoice?> showServerAssistConsentSheet({
  required BuildContext context,
  required String messagePreview,
  required ServerAssistFeature feature,
}) {
  return showModalBottomSheet<ServerAssistConsentChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => ServerAssistConsentSheet(
      messagePreview: messagePreview,
      feature: feature,
    ),
  );
}
