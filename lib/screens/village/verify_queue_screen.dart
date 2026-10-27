import 'package:flutter/material.dart';
import 'package:lingafriq/services/lexicon_suggest_client.dart';

/// Village Verify queue for community lexicon suggestions (P7-920).
class VerifyQueueScreen extends StatefulWidget {
  const VerifyQueueScreen({
    super.key,
    this.client,
    this.canApprove = false,
  });

  final LexiconSuggestClient? client;
  final bool canApprove;

  @override
  State<VerifyQueueScreen> createState() => _VerifyQueueScreenState();
}

class _VerifyQueueScreenState extends State<VerifyQueueScreen> {
  late final LexiconSuggestClient _client;
  List<LexiconSuggestionDto> _pending = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? LexiconSuggestClient();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!widget.canApprove) {
        setState(() {
          _pending = const [];
          _loading = false;
        });
        return;
      }
      final rows = await _client.fetchPendingQueue();
      if (!mounted) return;
      setState(() {
        _pending = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the verify queue.';
        _loading = false;
      });
    }
  }

  Future<void> _approve(String id) async {
    await _client.approve(id);
    await _load();
  }

  Future<void> _reject(String id) async {
    await _client.reject(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify queue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !widget.canApprove
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Native validators can review community word suggestions here.',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : _error != null
                  ? Center(child: Text(_error!))
                  : _pending.isEmpty
                      ? Center(
                          child: Text(
                            'No pending suggestions.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pending.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final row = _pending[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.lemma,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(row.glossEn),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _reject(row.suggestionId),
                                            child: const Text('Reject'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: () => _approve(row.suggestionId),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}
