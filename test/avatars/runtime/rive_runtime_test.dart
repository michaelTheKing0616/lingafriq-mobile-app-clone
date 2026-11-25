import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/runtime/character_controller.dart';
import 'package:lingafriq/avatars/runtime/rive_file_cache.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RiveNative.init();
    RiveFileCache.instance.renderer = Factory.flutter;
  });

  setUp(() {
    RiveFileCache.instance.clear();
  });

  test('RiveFileCache loads each asset once', () async {
    const path = RiveRuntimeAssets.cast;
    final first = await RiveFileCache.instance.load(path);
    final second = await RiveFileCache.instance.load(path);
    expect(identical(first, second), isTrue);
    expect(RiveFileCache.instance.cachedAssetCount, 1);
  });

  test('CharacterController attaches one RiveWidgetController', () async {
    final character = CharacterController(
      assetPath: RiveRuntimeAssets.cast,
      artboard: 'CharacterChip',
      viewModelName: 'Polie',
    );
    await character.attach();
    expect(character.isAttached, isTrue);
    expect(character.controller.active, isTrue);
    character.active = false;
    expect(character.controller.active, isFalse);
    character.dispose();
    expect(character.isAttached, isFalse);
  });
}
