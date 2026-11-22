/// Five shell tabs. Word Card is a global tool, not a tab.
enum ShellTab { today, learn, speak, play, village }

/// Result of reading a link. [tab] is null when the link matches nothing.
class TabLink {
  const TabLink._({required this.raw, required this.detail, this.tab});

  /// Text the learner tried to open.
  final String raw;

  /// Parser detail when the link could not be read. Empty when it was read.
  final String detail;

  /// Matching tab. Null for an unknown link.
  final ShellTab? tab;

  bool get known => tab != null;
}

/// Route names used inside one tab navigator.
abstract final class ShellRoutes {
  static const String root = 'shell-root';
  static const String section = 'shell-section';
  static const String tool = 'shell-tool';
}

/// Maps a link onto one of the five tabs.
///
/// A [FormatException] is kept on [TabLink.detail]. It is not discarded.
abstract final class TabRoutes {
  static const List<ShellTab> tabs = ShellTab.values;

  static TabLink resolve(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return TabLink._(raw: raw, detail: '');
    }
    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException catch (error) {
      return TabLink._(raw: raw, detail: error.message);
    }
    final String name = _leaf(uri);
    final ShellTab? tab = _tabs[name];
    if (tab == null) {
      return TabLink._(raw: raw, detail: '');
    }
    return TabLink._(raw: raw, detail: '', tab: tab);
  }

  static String _leaf(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last.toLowerCase();
    }
    final String path = uri.path;
    if (path.startsWith('/')) {
      return path.substring(1).toLowerCase();
    }
    return path.toLowerCase();
  }

  static const Map<String, ShellTab> _tabs = <String, ShellTab>{
    'today': ShellTab.today,
    'learn': ShellTab.learn,
    'speak': ShellTab.speak,
    'play': ShellTab.play,
    'village': ShellTab.village,
  };
}
