import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ChatSearchScreen extends ConsumerStatefulWidget {
  final String? room;
  final String type; // 'global' | 'private' | 'all'

  const ChatSearchScreen({
    Key? key,
    this.room,
    this.type = 'all',
  }) : super(key: key);

  @override
  ConsumerState<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends ConsumerState<ChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  late final Debouncer _searchDebouncer;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiProvider.notifier);
      final data = await api.searchChatMessages(
        query: trimmed,
        room: widget.room,
        type: widget.type,
        limit: 100,
      );
      setState(() {
        _results = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
                boxShadow: PanAfricanShadows.md,
                border: Border.all(
                  color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _queryController,
                onChanged: (value) =>
                    _searchDebouncer.run(() => _search(value)),
                decoration: InputDecoration(
                  hintText: 'Search by text…',
                  hintStyle: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: isDark
                        ? PanAfricanColors.textSecondaryDark
                        : PanAfricanColors.textSecondaryLight,
                  ),
                  prefixIcon: Icon(Icons.search, color: isDark
                      ? PanAfricanColors.textSecondaryDark
                      : PanAfricanColors.textSecondaryLight),
                  border: InputBorder.none,
                ),
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: isDark
                      ? PanAfricanColors.textPrimaryDark
                      : PanAfricanColors.textPrimaryLight,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Text(
                _error!,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: PanAfricanColors.error,
                ),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No messages found.\nTry a different word or phrase.',
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: isDark
                            ? PanAfricanColors.textSecondaryDark
                            : PanAfricanColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    itemBuilder: (context, index) {
                      final m = _results[index];
                      final room = m['room_id']?.toString() ?? '';
                      final username =
                          m['sender_username']?.toString() ?? 'User';
                      final text = m['message']?.toString() ?? '';
                      final ts = m['timestamp']?.toString();
                      return ListTile(
                        title: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '@$username • $room • ${_formatTime(ts)}',
                          style: PanAfricanTypography.labelSmall(context).copyWith(
                            color: isDark
                                ? PanAfricanColors.textSecondaryDark
                                : PanAfricanColors.textSecondaryLight,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}


