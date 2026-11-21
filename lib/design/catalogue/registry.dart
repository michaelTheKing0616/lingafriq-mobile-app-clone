import 'package:flutter/material.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/text/diacritic_keyboard.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

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
const String catalogueNoLayoutMessage = 'No diacritic layout for this language.';

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
typedef CatalogueBuilder = Widget Function(
  Brightness brightness,
  double textScale,
  String state,
);

/// One registered widget. [states] is never empty. Each id is a real state.
class CatalogueUseCase {
  const CatalogueUseCase({
    required this.id,
    required this.states,
    required this.build,
  }) : assert(states.length > 0, 'A use case needs at least one state');

  final String id;
  final List<String> states;
  final CatalogueBuilder build;
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

Widget _buildDiacriticKeyboard(Brightness brightness, double textScale, String state) {
  final String languageId = switch (state) {
    'yoruba' => 'yo',
    'noLayout' => 'am',
    _ => throw ArgumentError.value(state, 'state', 'Not a diacritic keyboard state'),
  };
  return _CatalogueFrame(
    brightness: brightness,
    textScale: textScale,
    child: _KeyboardPreview(languageId: languageId),
  );
}

Widget _buildReadingOption(Brightness brightness, double textScale, String state) {
  final bool enabled = switch (state) {
    'on' => true,
    'off' => false,
    _ => throw ArgumentError.value(state, 'state', 'Not a reading option state'),
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
  });

  final Brightness brightness;
  final double textScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = catalogueTheme(brightness);
    return SizedBox(
      key: catalogueSurfaceKey,
      width: catalogueSurface.width,
      height: catalogueSurface.height,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
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
          body: Align(
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
    );
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
