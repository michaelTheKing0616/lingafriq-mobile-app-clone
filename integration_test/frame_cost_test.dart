// P12-013: Avatar frame-cost budget harness (CI self-test + advance path).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingafriq/avatars/runtime/frame_cost_harness.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final repo = Directory.current;
  final budgetScript = repo.uri.resolve('scripts/perf/frame_budget.sh');

  group('P12-013 frame_budget.sh', () {
    test('self-test passes under 2 ms p95', () async {
      final proc = await Process.run(
        'bash',
        [budgetScript.toFilePath(), '--self-test'],
        workingDirectory: repo.path,
      );
      expect(proc.exitCode, 0, reason: '${proc.stdout}\n${proc.stderr}');
      final report =
          jsonDecode(proc.stdout as String) as Map<String, dynamic>;
      expect(report['verdict'], 'pass');
      expect(report['p95_added_cost_ms'] as num, lessThanOrEqualTo(2.0));
    });

    test('missing reference device fails loud as Blocked', () async {
      final proc = await Process.run(
        'bash',
        [budgetScript.toFilePath(), '--require-device'],
        workingDirectory: repo.path,
        environment: {
          ...Platform.environment,
          'FRAME_COST_FORCE_NO_DEVICE': '1',
        },
      );
      expect(proc.exitCode, 3);
      expect(proc.stderr.toString(), contains('Blocked'));
    });
  });

  group('P12-013 evaluateAvatarFrameCost', () {
    AvatarFrameCostSample sample(double added, {double total = 16.0}) {
      return AvatarFrameCostSample(
        advanceMs: added / 2,
        uiMs: added / 2,
        totalFrameMs: total,
      );
    }

    test('AC1 pass when p95 added cost <= 2 ms at 60 fps', () {
      final samples = List.generate(
        60,
        (_) => sample(0.4, total: 16.0),
      );
      final verdict = evaluateAvatarFrameCost(
        samples: samples,
        reducedMotion: false,
        droppedFrames: 0,
      );
      expect(verdict, AvatarFrameCostVerdict.pass);
    });

    test('AC2 30 fps tier is degraded not pass', () {
      final samples = List.generate(
        60,
        (_) => sample(0.5, total: 33.0),
      );
      final verdict = evaluateAvatarFrameCost(
        samples: samples,
        reducedMotion: false,
        droppedFrames: 0,
      );
      expect(verdict, AvatarFrameCostVerdict.degraded);
    });

    test('AC3 fail names budget breach via report worst frames', () {
      final samples = [
        sample(4.0),
        sample(3.5),
        sample(3.0),
        sample(2.8),
        sample(2.5),
        ...List.generate(55, (_) => sample(0.3)),
      ];
      final report = AvatarFrameCostReport(
        screen: 'avatar_scroll',
        samples: samples,
        reducedMotion: false,
        droppedFrames: 0,
      );
      expect(report.verdict, AvatarFrameCostVerdict.fail);
      expect(report.worstAddedCostMs().first, greaterThan(2.0));
      expect(report.worstAddedCostMs().length, 5);
    });

    test('AC4 reduced-motion static path requires zero dropped frames', () {
      expect(
        evaluateAvatarFrameCost(
          samples: const [],
          reducedMotion: true,
          droppedFrames: 0,
        ),
        AvatarFrameCostVerdict.fail,
      );
      final ok = evaluateAvatarFrameCost(
        samples: [sample(0, total: 16.0)],
        reducedMotion: true,
        droppedFrames: 0,
      );
      expect(ok, AvatarFrameCostVerdict.pass);
      final bad = evaluateAvatarFrameCost(
        samples: [sample(0, total: 16.0)],
        reducedMotion: true,
        droppedFrames: 1,
      );
      expect(bad, AvatarFrameCostVerdict.fail);
    });

    test('parseFrameCostLogLine round-trip', () {
      final report = AvatarFrameCostReport(
        screen: 'avatar_speaking',
        samples: List.generate(10, (_) => sample(0.4)),
        reducedMotion: false,
        droppedFrames: 0,
      );
      report.emitLog();
      final line = 'I/flutter: LingAfriqFrameCost: report=${jsonEncode(report.toJson())}';
      final parsed = parseFrameCostLogLine(line);
      expect(parsed, isNotNull);
      expect(parsed!.screen, 'avatar_speaking');
      expect(parsed.verdict, AvatarFrameCostVerdict.pass);
    });
  });

  group('P12-013 Rive advance on speaking path', () {
    test('idle/speaking advance mean within contract frameMs', () async {
      await rive.RiveNative.init();
      final contract = jsonDecode(
        File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final frameMs = (contract['budget'] as Map)['frameMs'] as int;
      final bytes =
          File('assets/rive/lingafriq_cast.riv').readAsBytesSync();
      final file =
          (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;

      double meanAdvance(String activity) {
        final controller = rive.RiveWidgetController(
          file,
          artboardSelector: rive.ArtboardSelector.byName('Character'),
          stateMachineSelector:
              rive.StateMachineSelector.byName('CharacterSM'),
        );
        final instance = controller.dataBind(rive.DataBind.byName('Polie'));
        instance.enumerator('activity')!.value = activity;
        final sw = Stopwatch()..start();
        const frames = 300;
        for (var i = 0; i < frames; i++) {
          controller.advance(1 / 60);
        }
        sw.stop();
        instance.dispose();
        controller.dispose();
        return sw.elapsedMicroseconds / frames / 1000.0;
      }

      expect(meanAdvance('speaking'), lessThanOrEqualTo(frameMs.toDouble()));
      expect(meanAdvance('idle'), lessThanOrEqualTo(frameMs.toDouble()));
    });
  });
}
