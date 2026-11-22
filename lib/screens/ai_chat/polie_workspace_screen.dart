import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/icons/lingafriq_icons.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

export 'package:lingafriq/features/polie_workspace/polie_workspace_screen.dart'
    show PolieWorkspaceScreen;

/// The six tutor modes the product already names, in sitemap order.
///
/// Chat, Explain, Correct me, Roleplay, Story, Translate.
/// A chip stays on Polie. This set does not add another mode.
enum SpeakTutorMode { chat, explain, correctMe, roleplay, story, translate }

/// Polie opened with no reply, or the screen did not open.
enum SpeakPolieStatus { empty, error, offline }

/// Polie for the Speak hub. The six tutor modes are chips on this screen.
class SpeakPolieScreen extends StatefulWidget {
  const SpeakPolieScreen({
    super.key,
    this.status = SpeakPolieStatus.empty,
    this.onBack,
    this.onHoldToTalk,
    this.onRetry,
  });

  static const List<SpeakTutorMode> modes = SpeakTutorMode.values;

  static Key modeKey(SpeakTutorMode mode) =>
      ValueKey<String>('speak-tutor-${mode.name}');

  final SpeakPolieStatus status;

  final VoidCallback? onBack;

  /// Next step when Polie has not spoken. It does not invent a reply.
  final VoidCallback? onHoldToTalk;

  final VoidCallback? onRetry;

  static String modeLabel(AppLocalizations l10n, SpeakTutorMode mode) {
    return switch (mode) {
      SpeakTutorMode.chat => l10n.hubHSpeakModeChat,
      SpeakTutorMode.explain => l10n.hubHSpeakModeExplain,
      SpeakTutorMode.correctMe => l10n.hubHSpeakModeCorrect,
      SpeakTutorMode.roleplay => l10n.hubHSpeakModeRoleplay,
      SpeakTutorMode.story => l10n.hubHSpeakModeStory,
      SpeakTutorMode.translate => l10n.hubHSpeakModeTranslate,
    };
  }

  @override
  State<SpeakPolieScreen> createState() => _SpeakPolieScreenState();
}

class _SpeakPolieScreenState extends State<SpeakPolieScreen> {
  SpeakTutorMode _mode = SpeakTutorMode.chat;

  void _back() {
    final VoidCallback? custom = widget.onBack;
    if (custom != null) {
      custom();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            LingButton(
              label: l10n.hubHSpeakBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: _back,
              role: LingButtonRole.quiet,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHSpeakPolie,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            Text(
              l10n.hubHSpeakTalk,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            if (widget.status == SpeakPolieStatus.empty) ...<Widget>[
              for (final SpeakTutorMode mode in SpeakPolieScreen.modes)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: LingAfriqTokens.spacing8,
                  ),
                  child: _ModeChip(
                    mode: mode,
                    selected: mode == _mode,
                    palette: palette,
                    l10n: l10n,
                    onTap: () => setState(() => _mode = mode),
                  ),
                ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              LingEmptyState(
                title: l10n.hubHSpeakNoReply,
                whatHappened: l10n.hubHSpeakPolieEmptyWhat,
                why: l10n.hubHSpeakPolieEmptyWhy,
                whatToDo: l10n.hubHSpeakPolieEmptyNext,
                actionLabel: l10n.hubHSpeakHoldToTalk,
                unavailableLabel: l10n.commonStateUnavailable,
                onAction: widget.onHoldToTalk ?? () {},
              ),
            ] else if (widget.status == SpeakPolieStatus.error)
              LingErrorState(
                whatHappened: l10n.hubHSpeakPolieErrorWhat,
                why: l10n.hubHSpeakPolieErrorWhy,
                whatToDo: l10n.hubHSpeakErrorNext,
                actionLabel: l10n.commonActionTryAgain,
                unavailableLabel: l10n.commonStateUnavailable,
                onAction: widget.onRetry ?? () {},
              )
            else
              LingOfflineState(
                whatHappened: l10n.shellOfflineWhat,
                why: l10n.hubHSpeakPolieOfflineWhy,
                whatToDo: l10n.shellOfflineNext,
                queuedActions: 0,
                actionLabel: l10n.commonActionTryAgain,
                unavailableLabel: l10n.commonStateUnavailable,
                onAction: widget.onRetry ?? () {},
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.palette,
    required this.l10n,
    required this.onTap,
  });

  final SpeakTutorMode mode;
  final bool selected;
  final LingPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name = SpeakPolieScreen.modeLabel(l10n, mode);
    final String spoken = selected ? l10n.hubHSpeakModeOn(name) : name;
    return Semantics(
      key: SpeakPolieScreen.modeKey(mode),
      container: true,
      button: true,
      selected: selected,
      label: spoken,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: Material(
          color: palette.surfaceContainer,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const StadiumBorder(),
            excludeFromSemantics: true,
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: LingAfriqTokens.spacing16,
                vertical: LingAfriqTokens.spacing12,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(LingAfriqTokens.radiuspill),
                ),
                border: selected
                    ? Border.all(
                        color: palette.onSurface,
                        width: LingAfriqTokens.strokeregular,
                      )
                    : null,
              ),
              child: Row(
                children: <Widget>[
                  if (selected) ...<Widget>[
                    ExcludeSemantics(
                      child: LingIcon(
                        name: LingIconName.check,
                        color: palette.onSurface,
                        accent: palette.accent,
                      ),
                    ),
                    const SizedBox(width: LingAfriqTokens.spacing8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ExcludeSemantics(
                          child: Text(
                            name,
                            style: lingBody(palette.onSurface),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        if (selected)
                          ExcludeSemantics(
                            child: Text(
                              l10n.hubHSpeakOn,
                              style: lingBody(palette.onSurface),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
