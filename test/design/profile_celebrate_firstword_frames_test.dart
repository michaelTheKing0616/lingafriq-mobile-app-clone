import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// Paints the P3-018 frames from ramp roles and LingAfriqType.
/// The only golden files it compares are the frames in
/// docs/build/design/screens/. Write them with:
/// flutter test test/design/profile_celebrate_firstword_frames_test.dart --update-goldens

const _outDir = 'docs/build/design/screens';
const _greeting = 'Ẹ kú àárọ̀';
const _syllable = 'kú';
const _surfaceHeight = 16000.0;

const _profileRows = <String>[
  'Wardrobe',
  'Progress',
  'Achievements',
  'Settings',
  'All features',
];

const _looks = <String>['Head wrap', 'Short hair', 'No portrait'];

enum _Screen { profile, wardrobe, firstword, levelup, lesson }

enum _Mode { data, skeleton, empty, error, offline, reduced }

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

Map<String, dynamic> _specJson() =>
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
    spec = _specJson();
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

  test('spec cites tokens and does not hard-code a colour or duration', () {
    final text = File(
      'docs/build/design/screens/profile_celebrate_firstword.md',
    ).readAsStringSync();
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
    expect(text.contains('${LingAfriqTokens.motionRareLevelUp}'), isFalse);
    expect(
      text.contains('${LingAfriqTokens.motionRareLessonComplete}'),
      isFalse,
    );
    expect(text.contains('motion.rare'), isTrue);
    expect(text.contains('motion.rare.durationMs.levelUp'), isTrue);
    expect(text.contains('motion.rare.durationMs.lessonComplete'), isTrue);
    expect(text.contains('LingAfriqTokens.motionRareLevelUp'), isTrue);
    expect(text.contains('LingAfriqTokens.motionRareLessonComplete'), isTrue);
    expect(text.contains('LingAfriqTokens.motionRareEasing'), isTrue);
    expect(text.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(text.contains('LingAfriqType.target'), isTrue);
    expect(text.contains('colorRamps.modes.light'), isTrue);
    expect(text.contains('colorRamps.modes.dark'), isTrue);
    expect(text.contains('MediaQuery.disableAnimations'), isTrue);
    expect(text.contains('TextScaler.linear(2)'), isTrue);
    expect(text.contains('adds no motion of its own'), isTrue);
    expect(text.contains('gentler'), isTrue);
    expect(text.contains('is not removed'), isTrue);
    expect(text.contains(_greeting), isTrue);
    expect(text.contains('Speak within 60 seconds'), isTrue);
    expect(text.contains('Open wardrobe'), isTrue);
    expect(text.contains('Skip for now'), isTrue);
    expect(text.contains('Avatar can wait until after lesson 2'), isTrue);
    expect(text.contains('This is optional.'), isTrue);
    expect(text.contains('Save look'), isTrue);
    expect(text.contains('I said it'), isTrue);
    expect(text.contains('Lesson unit complete'), isTrue);
    expect(text.contains('Unit 2. Family'), isTrue);
    expect(text.contains('You said the greeting.'), isTrue);
    expect(text.contains('Back to Today'), isTrue);
    expect(text.contains('You speak now'), isTrue);
    expect(text.contains('Good morning.'), isTrue);
    expect(text.contains('Mid, then high, then rising, then low.'), isTrue);
    expect(text.contains('No account yet.'), isTrue);
    expect(text.contains('Morning greetings.'), isTrue);
    expect(text.contains('All features'), isTrue);
    expect(text.contains('What happened'), isTrue);
    expect(text.contains('No shimmer'), isTrue);
    expect(text.contains('no XP'), isTrue);
    expect(text.contains('league rank'), isTrue);
    expect(text.contains('Draft'), isTrue);
    expect(text.contains('Unmet'), isTrue);
    for (final look in _looks) {
      expect(text.contains(look), isTrue, reason: look);
    }
    expect(text.toLowerCase().contains('confidence number'), isTrue);
    expect(RegExp(r'confidence\s*[:=]\s*\d').hasMatch(text), isFalse);
  });

  testWidgets('export Profile, wardrobe, first word, and celebration frames', (
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
      _Frame('profile-light', 'light', 1, _Screen.profile, _Mode.data),
      _Frame('profile-dark', 'dark', 1, _Screen.profile, _Mode.data),
      _Frame('profile-200', 'light', 2, _Screen.profile, _Mode.data),
      _Frame('profile-skeleton', 'light', 1, _Screen.profile, _Mode.skeleton),
      _Frame('profile-empty', 'light', 1, _Screen.profile, _Mode.empty),
      _Frame('profile-error', 'light', 1, _Screen.profile, _Mode.error),
      _Frame('profile-offline', 'light', 1, _Screen.profile, _Mode.offline),
      _Frame('profile-reduced', 'light', 1, _Screen.profile, _Mode.reduced),
      _Frame('wardrobe-light', 'light', 1, _Screen.wardrobe, _Mode.data),
      _Frame('wardrobe-dark', 'dark', 1, _Screen.wardrobe, _Mode.data),
      _Frame('wardrobe-200', 'light', 2, _Screen.wardrobe, _Mode.data),
      _Frame('wardrobe-empty', 'light', 1, _Screen.wardrobe, _Mode.empty),
      _Frame('wardrobe-reduced', 'light', 1, _Screen.wardrobe, _Mode.reduced),
      _Frame('firstword-light', 'light', 1, _Screen.firstword, _Mode.data),
      _Frame('firstword-dark', 'dark', 1, _Screen.firstword, _Mode.data),
      _Frame('firstword-200', 'light', 2, _Screen.firstword, _Mode.data),
      _Frame(
        'firstword-skeleton',
        'light',
        1,
        _Screen.firstword,
        _Mode.skeleton,
      ),
      _Frame('firstword-empty', 'light', 1, _Screen.firstword, _Mode.empty),
      _Frame('firstword-error', 'light', 1, _Screen.firstword, _Mode.error),
      _Frame('firstword-offline', 'light', 1, _Screen.firstword, _Mode.offline),
      _Frame('firstword-reduced', 'light', 1, _Screen.firstword, _Mode.reduced),
      _Frame('levelup-light', 'light', 1, _Screen.levelup, _Mode.data),
      _Frame('levelup-dark', 'dark', 1, _Screen.levelup, _Mode.data),
      _Frame('levelup-200', 'light', 2, _Screen.levelup, _Mode.data),
      _Frame('levelup-skeleton', 'light', 1, _Screen.levelup, _Mode.skeleton),
      _Frame('levelup-empty', 'light', 1, _Screen.levelup, _Mode.empty),
      _Frame('levelup-error', 'light', 1, _Screen.levelup, _Mode.error),
      _Frame('levelup-offline', 'light', 1, _Screen.levelup, _Mode.offline),
      _Frame('levelup-reduced', 'light', 1, _Screen.levelup, _Mode.reduced),
      _Frame('lesson-complete-light', 'light', 1, _Screen.lesson, _Mode.data),
      _Frame('lesson-complete-dark', 'dark', 1, _Screen.lesson, _Mode.data),
      _Frame('lesson-complete-200', 'light', 2, _Screen.lesson, _Mode.data),
      _Frame(
        'lesson-complete-reduced',
        'light',
        1,
        _Screen.lesson,
        _Mode.reduced,
      ),
    ];

    final lightPixels = <_Screen, Uint8List>{};
    final lightHeight = <_Screen, double>{};

    for (final frame in frames) {
      final roles = frame.theme == 'dark' ? rolesDark : rolesLight;
      final reduced = frame.mode == _Mode.reduced;
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
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
      FlutterError.onError = previous;
      expect(errors, isEmpty, reason: frame.fileName);

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
        lightHeight[frame.screen] = boundary.size.height;
      }
      if (frame.mode == _Mode.data &&
          frame.theme == 'light' &&
          frame.scale == 2) {
        expect(
          boundary.size.height,
          greaterThan(lightHeight[frame.screen]!),
          reason: frame.fileName,
        );
      }
      if (frame.mode == _Mode.reduced) {
        final pixels = await _rgba(tester, const Key('frame'));
        final rare = lightPixels[frame.screen];
        if (frame.screen == _Screen.levelup || frame.screen == _Screen.lesson) {
          expect(pixels, isNot(equals(rare)), reason: frame.fileName);
          expect(
            tester.widget<CelebrationMark>(find.byType(CelebrationMark)).phase,
            'end',
            reason: frame.fileName,
          );
        } else {
          expect(pixels, equals(rare), reason: frame.fileName);
        }
      }

      await expectLater(
        find.byKey(const Key('frame')),
        matchesGoldenFile('../../$_outDir/${frame.fileName}.png'),
      );
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
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
  final buttons = tester.widgetList<SpecButton>(find.byType(SpecButton)).toList();
  for (final button in buttons) {
    expect(button.semanticsLabel.trim(), isNotEmpty, reason: frame.fileName);
    expect(button.label.trim(), isNotEmpty, reason: frame.fileName);
    final size = tester.getSize(find.byWidget(button));
    expect(
      size.width,
      greaterThanOrEqualTo(LingAfriqTokens.spacing48),
      reason: '${frame.fileName} ${button.label}',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(LingAfriqTokens.spacing48),
      reason: '${frame.fileName} ${button.label}',
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
    expect(RegExp(r'Level\s+\d').hasMatch(value), isFalse, reason: value);
    expect(RegExp(r'\d+:\d+').hasMatch(value), isFalse, reason: value);
  }

  final accent = buttons.where((button) => button.filled).length;
  if (frame.mode == _Mode.skeleton) {
    expect(accent, 0, reason: frame.fileName);
    expect(find.text('Loading'), findsOneWidget);
    expect(buttons, isEmpty, reason: frame.fileName);
    expect(find.byType(CelebrationMark), findsNothing);
    expect(find.byType(ToneContour), findsNothing);
  } else {
    expect(accent, 1, reason: frame.fileName);
    final filled = buttons.where((button) => button.filled).single;
    expect(filled.background, roles.accent, reason: frame.fileName);
  }

  final showsData = frame.mode == _Mode.data || frame.mode == _Mode.reduced;
  if (showsData && frame.screen == _Screen.profile) {
    _expectProfile(tester, buttons);
  }
  if (showsData && frame.screen == _Screen.wardrobe) {
    _expectWardrobe(tester, buttons, roles);
  }
  if (showsData && frame.screen == _Screen.firstword) {
    _expectFirstWord(tester, buttons, frame);
  }
  if (showsData && frame.screen == _Screen.levelup) {
    _expectLevelUp(tester, buttons, frame);
  }
  if (showsData && frame.screen == _Screen.lesson) {
    _expectLesson(tester, buttons, frame);
  }

  if (frame.mode == _Mode.empty ||
      frame.mode == _Mode.error ||
      frame.mode == _Mode.offline) {
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(find.text(_greeting), findsNothing);
    expect(find.byType(CelebrationMark), findsNothing);
  }

  if (frame.mode == _Mode.error) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'cross');
  }
  if (frame.mode == _Mode.offline) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'info');
  }
  if (frame.mode == _Mode.empty && frame.screen == _Screen.wardrobe) {
    expect(find.text('No look chosen yet'), findsOneWidget);
    expect(find.text('On'), findsNothing);
    expect(find.text('Save look'), findsNothing);
    expect(find.text('Skip for now'), findsOneWidget);
    _expectOrder(tester, _looks);
    expect(find.byType(CueMark), findsNothing);
  }
}

