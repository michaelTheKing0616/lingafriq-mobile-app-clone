import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// Paints the P3-015 frames from ramp roles and LingAfriqType.
/// The only golden files it compares are the frames in
/// docs/build/design/screens/. Write them with:
/// flutter test test/design/today_path_lesson_frames_test.dart --update-goldens

const _outDir = 'docs/build/design/screens';

enum _Screen { today, path, lesson }

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
  Color get success => values['success']!;
  Color get onSuccess => values['onSuccess']!;
  Color get warning => values['warning']!;
  Color get onWarning => values['onWarning']!;
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

Map<String, dynamic> _spec() => jsonDecode(
      File('design/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;

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
    await _loadFont(LingAfriqType.targetFamily, 'assets/google_fonts/Andika-Regular.ttf');
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
    final text = File('docs/build/design/screens/today_path_lesson.md').readAsStringSync();
    expect(text.contains('\u2014'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(text), isFalse);
    expect(text.toLowerCase().contains('world-class'), isFalse);
    expect(text.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(text), isFalse);
    expect(RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(text), isFalse);
    expect(text.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(text.contains('LingAfriqType.target'), isTrue);
    expect(text.contains('colorRamps.modes.light'), isTrue);
    expect(text.contains('colorRamps.modes.dark'), isTrue);
    expect(text.contains('12 minutes'), isTrue);
    expect(text.contains('Open anyway'), isTrue);
    expect(text.contains('resolvePathNodeState'), isTrue);
  });

  testWidgets('export Today, Path, and lesson frames at 390 px', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 3600);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(390, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rolesLight = _roles(spec, 'light');
    final rolesDark = _roles(spec, 'dark');
    final type = _typeScale(spec);
    Directory(_outDir).createSync(recursive: true);

    const frames = <_Frame>[
      _Frame('today-light', 'light', 1, _Screen.today, _Mode.data),
      _Frame('today-dark', 'dark', 1, _Screen.today, _Mode.data),
      _Frame('today-200', 'light', 2, _Screen.today, _Mode.data),
      _Frame('today-skeleton', 'light', 1, _Screen.today, _Mode.skeleton),
      _Frame('today-empty', 'light', 1, _Screen.today, _Mode.empty),
      _Frame('today-error', 'light', 1, _Screen.today, _Mode.error),
      _Frame('today-offline', 'light', 1, _Screen.today, _Mode.offline),
      _Frame('today-reduced', 'light', 1, _Screen.today, _Mode.reduced),
      _Frame('path-light', 'light', 1, _Screen.path, _Mode.data),
      _Frame('path-dark', 'dark', 1, _Screen.path, _Mode.data),
      _Frame('path-200', 'light', 2, _Screen.path, _Mode.data),
      _Frame('path-skeleton', 'light', 1, _Screen.path, _Mode.skeleton),
      _Frame('path-empty', 'light', 1, _Screen.path, _Mode.empty),
      _Frame('path-error', 'light', 1, _Screen.path, _Mode.error),
      _Frame('path-offline', 'light', 1, _Screen.path, _Mode.offline),
      _Frame('path-reduced', 'light', 1, _Screen.path, _Mode.reduced),
      _Frame('lesson-light', 'light', 1, _Screen.lesson, _Mode.data),
      _Frame('lesson-dark', 'dark', 1, _Screen.lesson, _Mode.data),
      _Frame('lesson-200', 'light', 2, _Screen.lesson, _Mode.data),
      _Frame('lesson-skeleton', 'light', 1, _Screen.lesson, _Mode.skeleton),
      _Frame('lesson-empty', 'light', 1, _Screen.lesson, _Mode.empty),
      _Frame('lesson-error', 'light', 1, _Screen.lesson, _Mode.error),
      _Frame('lesson-offline', 'light', 1, _Screen.lesson, _Mode.offline),
      _Frame('lesson-reduced', 'light', 1, _Screen.lesson, _Mode.reduced),
    ];

    for (final frame in frames) {
      final roles = frame.theme == 'dark' ? rolesDark : rolesLight;
      final reduced = frame.mode == _Mode.reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 3600),
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

      _expectFrame(tester, frame);

      await expectLater(
        find.byKey(const Key('frame')),
        matchesGoldenFile('../../$_outDir/${frame.fileName}.png'),
      );
    }
  });
}

