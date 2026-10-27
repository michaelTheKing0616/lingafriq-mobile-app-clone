import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/customisation/slot_binding.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarPartCatalog', () {
    test('splits options past ten into streamed packs', () {
      final catalog = AvatarPartCatalog.fromContractJson({
        'properties': [
          {
            'name': 'hair',
            'type': 'Artboard',
            'category': 'Hair',
            'options': List.generate(
              12,
              (i) => 'Hair/Style$i',
            ),
          },
        ],
      });
      final hair = catalog.slot('hair');
      expect(hair.inlineOptions.length, kMaxInlinePartOptionsPerSlot);
      expect(hair.streamedOptions.length, 2);
      expect(hair.sourceFor('Hair/Style0'), AvatarPartSource.inlineMainFile);
      expect(hair.sourceFor('Hair/Style11'), AvatarPartSource.streamedPack);
      expect(
        streamedPartAssetPath('Hair/Style11'),
        'assets/rive/avatars/parts/Hair/Style11.riv',
      );
    });

    test('contract library meets hair and headwear minimums', () {
      final raw = File('assets/rive/lingafriq_cast.contract.json').readAsStringSync();
      final catalog = AvatarPartCatalog.fromContractJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      catalog.validateLibraryMinimums();
      final hair = catalog.slot(AvatarPartSlots.hair);
      expect(hair.allOptions.length, greaterThanOrEqualTo(6));
      expect(catalog.slot(AvatarPartSlots.headwear).allOptions.length, greaterThanOrEqualTo(4));
    });
  });

  group('SlotBinding on lingafriq_cast.riv', () {
    late rive.File file;
    late AvatarPartCatalog catalog;
    late Map<String, dynamic> contract;

    setUpAll(() async {
      await rive.RiveNative.init();
      contract = jsonDecode(
        File('assets/rive/lingafriq_cast.contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      catalog = AvatarPartCatalog.fromContractJson(contract);
      final bytes = File('assets/rive/lingafriq_cast.riv').readAsBytesSync();
      file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
    });

    test('swaps hair via Artboard property binding', () {
      final vm = file.viewModelByName('CharacterVM')!;
      final inst = vm.createInstanceByName('Polie')!;
      expect(
        () => SlotBinding(catalog: catalog).applyParts(
          instance: inst,
          mainFile: file,
          parts: {AvatarPartSlots.hair: 'Hair/Shuku'},
        ),
        returnsNormally,
      );
      expect(file.artboardToBind('Hair/Shuku'), isNotNull);
    });

    test('rejects unknown option for slot', () {
      final vm = file.viewModelByName('CharacterVM')!;
      final inst = vm.createDefaultInstance()!;
      expect(
        () => SlotBinding(catalog: catalog).applyParts(
          instance: inst,
          mainFile: file,
          parts: {AvatarPartSlots.hair: 'Hair/NotInContract'},
        ),
        throwsA(isA<SlotBindingException>()),
      );
    });

    test('streamed option requires decoded pack file', () {
      final extended = AvatarPartCatalog.fromContractJson({
        'properties': [
          {
            'name': 'hair',
            'type': 'Artboard',
            'category': 'Hair',
            'options': [
              ...List.generate(11, (i) => 'Hair/Inline$i'),
              'Hair/StreamedExtra',
            ],
          },
        ],
      });
      final vm = file.viewModelByName('CharacterVM')!;
      final inst = vm.createDefaultInstance()!;
      expect(
        () => SlotBinding(catalog: extended).applyParts(
          instance: inst,
          mainFile: file,
          parts: {AvatarPartSlots.hair: 'Hair/StreamedExtra'},
        ),
        throwsA(
          predicate<SlotBindingException>(
            (e) => e.code == SlotBindingError.streamPackMissing,
          ),
        ),
      );
    });
  });
}