void _expectProfile(WidgetTester tester, List<SpecButton> buttons) {
  _expectOrder(tester, _profileRows);
  expect(find.text('Me'), findsOneWidget);
  expect(find.text('Your profile.'), findsOneWidget);
  expect(find.text('Avatar can wait until after lesson 2.'), findsOneWidget);
  expect(find.text('Morning greetings.'), findsOneWidget);
  expect(find.text('Skip for now'), findsOneWidget);
  final skip = buttons.singleWhere((button) => button.label == 'Skip for now');
  expect(skip.filled, isFalse);
  expect(skip.semanticsLabel, 'Skip avatar for now');
  final wardrobe = buttons.singleWhere((button) => button.label == 'Wardrobe');
  expect(wardrobe.filled, isFalse);
  expect(wardrobe.semanticsLabel, 'Open wardrobe');
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'All features');
  expect(filled.semanticsLabel, 'Open all features');
  expect(find.byType(CueMark), findsNothing);
  expect(find.byType(CelebrationMark), findsNothing);
  expect(find.byType(ToneContour), findsNothing);
}

void _expectWardrobe(
  WidgetTester tester,
  List<SpecButton> buttons,
  _Roles roles,
) {
  _expectOrder(tester, _looks);
  expect(find.text('Wardrobe'), findsOneWidget);
  expect(find.text('This is optional.'), findsOneWidget);
  final chosen = buttons.singleWhere((button) => button.label == 'Head wrap');
  expect(chosen.filled, isFalse);
  expect(chosen.note, 'On');
  expect(chosen.border, roles.onSurface);
  expect(chosen.semanticsLabel, 'Head wrap, on');
  expect((chosen.mark! as CueMark).kind, 'check');
  final hair = buttons.singleWhere((button) => button.label == 'Short hair');
  expect(hair.note, 'Hair cut short.');
  expect(hair.border, isNull);
  expect(hair.semanticsLabel, 'Choose Short hair');
  final none = buttons.singleWhere((button) => button.label == 'No portrait');
  expect(none.note, 'No picture.');
  expect(none.border, isNull);
  expect(none.mark, isNull);
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'Save look');
  expect(filled.semanticsLabel, 'Save this look');
  expect(find.byType(ToneContour), findsNothing);
}

