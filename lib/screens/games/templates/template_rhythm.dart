import 'package:flutter/material.dart';
import 'game_template_shell.dart';

class TemplateRhythm extends StatelessWidget {
  final String title;
  final Widget rhythmArea;
  final Widget? controls;
  final bool loading;
  final String? progressLabel;
  final String? languageLabel;
  final String? scoreLabel;

  const TemplateRhythm({
    super.key,
    required this.title,
    required this.rhythmArea,
    this.controls,
    this.loading = false,
    this.progressLabel,
    this.languageLabel,
    this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GameTemplateShell(
      title: title,
      languageLabel: languageLabel,
      progressLabel: progressLabel,
      scoreLabel: scoreLabel,
      loading: loading,
      playArea: rhythmArea,
      actionBar: controls,
    );
  }
}
