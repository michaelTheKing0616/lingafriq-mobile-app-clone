import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/customisation/palette.dart';
import 'package:rive/rive.dart';

import '../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File castFile;

  setUpAll(() async {
    await RiveNative.init();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/avatars/skin_tone_golden_test.dart'),
    );
    final bytes =
        await io.File('assets/rive/lingafriq_cast.riv').readAsBytes();
    castFile = (await File.decode(bytes, riveFactory: Factory.flutter))!;
  });

  test('skin catalog has at least ten undertoned swatches', () {
    expect(AvatarSkinTone.catalog.length, greaterThanOrEqualTo(AvatarSkinTone.minCount));
    final undertones = AvatarSkinTone.catalog.map((t) => t.undertone).toSet();
    expect(undertones.length, greaterThanOrEqualTo(5));
    expect(AvatarSkinTone.byId(12).slug, 'albinism-pale');
  });

  test('hair and outfit colours bind on CharacterVM without re-export', () async {
    final bytes =
        await io.File('assets/rive/lingafriq_cast.riv').readAsBytes();
    final file = (await File.decode(bytes, riveFactory: Factory.flutter))!;
    final vm = file.viewModelByName('CharacterVM')!;
    final inst = vm.createDefaultInstance()!;

    AvatarColorPalette.bind(
      inst,
      const AvatarAppearance(
        skinToneId: 6,
        hairColorId: 4,
        outfitPrimary: Color(0xFF2E9E6B),
        outfitSecondary: Color(0xFFE5603B),
      ),
    );

    expect(inst.color('skinTone')!.value, AvatarSkinTone.byId(6).color);
    expect(inst.color('hairColor')!.value, AvatarHairColor.byId(4).color);
    expect(inst.color('outfitPrimary')!.value, const Color(0xFF2E9E6B));
    expect(inst.color('outfitSecondary')!.value, const Color(0xFFE5603B));

    AvatarColorPalette.bindHairColor(inst, 7);
    expect(inst.color('hairColor')!.value, AvatarHairColor.byId(7).color);
  });

  const goldenTones = <int>[1, 6, 10, 12];
  const artboards = <String, Size>{
    'CharacterChip': const Size(56, 56),
    'Character': const Size(120, 160),
    'Bust': const Size(120, 120),
  };

  for (final toneId in goldenTones) {
    for (final entry in artboards.entries) {
      testWidgets(
        'skin tone $toneId on ${entry.key}',
        (tester) async {
          final controller = RiveWidgetController(
            castFile,
            artboardSelector: ArtboardNamed(entry.key),
            stateMachineSelector: const StateMachineNamed('CharacterSM'),
          );
          addTearDown(controller.dispose);
          final instance = controller.dataBind(DataBind.byName('Polie'));
          instance.enumerator('expression')?.value = 'neutral';
          instance.number('intensity')?.value = 0.7;
          instance.boolean('reducedMotion')?.value = true;
          AvatarColorPalette.bind(
            instance,
            AvatarAppearance(skinToneId: toneId, hairColorId: 2),
          );
          controller.active = false;

          await pinSurface(tester, size: entry.value);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Center(
                  child: RepaintBoundary(
                    key: ValueKey('skin-$toneId-${entry.key}'),
                    child: SizedBox(
                      width: entry.value.width,
                      height: entry.value.height,
                      child: RiveWidget(
                        controller: controller,
                        fit: Fit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          await expectLater(
            find.byKey(ValueKey('skin-$toneId-${entry.key}')),
            matchesGoldenFile(
              'goldens/skin_${toneId}_${entry.key.toLowerCase()}.png',
            ),
          );
        },
      );
    }
  }
}
