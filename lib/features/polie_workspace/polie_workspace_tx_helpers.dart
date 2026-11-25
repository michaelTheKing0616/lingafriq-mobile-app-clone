import 'package:flutter/material.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';

/// Maps route/setup language strings to a known Polie translation picker label.
String polieTxInitLabel(String raw) {
  final o = polieOptionForDisplayName(raw) ?? polieOptionForBackendKey(raw);
  if (o != null) return o.displayName;
  return polieOptionFromGroqLabel(raw).displayName;
}

String polieBackendKeyForDisplayOrGroq(String displayLabel) {
  final o = polieOptionForDisplayName(displayLabel);
  if (o != null) return o.backendKey;
  return polieOptionFromGroqLabel(displayLabel).backendKey;
}

void ensureDistinctTxLanguages(
  ValueNotifier<String> source,
  ValueNotifier<String> target,
) {
  if (source.value != target.value) return;
  final alt = kPolieTranslateLanguageOptions
      .map((e) => e.displayName)
      .firstWhere(
        (d) => d != source.value,
        orElse: () => kPolieTranslateLanguageOptions.first.displayName,
      );
  if (alt != source.value) target.value = alt;
}
