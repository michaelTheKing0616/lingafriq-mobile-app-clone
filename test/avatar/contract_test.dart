// Sample contract test for lingafriq_cast.riv. Runtime: rive ^0.14.11 (rive_native).
// VERIFIED 2026-10-21 (Africa/Lagos): 7/7 pass headless with Flutter 3.x stable (Dart 3.13.5), rive 0.14.11, rive_native 0.1.11+3, Linux x64.
// Headless setup: `dart run rive_native:setup --platform linux`, then
// LD_LIBRARY_PATH=build/rive_native/native/build/linux/bin/lib/debug_shared flutter test
// (without it, rive_native fails to dlopen librive_native(_plugin).so: the plugin .so is only produced by a desktop app build).
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late rive.File file;
  late Map<String, dynamic> contract;

  setUpAll(() async {
    await rive.RiveNative.init();
    contract = jsonDecode(
      File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
    );
    final bytes = File('assets/rive/lingafriq_cast.riv').readAsBytesSync();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  test('file stays within the size budget', () {
    final size = File('assets/rive/lingafriq_cast.riv').lengthSync();
    expect(
      size,
      lessThanOrEqualTo(contract['budget']['bytesPerCharacterFile'] as int),
    );
  });

  test('artboards exist and each has CharacterSM', () {
    for (final name in (contract['artboards'] as Map).keys) {
      final ab = file.artboard(name);
      expect(ab, isNotNull, reason: 'missing artboard $name');
      expect(
        ab!.stateMachine('CharacterSM'),
        isNotNull,
        reason: '$name lacks CharacterSM',
      );
    }
  });

  test('CharacterVM matches the contract exactly (names, order, types)', () {
    final vm = file.viewModelByName('CharacterVM')!;
    final got = vm.properties.map((p) => '${p.name}:${p.type.name}').toList();
    const typeMap = {
      'Enum': 'enumType',
      'Number': 'number',
      'Boolean': 'boolean',
      'Color': 'color',
      'Trigger': 'trigger',
      'Artboard': 'artboard',
    };
    final want = (contract['properties'] as List)
        .map((p) => '${p['name']}:${typeMap[p['type']]}')
        .toList();
    expect(got, want);
  });

  test('enum values match the contract', () {
    final vm = file.viewModelByName('CharacterVM')!;
    final inst = vm.createDefaultInstance()!;
    (contract['enums'] as Map).forEach((name, values) {
      final e = inst.enumerator(name as String)!;
      for (final v in values as List) {
        e.value = v as String;
        expect(e.value, v, reason: '$name rejects $v');
      }
    });
  });

  test('wheelchair boolean exists, last property (v3.2)', () {
    final inst = file.viewModelByName('CharacterVM')!.createDefaultInstance()!;
    expect(inst.boolean('wheelchair'), isNotNull);
    expect((contract['properties'] as List).last['name'], 'wheelchair');
  });

  test('bodyType and faceShape exist (v3.1)', () {
    final inst = file.viewModelByName('CharacterVM')!.createDefaultInstance()!;
    expect(inst.enumerator('bodyType'), isNotNull);
    expect(inst.enumerator('faceShape'), isNotNull);
    expect(inst.number('blinkRate'), isNotNull);
  });

  test('every preset instance is exported', () {
    final vm = file.viewModelByName('CharacterVM')!;
    for (final n in contract['instances'] as List) {
      expect(
        vm.createInstanceByName(n as String),
        isNotNull,
        reason: 'missing instance $n',
      );
    }
  });
}