void _expectFirstWord(
  WidgetTester tester,
  List<SpecButton> buttons,
  _Frame frame,
) {
  expect(find.text('You speak now'), findsOneWidget);
  expect(find.text('Polie greets you in the language.'), findsOneWidget);
  expect(find.text('No account yet.'), findsOneWidget);
  expect(find.text('Tone Lens'), findsOneWidget);
  expect(find.text(_greeting), findsOneWidget);
  expect(find.text('Good morning.'), findsOneWidget);
  expect(find.text('Mid, then high, then rising, then low.'), findsOneWidget);
  expect(find.text('Speak within 60 seconds.'), findsOneWidget);
  expect(find.text('This is a target, not a timer.'), findsOneWidget);
  expect(find.text('Sample'), findsOneWidget);
  expect(find.text('We heard this syllable.'), findsOneWidget);
  expect(find.text(_syllable), findsOneWidget);
  expect(find.text('It was mid. The high tone sits up.'), findsOneWidget);
  final hear = buttons.singleWhere((button) => button.label == 'Hear it');
  expect(hear.filled, isFalse);
  expect(hear.semanticsLabel, 'Hear $_greeting');
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'I said it');
  expect(filled.semanticsLabel, 'I said the greeting');
  expect(
    tester.widget<ToneContour>(find.byType(ToneContour)).kind,
    'greeting',
  );
  _expectTarget(tester, _greeting, frame);
  _expectTarget(tester, _syllable, frame);
  expect(find.byType(CelebrationMark), findsNothing);
}

