import '../../avatars/cast/cast_file_cache.dart';
import 'rive_game_guide.dart';

/// Preloads the shared cast file. The old per-character .riv files are retired.
class RiveAssetLoader {
  static const String _riveAssetPath = CastFileCache.assetPath;

  static Future<void> loadRiveAsset(RiveGameGuideController controller) async {
    await CastFileCache.instance.load();
  }

  static Future<bool> riveFileExists() async {
    try {
      await CastFileCache.instance.load();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String get assetPath => _riveAssetPath;
}
