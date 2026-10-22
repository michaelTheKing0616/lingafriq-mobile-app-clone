import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

/// One decode of the cast file for the whole process.
class CastFileCache {
  CastFileCache._();

  static final CastFileCache instance = CastFileCache._();
  static const assetPath = 'assets/rive/lingafriq_cast.riv';

  File? file;
  Future<File>? _loading;

  /// App builds use [Factory.rive]. Widget tests set [Factory.flutter]: the
  /// shipped native library has no headless GPU context, so [Factory.rive]
  /// aborts inside the tester.
  Factory renderer = Factory.rive;

  /// A completed future from another test zone never resumes, so a decoded
  /// file is handed back as a new future in the caller's zone.
  Future<File> load() {
    final decoded = file;
    if (decoded != null) return Future<File>.value(decoded);
    return _loading ??= _decode();
  }

  Future<File> _decode() async {
    final data = await rootBundle.load(assetPath);
    final decoded = await File.decode(
      data.buffer.asUint8List(),
      riveFactory: renderer,
    );
    if (decoded == null) {
      throw StateError('Could not decode $assetPath');
    }
    file = decoded;
    return decoded;
  }
}
