import 'package:flutter/material.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/components/ling_bottom_sheet.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_card.dart';
import 'package:lingafriq/design/components/ling_chip.dart';
import 'package:lingafriq/design/components/ling_dialog.dart';
import 'package:lingafriq/design/components/ling_list_row.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/components/ling_text_field.dart';
import 'package:lingafriq/design/text/diacritic_keyboard.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Logical size of every catalogue screen. Width is the screen-frame spec.
const Size catalogueSurface = Size(390, 640);

/// Text scales the harness paints. 1.0 is 100 percent. 2.0 is 200 percent.
const List<double> catalogueTextScales = <double>[1, 2];

/// Brightness values the harness paints.
const List<Brightness> catalogueBrightnesses = <Brightness>[
  Brightness.light,
  Brightness.dark,
];

/// Finder key for the fixed catalogue surface.
const Key catalogueSurfaceKey = ValueKey<String>('catalogue-surface');

/// Target-language sample. The first phrase of [LingAfriqType.glyphProof].
const String catalogueTargetSample = 'Ẹ kú àárọ̀';

/// Passed into [DiacriticKeyboard] when the language has no Latin row.
const String catalogueNoLayoutMessage =
    'No diacritic layout for this language.';

/// Theme for one brightness. The seed is [LingAfriqTokens.navy].
ThemeData catalogueTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: LingAfriqTokens.navy,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: LingAfriqType.bodyFamily,
  );
}

/// Builds one catalogue screen for [brightness], [textScale], and [state].
typedef CatalogueBuilder =
    Widget Function(Brightness brightness, double textScale, String state);

/// One golden frame. Core controls skip dark text scale 2.0.
class CatalogueGoldenFrame {
  const CatalogueGoldenFrame(this.brightness, this.textScale);

  final Brightness brightness;
  final double textScale;
}

/// Light and dark, at text scale 1.0 and 2.0.
const List<CatalogueGoldenFrame> catalogueFullGoldenFrames =
    <CatalogueGoldenFrame>[
      CatalogueGoldenFrame(Brightness.light, 1),
      CatalogueGoldenFrame(Brightness.light, 2),
      CatalogueGoldenFrame(Brightness.dark, 1),
      CatalogueGoldenFrame(Brightness.dark, 2),
    ];

/// Light 1.0, dark 1.0, and light 2.0.
const List<CatalogueGoldenFrame> catalogueCoreGoldenFrames =
    <CatalogueGoldenFrame>[
      CatalogueGoldenFrame(Brightness.light, 1),
      CatalogueGoldenFrame(Brightness.dark, 1),
      CatalogueGoldenFrame(Brightness.light, 2),
    ];

/// States every core control paints.
const List<String> catalogueControlStates = <String>[
  'default',
  'pressed',
  'focused',
  'disabled',
  'loading',
];

/// One registered widget. [states] is never empty. Each id is a real state.
class CatalogueUseCase {
  const CatalogueUseCase({
    required this.id,
    required this.states,
    required this.build,
    this.goldenFrames = catalogueFullGoldenFrames,
  }) : assert(states.length > 0, 'A use case needs at least one state');

  final String id;
  final List<String> states;
  final CatalogueBuilder build;
  final List<CatalogueGoldenFrame> goldenFrames;
}

