import 'package:lingafriq/services/quiz/item_graders.dart';
import 'package:lingafriq/services/search_index_service.dart';

/// Hub order for the five-tab shell. Any other hub sorts after these.
const List<String> kFeatureHubOrder = <String>[
  'Today',
  'Learn',
  'Speak',
  'Play',
  'Village',
  'Me',
];

/// Route-map keys for Global Chat. The drawer hides these when chat is closed.
const Set<String> kGlobalChatFeatureKeys = <String>{
  'global_chat',
  'shellGlobalChat',
};

/// Day 1 is open. Every other unlock stage is locked.
const String kFeatureOpenStage = 'Day 1';

/// One feature from the route map. The label is copied from that file.
class FeatureEntry {
  const FeatureEntry({
    required this.key,
    required this.label,
    required this.hub,
    required this.unlockStage,
    required this.learningLoop,
    required this.routeKey,
    required this.drawerKeys,
  });

  /// Route key, or the drawer key when no route uses this label.
  final String key;

  final String label;
  final String hub;
  final String unlockStage;

  /// What the feature is, copied from the route map. This is the preview.
  final String learningLoop;

  /// Set when this entry is a route. Null for a drawer-only feature.
  final String? routeKey;

  /// Drawer keys that name this same feature.
  final List<String> drawerKeys;

  bool get locked => unlockStage != kFeatureOpenStage;

  bool coversDrawerKey(String drawerKey) {
    return key == drawerKey || drawerKeys.contains(drawerKey);
  }
}

/// Features that share one hub, already in A to Z order.
class FeatureHubGroup {
  const FeatureHubGroup({required this.hub, required this.entries});

  final String hub;
  final List<FeatureEntry> entries;
}

class _MapRow {
  const _MapRow({
    required this.kind,
    required this.key,
    required this.label,
    required this.hub,
    required this.unlockStage,
    required this.learningLoop,
  });

  final String kind;
  final String key;
  final String label;
  final String hub;
  final String unlockStage;
  final String learningLoop;
}

/// Every feature in the route map, with drawer items covered.
///
/// A route row is an entry point. A drawer row with the same label shares
/// that entry. A drawer label with no route stays as its own entry. Nothing
/// is added that the map does not name.
class FeatureDirectory {
  const FeatureDirectory._({required this.entries, required this.drawerKeys});

  /// Shipped route map. Labels are copied from that file, not invented.
  factory FeatureDirectory.shipped() {
    return _shipped ??= FeatureDirectory.fromRouteMap(kRouteMapCsv);
  }

  factory FeatureDirectory.fromRouteMap(String csv) {
    final List<_MapRow> rows = _rows(csv);
    final List<String> drawerKeys = <String>[];
    final Set<String> seenDrawer = <String>{};
    final Map<String, List<String>> drawerKeysByLabel =
        <String, List<String>>{};
    final Map<String, _MapRow> firstDrawerByKey = <String, _MapRow>{};
    for (final _MapRow row in rows) {
      if (row.kind != 'drawer') continue;
      firstDrawerByKey.putIfAbsent(row.key, () => row);
      if (!seenDrawer.add(row.key)) continue;
      drawerKeys.add(row.key);
      drawerKeysByLabel
          .putIfAbsent(_fold(row.label), () => <String>[])
          .add(row.key);
    }

    final List<FeatureEntry> entries = <FeatureEntry>[];
    final Set<String> coveredLabels = <String>{};
    for (final _MapRow row in rows) {
      if (row.kind != 'route') continue;
      final String label = _fold(row.label);
      final List<String> attached = coveredLabels.add(label)
          ? List<String>.from(drawerKeysByLabel[label] ?? const <String>[])
          : const <String>[];
      entries.add(
        FeatureEntry(
          key: row.key,
          label: row.label,
          hub: row.hub,
          unlockStage: row.unlockStage,
          learningLoop: row.learningLoop,
          routeKey: row.key,
          drawerKeys: attached,
        ),
      );
    }
    for (final String key in drawerKeys) {
      final _MapRow? row = firstDrawerByKey[key];
      if (row == null) continue;
      if (!coveredLabels.add(_fold(row.label))) continue;
      entries.add(
        FeatureEntry(
          key: row.key,
          label: row.label,
          hub: row.hub,
          unlockStage: row.unlockStage,
          learningLoop: row.learningLoop,
          routeKey: null,
          drawerKeys: <String>[row.key],
        ),
      );
    }
    return FeatureDirectory._(entries: entries, drawerKeys: drawerKeys);
  }

  static FeatureDirectory? _shipped;

  final List<FeatureEntry> entries;

