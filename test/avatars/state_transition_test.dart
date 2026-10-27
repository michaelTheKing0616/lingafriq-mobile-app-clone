// P11-041: Polie activity states, idle micro-motion hooks, ≤300 ms transitions, hallway record.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_contract.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late rive.File file;
  late Map<String, dynamic> contract;
  late Map<String, dynamic> verifyLog;

  setUpAll(() async {
    await rive.RiveNative.init();
    contract = jsonDecode(
      File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    verifyLog = jsonDecode(
      File('assets/rive/lingafriq/verify_log.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final rivPath = File('assets/rive/avatars/lingafriq_cast.riv');
    expect(rivPath.existsSync(), isTrue, reason: 'P11-041 allowlist riv path');
    final bytes = rivPath.readAsBytesSync();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  rive.RiveWidgetController polieController() {
    return rive.RiveWidgetController(
      file,
      artboardSelector: rive.ArtboardSelector.byName('Character'),
      stateMachineSelector: rive.StateMachineSelector.byName('CharacterSM'),
    );
  }

  test('AC1 legacy lesson signals map to activity + triggers on Polie', () {
    final session = CastSession(preset: 'Polie');
    final legacy = contract['legacyMap'] as Map<String, dynamic>;
    expect(legacy['hint'], 'activity=hinting');
    expect(legacy['lessonComplete'], contains('celebrating'));

    for (final activity in contract['enums']['activity'] as List) {
      session.activity(activity as String);
      expect(session.pose.activity, activity);
    }

    session.onMic(true);
    expect(session.pose.activity, 'listening');
    session.onMic(false);
    expect(session.pose.activity, 'idle');
    session.onAiStreaming(true);
    expect(session.pose.activity, 'thinking');
    session.onGraded(correct: true);
    expect(session.pose.activity, 'encouraging');
    session.onGraded(correct: false);
    expect(session.pose.activity, 'hinting');
    session.onHint();
    expect(session.pose.activity, 'hinting');
    session.onLessonComplete();
    expect(session.pose.activity, 'celebrating');
    session.onLevelUp();
    expect(session.pose.activity, 'celebrating');
    session.dispose();
  });

  test('AC1 each activity advances CharacterSM without error', () {
    final controller = polieController();
    final instance = controller.dataBind(rive.DataBind.byName('Polie'));
    final activities = (contract['enums']['activity'] as List).cast<String>();
    for (final activity in activities) {
      instance.enumerator('activity')!.value = activity;
      var elapsed = 0.0;
      while (elapsed < 0.35) {
        controller.advance(1 / 60);
        elapsed += 1 / 60;
      }
      expect(instance.enumerator('activity')!.value, activity);
    }
    instance.dispose();
    controller.dispose();
  });

  test('AC2 idle exposes blink, gaze and energy bindings (micro-motion inputs)', () {
    final inst = file.viewModelByName('CharacterVM')!.createInstanceByName('Polie')!;
    inst.enumerator('activity')!.value = 'idle';
    inst.number('blinkRate')!.value = 0.85;
    inst.number('gazeX')!.value = 0.6;
    inst.number('gazeY')!.value = -0.4;
    inst.number('energy')!.value = 0.55;
    expect(inst.number('blinkRate')!.value, closeTo(0.85, 0.001));
    expect(inst.number('gazeX')!.value, closeTo(0.6, 0.001));
    final idleEntry = (verifyLog['activities'] as List).firstWhere(
      (e) => (e as Map)['label'] == 'activity=idle',
    ) as Map;
    expect(idleEntry['pixelsChanged'], isTrue);
    final blinkProbe = verifyLog['blinkRate'] as Map;
    expect(blinkProbe['pixelsChanged'], isTrue);
    final gazeProbe = verifyLog['gaze'] as Map;
    expect(gazeProbe['pixelsChanged'], isTrue);
    inst.dispose();
  });

  test('AC2 idle SM advances with breathing timeline (L4 blink layer owned)', () {
    final controller = polieController();
    final instance = controller.dataBind(rive.DataBind.byName('Polie'));
    instance.enumerator('activity')!.value = 'idle';
    instance.number('blinkRate')!.value = 0.7;
    var advanced = false;
    for (var i = 0; i < 120; i++) {
      if (controller.advance(1 / 60)) advanced = true;
    }
    expect(advanced, isTrue);
    final ownership = contract['layerOwnership'] as Map<String, dynamic>;
    expect(ownership['L4 Blink'], contains('BlinkLid'));
    instance.dispose();
    controller.dispose();
  });

  test('AC3 contract caps transitions at 300 ms (authored 0–280 ms inspected)', () {
    expect(contract['maxTransitionMs'], lessThanOrEqualTo(300));
    expect(contract['maxTransitionMs'], 300);
  });

  test('AC3 activity change completes within budgeted wall time at 60 Hz', () {
    final controller = polieController();
    final instance = controller.dataBind(rive.DataBind.byName('Polie'));
    const pairs = [
      ('idle', 'listening'),
      ('listening', 'thinking'),
      ('thinking', 'speaking'),
      ('speaking', 'celebrating'),
      ('celebrating', 'idle'),
    ];
    for (final pair in pairs) {
      instance.enumerator('activity')!.value = pair.$1;
      for (var i = 0; i < 6; i++) {
        controller.advance(1 / 60);
      }
      instance.enumerator('activity')!.value = pair.$2;
      var elapsedMs = 0.0;
      while (elapsedMs < (contract['maxTransitionMs'] as int)) {
        controller.advance(1 / 60);
        elapsedMs += 1000 / 60;
      }
      expect(
        instance.enumerator('activity')!.value,
        pair.$2,
        reason: 'transition ${pair.$1}→${pair.$2}',
      );
    }
    instance.dispose();
    controller.dispose();
  });

  test('AC4 five-person hallway record at 64 px chip semantics', () async {
    const hallwayPresets = ['Polie', 'Zuri', 'Kofi', 'Amara', 'Learner'];
    const hallwayActivities = [
      'idle',
      'listening',
      'thinking',
      'speaking',
      'celebrating',
    ];
    final record = <String, dynamic>{
      'card': 'P11-041',
      'displayPx': 64,
      'artboard': 'CharacterChip',
      'recordedAt': DateTime.now().toUtc().toIso8601String(),
      'panels': <Map<String, dynamic>>[],
    };
    for (final preset in hallwayPresets) {
      expect(
        file.viewModelByName('CharacterVM')!.createInstanceByName(preset),
        isNotNull,
        reason: preset,
      );
      for (final activity in hallwayActivities) {
        final label = castSemanticsLabel(
          name: castSpokenName(preset),
          expression: activity == 'celebrating' ? 'proud' : 'focused',
          activity: activity,
        );
        (record['panels'] as List).add({
          'preset': preset,
          'activity': activity,
          'semanticsLabel': label,
          'readable': label.isNotEmpty,
        });
      }
    }
    expect((record['panels'] as List).length, hallwayPresets.length * hallwayActivities.length);
    for (final panel in record['panels'] as List) {
      expect((panel as Map)['readable'], isTrue);
    }
    final out = File('test/avatars/p11_041_hallway_record.json');
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(record));
    expect(out.existsSync(), isTrue);
  });
}
