import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/motion/motion_scope.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/ar/point_and_say_screen.dart';
import 'package:lingafriq/screens/media/import_media_screen.dart';
import 'package:lingafriq/screens/translate/live_translate_screen.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/search_index_service.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sheet actions, in the order the sheet paints them.
enum LensAction {
  pointSay('lens-point-say'),
  liveTranslate('lens-live-translate'),
  importMedia('lens-import-media'),
  conversationBridge('lens-conversation-bridge');

  const LensAction(this.routeName);

  /// Route name for the page this action opens. Not learner copy.
  final String routeName;
}

/// Camera access for the sheet. Anything other than granted is denied.
enum LensCameraAccess { allowed, denied }

/// Reads [status]. Granted is allowed. Every other status is denied.
LensCameraAccess lensAccessFor(PermissionStatus status) {
  if (status.isGranted) return LensCameraAccess.allowed;
  return LensCameraAccess.denied;
}

/// Platform camera status. A failed read is denied.
Future<LensCameraAccess> lensReadCamera() async {
  try {
    return lensAccessFor(await Permission.camera.status);
  } on Object {
    return LensCameraAccess.denied;
  }
}

/// True only when the bundled Point & Say model loads and is not empty.
///
/// A missing file, an empty file, or a failed read is not present. This does
/// not invent labels.
Future<bool> lensRecognizerIsPresent({
  Future<ByteData> Function(String asset)? loadAsset,
}) async {
  final Future<ByteData> Function(String asset) load =
      loadAsset ?? rootBundle.load;
  try {
    final ByteData bytes = await load(PointSayModelLicence.bundledAsset);
    return bytes.lengthInBytes > 0;
  } on Object {
    return false;
  }
}

/// Spoken and painted name for [action].
String lensActionLabel(AppLocalizations l10n, LensAction action) {
  return switch (action) {
    LensAction.pointSay => l10n.shellPointSay,
    LensAction.liveTranslate => l10n.shellLiveTranslate,
    LensAction.importMedia => l10n.shellImportMedia,
    LensAction.conversationBridge => l10n.lensBridge,
  };
}

Future<bool> _noNetwork() async => false;

/// Page an action opens.
///
/// Offline Live Translate and Conversation Bridge show the offline state.
/// Offline Point & Say opens the existing screen only when [recognizerPresent]
/// is already true. A missing recognizer does not open that screen.
Widget lensDestination({
  required LensAction action,
  required bool offline,
  required bool recognizerPresent,
  String pointSayLanguage = 'yoruba',
}) {
  switch (action) {
    case LensAction.pointSay:
      if (offline && !recognizerPresent) {
        return const LensRecognizerMissingPage();
      }
      return PointAndSayScreen(
        language: pointSayLanguage,
        hasInternet: offline ? _noNetwork : null,
      );
    case LensAction.liveTranslate:
    case LensAction.conversationBridge:
      if (offline) return LensOfflinePage(action: action);
      return const LiveTranslateWithConfidenceScreen();
    case LensAction.importMedia:
      return const ImportMediaScreen();
  }
}

/// Opens the screen Search uses for a word, or an empty state when [word] is
/// absent. An absent word does not invent a card.
Future<void> openLensDictionary(BuildContext context, SearchWord? word) {
  if (word == null) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: LensSheet.dictionaryRoute),
        builder: (BuildContext context) => const LensDictionaryEmptyPage(),
      ),
    );
  }
  return showWordCardSheet(context, lexeme: word.toLexeme());
}

/// Sheet the shell Lens control opens.
///
/// [AppShell.onLens] calls [LensEntry.open]. The sheet is not a tab.
abstract final class LensEntry {
  static Future<void> open(
    BuildContext context, {
    bool offline = false,
    LensCameraAccess? camera,
    bool? recognizerPresent,
    SearchWord? dictionaryWord,
    Future<bool> Function()? openSettings,
    Future<LensCameraAccess> Function()? readCamera,
    Future<bool> Function()? readRecognizer,
  }) async {
    final LensCameraAccess access =
        camera ?? await (readCamera ?? lensReadCamera)();
    final bool present =
        recognizerPresent ?? await (readRecognizer ?? lensRecognizerIsPresent)();
    if (!context.mounted) return;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingMotionPlan plan = LingMotionPlan.resolve(reduced: reduced);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: palette.surface,
      sheetAnimationStyle: AnimationStyle(
        duration: plan.duration,
        reverseDuration: plan.duration,
      ),
      builder: (BuildContext context) {
        return LensSheet(
          camera: access,
          offline: offline,
          recognizerPresent: present,
          dictionaryWord: dictionaryWord,
          openSettings: openSettings ?? openAppSettings,
        );
      },
    );
  }
}

