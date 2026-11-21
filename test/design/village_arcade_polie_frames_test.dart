import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// Paints the P3-017 frames from ramp roles and LingAfriqType.
/// The only golden files it compares are the frames in
/// docs/build/design/screens/. Write them with:
/// flutter test test/design/village_arcade_polie_frames_test.dart --update-goldens

const _outDir = 'docs/build/design/screens';
const _greeting = 'Ẹ kú àárọ̀';
const _surfaceHeight = 16000.0;

const _shelves = <String>[
  'Tone & Sound',
  'Words',
  'Grammar',
  'Speaking',
  'Culture',
  'Traditional',
  'Multiplayer',
];

const _places = <String>[
  'Circles',
  'Square',
  'Chats',
  'Status',
  'Clips',
  'Radio',
  'School',
  'Elder Hut',
  'Corrections',
  'Create',
];

const _chips = <String>[
  'Chat',
  'Explain',
  'Correct me',
  'Roleplay',
  'Story',
  'Translate',
];

enum _Screen { village, arcade, polie }

enum _Mode {
  data,
  skeleton,
  empty,
  error,
  offline,
  reduced,
  listening,
  unavailable,
}

class _Frame {
  const _Frame(this.fileName, this.theme, this.scale, this.screen, this.mode);

  final String fileName;
  final String theme;
  final double scale;
  final _Screen screen;
  final _Mode mode;
}

class _Roles {
  _Roles(this.values);

  final Map<String, Color> values;

  Color get surface => values['surface']!;
  Color get surfaceContainer => values['surfaceContainer']!;
  Color get onSurface => values['onSurface']!;
  Color get onSurfaceVariant => values['onSurfaceVariant']!;
  Color get accent => values['accent']!;
  Color get onAccent => values['onAccent']!;
  Color get danger => values['danger']!;
  Color get onDanger => values['onDanger']!;
  Color get info => values['info']!;
  Color get onInfo => values['onInfo']!;
}

class _TypeScale {
  _TypeScale({required this.displaySize, required this.displayHeight});

  final double displaySize;
  final double displayHeight;

  TextStyle display(Color color) => TextStyle(
    fontFamily: LingAfriqType.displayFamily,
    fontSize: displaySize,
    height: displayHeight,
    color: color,
  );

  TextStyle body(Color color) => TextStyle(
    fontFamily: LingAfriqType.bodyFamily,
    fontSize: LingAfriqType.bodySize,
    height: LingAfriqType.targetHeight,
    color: color,
  );

  TextStyle target(Color color) => LingAfriqType.target.copyWith(color: color);
}

