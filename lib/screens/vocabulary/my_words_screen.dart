import 'package:flutter/material.dart';
import 'package:lingafriq/screens/vocabulary/living_dictionary_screen.dart';

/// P7-919 — My Words personal layer (same GET/POST/DELETE contract as living dictionary).
class MyWordsScreen extends StatelessWidget {
  const MyWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LivingDictionaryScreen(variant: LivingDictionaryUiVariant.myWords);
  }
}
