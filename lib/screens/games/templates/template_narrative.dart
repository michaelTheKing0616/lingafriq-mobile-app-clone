import 'package:flutter/material.dart';
import 'game_template_shell.dart';

class TemplateNarrative extends StatelessWidget {
  final String title;
  final Widget narrativeContent;
  final Widget? actions;
  final bool loading;
  final String? progressLabel;
  final String? languageLabel;
  final String? scoreLabel;

  const TemplateNarrative({
    super.key,
    required this.title,
    required this.narrativeContent,
    this.actions,
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
      playArea: narrativeContent,
      actionBar: actions,
    );
  }
}
