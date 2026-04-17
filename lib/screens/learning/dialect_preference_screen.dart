import 'package:flutter/material.dart';
import 'package:lingafriq/screens/learning/dialect_variant_picker.dart';

/// Full-screen wrapper for [DialectVariantPicker] (used from drawer modals and named routes).
///
/// Optional route arguments: `{ 'umbrellaLanguage': 'yo' }` (defaults to `yo`).
class DialectPreferenceScreen extends StatelessWidget {
  const DialectPreferenceScreen({super.key});

  static String umbrellaLanguageFromArgs(Object? arguments) {
    if (arguments is Map) {
      final u = arguments['umbrellaLanguage']?.toString().trim();
      if (u != null && u.isNotEmpty) return u.toLowerCase();
    }
    return 'yo';
  }

  @override
  Widget build(BuildContext context) {
    final lang = umbrellaLanguageFromArgs(ModalRoute.of(context)?.settings.arguments);
    return Scaffold(
      appBar: AppBar(title: const Text('Common vs local dialect')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: DialectVariantPicker(umbrellaLanguage: lang),
        ),
      ),
    );
  }
}