void _expectLevelUp(WidgetTester tester, List<SpecButton> buttons, _Frame frame) {
  expect(find.text('Rare'), findsOneWidget);
  expect(find.text('Lesson unit complete'), findsOneWidget);
  expect(find.text('Unit 2. Family'), findsOneWidget);
  expect(find.text('Next is the Family unit.'), findsOneWidget);
  expect(find.text('Continue'), findsOneWidget);
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'Continue');
  expect(filled.semanticsLabel, 'Continue to the Family unit');
  expect(
    tester.widget<CelebrationMark>(find.byType(CelebrationMark)).phase,
    frame.mode == _Mode.reduced ? 'end' : 'travel',
  );
  expect(find.text('Level up'), findsNothing);
  expect(find.byType(ToneContour), findsNothing);
}

void _expectLesson(WidgetTester tester, List<SpecButton> buttons, _Frame frame) {
  expect(find.text('Rare'), findsOneWidget);
  expect(find.text('Lesson complete'), findsOneWidget);
  expect(find.text('You said the greeting.'), findsOneWidget);
  final filled = buttons.where((button) => button.filled).single;
  expect(filled.label, 'Back to Today');
  expect(filled.semanticsLabel, 'Back to Today');
  expect(
    tester.widget<CelebrationMark>(find.byType(CelebrationMark)).phase,
    frame.mode == _Mode.reduced ? 'end' : 'travel',
  );
  expect(find.byType(ToneContour), findsNothing);
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

void _expectTarget(WidgetTester tester, String sample, _Frame frame) {
  final andika = tester.renderObjectList<RenderParagraph>(find.text(sample));
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

bool _quietReduced(_Frame frame) {
  return frame.mode == _Mode.reduced &&
      (frame.screen == _Screen.profile ||
          frame.screen == _Screen.wardrobe ||
          frame.screen == _Screen.firstword);
}

Widget _screen(_Frame frame, _Roles roles, _TypeScale type) {
  final mode = _quietReduced(frame) ? _Mode.data : frame.mode;
  return switch (frame.screen) {
    _Screen.profile => _profile(mode, roles, type),
    _Screen.wardrobe => _wardrobe(mode, roles, type),
    _Screen.firstword => _firstWord(mode, roles, type),
    _Screen.levelup => _levelUp(mode, roles, type),
    _Screen.lesson => _lesson(mode, roles, type),
  };
}

Widget _profile(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading the profile',
      heights: const [
        LingAfriqTokens.spacing32,
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
      title: 'Me',
      headline: 'No profile yet',
      headlineColor: roles.onSurface,
      happened: 'This profile is empty.',
      why: 'You have not saved a lesson yet.',
      todo: 'Say the first word.',
      buttons: [
        _primary(roles, type, 'Say the first word', 'Say the first word'),
      ],
    ),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'Me',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'Profile did not load',
      headlineColor: roles.danger,
      happened: 'The profile did not open.',
      why: 'The profile did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'Me',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'This profile is not saved on the phone.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _ => _column([
      Text('Me', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('Your profile.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(
        'Avatar can wait until after lesson 2.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _quiet(roles, type, 'Skip for now', 'Skip avatar for now'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _quietRow(
        roles,
        type,
        'Wardrobe',
        'Pick a look later.',
        'Open wardrobe',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'Progress',
        'Morning greetings.',
        'Open progress',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(
        roles,
        type,
        'Achievements',
        'You said a greeting.',
        'Open achievements',
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _quietRow(roles, type, 'Settings', 'Sound and text.', 'Open settings'),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'All features', 'Open all features'),
    ]),
  };
}

Widget _wardrobe(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.empty => _column([
      Text('Wardrobe', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('This is optional.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('No look chosen yet', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _lookRow(
        roles,
        type,
        name: 'Head wrap',
        line: 'A cloth on the head.',
        semantics: 'Choose Head wrap',
        on: false,
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _lookRow(
        roles,
        type,
        name: 'Short hair',
        line: 'Hair cut short.',
        semantics: 'Choose Short hair',
        on: false,
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _lookRow(
        roles,
        type,
        name: 'No portrait',
        line: 'No picture.',
        semantics: 'Choose No portrait',
        on: false,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'What happened', 'No look is chosen.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'Why', 'You have not picked one.'),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _fact(type, roles, 'What to do', 'Pick a look, or skip for now.'),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Skip for now', 'Skip avatar for now'),
    ]),
    _ => _column([
      Text('Wardrobe', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text('This is optional.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _lookRow(
        roles,
        type,
        name: 'Head wrap',
        line: 'On',
        semantics: 'Head wrap, on',
        on: true,
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _lookRow(
        roles,
        type,
        name: 'Short hair',
        line: 'Hair cut short.',
        semantics: 'Choose Short hair',
        on: false,
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      _lookRow(
        roles,
        type,
        name: 'No portrait',
        line: 'No picture.',
        semantics: 'Choose No portrait',
        on: false,
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Save look', 'Save this look'),
    ]),
  };
}

Widget _firstWord(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading the first word',
      heights: const [
        LingAfriqTokens.spacing32,
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
      title: 'You speak now',
      headline: 'No word yet',
      headlineColor: roles.onSurface,
      happened: 'There is no greeting to say.',
      why: 'No word came back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'You speak now',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'The first word did not open',
      headlineColor: roles.danger,
      happened: 'The greeting did not load.',
      why: 'The word did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'You speak now',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'This greeting is not saved on the phone.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _ => _column([
      Text('You speak now', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Text(
        'Polie greets you in the language.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text('No account yet.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('Tone Lens', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Semantics(
        label: 'Tone on $_greeting. Mid, then high, then rising, then low.',
        child: ToneContour(kind: 'greeting', color: roles.onSurface),
      ),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(_greeting, style: type.target(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text('Good morning.', style: type.body(roles.onSurfaceVariant)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(
        'Mid, then high, then rising, then low.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      SpecNote(
        label: 'Speak within 60 seconds.',
        semanticsLabel: 'Product target. Speak within 60 seconds. Not a timer.',
        background: roles.surfaceContainer,
        textStyle: type.body(roles.onSurface),
      ),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(
        'This is a target, not a timer.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _quiet(roles, type, 'Hear it', 'Hear $_greeting'),
      const SizedBox(height: LingAfriqTokens.spacing24),
      SpecNote(
        label: 'Sample',
        semanticsLabel: 'Sample data',
        background: roles.surfaceContainer,
        textStyle: type.body(roles.onSurface),
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
      Text('We heard this syllable.', style: type.body(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(_syllable, style: type.target(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(
        'It was mid. The high tone sits up.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'I said it', 'I said the greeting'),
    ]),
  };
}

Widget _levelUp(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
      roles,
      type,
      label: 'Loading the celebration',
      heights: const [
        LingAfriqTokens.spacing48,
        LingAfriqTokens.spacing64,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing32,
        LingAfriqTokens.spacing48,
      ],
    ),
    _Mode.empty => _notice(
      roles: roles,
      type: type,
      title: 'Level up',
      headline: 'No next unit',
      headlineColor: roles.onSurface,
      happened: 'There is no next unit.',
      why: 'The path did not name one.',
      todo: 'Go back to Today.',
      buttons: [_primary(roles, type, 'Back to Today', 'Back to Today')],
    ),
    _Mode.error => _notice(
      roles: roles,
      type: type,
      title: 'Level up',
      cue: 'cross',
      cueFill: roles.danger,
      cueMark: roles.onDanger,
      headline: 'Level up did not open',
      headlineColor: roles.danger,
      happened: 'The celebration did not start.',
      why: 'The next unit did not come back.',
      todo: 'Try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _Mode.offline => _notice(
      roles: roles,
      type: type,
      title: 'Level up',
      cue: 'info',
      cueFill: roles.info,
      cueMark: roles.onInfo,
      headline: 'You are offline',
      headlineColor: roles.info,
      happened: 'The phone has no network.',
      why: 'The next unit is not saved on the phone.',
      todo: 'Connect, then try again.',
      buttons: [_primary(roles, type, 'Try again', 'Try again')],
    ),
    _ => _column([
      SpecNote(
        label: 'Rare',
        semanticsLabel: 'Rare tier motion',
        background: roles.surfaceContainer,
        textStyle: type.body(roles.onSurface),
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      CelebrationMark(
        color: roles.onSurface,
        phase: mode == _Mode.reduced ? 'end' : 'travel',
        semanticsLabel: mode == _Mode.reduced
            ? 'Celebration mark. End state.'
            : 'Celebration mark. Mid travel.',
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      Text('Lesson unit complete', style: type.display(roles.onSurface)),
      const SizedBox(height: LingAfriqTokens.spacing8),
      Semantics(
        label: 'Next unit. Unit 2. Family.',
        excludeSemantics: true,
        child: Text('Unit 2. Family', style: type.body(roles.onSurface)),
      ),
      const SizedBox(height: LingAfriqTokens.spacing4),
      Text(
        'Next is the Family unit.',
        style: type.body(roles.onSurfaceVariant),
      ),
      const SizedBox(height: LingAfriqTokens.spacing24),
      _primary(roles, type, 'Continue', 'Continue to the Family unit'),
    ]),
  };
}

Widget _lesson(_Mode mode, _Roles roles, _TypeScale type) {
  final reduced = mode == _Mode.reduced;
  return _column([
    SpecNote(
      label: 'Rare',
      semanticsLabel: 'Rare tier motion',
      background: roles.surfaceContainer,
      textStyle: type.body(roles.onSurface),
    ),
    const SizedBox(height: LingAfriqTokens.spacing16),
    CelebrationMark(
      color: roles.onSurface,
      phase: reduced ? 'end' : 'travel',
      semanticsLabel: reduced
          ? 'Celebration mark. End state.'
          : 'Celebration mark. Mid travel.',
    ),
    const SizedBox(height: LingAfriqTokens.spacing16),
    Text('Lesson complete', style: type.display(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing8),
    Text('You said the greeting.', style: type.body(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing24),
    _primary(roles, type, 'Back to Today', 'Back to Today'),
  ]);
}

Widget _lookRow(
  _Roles roles,
  _TypeScale type, {
  required String name,
  required String line,
  required String semantics,
  required bool on,
}) {
  return SpecButton(
    label: name,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: true,
    filled: false,
    alignStart: true,
    note: line,
    border: on ? roles.onSurface : null,
    mark: on ? CueMark(color: roles.onSurface, kind: 'check') : null,
  );
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
      SpecBlock(color: roles.surfaceContainer, height: height),
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

class SpecNote extends StatelessWidget {
  const SpecNote({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.background,
    required this.textStyle,
  });

  final String label;
  final String semanticsLabel;
  final Color background;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiuspill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing8,
            ),
            child: Text(label, style: textStyle),
          ),
        ),
      ),
    );
  }
}

class SpecBlock extends StatelessWidget {
  const SpecBlock({super.key, required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
        ),
      ),
    );
  }
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
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
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
    }
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.kind != kind;
}

class ToneContour extends StatelessWidget {
  const ToneContour({super.key, required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LingAfriqTokens.spacing48,
      width: double.infinity,
      child: CustomPaint(painter: _ContourPainter(kind, color)),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter(this.kind, this.color);

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    final left = LingAfriqTokens.spacing8;
    final right = size.width - LingAfriqTokens.spacing8;
    final top = LingAfriqTokens.spacing8;
    final bottom = size.height - LingAfriqTokens.spacing8;
    final midY = size.height / 2;
    if (kind != 'greeting') return;
    final gap = LingAfriqTokens.spacing4;
    final span = right - left;
    final seg = (span - gap * 3) / 4;
    canvas.drawLine(Offset(left, midY), Offset(left + seg, midY), paint);
    final highStart = left + seg + gap;
    canvas.drawLine(Offset(highStart, top), Offset(highStart + seg, top), paint);
    final riseStart = highStart + seg + gap;
    canvas.drawLine(
      Offset(riseStart, bottom),
      Offset(riseStart + seg, top),
      paint,
    );
    final lowStart = riseStart + seg + gap;
    canvas.drawLine(
      Offset(lowStart, bottom),
      Offset(lowStart + seg, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

class CelebrationMark extends StatelessWidget {
  const CelebrationMark({
    super.key,
    required this.color,
    required this.phase,
    required this.semanticsLabel,
  });

  final Color color;
  final String phase;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: LingAfriqTokens.spacing64,
        height: LingAfriqTokens.spacing64,
        child: CustomPaint(painter: _CelebrationPainter(color, phase)),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.color, this.phase);

  final Color color;
  final String phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - LingAfriqTokens.spacing8;
    const angles = <double>[
      -math.pi / 2,
      0,
      math.pi / 2,
      math.pi,
    ];
    if (phase == 'end') {
      canvas.drawCircle(center, radius, paint);
      final outer = size.shortestSide / 2 - LingAfriqTokens.spacing4;
      for (final angle in angles) {
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(center + dir * radius, center + dir * outer, paint);
      }
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
    for (final angle in angles) {
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center, center + dir * (radius / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}
