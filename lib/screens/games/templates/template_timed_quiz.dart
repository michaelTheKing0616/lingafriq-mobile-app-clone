import 'package:flutter/material.dart';
import 'game_template_shell.dart';

class TemplateTimedQuiz extends StatelessWidget {
  final String title;
  final Widget questionArea;
  final Widget? actions;
  final bool loading;
  final String? progressLabel;
  final String? languageLabel;
  final String? scoreLabel;

  const TemplateTimedQuiz({
    super.key,
    required this.title,
    required this.questionArea,
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
      playArea: questionArea,
      actionBar: actions,
    );
  }
}
