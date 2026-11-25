import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory that contains this app's `pubspec.yaml` and `lib/`.
///
/// `flutter test` uses the package directory as the working directory, whatever
/// that folder is named. Older checkouts also ran from a parent that contained
/// a nested `lingafriq-mobile-app-clone` directory; that layout still resolves.
String appRepoRoot() {
  final cwd = Directory.current.path;
  if (_isAppRoot(cwd)) return cwd;
  final nested = p.join(cwd, 'lingafriq-mobile-app-clone');
  if (_isAppRoot(nested)) return nested;
  return cwd;
}

bool _isAppRoot(String path) {
  return File(p.join(path, 'pubspec.yaml')).existsSync() &&
      Directory(p.join(path, 'lib')).existsSync();
}