void _expectFrame(WidgetTester tester, _Frame frame) {
  final buttons = tester.widgetList<SpecButton>(find.byType(SpecButton));
  for (final button in buttons) {
    expect(button.semanticsLabel.trim(), isNotEmpty, reason: frame.fileName);
    final size = tester.getSize(find.byWidget(button));
    expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48), reason: frame.fileName);
    expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48), reason: frame.fileName);
  }

  if (frame.mode == _Mode.data || frame.mode == _Mode.reduced) {
    if (frame.screen == _Screen.today) {
      expect(find.text('12 minutes'), findsOneWidget);
      expect(find.text('Due reviews'), findsOneWidget);
      expect(find.text('Next lesson'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byType(SpecButton), findsOneWidget);
    }
    if (frame.screen == _Screen.path) {
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Review due'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Open anyway'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    }
    if (frame.screen == _Screen.lesson) {
      expect(find.text('12 minutes'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Due reviews'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    }
    final andika = tester.renderObjectList<RenderParagraph>(find.text('Ẹ kú àárọ̀'));
    expect(andika, isNotEmpty, reason: frame.fileName);
    for (final paragraph in andika) {
      expect(paragraph.text.style?.fontFamily, LingAfriqType.targetFamily);
      expect(paragraph.text.style?.fontSize, LingAfriqType.targetSize);
      expect(paragraph.size.height, greaterThanOrEqualTo(LingAfriqType.targetSize));
    }
    if (frame.scale == 2) {
      expect(andika.first.size.height, greaterThan(LingAfriqType.targetSize * 2));
    }
  }

  if (frame.mode == _Mode.error || frame.mode == _Mode.offline || frame.mode == _Mode.empty) {
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
  }

  if (frame.mode == _Mode.skeleton) {
    expect(find.text('Loading'), findsOneWidget);
  }
}

Widget _screen(_Frame frame, _Roles roles, _TypeScale type) {
  final mode = frame.mode == _Mode.reduced ? _Mode.data : frame.mode;
  return switch (frame.screen) {
    _Screen.today => _today(mode, roles, type),
    _Screen.path => _path(mode, roles, type),
    _Screen.lesson => _lesson(mode, roles, type),
  };
}

Widget _today(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
        roles,
        type,
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
        title: 'Today',
        headline: 'No plan yet',
        headlineColor: roles.onSurface,
        happened: 'Today has nothing queued.',
        why: 'There is no review due, and no lesson is chosen.',
        todo: 'Open Path and start the first lesson.',
        buttons: [
          _primary(roles, type, 'Open Path', 'Open Path'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Today',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'Today did not load',
        headlineColor: roles.danger,
        happened: 'The plan did not open.',
        why: 'The lesson list did not come back.',
        todo: 'Try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Today',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'This plan is not saved on the phone.',
        todo: 'Connect, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _ => _column([
        Text('Today', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text('One plan for today.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _pill(roles, type, '12 minutes', 'About 12 minutes'),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _planRow(
          roles,
          type,
          number: '1',
          title: 'Due reviews',
          line: 'Three words are ready to review.',
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _planRow(
          roles,
          type,
          number: '2',
          title: 'Next lesson',
          line: 'Morning greetings',
          target: 'Ẹ kú àárọ̀',
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _planRow(
          roles,
          type,
          number: '3',
          title: 'Speaking',
          line: 'Say one greeting out loud.',
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _primary(roles, type, 'Start', 'Start the 12 minute plan'),
      ]),
  };
}

Widget _path(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _column([
        Text('Loading', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing48),
        const SizedBox(height: LingAfriqTokens.spacing12),
        for (var i = 0; i < 4; i++) ...[
          Row(
            children: [
              _disc(fill: roles.surfaceContainer, child: const SizedBox.shrink()),
              const SizedBox(width: LingAfriqTokens.spacing12),
              Expanded(child: _block(roles, LingAfriqTokens.spacing32)),
            ],
          ),
          const SizedBox(height: LingAfriqTokens.spacing12),
        ],
      ]),
    _Mode.empty => _notice(
        roles: roles,
        type: type,
        title: 'Path',
        headline: 'No lessons yet',
        headlineColor: roles.onSurface,
        happened: 'This path has no lessons.',
        why: 'The lesson list is empty.',
        todo: 'Try again later.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Path',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'Path did not load',
        headlineColor: roles.danger,
        happened: 'The lesson map did not open.',
        why: 'The lesson list failed to load.',
        todo: 'Try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Path',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'This path is not saved on the phone.',
        todo: 'Connect, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _ => _column([
        Text('Path', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: roles.surfaceContainer,
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            child: _column([
              Text('Unit 1. Greetings', style: type.body(roles.onSurface)),
              const SizedBox(height: LingAfriqTokens.spacing4),
              Text(
                'I can greet someone in the morning.',
                style: type.body(roles.onSurfaceVariant),
              ),
            ]),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _node(
          roles,
          last: false,
          disc: _disc(
            fill: roles.surfaceContainer,
            child: CueMark(color: roles.onSurface, kind: 'lock'),
          ),
          body: _column([
            Text('Lesson 4. Family names', style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text('Locked', style: type.body(roles.onSurfaceVariant)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text(
              'Unlocks after Morning greetings.',
              style: type.body(roles.onSurfaceVariant),
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            _quiet(roles, type, 'Preview', 'Preview Family names'),
            const SizedBox(height: LingAfriqTokens.spacing8),
            _quiet(roles, type, 'Open anyway', 'Open Family names anyway'),
          ]),
        ),
        _node(
          roles,
          last: false,
          disc: _disc(
            fill: roles.surfaceContainer,
            border: roles.onSurface,
            child: Text('3', style: type.body(roles.onSurface)),
          ),
          body: _column([
            Text('Lesson 3. Morning greetings', style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text('Now', style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text('Ẹ kú àárọ̀', style: type.target(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing8),
            _primary(roles, type, 'Start', 'Start Morning greetings'),
          ]),
        ),
        _node(
          roles,
          last: false,
          disc: _disc(
            fill: roles.warning,
            child: CueMark(color: roles.onWarning, kind: 'triangle'),
          ),
          body: _column([
            Text('Lesson 2. Market words', style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text('Review due', style: type.body(roles.warning)),
          ]),
        ),
        _node(
          roles,
          last: true,
          disc: _disc(
            fill: roles.success,
            child: CueMark(color: roles.onSuccess, kind: 'check'),
          ),
          body: _column([
            Text('Lesson 1. Hello', style: type.body(roles.onSurface)),
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text('Done', style: type.body(roles.success)),
          ]),
        ),
      ]),
  };
}

Widget _lesson(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _column([
        Text('Loading', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing32),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Row(
          children: [
            Expanded(child: _block(roles, LingAfriqTokens.spacing8, pill: true)),
            const SizedBox(width: LingAfriqTokens.spacing4),
            Expanded(child: _block(roles, LingAfriqTokens.spacing8, pill: true)),
            const SizedBox(width: LingAfriqTokens.spacing4),
            Expanded(child: _block(roles, LingAfriqTokens.spacing8, pill: true)),
          ],
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing32),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing32),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing48),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing48),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing48),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _block(roles, LingAfriqTokens.spacing48),
      ]),
    _Mode.empty => _notice(
        roles: roles,
        type: type,
        title: 'Lesson',
        headline: 'No lesson in this plan',
        headlineColor: roles.onSurface,
        happened: 'The session has no lesson.',
        why: 'You have not chosen a lesson.',
        todo: 'Open Path and choose a lesson.',
        buttons: [
          _primary(roles, type, 'Open Path', 'Open Path'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Lesson',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'Lesson did not open',
        headlineColor: roles.danger,
        happened: 'The lesson stopped before the first word.',
        why: 'The lesson file is missing on this phone.',
        todo: 'Try again. If it fails, go back to Path and pick another lesson.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
          _quiet(roles, type, 'Back to Path', 'Back to Path'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Lesson',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'This lesson is not saved on the phone.',
        todo: 'Connect, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
          _quiet(roles, type, 'Back to Today', 'Back to Today'),
        ],
      ),
    _ => _column([
        Align(
          alignment: Alignment.centerLeft,
          child: _quiet(roles, type, 'Close', 'Close lesson', fillWidth: false),
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text('Today', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Semantics(
          label: 'About 12 minutes',
          excludeSemantics: true,
          child: Text('12 minutes', style: type.body(roles.onSurface)),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Row(
          children: [
            Expanded(child: _segment(roles.onSurface)),
            const SizedBox(width: LingAfriqTokens.spacing4),
            Expanded(child: _segment(roles.surfaceContainer)),
            const SizedBox(width: LingAfriqTokens.spacing4),
            Expanded(child: _segment(roles.surfaceContainer)),
          ],
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text('Step 1 of 3', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text('Due reviews', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text('Hear the word. Then tap it.', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text('Ẹ kú àárọ̀', style: type.target(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _choice(roles, 'Ẹ kú àárọ̀', type.target(roles.onSurface), 'Ẹ kú àárọ̀'),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _choice(roles, 'Good night', type.body(roles.onSurface), 'Good night'),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _choice(roles, 'Thank you', type.body(roles.onSurface), 'Thank you'),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _primary(roles, type, 'Check', 'Check this answer'),
      ]),
  };
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

Widget _skeleton(_Roles roles, _TypeScale type, {required List<double> heights}) {
  return _column([
    Text('Loading', style: type.body(roles.onSurfaceVariant)),
    const SizedBox(height: LingAfriqTokens.spacing12),
    for (final height in heights) ...[
      _block(roles, height),
      const SizedBox(height: LingAfriqTokens.spacing12),
    ],
  ]);
}

Widget _planRow(
  _Roles roles,
  _TypeScale type, {
  required String number,
  required String title,
  required String line,
  String? target,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _disc(
        fill: roles.surfaceContainer,
        child: Text(number, style: type.body(roles.onSurface)),
      ),
      const SizedBox(width: LingAfriqTokens.spacing12),
      Expanded(
        child: _column([
          Text(title, style: type.body(roles.onSurface)),
          const SizedBox(height: LingAfriqTokens.spacing4),
          Text(line, style: type.body(roles.onSurfaceVariant)),
          if (target != null) ...[
            const SizedBox(height: LingAfriqTokens.spacing4),
            Text(target, style: type.target(roles.onSurface)),
          ],
        ]),
      ),
    ],
  );
}

Widget _node(
  _Roles roles, {
  required bool last,
  required Widget disc,
  required Widget body,
}) {
  return Stack(
    children: [
      if (!last)
        Positioned(
          left: (LingAfriqTokens.spacing48 - LingAfriqTokens.strokehairline) / 2,
          top: LingAfriqTokens.spacing48,
          bottom: 0,
          width: LingAfriqTokens.strokehairline,
          child: ColoredBox(color: roles.onSurfaceVariant),
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: LingAfriqTokens.spacing48, child: disc),
          const SizedBox(width: LingAfriqTokens.spacing12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing16),
              child: body,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _pill(_Roles roles, _TypeScale type, String label, String semantics) {
  return Semantics(
    label: semantics,
    excludeSemantics: true,
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: roles.surfaceContainer,
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiuspill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing8,
            ),
            child: Text(label, style: type.body(roles.onSurface)),
          ),
        ),
      ),
    ),
  );
}

Widget _disc({
  required Color fill,
  required Widget child,
  Color? border,
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: LingAfriqTokens.spacing48,
      minHeight: LingAfriqTokens.spacing48,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border == null
            ? null
            : Border.all(color: border, width: LingAfriqTokens.strokeregular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing8),
        child: Center(child: child),
      ),
    ),
  );
}

Widget _block(_Roles roles, double height, {bool pill = false}) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: roles.surfaceContainer,
        borderRadius: BorderRadius.circular(
          pill ? LingAfriqTokens.radiuspill : LingAfriqTokens.radiusmd,
        ),
      ),
    ),
  );
}

Widget _segment(Color color) {
  return SizedBox(
    height: LingAfriqTokens.spacing8,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LingAfriqTokens.radiuspill),
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
  );
}

Widget _quiet(
  _Roles roles,
  _TypeScale type,
  String label,
  String semantics, {
  bool fillWidth = true,
}) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: fillWidth,
  );
}

Widget _choice(_Roles roles, String label, TextStyle style, String semantics) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: style.color ?? roles.onSurface,
    textStyle: style,
    fillWidth: true,
  );
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
  });

  final String label;
  final String semanticsLabel;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
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
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing12,
            ),
            child: Text(label, textAlign: TextAlign.center, style: textStyle),
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
      case 'triangle':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.12)
          ..lineTo(w * 0.9, h * 0.86)
          ..lineTo(w * 0.1, h * 0.86)
          ..close();
        canvas.drawPath(path, paint);
      case 'cross':
        canvas.drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), paint);
        canvas.drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), paint);
      case 'info':
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.38, paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.42), Offset(w * 0.5, h * 0.72), paint);
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
    }
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.kind != kind;
}
