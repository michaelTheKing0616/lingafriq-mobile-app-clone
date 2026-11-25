import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/contract/character_vm.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CharacterVmContract schema;
  late Map<String, dynamic> rivContract;
  late rive.File rivFile;

  setUpAll(() async {
    await rive.RiveNative.init();
    final schemaText = File(CharacterVmContract.schemaRelativePath).readAsStringSync();
    schema = CharacterVmContract.loadFromJsonString(schemaText);
    rivContract = jsonDecode(
      File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final bytes = File('assets/rive/lingafriq_cast.riv').readAsBytesSync();
    rivFile = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  test('schema property list matches lingafriq_cast.contract.json', () {
    final want = (rivContract['properties'] as List)
        .map((p) => p['name'] as String)
        .toList();
    expect(schema.boundPropertyNames, want);
  });

  test('enum parity between schema and riv contract', () {
    final want = (rivContract['enums'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).cast<String>()),
    );
    expect(schema.enums, want);
  });

  test('lesson triggers match ADR-030 card list', () {
    expect(
      schema.lessonTriggerNames,
      ['celebrate', 'levelUp', 'wave', 'nod', 'shrug', 'tapped'],
    );
    expect(
      CharacterVmTrigger.lessonTriggers.map((t) => t.riveName),
      schema.lessonTriggerNames,
    );
  });

  test('activity is a single enum (no legacy listening/speaking booleans)', () {
    expect(CharacterVmActivity.values.map((e) => e.riveName), schema.enums['activity']);
    expect(schema.boundPropertyNames.contains('isListening'), isFalse);
    expect(schema.boundPropertyNames.contains('isSpeaking'), isFalse);
  });

  test('numeric writes clamp and emit CharacterVmOutOfRangeEvent', () {
    final events = <CharacterVmOutOfRangeEvent>[];
    final vm = rivFile.viewModelByName('CharacterVM')!;
    final inst = vm.createDefaultInstance()!;
    final writer = CharacterVmWriter(
      instance: inst,
      onOutOfRange: events.add,
    );
    writer.apply(
      const CharacterVmState(intensity: 2.5, gazeX: -3, gazeY: 4),
    );
    expect(inst.number('intensity')!.value, 1);
    expect(inst.number('gazeX')!.value, -1);
    expect(inst.number('gazeY')!.value, 1);
    expect(events.length, 3);
    expect(events.map((e) => e.property).toSet(), {'intensity', 'gazeX', 'gazeY'});
  });

  test('CI fails when schema names a property missing from loaded .riv', () {
    final missing = CharacterVmContract.missingOnRive(rivFile, schema);
    expect(
      missing,
      isEmpty,
      reason: 'CharacterVM missing on .riv: ${missing.join(", ")}',
    );
  });

  test('intensity default is 0.6 per ADR-030', () {
    expect(CharacterVmContract.intensityDefault, 0.6);
    expect(const CharacterVmState().intensity, 0.6);
  });
}
