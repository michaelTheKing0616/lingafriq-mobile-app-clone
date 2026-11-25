import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/offline/cache_eviction.dart';
import '../../services/offline/lesson_download_service.dart';
import '../../services/offline/local_database_service.dart';

enum DownloadUnitState { idle, downloading, pausedWifi, complete, error, lowStorage }

class DownloadUnit {
  const DownloadUnit({
    required this.language,
    required this.title,
    required this.bytes,
    required this.state,
    this.progress = 0,
  });

  final String language;
  final String title;
  final int bytes;
  final DownloadUnitState state;
  final double progress;
}

/// Loads stored units and opens [DownloadsScreen].
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  bool _wifiOnly = true;
  bool _lowStorage = false;
  List<DownloadUnit> _units = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool(wifiOnlyPrefKey) ?? true;
    final downloads = LessonDownloadService();
    var lowStorage = false;
    try {
      lowStorage = await downloads.isStorageQuotaExceeded();
    } catch (_) {}
    final units = <DownloadUnit>[];
    try {
      await LocalDatabaseService().init();
      final byLanguage = <String, int>{};
      for (final lesson in LocalDatabaseService().getAllLessons()) {
        byLanguage[lesson.language] = (byLanguage[lesson.language] ?? 0) + lesson.sizeBytes;
      }
      for (final entry in byLanguage.entries) {
        final recorded = await CacheEvictionManager().unitBytes(entry.key);
        units.add(DownloadUnit(
          language: entry.key,
          title: entry.key,
          bytes: recorded ?? entry.value,
          state: DownloadUnitState.complete,
        ));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _wifiOnly = wifiOnly;
      _lowStorage = lowStorage;
      _units = units;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DownloadsScreen(
      units: _units,
      wifiOnly: _wifiOnly,
      lowStorage: _lowStorage,
      onWifiOnlyChanged: (value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(wifiOnlyPrefKey, value);
        if (mounted) setState(() => _wifiOnly = value);
      },
      onDownload: (language, {required allowMobile}) {
        LessonDownloadService().downloadLessonPack(language, allowMobile: allowMobile);
      },
      onDelete: (language) async {
        await LessonDownloadService().deleteDownloadedLessons(language);
        await _load();
      },
    );
  }
}

/// Storage management for downloaded units. Wi-Fi is the default.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({
    super.key,
    required this.units,
    required this.wifiOnly,
    required this.lowStorage,
    this.onWifiOnlyChanged,
    this.onDownload,
    this.onDelete,
  });

  final List<DownloadUnit> units;
  final bool wifiOnly;
  final bool lowStorage;
  final ValueChanged<bool>? onWifiOnlyChanged;
  final void Function(String language, {required bool allowMobile})? onDownload;
  final Future<void> Function(String language)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 1 + (lowStorage ? 1 : 0) + units.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wi-Fi only'),
              value: wifiOnly,
              onChanged: onWifiOnlyChanged,
            );
          }
          if (lowStorage && index == 1) {
            return Semantics(
              liveRegion: true,
              label: 'Not enough storage',
              child: const Text('Not enough storage'),
            );
          }
          final unitIndex = index - 1 - (lowStorage ? 1 : 0);
          final unit = units[unitIndex];
          return _UnitTile(unit: unit, onDownload: onDownload, onDelete: onDelete);
        },
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.unit, this.onDownload, this.onDelete});

  final DownloadUnit unit;
  final void Function(String language, {required bool allowMobile})? onDownload;
  final Future<void> Function(String language)? onDelete;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = unit.bytes > 0 ? formatPackSize(unit.bytes) : 'Size not listed';
    final over = unit.bytes > 0 && packExceedsCeiling(unit.bytes);
    final status = _status(unit.state);
    return Semantics(
      label: '${unit.title}, $sizeLabel, $status',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(unit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sizeLabel),
              if (over) const Text('Over 30 MB'),
              Text(status),
              if (unit.state == DownloadUnitState.downloading)
                Semantics(
                  label: 'Downloading ${(unit.progress * 100).round()} percent',
                  value: '${(unit.progress * 100).round()} percent',
                  child: LinearProgressIndicator(value: unit.progress),
                ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: onDownload == null
                        ? null
                        : () => onDownload!(unit.language, allowMobile: false),
                    child: const Text('Download'),
                  ),
                  TextButton(
                    onPressed: onDownload == null
                        ? null
                        : () => onDownload!(unit.language, allowMobile: true),
                    child: const Text('Download on mobile data'),
                  ),
                  TextButton(
                    onPressed: onDelete == null ? null : () => _confirmDelete(context),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _status(DownloadUnitState state) {
    switch (state) {
      case DownloadUnitState.idle:
        return 'Ready';
      case DownloadUnitState.downloading:
        return 'Downloading';
      case DownloadUnitState.pausedWifi:
        return 'Waiting for Wi-Fi';
      case DownloadUnitState.complete:
        return 'Downloaded';
      case DownloadUnitState.error:
        return 'Could not download';
      case DownloadUnitState.lowStorage:
        return 'Not enough storage';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete download'),
        content: Text('Delete ${unit.title}? This frees the storage it uses.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await onDelete?.call(unit.language);
  }
}