/// The design widgets that exist today, and only the states they already have.
final List<CatalogueUseCase> catalogueUseCases = <CatalogueUseCase>[
  CatalogueUseCase(
    id: 'targetText',
    states: const <String>['data'],
    build: _buildTargetText,
  ),
  CatalogueUseCase(
    id: 'diacriticKeyboard',
    states: const <String>['yoruba', 'noLayout'],
    build: _buildDiacriticKeyboard,
  ),
  CatalogueUseCase(
    id: 'readingOption',
    states: const <String>['on', 'off'],
    build: _buildReadingOption,
  ),
  CatalogueUseCase(
    id: 'lingButton',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingButton,
  ),
  CatalogueUseCase(
    id: 'lingCard',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingCard,
  ),
  CatalogueUseCase(
    id: 'lingTextField',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingTextField,
  ),
  CatalogueUseCase(
    id: 'lingListRow',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingListRow,
  ),
  CatalogueUseCase(
    id: 'lingBottomSheet',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingBottomSheet,
  ),
  CatalogueUseCase(
    id: 'lingDialog',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingDialog,
  ),
  CatalogueUseCase(
    id: 'lingChip',
    states: catalogueControlStates,
    goldenFrames: catalogueCoreGoldenFrames,
    build: _buildLingChip,
  ),
];

Widget _buildTargetText(Brightness brightness, double textScale, String state) {
  if (state != 'data') {
    throw ArgumentError.value(state, 'state', 'Not a TargetText state');
  }
  return _CatalogueFrame(
    brightness: brightness,
    textScale: textScale,
    child: const TargetText(text: catalogueTargetSample),
  );
}

Widget _buildDiacriticKeyboard(
  Brightness brightness,
  double textScale,
  String state,
) {
  final String languageId = switch (state) {
    'yoruba' => 'yo',
    'noLayout' => 'am',
    _ => throw ArgumentError.value(
      state,
      'state',
      'Not a diacritic keyboard state',
    ),
  };
  return _CatalogueFrame(
    brightness: brightness,
    textScale: textScale,
    child: _KeyboardPreview(languageId: languageId),
  );
}

Widget _buildReadingOption(
  Brightness brightness,
  double textScale,
  String state,
) {
  final bool enabled = switch (state) {
    'on' => true,
    'off' => false,
    _ => throw ArgumentError.value(
      state,
      'state',
      'Not a reading option state',
    ),
  };
  return _CatalogueFrame(
    brightness: brightness,
    textScale: textScale,
    child: _ReadingPreview(enabled: enabled),
  );
}

class _CatalogueFrame extends StatelessWidget {
  const _CatalogueFrame({
    required this.brightness,
    required this.textScale,
    required this.child,
    this.localized = false,
    this.expand = false,
    this.background,
  });

  final Brightness brightness;
  final double textScale;
  final Widget child;
  final bool localized;
  final bool expand;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = catalogueTheme(brightness);
    final bool framed = localized || expand || background != null;
    return SizedBox(
      key: catalogueSurfaceKey,
      width: catalogueSurface.width,
      height: catalogueSurface.height,
      child: framed ? _framedApp(theme) : _legacyApp(theme),
    );
  }

  Widget _legacyApp(ThemeData theme) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }

  Widget _framedApp(ThemeData theme) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        backgroundColor: background,
        body: expand
            ? SizedBox.expand(child: child)
            : Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }
}

Color _rampSurface(Brightness brightness) {
  return brightness == Brightness.dark
      ? LingAfriqTokens.roleDarkSurface
      : LingAfriqTokens.roleLightSurface;
}

Widget _controlFrame({
  required Brightness brightness,
  required double textScale,
  required Widget child,
  Alignment alignment = Alignment.topCenter,
}) {
  return _CatalogueFrame(
    brightness: brightness,
    textScale: textScale,
    localized: true,
    expand: true,
    background: _rampSurface(brightness),
    child: Align(alignment: alignment, child: child),
  );
}

Widget _buildLingButton(Brightness brightness, double textScale, String state) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    child: _WithCopy(
      builder: (AppLocalizations copy) => Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: LingButton(
          label: copy.commonActionContinue,
          unavailableLabel: copy.commonStateUnavailable,
          onPressed: state == 'disabled' ? null : () {},
          forcedState: LingForcedState.fromCatalogue(state),
        ),
      ),
    ),
  );
}