Future<void> _loadFont(String family, String asset) async {
  final data = File(asset).readAsBytes().then(ByteData.sublistView);
  final loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Map<String, dynamic> _spec() =>
    jsonDecode(File('design/tokens/tokens.json').readAsStringSync())
        as Map<String, dynamic>;

Color _parseHex(String hex) {
  var raw = hex.replaceFirst('#', '');
  if (raw.length == 6) raw = 'FF$raw';
  return Color(int.parse(raw, radix: 16));
}

_Roles _roles(Map<String, dynamic> spec, String theme) {
  final colorRamps = spec['colorRamps'] as Map;
  final ramps = colorRamps['ramps'] as Map;
  final roles = (colorRamps['modes'] as Map)[theme] as Map;
  final values = <String, Color>{};
  for (final name in roles.keys) {
    final role = roles[name] as Map;
    final ramp = ramps[role['ramp']] as Map;
    final step = (ramp['steps'] as Map)['${role['step']}'] as Map;
    values[name as String] = _parseHex(step['hex'] as String);
  }
  return _Roles(values);
}

_TypeScale _typeScale(Map<String, dynamic> spec) {
  final display = (spec['type'] as Map)['display'] as Map;
  return _TypeScale(
    displaySize: (display['size'] as num).toDouble(),
    displayHeight: (display['height'] as num).toDouble(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> spec;

  setUpAll(() async {
    spec = _spec();
    await _loadFont(
      LingAfriqType.targetFamily,
      'assets/google_fonts/Andika-Regular.ttf',
    );
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
    await _loadFont(
      LingAfriqType.displayFamily,
      'assets/fonts/lingafriq/Nunito-Bold-LatinAfrica.ttf',
    );
  });

  test('spec cites tokens and does not hard-code a colour', () {
    final text = File('docs/build/design/screens/village_arcade_polie.md')
        .readAsStringSync();
    expect(text.contains('\u2014'), isFalse);
    expect(text.contains('\u2013'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(text), isFalse);
    final percents = RegExp(r'\d+(?:\.\d+)?\s*%')
        .allMatches(text)
        .map((match) => match.group(0))
        .toSet();
    expect(percents, {'200%'});
    expect(text.toLowerCase().contains('world-class'), isFalse);
    expect(text.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(text), isFalse);
    expect(
      RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(text),
      isFalse,
    );
    expect(text.contains('no XP'), isTrue);
    expect(text.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(text.contains('LingAfriqType.target'), isTrue);
    expect(text.contains('colorRamps.modes.light'), isTrue);
    expect(text.contains('colorRamps.modes.dark'), isTrue);
    expect(text.contains('MediaQuery.disableAnimations'), isTrue);
    expect(text.contains('TextScaler.linear(2)'), isTrue);
    expect(text.contains(_greeting), isTrue);
    expect(text.contains('Open Square'), isTrue);
    expect(text.contains('Hold to talk'), isTrue);
    expect(text.contains('What happened'), isTrue);
    expect(text.contains('Draft'), isTrue);
    expect(text.contains('Unmet'), isTrue);
    for (final shelf in _shelves) {
      expect(text.contains(shelf), isTrue, reason: shelf);
    }
    for (final place in _places) {
      expect(text.contains(place), isTrue, reason: place);
    }
    for (final chip in _chips) {
      expect(text.contains(chip), isTrue, reason: chip);
    }
    expect(text.toLowerCase().contains('confidence number'), isTrue);
    expect(RegExp(r'confidence\s*[:=]\s*\d').hasMatch(text), isFalse);
  });

  testWidgets('export Village, Arcade, and Polie frames at 390 px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, _surfaceHeight);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(390, _surfaceHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rolesLight = _roles(spec, 'light');
    final rolesDark = _roles(spec, 'dark');
    final type = _typeScale(spec);
    Directory(_outDir).createSync(recursive: true);

    const frames = <_Frame>[
      _Frame('village-light', 'light', 1, _Screen.village, _Mode.data),
      _Frame('village-dark', 'dark', 1, _Screen.village, _Mode.data),
      _Frame('village-200', 'light', 2, _Screen.village, _Mode.data),
      _Frame('village-skeleton', 'light', 1, _Screen.village, _Mode.skeleton),
      _Frame('village-empty', 'light', 1, _Screen.village, _Mode.empty),
      _Frame('village-error', 'light', 1, _Screen.village, _Mode.error),
      _Frame('village-offline', 'light', 1, _Screen.village, _Mode.offline),
      _Frame('village-reduced', 'light', 1, _Screen.village, _Mode.reduced),
      _Frame('arcade-light', 'light', 1, _Screen.arcade, _Mode.data),
      _Frame('arcade-dark', 'dark', 1, _Screen.arcade, _Mode.data),
      _Frame('arcade-200', 'light', 2, _Screen.arcade, _Mode.data),
      _Frame('arcade-skeleton', 'light', 1, _Screen.arcade, _Mode.skeleton),
      _Frame('arcade-empty', 'light', 1, _Screen.arcade, _Mode.empty),
      _Frame('arcade-error', 'light', 1, _Screen.arcade, _Mode.error),
      _Frame('arcade-offline', 'light', 1, _Screen.arcade, _Mode.offline),
      _Frame('arcade-reduced', 'light', 1, _Screen.arcade, _Mode.reduced),
      _Frame('polie-light', 'light', 1, _Screen.polie, _Mode.data),
      _Frame('polie-dark', 'dark', 1, _Screen.polie, _Mode.data),
      _Frame('polie-200', 'light', 2, _Screen.polie, _Mode.data),
      _Frame('polie-skeleton', 'light', 1, _Screen.polie, _Mode.skeleton),
      _Frame('polie-empty', 'light', 1, _Screen.polie, _Mode.empty),
      _Frame('polie-error', 'light', 1, _Screen.polie, _Mode.error),
      _Frame('polie-offline', 'light', 1, _Screen.polie, _Mode.offline),
      _Frame('polie-reduced', 'light', 1, _Screen.polie, _Mode.reduced),
      _Frame('polie-listening', 'light', 1, _Screen.polie, _Mode.listening),
      _Frame(
        'polie-ai-unavailable',
        'light',
        1,
        _Screen.polie,
        _Mode.unavailable,
      ),
    ];

    final lightPixels = <_Screen, Uint8List>{};

    for (final frame in frames) {
      final roles = frame.theme == 'dark' ? rolesDark : rolesLight;
      final reduced = frame.mode == _Mode.reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(390, _surfaceHeight),
            textScaler: TextScaler.linear(frame.scale),
            disableAnimations: reduced,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const Key('frame'),
                child: SizedBox(
                  width: 390,
                  child: ColoredBox(
                    color: roles.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
                      child: _screen(frame, roles, type),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('frame')),
      );
      expect(boundary.size.width, 390, reason: frame.fileName);
      expect(boundary.size.height, greaterThan(200), reason: frame.fileName);
      expect(
        boundary.size.height,
        lessThan(_surfaceHeight),
        reason: frame.fileName,
      );

      _expectFrame(tester, frame, roles);

      if (frame.mode == _Mode.data &&
          frame.theme == 'light' &&
          frame.scale == 1) {
        lightPixels[frame.screen] = await _rgba(tester, const Key('frame'));
      }
      if (frame.mode == _Mode.reduced) {
        final pixels = await _rgba(tester, const Key('frame'));
        expect(
          pixels,
          equals(lightPixels[frame.screen]),
          reason: frame.fileName,
        );
      }

      await expectLater(
        find.byKey(const Key('frame')),
        matchesGoldenFile('../../$_outDir/${frame.fileName}.png'),
      );
    }
  });
}

Future<Uint8List> _rgba(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ImageByteFormat.rawRgba),
  );
  return Uint8List.fromList(data!.buffer.asUint8List());
}

void _expectFrame(WidgetTester tester, _Frame frame, _Roles roles) {
  final buttons = tester
      .widgetList<SpecButton>(find.byType(SpecButton))
      .toList();
  for (final button in buttons) {
    expect(button.semanticsLabel.trim(), isNotEmpty, reason: frame.fileName);
    expect(button.label.trim(), isNotEmpty, reason: frame.fileName);
    final size = tester.getSize(find.byWidget(button));
    expect(
      size.width,
      greaterThanOrEqualTo(LingAfriqTokens.spacing48),
      reason: frame.fileName,
    );
    expect(
      size.height,
      greaterThanOrEqualTo(LingAfriqTokens.spacing48),
      reason: frame.fileName,
    );
  }

  final texts = tester.widgetList<Text>(find.byType(Text));
  for (final text in texts) {
    final value = text.data ?? '';
    expect(value.contains('%'), isFalse, reason: frame.fileName);
    expect(
      value.toLowerCase().contains('confidence'),
      isFalse,
      reason: frame.fileName,
    );
    expect(value.contains('XP'), isFalse, reason: frame.fileName);
    expect(value.contains('\u2014'), isFalse, reason: frame.fileName);
    expect(value.contains('\u2013'), isFalse, reason: frame.fileName);
  }

  final accent = buttons.where((button) => button.filled).length;
  if (frame.mode == _Mode.skeleton) {
    expect(accent, 0, reason: frame.fileName);
    expect(find.text('Loading'), findsOneWidget);
    expect(buttons, isEmpty, reason: frame.fileName);
  } else {
    expect(accent, 1, reason: frame.fileName);
  }

  if (frame.mode == _Mode.data || frame.mode == _Mode.reduced) {
    if (frame.screen == _Screen.village) {
      _expectOrder(tester, _places);
      expect(find.text('A list of places.'), findsOneWidget);
      expect(find.text('Locked'), findsNWidgets(2));
      expect(find.text('Unlocks at A2.'), findsOneWidget);
      expect(find.text('Unlocks at B1.'), findsOneWidget);
      expect(find.text('Preview'), findsNWidgets(2));
      expect(find.text('Open Square'), findsOneWidget);
      final filled = buttons.where((button) => button.filled).single;
      expect(filled.label, 'Open Square');
      expect(filled.background, roles.accent);
      expect(
        tester
            .widgetList<CueMark>(find.byType(CueMark))
            .map((mark) => mark.kind)
            .toList(),
        ['lock', 'lock'],
      );
    }
    if (frame.screen == _Screen.arcade) {
      _expectOrder(tester, _shelves);
      _expectOrder(tester, const [
        'Tone Trainer',
        'Word Match (audio)',
        'Word Match',
        'Memory Map',
        'Fill in the Blank',
        'Grammar Detective',
        'Market Bargaining',
        'Pronunciation Duel',
        'Proverb Unlocker',
        'Quiz Chef',
        'Ayo (mancala)',
        'Snakes & Ladders (cultural)',
        'Conversation Relay',
        'Liar Liar',
      ]);
      expect(find.text('Games sit on skill shelves.'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      final filled = buttons.where((button) => button.filled).single;
      expect(filled.label, 'Play');
      expect(filled.semanticsLabel, 'Play Tone Trainer');
      expect(find.byType(CueMark), findsNothing);
    }
    if (frame.screen == _Screen.polie) {
      _expectSpeaking(tester, buttons, roles, frame);
    }
  }

  if (frame.mode == _Mode.listening) {
    _expectChips(tester, buttons, roles);
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('You are talking.'), findsOneWidget);
    expect(find.text('Polie is listening.'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text(_greeting), findsNothing);
    expect(find.text('Speaking'), findsNothing);
    final filled = buttons.where((button) => button.filled).single;
    expect(filled.label, 'Stop');
    expect(
      tester
          .widgetList<CueMark>(find.byType(CueMark))
          .map((mark) => mark.kind)
          .toSet(),
      {'listen', 'check'},
    );
  }

  if (frame.mode == _Mode.unavailable) {
    _expectChips(tester, buttons, roles);
    expect(find.text('Polie is not available'), findsOneWidget);
    expect(find.text('No reply came back.'), findsOneWidget);
    expect(find.text('The tutor cannot answer right now.'), findsOneWidget);
    expect(
      find.text('Try again later. Polie did not speak for you.'),
      findsOneWidget,
    );
    expect(find.text(_greeting), findsNothing);
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    final filled = buttons.where((button) => button.filled).single;
    expect(filled.label, 'Try again');
    expect(
      tester
          .widgetList<CueMark>(find.byType(CueMark))
          .map((mark) => mark.kind)
          .toSet(),
      {'check', 'info'},
    );
  }

  if (frame.mode == _Mode.empty && frame.screen == _Screen.polie) {
    _expectChips(tester, buttons, roles);
    expect(find.text('No reply yet'), findsOneWidget);
    expect(find.text(_greeting), findsNothing);
    expect(find.text('Hold to talk'), findsOneWidget);
  }

  if (frame.mode == _Mode.error ||
      frame.mode == _Mode.offline ||
      frame.mode == _Mode.empty) {
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
  }

  if (frame.mode == _Mode.error) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'cross');
    expect(find.text(_greeting), findsNothing);
  }
  if (frame.mode == _Mode.offline) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'info');
    expect(find.text(_greeting), findsNothing);
  }
}

