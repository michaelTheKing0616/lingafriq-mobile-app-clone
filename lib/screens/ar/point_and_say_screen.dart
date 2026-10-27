import 'package:flutter/material.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';

/// Legacy route `point-and-say` resolves to [LensScreen] (P7-902, ADR-009).
class PointAndSayScreen extends StatelessWidget {
  const PointAndSayScreen({super.key, required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return LensScreen(fallbackLanguage: language);
  }
}
