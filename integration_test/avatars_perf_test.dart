// P11-047: Avatar size, frame-advance cost, and part-swap stability (device + CI).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingafriq/avatars/cast/cast_contract.dart';
import 'package:lingafriq/avatars/customisation/slot_binding.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final repo = Directory.current;
  final budgetGate = repo.uri.resolve('scripts/avatars/check_budgets.py');

  group('P11-047 CI budget gate', () {
    test('check_budgets.py --gate passes on lingafriq_cast.riv', () async {
      final proc = await Process.run(
        'python3',
        [budgetGate.toFilePath(), '--gate', '--json'],
        workingDirectory: repo.path,
      );
      expect(proc.exitCode, 0, reason: '${proc.stdout}\n${proc.stderr}');
      final report = jsonDecode(proc.stdout as String) as Map<String, dynamic>;
      expect(report['bytes'] as int, lessThanOrEqualTo(report['max_bytes'] as int));
      final boards = report['artboards'] as Map<String, dynamic>;
      expect(boards.keys, containsAll(['Character', 'CharacterChip', 'Bust']));
    });

    test('check_budgets.py --self-test', () async {
      final proc = await Process.run(
        'python3',
        [budgetGate.toFilePath(), '--self-test'],
        workingDirectory: repo.path,
      );
      expect(proc.exitCode, 0, reason: proc.stderr.toString());
    });
  });

  group('P11-047 runtime advance budget', () {
    late rive.File file;
    late Map<String, dynamic> contract;
    late CastContract castContract;

    setUpAll(() async {
      await rive.RiveNative.init();
      contract = jsonDecode(
        File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      castContract = CastContract.parse(contract);
      final bytes = File('assets/rive/lingafriq_cast.riv').readAsBytesSync();
      file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
    });

    test('AC1 file bytes within contract budget', () {
      final onDisk = File('assets/rive/lingafriq_cast.riv').lengthSync();
      expect(onDisk, lessThanOrEqualTo(castContract.budgetBytes));
    });

    double meanAdvanceMs({
      required String activity,
      int frames = 600,
    }) {
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('Character'),
        stateMachineSelector: rive.StateMachineSelector.byName('CharacterSM'),
      );
      final instance = controller.dataBind(rive.DataBind.byName('Polie'));
      instance.enumerator('activity')!.value = activity;
      final sw = Stopwatch()..start();
      for (var i = 0; i < frames; i++) {
        controller.advance(1 / 60);
      }
      sw.stop();
      instance.dispose();
      controller.dispose();
      return sw.elapsedMicroseconds / frames / 1000.0;
    }

    test('AC2 idle and speaking advance mean ≤ frame_ms budget', () {
      final frameMs = (contract['budget'] as Map)['frameMs'] as int;
      final idleMean = meanAdvanceMs(activity: 'idle');
      final speakMean = meanAdvanceMs(activity: 'speaking');
      expect(idleMean, lessThanOrEqualTo(frameMs.toDouble()));
      expect(speakMean, lessThanOrEqualTo(frameMs.toDouble()));
    });

    test('AC2 thermal fallback: 30 fps still within doubled frame budget', () {
      final frameMs = (contract['budget'] as Map)['frameMs'] as int;
      final celebratingMean = meanAdvanceMs(activity: 'celebrating');
      expect(celebratingMean * 2, lessThanOrEqualTo(frameMs * 2.0));
    });

    test('AC3 part swap on Character advances without throwing', () {
      final catalog = AvatarPartCatalog.fromContractJson(contract);
      final vm = file.viewModelByName('CharacterVM')!;
      final inst = vm.createInstanceByName('Polie')!;
      final binding = SlotBinding(catalog: catalog);
      const hairSwaps = ['Hair/Shuku', 'Hair/Locs', 'Hair/Afro'];
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('Character'),
        stateMachineSelector: rive.StateMachineSelector.byName('CharacterSM'),
      );
      controller.dataBind(rive.DataBind.byName('Polie'));
      for (final hair in hairSwaps) {
        binding.applyParts(
          instance: inst,
          mainFile: file,
          parts: {AvatarPartSlots.hair: hair},
        );
        for (var i = 0; i < 3; i++) {
          expect(() => controller.advance(1 / 60), returnsNormally);
        }
      }
      binding.applyParts(
        instance: inst,
        mainFile: file,
        parts: {AvatarPartSlots.headwear: 'Headwear/Gele'},
      );
      for (var i = 0; i < 6; i++) {
        expect(() => controller.advance(1 / 60), returnsNormally);
      }
      inst.dispose();
      controller.dispose();
    });

    test('AC4 CharacterChip artboard advances within budget at 64 px logical use', () {
      final frameMs = (contract['budget'] as Map)['frameMs'] as int;
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('CharacterChip'),
        stateMachineSelector: rive.StateMachineSelector.byName('CharacterSM'),
      );
      final instance = controller.dataBind(rive.DataBind.byName('Polie'));
      instance.enumerator('activity')!.value = 'idle';
      final sw = Stopwatch()..start();
      for (var i = 0; i < 180; i++) {
        controller.advance(1 / 60);
      }
      sw.stop();
      final meanMs = sw.elapsedMicroseconds / 180 / 1000.0;
      expect(meanMs, lessThanOrEqualTo(frameMs.toDouble()));
      instance.dispose();
      controller.dispose();
    });
  });
}
