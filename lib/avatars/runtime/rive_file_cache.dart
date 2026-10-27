import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

/// Canonical cast asset decoded once per process via [RiveFileCache].
abstract final class RiveRuntimeAssets {
  static const cast = 'assets/rive/lingafriq_cast.riv';
}

/// Decodes each Rive asset at most once. Widget tests set [renderer] to
/// [Factory.flutter] because headless runs have no GPU context for [Factory.rive].
class RiveFileCache {
  RiveFileCache._();

  static final RiveFileCache instance = RiveFileCache._();

  final Map<String, File> _decoded = {};
  final Map<String, Future<File>> _inFlight = {};

  Factory renderer = Factory.rive;

  /// How many assets have finished decoding (for tests).
  int get cachedAssetCount => _decoded.length;

  Future<File> load(String assetPath) {
    final hit = _decoded[assetPath];
    if (hit != null) {
      return Future<File>.value(hit);
    }
    final pending = _inFlight[assetPath];
    if (pending != null) {
      return pending;
    }
    final future = _decode(assetPath);
    _inFlight[assetPath] = future;
    return future;
  }

  Future<File> _decode(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final file = await File.decode(
        data.buffer.asUint8List(),
        riveFactory: renderer,
      );
      if (file == null) {
        throw StateError('Could not decode $assetPath');
      }
      _decoded[assetPath] = file;
      return file;
    } finally {
      _inFlight.remove(assetPath);
    }
  }

  void clear({String? assetPath}) {
    if (assetPath != null) {
      _decoded.remove(assetPath);
      _inFlight.remove(assetPath);
      return;
    }
    _decoded.clear();
    _inFlight.clear();
  }
}
