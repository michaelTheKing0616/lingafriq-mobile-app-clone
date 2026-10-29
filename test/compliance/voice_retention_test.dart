import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/voice/voice_recording_retention.dart';
import 'package:lingafriq/widgets/privacy/voice_retention_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  testWidgets('tile shows disclosure, retention choice and delete-now', (
    tester,
  ) async {
    await tester.runAsync(
      () async => make('voice_recording_9.wav', const Duration(minutes: 1)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VoiceRetentionTile(retention: r)),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('voice-retention-disclosure')),
      findsOneWidget,
    );
    expect(find.text('After 24 hours'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('voice-delete-now')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.textContaining('Deleted 1 recording'), findsOneWidget);
  });
}
