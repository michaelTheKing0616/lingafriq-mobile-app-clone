import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/voice/voice_recording_retention.dart';
import 'package:lingafriq/widgets/privacy/voice_retention_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_kit.dart';

void main() {
  setUpAll(
    () => loadComplianceFonts('test/compliance/voice_retention_test.dart'),
  );
  late Directory dir;
  late VoiceRecordingRetention r;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('vr');
    r = VoiceRecordingRetention(dir: () async => dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File make(String name, Duration age) {
    final f = File('${dir.path}/$name')..writeAsStringSync('x');
    f.setLastModifiedSync(DateTime.now().subtract(age));
    return f;
  }

  test('default retention is short (24h)', () async {
    expect(await VoiceRecordingRetention.hours(), 24);
  });

  test('sweep deletes only expired raw recordings', () async {
    final old = make('voice_recording_1.wav', const Duration(hours: 30));
    final fresh = make('shadowing_2.wav', const Duration(hours: 1));
    final lesson = make('lesson_42.wav', const Duration(days: 90));
    final clip = make('clip_3.m4a', const Duration(days: 90));
    expect(await r.sweep(), 1);
    expect(old.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
    expect(lesson.existsSync(), isTrue);
    expect(clip.existsSync(), isTrue);
  });

  test(
    'configurable: 7 days keeps 30h-old audio; delete-now removes all raw',
    () async {
      await VoiceRecordingRetention.setHours(168);
      final a = make('voice_recording_1.wav', const Duration(hours: 30));
      make('audio.wav', const Duration(minutes: 1));
      expect(await r.sweep(), 0);
      expect(a.existsSync(), isTrue);
      expect(await r.deleteAll(), 2);
      expect(() => VoiceRecordingRetention.setHours(5), throwsArgumentError);
    },
  );

  Widget home() => Scaffold(
    body: ListView(children: [VoiceRetentionTile(retention: r)]),
  );

  for (final v in goldenVariants) {
    testWidgets('tile layout holds: ${v.name}', (tester) async {
      await pumpVariant(tester, v, home());
      expectNoLayoutErrors(tester);
      // Title keeps (nearly) full width: never squeezed by the selector.
      final title = find.text(
        v.locale.languageCode == 'ar'
            ? 'التسجيلات على هذا الجهاز'
            : 'Recordings on this device',
      );
      expect(tester.getSize(title).width, greaterThan(v.size.width * 0.4));
      expect(
        tester.getSize(find.byKey(const ValueKey('voice-delete-now'))).height,
        greaterThanOrEqualTo(48),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/voice_retention_${v.name}.png'),
      );
    });
  }

  testWidgets('delete-now asks for confirmation; cancel keeps files', (
    tester,
  ) async {
    final f = await tester.runAsync(
      () async => make('voice_recording_9.wav', const Duration(minutes: 1)),
    );
    await pumpVariant(tester, goldenVariants.first, home());
    expect(find.text('After 24 hours'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('voice-delete-now')));
    await tester.pumpAndSettle();
    expect(find.text('Delete recordings on this device?'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/voice_retention_confirm_ltr_390.png'),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(f!.existsSync(), isTrue);

    await tester.tap(find.byKey(const ValueKey('voice-delete-now')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('voice-delete-confirm')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(f.existsSync(), isFalse);
    expect(find.text('1 recording deleted from this device.'), findsOneWidget);
  });

  testWidgets('choosing a period persists it', (tester) async {
    await pumpVariant(tester, goldenVariants.first, home());
    await tester.tap(find.text('After 24 hours'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('After 7 days').last);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(await VoiceRecordingRetention.hours(), 168);
  });

  test('privacy settings radios use RadioGroup (no deprecated onChanged)', () {
    final src = File(
      'lib/screens/settings/privacy_settings_screen.dart',
    ).readAsStringSync();
    expect(src, contains('RadioGroup<String>('));
    expect(
      src,
      isNot(matches(RegExp(r'Radio<String>\(\s*value: value,\s*groupValue'))),
    );
  });
}
