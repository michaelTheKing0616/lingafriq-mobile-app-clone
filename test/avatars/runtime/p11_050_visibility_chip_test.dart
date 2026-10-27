import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/runtime/chip_static.dart';
import 'package:lingafriq/avatars/runtime/character_controller.dart';
import 'package:lingafriq/avatars/runtime/rive_file_cache.dart';
import 'package:lingafriq/avatars/runtime/visibility_pause.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RiveNative.init();
    RiveFileCache.instance.renderer = Factory.flutter;
  });

  setUp(() {
    RiveFileCache.instance.clear();
    AvatarBatteryProbe.isLowBattery = () async => false;
  });

  test('applyLowPowerIdleMotion pauses controller when low power', () {
    final character = CharacterController(
      assetPath: RiveRuntimeAssets.cast,
      artboard: 'CharacterChip',
      viewModelName: 'Polie',
    );
    applyLowPowerIdleMotion(lowPower: true, character: character);
    expect(character.active, isFalse);
  });

  test('ChipStaticPolicy enables static chips for long lists', () {
    expect(ChipStaticPolicy.useStaticForList(7), isFalse);
    expect(ChipStaticPolicy.useStaticForList(8), isTrue);
  });

  testWidgets('CharacterVisibilityPause pauses offscreen controller', (
    tester,
  ) async {
    final character = CharacterController(
      assetPath: RiveRuntimeAssets.cast,
      artboard: 'CharacterChip',
      viewModelName: 'Polie',
    );
    await character.attach();
    final scroll = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 200,
          width: 200,
          child: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 600),
              SizedBox(
                height: 80,
                child: CharacterVisibilityPause(
                  controller: character,
                  watchBattery: false,
                  child: const ColoredBox(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(character.active, isFalse);

    scroll.jumpTo(520);
    await tester.pump();
    await tester.pump();
    expect(character.active, isTrue);

    character.dispose();
    scroll.dispose();
  });

  testWidgets('ListAvatarChip shows static widget in long lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ListAvatarChip(
          listItemCount: 10,
          staticChip: Text('static'),
          liveChip: Text('live'),
        ),
      ),
    );
    expect(find.text('static'), findsOneWidget);
    expect(find.text('live'), findsNothing);
  });

  testWidgets('battery probe triggers low-power pause', (tester) async {
    AvatarBatteryProbe.isLowBattery = () async => true;
    final character = CharacterController(
      assetPath: RiveRuntimeAssets.cast,
      artboard: 'CharacterChip',
      viewModelName: 'Polie',
    );
    await character.attach();
    character.active = true;

    await tester.pumpWidget(
      MaterialApp(
        home: CharacterVisibilityPause(
          controller: character,
          watchBattery: true,
          child: const SizedBox(height: 48, width: 48),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(character.active, isFalse);
    character.dispose();
  });
}
