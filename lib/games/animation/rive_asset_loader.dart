import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'dart:io';
import 'rive_game_guide.dart';

/// Rive Asset Loader
/// Loads the Rive file and initializes the controller
/// Works with or without the actual Rive file (graceful fallback)
class RiveAssetLoader {
  static const String _riveAssetPath = 'assets/rive/game_guide.riv';

  /// Load Rive file and initialize controller
  static Future<void> loadRiveAsset(RiveGameGuideController controller) async {
    try {
      // Try to load the Rive file
      final data = await rootBundle.load(_riveAssetPath);
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;

      // Initialize controller with artboard
      controller.initialize(artboard);

      debugPrint('✅ Rive asset loaded successfully');
    } catch (e) {
      // File doesn't exist or can't be loaded - this is OK
      // The controller will use the fallback icon
      debugPrint('⚠️ Rive asset not found at $_riveAssetPath. Using fallback. Error: $e');
      debugPrint('💡 To add Rive animation: Create game_guide.riv and place it in assets/rive/');
      debugPrint('💡 See RIVE_ASSET_SPECIFICATIONS.md for requirements');
    }
  }

  /// Check if Rive file exists
  static Future<bool> riveFileExists() async {
    try {
      await rootBundle.load(_riveAssetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}

