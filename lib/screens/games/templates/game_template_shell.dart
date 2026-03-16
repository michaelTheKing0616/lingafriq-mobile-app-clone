import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/game_ui/index.dart';

class GameTemplateShell extends StatelessWidget {
  final String title;
  final String? languageLabel;
  final String? progressLabel;
  final String? scoreLabel;
  final Widget playArea;
  final Widget? actionBar;
  final bool loading;
  final String loadingMessage;
  final VoidCallback? onBack;
  final List<Widget> appBarActions;

  const GameTemplateShell({
    super.key,
    required this.title,
    required this.playArea,
    this.languageLabel,
    this.progressLabel,
    this.scoreLabel,
    this.actionBar,
    this.loading = false,
    this.loadingMessage = 'Loading game...',
    this.onBack,
    this.appBarActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GameLoadingOverlay(
      visible: loading,
      message: loadingMessage,
      child: Scaffold(
        appBar: GameTopBar(
          title: title,
          languageLabel: languageLabel,
          progressLabel: progressLabel,
          scoreLabel: scoreLabel,
          onBack: onBack ?? () => Navigator.of(context).pop(),
          actions: appBarActions,
        ),
        body: Column(
          children: [
            Expanded(child: playArea),
            if (actionBar != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: actionBar!,
              ),
          ],
        ),
      ),
    );
  }
}
