import 'package:flutter/material.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';

/// Shared on-device classifier for Point and Say (P7-945).
OnDeviceObjectClassifier createPointSayObjectClassifier() =>
    OnDeviceObjectClassifier();

/// Legacy route `point-and-say` resolves to [LensScreen] (P7-902, ADR-009).
class PointAndSayScreen extends StatelessWidget {
  const PointAndSayScreen({super.key, required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return LensScreen(fallbackLanguage: language);
  }
}
