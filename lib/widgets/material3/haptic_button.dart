// Haptic Button Widget
// Material 3 button with haptic feedback and animations

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/haptic_feedback_helper.dart';
import 'material3_migration_helper.dart';

class HapticFilledButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final ButtonStyle? style;
  final bool animate;

  const HapticFilledButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.style,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = FilledButton(
      onPressed: onPressed != null
          ? () {
              HapticHelper.lightImpact();
              onPressed!();
            }
          : null,
      style: style ?? Material3Helper.filledButtonStyle(context),
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }

    if (animate) {
      return button.animate().scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.95, 0.95),
        duration: 100.ms,
        curve: Curves.easeInOut,
      );
    }

    return button;
  }
}

class HapticOutlinedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final ButtonStyle? style;
  final bool animate;

  const HapticOutlinedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.style,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = OutlinedButton(
      onPressed: onPressed != null
          ? () {
              HapticHelper.lightImpact();
              onPressed!();
            }
          : null,
      style: style ?? Material3Helper.outlinedButtonStyle(context),
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }

    if (animate) {
      return button.animate().scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.95, 0.95),
        duration: 100.ms,
        curve: Curves.easeInOut,
      );
    }

    return button;
  }
}

class HapticTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final ButtonStyle? style;
  final bool animate;

  const HapticTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.style,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = TextButton(
      onPressed: onPressed != null
          ? () {
              HapticHelper.lightImpact();
              onPressed!();
            }
          : null,
      style: style ?? Material3Helper.textButtonStyle(context),
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }

    if (animate) {
      return button.animate().scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.95, 0.95),
        duration: 100.ms,
        curve: Curves.easeInOut,
      );
    }

    return button;
  }
}

class HapticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? iconSize;
  final String actionType;

  const HapticIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.iconSize,
    this.actionType = 'button_press',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon, color: color, size: iconSize),
      onPressed: onPressed != null
          ? () {
              HapticHelper.feedbackForAction(actionType);
              onPressed!();
            }
          : null,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12),
      ),
    );

    return button.animate().scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(0.9, 0.9),
      duration: 100.ms,
      curve: Curves.easeInOut,
    );
  }
}

