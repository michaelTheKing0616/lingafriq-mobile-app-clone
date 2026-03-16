import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'game_ui_tokens.dart';

class GameTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? languageLabel;
  final String? progressLabel;
  final String? scoreLabel;
  final VoidCallback? onBack;
  final bool warningState;
  final List<Widget> actions;

  const GameTopBar({
    super.key,
    required this.title,
    this.languageLabel,
    this.progressLabel,
    this.scoreLabel,
    this.onBack,
    this.warningState = false,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(GameUiTokens.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;
    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      leading: onBack == null
          ? null
          : IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PanAfricanTypography.titleMedium(context),
            ),
          ),
          if (languageLabel != null) _Chip(label: languageLabel!, color: PanAfricanColors.primary),
          if (progressLabel != null) _Chip(label: progressLabel!, color: warningState ? PanAfricanColors.warning : PanAfricanColors.kenteBlue),
          if (scoreLabel != null) _Chip(label: scoreLabel!, color: GameUiTokens.score(context)),
        ],
      ),
      actions: actions,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelSmall(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