Widget _buildLingCard(Brightness brightness, double textScale, String state) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    child: _WithCopy(
      builder: (AppLocalizations copy) => Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: LingCard(
          semanticLabel: catalogueTargetSample,
          unavailableLabel: copy.commonStateUnavailable,
          onPressed: state == 'disabled' ? null : () {},
          forcedState: LingForcedState.fromCatalogue(state),
          child: const TargetText(text: catalogueTargetSample),
        ),
      ),
    ),
  );
}

Widget _buildLingTextField(
  Brightness brightness,
  double textScale,
  String state,
) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    child: _WithCopy(
      builder: (AppLocalizations copy) => Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: LingTextField(
          label: copy.commonActionSave,
          unavailableLabel: copy.commonStateUnavailable,
          forcedState: LingForcedState.fromCatalogue(state),
        ),
      ),
    ),
  );
}

Widget _buildLingListRow(
  Brightness brightness,
  double textScale,
  String state,
) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    child: _WithCopy(
      builder: (AppLocalizations copy) => LingListRow(
        label: copy.commonActionSave,
        unavailableLabel: copy.commonStateUnavailable,
        onPressed: state == 'disabled' ? null : () {},
        forcedState: LingForcedState.fromCatalogue(state),
      ),
    ),
  );
}

Widget _buildLingBottomSheet(
  Brightness brightness,
  double textScale,
  String state,
) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    alignment: Alignment.bottomCenter,
    child: _WithCopy(
      builder: (AppLocalizations copy) => LingBottomSheet(
        label: copy.commonActionShowMore,
        actionLabel: copy.commonActionContinue,
        unavailableLabel: copy.commonStateUnavailable,
        onAction: state == 'disabled' ? null : () {},
        forcedState: LingForcedState.fromCatalogue(state),
      ),
    ),
  );
}

Widget _buildLingDialog(Brightness brightness, double textScale, String state) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    alignment: Alignment.center,
    child: _WithCopy(
      builder: (AppLocalizations copy) => Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: LingDialog(
          title: copy.commonActionTryAgain,
          actionLabel: copy.commonActionClose,
          unavailableLabel: copy.commonStateUnavailable,
          onAction: state == 'disabled' ? null : () {},
          forcedState: LingForcedState.fromCatalogue(state),
        ),
      ),
    ),
  );
}

Widget _buildLingChip(Brightness brightness, double textScale, String state) {
  return _controlFrame(
    brightness: brightness,
    textScale: textScale,
    child: _WithCopy(
      builder: (AppLocalizations copy) => Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: LingChip(
          label: copy.commonActionShowMore,
          unavailableLabel: copy.commonStateUnavailable,
          onPressed: state == 'disabled' ? null : () {},
          forcedState: LingForcedState.fromCatalogue(state),
        ),
      ),
    ),
  );
}

class _WithCopy extends StatelessWidget {
  const _WithCopy({required this.builder});

  final Widget Function(AppLocalizations copy) builder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? copy = AppLocalizations.of(context);
    assert(copy != null, 'Catalogue copy is missing');
    return builder(copy!);
  }
}

class _KeyboardPreview extends StatefulWidget {
  const _KeyboardPreview({required this.languageId});

  final String languageId;

  @override
  State<_KeyboardPreview> createState() => _KeyboardPreviewState();
}

class _KeyboardPreviewState extends State<_KeyboardPreview> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiacriticKeyboard(
      languageId: widget.languageId,
      controller: _controller,
      noLayoutMessage: catalogueNoLayoutMessage,
    );
  }
}

class _ReadingPreview extends StatefulWidget {
  const _ReadingPreview({required this.enabled});

  final bool enabled;

  @override
  State<_ReadingPreview> createState() => _ReadingPreviewState();
}

class _ReadingPreviewState extends State<_ReadingPreview> {
  late final ReadingOptionController _controller = ReadingOptionController()
    ..enabled = widget.enabled;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReadingOptionTile(
      controller: _controller,
      title: ReadingOptionController.title,
      subtitle: ReadingOptionController.subtitle,
    );
  }
}
