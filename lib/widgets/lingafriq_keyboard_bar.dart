import 'package:flutter/widgets.dart';

import 'diacritic_keyboard_bar.dart';

/// LingAfriq-branded diacritic bar (EP-§6.7). Implementation lives in [DiacriticKeyboardBar].
class LingAfriqKeyboardBar extends StatelessWidget {
  const LingAfriqKeyboardBar({
    super.key,
    required this.languageId,
    required this.focusNode,
    required this.controller,
    required this.layouts,
    this.copy = const DiacriticKeyboardCopy(),
    this.onLayoutMissing,
  });

  final String languageId;
  final FocusNode focusNode;
  final TextEditingController controller;
  final DiacriticKeyboardLayouts layouts;
  final DiacriticKeyboardCopy copy;
  final void Function(String languageId)? onLayoutMissing;

  @override
  Widget build(BuildContext context) {
    return DiacriticKeyboardBar(
      languageId: languageId,
      focusNode: focusNode,
      controller: controller,
      layouts: layouts,
      copy: copy,
      onLayoutMissing: onLayoutMissing,
    );
  }
}