void _expectSpeaking(
  WidgetTester tester,
  List<SpecButton> buttons,
  _Roles roles,
  _Frame frame,
) {
  _expectChips(tester, buttons, roles);
  expect(find.text('Talk with Polie.'), findsOneWidget);
  expect(find.text('Speaking'), findsOneWidget);
  expect(find.text('Polie is speaking.'), findsOneWidget);
  expect(find.text('Polie says'), findsOneWidget);
  expect(find.text('Good morning.'), findsOneWidget);
  expect(find.text('Hold to talk'), findsOneWidget);
  expect(find.text(_greeting), findsOneWidget);
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'Hold to talk');
  expect(filled.semanticsLabel, 'Hold to talk to Polie');
  expect(
    tester
        .widgetList<CueMark>(find.byType(CueMark))
        .map((mark) => mark.kind)
        .toSet(),
    {'waves', 'check'},
  );
  _expectTarget(tester, frame);
}

void _expectChips(WidgetTester tester, List<SpecButton> buttons, _Roles roles) {
  _expectOrder(tester, _chips);
  final chat = buttons.singleWhere((button) => button.label == 'Chat');
  expect(chat.note, 'On');
  expect(chat.border, roles.onSurface);
  expect(chat.filled, isFalse);
  expect(chat.semanticsLabel, 'Chat, on');
  final mark = chat.mark;
  expect(mark, isA<CueMark>());
  expect((mark! as CueMark).kind, 'check');
  for (final name in _chips.skip(1)) {
    final chip = buttons.singleWhere((button) => button.label == name);
    expect(chip.note, isNull, reason: name);
    expect(chip.border, isNull, reason: name);
    expect(chip.filled, isFalse, reason: name);
  }
}

