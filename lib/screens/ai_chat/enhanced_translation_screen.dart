import 'package:flutter/material.dart';
import 'package:lingafriq/screens/live_translate/live_translate_screen.dart';

/// Opens the live translate screen.
///
/// The navigation helper still constructs this type. The old response parser
/// now lives on [LiveTranslateScreen].
class EnhancedTranslationScreen extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final String? initialText;

  const EnhancedTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.initialText,
  });

  @override
  Widget build(BuildContext context) {
    return LiveTranslateScreen(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      initialText: initialText,
    );
  }
}
