import 'package:flutter/material.dart';
import 'package:lingafriq/services/learning/heritage_milestone_service.dart';

/// Surfaces `/api/v2/learning/heritage/milestones` (wired in [HeritageMilestoneService]).
class HeritageMilestonesScreen extends StatefulWidget {
  const HeritageMilestonesScreen({super.key});

  @override
  State<HeritageMilestonesScreen> createState() => _HeritageMilestonesScreenState();
}

class _HeritageMilestonesScreenState extends State<HeritageMilestonesScreen> {
  final _service = HeritageMilestoneService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchMilestones();
      final raw = data['milestones'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) list.add(Map<String, dynamic>.from(e));
        }
      }
      final src = data['source']?.toString();
      setState(() {
        _items = list;
        _dataSource = (src == 'cache' || src == 'pack_manifest') ? src : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _dataSource = null;
        _loading = false;
      });
    }
  }

  Future<void> _complete(String id) async {
    try {
      await _service.completeMilestone(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milestone saved')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heritage milestones'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length + (_dataSource != null ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_dataSource != null && i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _dataSource == 'pack_manifest'
                                  ? 'Showing milestones from your last offline pack. Connect to sync progress.'
                                  : 'Offline: showing your last saved milestone list.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      );
                    }
                    final idx = _dataSource != null ? i - 1 : i;
                    final m = _items[idx];
                    final id = m['id']?.toString() ?? '';
                    final title = m['title']?.toString() ?? id;
                    final desc = m['description']?.toString() ?? '';
                    final done = m['completed'] == true;
                    return Card(
                      child: ListTile(
                        title: Text(title),
                        subtitle: desc.isNotEmpty ? Text(desc) : null,
                        trailing: done
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : TextButton(
                                onPressed: id.isEmpty || _dataSource == 'pack_manifest'
                                    ? null
                                    : () => _complete(id),
                                child: const Text('Mark done'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