void _expectOrder(WidgetTester tester, List<String> labels) {
  final values = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .toList();
  var previous = -1;
  for (final label in labels) {
    final index = values.indexOf(label);
    expect(index, greaterThan(previous), reason: label);
    previous = index;
  }
}

void _expectTarget(WidgetTester tester, _Frame frame) {
  final andika = tester.renderObjectList<RenderParagraph>(find.text(_greeting));
  expect(andika, isNotEmpty, reason: frame.fileName);
  for (final paragraph in andika) {
    expect(paragraph.text.style?.fontFamily, LingAfriqType.targetFamily);
    expect(paragraph.text.style?.fontSize, LingAfriqType.targetSize);
    expect(
      paragraph.size.height,
      greaterThanOrEqualTo(LingAfriqType.targetSize),
    );
    expect(paragraph.size.width, greaterThan(0));
  }
  if (frame.scale == 2) {
    expect(andika.first.size.height, greaterThan(LingAfriqType.targetSize * 2));
  }
}

Widget _screen(_Frame frame, _Roles roles, _TypeScale type) {
  final mode = frame.mode == _Mode.reduced ? _Mode.data : frame.mode;
  return switch (frame.screen) {
    _Screen.village => _village(mode, roles, type),
    _Screen.arcade => _arcade(mode, roles, type),
    _Screen.polie => _polie(mode, roles, type),
  };
}

