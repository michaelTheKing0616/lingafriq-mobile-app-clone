import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class GameLoadingOverlay extends StatelessWidget {
  final bool visible;
  final String message;
  final VoidCallback? onCancel;
  final Widget child;

  const GameLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message = 'Loading game...',
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(message, style: PanAfricanTypography.bodyMedium(context)),
                    if (onCancel != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
