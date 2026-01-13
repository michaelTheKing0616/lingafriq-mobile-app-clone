/// Haptic Feedback Helper
/// Provides consistent haptic feedback throughout the app
import 'package:flutter/services.dart';

class HapticHelper {
  /// Light impact - for subtle interactions (tabs, buttons)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for confirmations, selections
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions (purchases, deletions)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for pickers, switches
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for errors, warnings
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Custom feedback based on action type
  static void feedbackForAction(String actionType) {
    switch (actionType) {
      case 'button_press':
      case 'tab_change':
        lightImpact();
        break;
      case 'selection':
      case 'toggle':
        selectionClick();
        break;
      case 'confirmation':
      case 'submit':
        mediumImpact();
        break;
      case 'delete':
      case 'purchase':
      case 'important':
        heavyImpact();
        break;
      case 'error':
      case 'warning':
        vibrate();
        break;
      default:
        lightImpact();
    }
  }
}

