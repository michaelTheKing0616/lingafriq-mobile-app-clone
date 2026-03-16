import 'package:flutter/material.dart';
import 'game_template_shell.dart';

class TemplatePronunciation extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? micControls;
  final bool loading;
  final String? progressLabel;
  final String? languageLabel;
  final String? scoreLabel;

  const TemplatePronunciation({
    super.key,
    required this.title,
    required this.content,
    this.micControls,
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
      playArea: content,
      actionBar: micControls,
    );
  }
}
