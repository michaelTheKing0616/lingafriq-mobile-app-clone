import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';

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
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];

  @override
  void dispose() {
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
        _error = 'Unable to search messages right now.';
      });
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
            padding: EdgeInsets.all(4.w),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F3527) : Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                boxShadow: DesignSystem.shadowMedium,
              ),
              child: TextField(
                controller: _queryController,
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: 'Search by text…',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No messages found.\nTry a different word or phrase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(4.w),
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
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
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