Widget _village(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading the village',
      heights: const [
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
      ],
    ),
    _Mode.empty => _notice(
      roles: roles,
      type: type,
      title: 'Village',
      headline: 'No places yet',
      headlineColor: roles.onSurface,
      happened: 'The place list is empty.',
      why: 'No place came back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'Village',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'Village did not load',
      headlineColor: roles.danger,
      happened: 'The place list did not open.',
      why: 'The list did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'Village',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'This village list is not saved on the phone.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _ => _column([
      Text('Village', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('A list of places.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _quietRow(roles, type, 'Circles', 'Study teams.', 'Open Circles'),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _column([
        Text('Square', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(
          'The feed and the rooms.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _primary(roles, type, 'Open Square', 'Open Square'),
      ]),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(roles, type, 'Chats', 'Messages in the village.', 'Open Chats'),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'Status',
        'A daily post in the language.',
        'Open Status',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _locked(
        roles,
        type,
        'Clips',
        'Unlocks at A2.',
        'Preview Clips',
        'Clips, locked. Unlocks at A2.',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(roles, type, 'Radio', 'Audio shows.', 'Open Radio'),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'School',
        'A class with a teacher.',
        'Open School',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'Elder Hut',
        'A short talk with a mentor.',
        'Open Elder Hut',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'Corrections',
        'A native speaker can correct you.',
        'Open Corrections',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _locked(
        roles,
        type,
        'Create',
        'Unlocks at B1.',
        'Preview Create',
        'Create, locked. Unlocks at B1.',
      ),
    ]),
  };
}

Widget _arcade(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading the arcade',
      heights: const [
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
      ],
    ),
    _Mode.empty => _notice(
      roles: roles,
      type: type,
      title: 'Arcade',
      headline: 'No games yet',
      headlineColor: roles.onSurface,
      happened: 'The shelves have no games.',
      why: 'No game came back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'Arcade',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'Arcade did not load',
      headlineColor: roles.danger,
      happened: 'The game list did not open.',
      why: 'The list did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'Arcade',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'These games are not saved on the phone.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _ => _column([
      Text('Arcade', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text(
        'Games sit on skill shelves.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Tone & Sound',
        featured: true,
        games: const [
          _Game('Tone Trainer', 'Hear a tone and pick the word.'),
          _Game('Word Match (audio)', 'Hear a word and match it.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Words',
        games: const [
          _Game('Word Match', 'Match a word to its meaning.'),
          _Game('Memory Map', 'Turn a tile and hear the word.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Grammar',
        games: const [
          _Game('Fill in the Blank', 'Type the missing word.'),
          _Game('Grammar Detective', 'Find what is wrong in the sentence.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Speaking',
        games: const [
          _Game('Market Bargaining', 'Talk with a trader about a price.'),
          _Game('Pronunciation Duel', 'Say a word with a friend.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Culture',
        games: const [
          _Game('Proverb Unlocker', 'Put a proverb back together.'),
          _Game('Quiz Chef', 'Follow a recipe in the language.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Traditional',
        games: const [
          _Game('Ayo (mancala)', 'Play the board and answer a word.'),
          _Game('Snakes & Ladders (cultural)', 'Move on the board and answer.'),
        ],
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _shelf(
        roles,
        type,
        'Multiplayer',
        games: const [
          _Game('Conversation Relay', 'Each person adds one spoken turn.'),
          _Game('Liar Liar', 'Spot the sentence that is wrong.'),
        ],
      ),
    ]),
  };
}

Widget _polie(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading Polie',
      heights: const [
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing48,
      ],
    ),
    _Mode.empty => _column([
      Text('Polie', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _chipList(roles, type),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('No reply yet', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'What happened', 'Polie has not spoken.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'Why', 'You have not held to talk.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'What to do', 'Hold to talk when you are ready.'),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Hold to talk', 'Hold to talk to Polie'),
    ]),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'Polie',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'Polie did not open',
      headlineColor: roles.danger,
      happened: 'The voice screen did not load.',
      why: 'The tutor screen did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'Polie',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'Polie needs the network to answer.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.listening => _column([
      Text('Polie', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('Talk with Polie.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _header(
        roles,
        type,
        kind: 'listen',
        word: 'Listening',
        line: 'You are talking.',
        semantics: 'Polie is listening',
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _chipList(roles, type),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('Polie is listening.', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Stop', 'Stop talking'),
    ]),
    _Mode.unavailable => _column([
      Text('Polie', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _chipList(roles, type),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _disc(
        fill: roles.info,
        child: CueMark(color: roles.onInfo, kind: 'info'),
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      Text('Polie is not available', style: type.body(roles.info)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'What happened', 'No reply came back.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'Why', 'The tutor cannot answer right now.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(
        type,
        roles,
        'What to do',
        'Try again later. Polie did not speak for you.',
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Try again', 'Try again'),
    ]),
    _ => _column([
      Text('Polie', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('Talk with Polie.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _header(
        roles,
        type,
        kind: 'waves',
        word: 'Speaking',
        line: 'Polie is speaking.',
        semantics: 'Polie is speaking',
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _chipList(roles, type),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('Polie says', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(_greeting, style: type.target(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text('Good morning.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Hold to talk', 'Hold to talk to Polie'),
    ]),
  };
}

Widget _shelf(
  _Roles roles,
  _TypeScale type,
  String name, {
  required List<_Game> games,
  bool featured = false,
}) {
  return _column([
    Text(name, style: type.body(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing8),
    if (featured) ...[
      Text(games.first.name, style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(games.first.line, style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      _primary(roles, type, 'Play', 'Play ${games.first.name}'),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        games.last.name,
        games.last.line,
        'Open ${games.last.name}',
      ),
    ] else ...[
      _quietRow(
        roles,
        type,
        games.first.name,
        games.first.line,
        'Open ${games.first.name}',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        games.last.name,
        games.last.line,
        'Open ${games.last.name}',
      ),
    ],
  ]);
}

Widget _header(
  _Roles roles,
  _TypeScale type, {
  required String kind,
  required String word,
  required String line,
  required String semantics,
}) {
  return Semantics(
    label: semantics,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _disc(
          fill: roles.surfaceContainer,
          child: CueMark(color: roles.onSurface, kind: kind),
        ),
        const SizedBox(width: LingAfriqTokens.spacing12),
        Expanded(
          child: _column([
            Text(word, style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text(line, style: type.body(roles.onSurfaceVariant)),
          ]),
        ),
      ],
    ),
  );
}

Widget _chipList(_Roles roles, _TypeScale type) {
  return _column([
    for (var i = 0; i < _chips.length; i++) ...[
      if (i > 0) const SizedBox(height: LingAfriqTokens.spacing8),
      _chip(roles, type, _chips[i], on: _chips[i] == 'Chat'),
    ],
  ]);
}

Widget _chip(_Roles roles, _TypeScale type, String label, {required bool on}) {
  return SpecButton(
    label: label,
    semanticsLabel: on ? '$label, on' : label,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: true,
    filled: false,
    pill: true,
    alignStart: true,
    border: on ? roles.onSurface : null,
    note: on ? 'On' : null,
    mark: on ? CueMark(color: roles.onSurface, kind: 'check') : null,
  );
}

Widget _locked(
  _Roles roles,
  _TypeScale type,
  String name,
  String line,
  String semantics,
  String blockSemantics,
) {
  return _column([
    Semantics(
      label: blockSemantics,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _disc(
            fill: roles.surfaceContainer,
            child: CueMark(color: roles.onSurface, kind: 'lock'),
          ),
          const SizedBox(width: LingAfriqTokens.spacing12),
          Expanded(
            child: _column([
              Text(name, style: type.body(roles.onSurface)),
              const SizedBox(height: LingAfriqTokens.spacing4),
              Text('Locked', style: type.body(roles.onSurfaceVariant)),
              const SizedBox(height: LingAfriqTokens.spacing4),
              Text(line, style: type.body(roles.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    ),
    const SizedBox(height: LingAfriqTokens.spacing8),
    _quiet(roles, type, 'Preview', semantics),
  ]);
}

Widget _notice({
  required _Roles roles,
  required _TypeScale type,
  required String title,
  required String headline,
  required Color headlineColor,
  required String happened,
  required String why,
  required String todo,
  required List<Widget> buttons,
  String? cue,
  Color? cueFill,
  Color? cueMark,
}) {
  return _column([
    Text(title, style: type.display(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing16),
    if (cue != null) ...[
      _disc(
        fill: cueFill!,
        child: CueMark(color: cueMark!, kind: cue),
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
    ],
    Text(headline, style: type.body(headlineColor)),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'What happened', happened),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'Why', why),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'What to do', todo),
    const SizedBox(height: LingAfriqTokens.spacing24),
    for (var i = 0; i < buttons.length; i++) ...[
      if (i > 0) const SizedBox(height: LingAfriqTokens.spacing8),
      buttons[i],
    ],
  ]);
}

Widget _fact(_TypeScale type, _Roles roles, String label, String line) {
  return _column([
    Text(label, style: type.body(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing4),
    Text(line, style: type.body(roles.onSurfaceVariant)),
  ]);
}

Widget _skeleton(
  _Roles roles,
  _TypeScale type, {
  required String label,
  required List<double> heights,
}) {
  return _column([
    Semantics(
      label: label,
      excludeSemantics: true,
      child: Text('Loading', style: type.body(roles.onSurfaceVariant)),
    ),
    const SizedBox(height: LingAfriqTokens.spacing12),
    for (final height in heights) ...[
      _block(roles, height),
      const SizedBox(height: LingAfriqTokens.spacing12),
    ],
  ]);
}

Widget _disc({required Color fill, required Widget child}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: LingAfriqTokens.spacing48,
      minHeight: LingAfriqTokens.spacing48,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing8),
        child: Center(child: child),
      ),
    ),
  );
}

Widget _block(_Roles roles, double height) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: roles.surfaceContainer,
        borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
      ),
    ),
  );
}

Widget _column(List<Widget> children) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

Widget _primary(_Roles roles, _TypeScale type, String label, String semantics) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.accent,
    foreground: roles.onAccent,
    textStyle: type.body(roles.onAccent),
    fillWidth: true,
    filled: true,
  );
}

Widget _quiet(_Roles roles, _TypeScale type, String label, String semantics) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: true,
    filled: false,
  );
}

Widget _quietRow(
  _Roles roles,
  _TypeScale type,
  String label,
  String line,
  String semantics,
) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: true,
    filled: false,
    alignStart: true,
    note: line,
  );
}

class _Game {
  const _Game(this.name, this.line);

  final String name;
  final String line;
}

class SpecButton extends StatelessWidget {
  const SpecButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.background,
    required this.foreground,
    required this.textStyle,
    required this.fillWidth,
    required this.filled,
    this.border,
    this.note,
    this.mark,
    this.pill = false,
    this.alignStart = false,
  });

  final String label;
  final String semanticsLabel;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;
  final bool fillWidth;
  final bool filled;
  final Color? border;
  final String? note;
  final Widget? mark;
  final bool pill;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final text = note == null
        ? Text(
            label,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: textStyle,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignStart
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(label, style: textStyle),
              Text(note!, style: textStyle),
            ],
          );
    final child = mark == null
        ? text
        : Row(
            children: [
              mark!,
              const SizedBox(width: LingAfriqTokens.spacing8),
              Expanded(child: text),
            ],
          );
    final button = Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: LingAfriqTokens.spacing48,
          minHeight: LingAfriqTokens.spacing48,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              pill ? LingAfriqTokens.radiuspill : LingAfriqTokens.radiusmd,
            ),
            border: border == null
                ? null
                : Border.all(
                    color: border!,
                    width: LingAfriqTokens.strokeregular,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing12,
            ),
            child: child,
          ),
        ),
      ),
    );
    if (!fillWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class CueMark extends StatelessWidget {
  const CueMark({super.key, required this.color, required this.kind});

  final Color color;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LingAfriqTokens.spacing24,
      height: LingAfriqTokens.spacing24,
      child: CustomPaint(painter: _CuePainter(color, kind)),
    );
  }
}

class _CuePainter extends CustomPainter {
  _CuePainter(this.color, this.kind);

  final Color color;
  final String kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case 'check':
        final path = Path()
          ..moveTo(w * 0.18, h * 0.55)
          ..lineTo(w * 0.42, h * 0.78)
          ..lineTo(w * 0.84, h * 0.26);
        canvas.drawPath(path, paint);
      case 'cross':
        canvas.drawLine(
          Offset(w * 0.22, h * 0.22),
          Offset(w * 0.78, h * 0.78),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.22),
          Offset(w * 0.22, h * 0.78),
          paint,
        );
      case 'info':
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.38, paint);
        canvas.drawLine(
          Offset(w * 0.5, h * 0.42),
          Offset(w * 0.5, h * 0.72),
          paint,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.28),
          LingAfriqTokens.strokehairline,
          Paint()..color = color,
        );
      case 'lock':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.46),
            const Radius.circular(LingAfriqTokens.radiusxs),
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromLTWH(w * 0.28, h * 0.12, w * 0.44, h * 0.48),
          3.14,
          3.14,
          false,
          paint,
        );
      case 'waves':
        final center = Offset(w * 0.32, h * 0.5);
        for (var i = 1; i <= 2; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: w * 0.16 * i),
            -0.9,
            1.8,
            false,
            paint,
          );
        }
      case 'listen':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.38, h * 0.12, w * 0.24, h * 0.42),
            Radius.circular(w * 0.12),
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromLTWH(w * 0.28, h * 0.28, w * 0.44, h * 0.36),
          0,
          3.14,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.64),
          Offset(w * 0.5, h * 0.82),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.36, h * 0.82),
          Offset(w * 0.64, h * 0.82),
          paint,
        );
      case 'dots':
        final fill = Paint()..color = color;
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(w * (0.25 + i * 0.25), h * 0.5),
            w * 0.08,
            fill,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.kind != kind;
}
