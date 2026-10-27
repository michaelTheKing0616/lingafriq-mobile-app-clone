import 'package:flutter/material.dart';
import 'package:lingafriq/services/lens/lens_collection_service.dart';

/// Copy key: lens.collection.empty (P7-909).
const String lensCollectionEmptyCopy =
    'Save words from Lens to build a personal deck for review.';

class LensCollectionScreen extends StatefulWidget {
  const LensCollectionScreen({
    super.key,
    required this.userId,
    this.collectionService,
  });

  final String userId;
  final LensCollectionService? collectionService;

  @override
  State<LensCollectionScreen> createState() => _LensCollectionScreenState();
}

class _LensCollectionScreenState extends State<LensCollectionScreen> {
  late final LensCollectionService _service;
  List<LensCollectionItem> _items = [];
  bool _loading = true;
  String? _error;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.collectionService ?? LensCollectionService();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listForUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _pending = _service.pendingSyncCount(widget.userId, items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _flushPending() async {
    setState(() => _loading = true);
    try {
      await _service.flushPendingSync(userId: widget.userId);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lens collection'),
        actions: [
          if (_pending > 0)
            TextButton(
              onPressed: _loading ? null : _flushPending,
              child: Text('Sync ($_pending)'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            lensCollectionEmptyCopy,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        final pending = item.syncState != LensCollectionSyncState.synced;
        return ListTile(
          minVerticalPadding: 12,
          title: Text(item.word),
          subtitle: Text('${item.language} · ${item.objectSetId}'),
          trailing: pending
              ? const Icon(Icons.cloud_upload_outlined, semanticLabel: 'Pending sync')
              : const Icon(Icons.check_circle_outline, semanticLabel: 'Synced'),
        );
      },
    );
  }
}