/// Lens choices, or the camera-denied state.
class LensSheet extends StatelessWidget {
  const LensSheet({
    required this.camera,
    required this.offline,
    required this.recognizerPresent,
    required this.openSettings,
    this.dictionaryWord,
    super.key,
  });

  static const Key sheetKey = ValueKey<String>('lens-sheet');
  static const Key permissionKey = ValueKey<String>('lens-permission-denied');
  static const Key dictionaryKey = ValueKey<String>('lens-living-dictionary');
  static const Key closeKey = ValueKey<String>('lens-close');
  static const String dictionaryRoute = 'lens-living-dictionary';

  static Key actionKey(LensAction action) =>
      ValueKey<String>('lens-action-${action.name}');

  final LensCameraAccess camera;
  final bool offline;
  final bool recognizerPresent;
  final SearchWord? dictionaryWord;
  final Future<bool> Function() openSettings;

  void _openAction(BuildContext context, LensAction action) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: action.routeName),
        builder: (BuildContext context) {
          return lensDestination(
            action: action,
            offline: offline,
            recognizerPresent: recognizerPresent,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final List<Widget> body = camera == LensCameraAccess.denied
        ? <Widget>[_denied(context, l10n)]
        : <Widget>[
            for (final LensAction action in LensAction.values)
              Padding(
                padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
                child: _ActionButton(
                  buttonKey: actionKey(action),
                  label: lensActionLabel(l10n, action),
                  palette: palette,
                  onTap: () => _openAction(context, action),
                ),
              ),
            _ActionButton(
              buttonKey: dictionaryKey,
              label: l10n.shellLivingDictionary,
              palette: palette,
              onTap: () {
                unawaited(openLensDictionary(context, dictionaryWord));
              },
            ),
          ];
    return Material(
      key: sheetKey,
      color: palette.surface,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LingAfriqTokens.spacing48,
              ),
              child: TextButton(
                key: closeKey,
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                child: Text(
                  l10n.commonActionClose,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
          Text(
            l10n.shellLens,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
          ...body,
        ],
      ),
    );
  }

  Widget _denied(BuildContext context, AppLocalizations l10n) {
    return LingErrorState(
      key: permissionKey,
      whatHappened: l10n.lensPermissionWhat,
      why: l10n.lensPermissionWhy,
      whatToDo: l10n.lensPermissionNext,
      actionLabel: l10n.rmOpenSettings,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: () {
        unawaited(openSettings());
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final LingPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: buttonKey,
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: Material(
          color: palette.surfaceContainer,
          borderRadius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiussm),
          ),
          child: InkWell(
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(LingAfriqTokens.radiussm),
              ),
            ),
            excludeFromSemantics: true,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LingAfriqTokens.spacing16,
                vertical: LingAfriqTokens.spacing12,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Offline Live Translate or Conversation Bridge. The network screen stays closed.
class LensOfflinePage extends StatelessWidget {
  const LensOfflinePage({required this.action, super.key});

  static const Key pageKey = ValueKey<String>('lens-offline');

  final LensAction action;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      key: pageKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              lensActionLabel(l10n, action),
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingOfflineState(
              whatHappened: l10n.shellOfflineWhat,
              why: l10n.lensOfflineTranslateWhy,
              whatToDo: l10n.shellOfflineNext,
              queuedActions: 0,
              actionLabel: l10n.commonActionTryAgain,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () {
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Offline Point & Say when the on-device recognizer is not already present.
class LensRecognizerMissingPage extends StatelessWidget {
  const LensRecognizerMissingPage({super.key});

  static const Key pageKey = ValueKey<String>('lens-recognizer-missing');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      key: pageKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.shellPointSay,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingErrorState(
              whatHappened: l10n.lensRecognizerMissingWhat,
              why: l10n.lensRecognizerMissingWhy,
              whatToDo: l10n.lensRecognizerMissingNext,
              actionLabel: l10n.commonActionClose,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () {
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Living Dictionary with no word from Lens. No card is invented.
class LensDictionaryEmptyPage extends StatelessWidget {
  const LensDictionaryEmptyPage({super.key});

  static const Key pageKey = ValueKey<String>('lens-dictionary-empty');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      key: pageKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            LingEmptyState(
              title: l10n.shellLivingDictionary,
              whatHappened: l10n.lensNoWordWhat,
              why: l10n.lensNoWordWhy,
              whatToDo: l10n.lensNoWordNext,
              actionLabel: l10n.commonActionClose,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () {
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