  /// Unique drawer keys, in route-map order.
  final List<String> drawerKeys;

  int get count => entries.length;

  int get drawerCount => drawerKeys.length;

  int get coveredDrawerCount {
    var covered = 0;
    for (final String key in drawerKeys) {
      if (entries.any((FeatureEntry entry) => entry.coversDrawerKey(key))) {
        covered += 1;
      }
    }
    return covered;
  }

  /// Drawer keys with no directory entry. Zero means every drawer item is listed.
  int get countDifference => drawerCount - coveredDrawerCount;

  bool hasEntryPoint(String routeKey) {
    for (final FeatureEntry entry in entries) {
      if (entry.routeKey == routeKey || entry.key == routeKey) return true;
    }
    return false;
  }

  /// Hubs in shell order. Inside each hub, features are A to Z.
  ///
  /// [query] keeps labels that contain it. [hiddenKeys] drops chat-gated rows
  /// from the list without removing them from [entries].
  List<FeatureHubGroup> groupsFor(
    String query, {
    Set<String> hiddenKeys = const <String>{},
  }) {
    final String needle = _fold(query);
    final Map<String, List<FeatureEntry>> byHub =
        <String, List<FeatureEntry>>{};
    for (final FeatureEntry entry in entries) {
      if (_hidden(entry, hiddenKeys)) continue;
      if (needle.isNotEmpty && !_fold(entry.label).contains(needle)) continue;
      byHub.putIfAbsent(entry.hub, () => <FeatureEntry>[]).add(entry);
    }
    final List<String> hubs = byHub.keys.toList()..sort(_byHub);
    return <FeatureHubGroup>[
      for (final String hub in hubs)
        FeatureHubGroup(hub: hub, entries: (byHub[hub]!..sort(_byEntry))),
    ];
  }
}

bool _hidden(FeatureEntry entry, Set<String> hiddenKeys) {
  if (hiddenKeys.isEmpty) return false;
  if (hiddenKeys.contains(entry.key)) return true;
  final String? routeKey = entry.routeKey;
  if (routeKey != null && hiddenKeys.contains(routeKey)) return true;
  for (final String key in entry.drawerKeys) {
    if (hiddenKeys.contains(key)) return true;
  }
  return false;
}

String _fold(String value) => foldAnswer(value, diacriticInsensitive: true);

int _byHub(String a, String b) {
  final int rank = _hubRank(a).compareTo(_hubRank(b));
  if (rank != 0) return rank;
  return _fold(a).compareTo(_fold(b));
}

int _hubRank(String hub) {
  final int index = kFeatureHubOrder.indexOf(hub);
  if (index >= 0) return index;
  return kFeatureHubOrder.length;
}

int _byEntry(FeatureEntry a, FeatureEntry b) {
  final int byLabel = _fold(a.label).compareTo(_fold(b.label));
  if (byLabel != 0) return byLabel;
  return a.key.compareTo(b.key);
}

List<_MapRow> _rows(String csv) {
  final List<List<String>> table = _csvRows(csv);
  if (table.isEmpty) return const <_MapRow>[];
  final List<String> header = table.first
      .map((String cell) => cell.trim())
      .toList();
  final Map<String, int> index = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    index[header[i]] = i;
  }
  String read(List<String> row, String name) {
    final int? at = index[name];
    if (at == null || at >= row.length) return '';
    return row[at].trim();
  }

  final List<_MapRow> rows = <_MapRow>[];
  for (final List<String> row in table.skip(1)) {
    final String key = read(row, 'key');
    final String label = read(row, 'label');
    if (key.isEmpty || label.isEmpty) continue;
    rows.add(
      _MapRow(
        kind: read(row, 'kind'),
        key: key,
        label: label,
        hub: read(row, 'hub'),
        unlockStage: read(row, 'unlock_stage'),
        learningLoop: read(row, 'learning_loop'),
      ),
    );
  }
  return rows;
}

List<List<String>> _csvRows(String csv) {
  final List<List<String>> rows = <List<String>>[];
  final List<String> row = <String>[];
  final StringBuffer cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < csv.length; i++) {
    final String char = csv[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          cell.write('"');
          i += 1;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
      continue;
    }
    if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (char == '\n') {
      row.add(cell.toString());
      cell.clear();
      if (row.any((String value) => value.trim().isNotEmpty)) {
        rows.add(List<String>.from(row));
      }
      row.clear();
    } else if (char != '\r') {
      cell.write(char);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    if (row.any((String value) => value.trim().isNotEmpty)) {
      rows.add(List<String>.from(row));
    }
  }
  return rows;
}
