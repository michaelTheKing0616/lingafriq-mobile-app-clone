import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/screens/chat/private_chat_screen.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

class GlobalPeopleSearchScreen extends ConsumerStatefulWidget {
  const GlobalPeopleSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalPeopleSearchScreen> createState() =>
      _GlobalPeopleSearchScreenState();
}

class _GlobalPeopleSearchScreenState
    extends ConsumerState<GlobalPeopleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 400));
  bool _isLoading = false;
  String? _error;
  List<PrivateChatContact> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }

    // We support both "@handle" and raw handle searches.
    final handle = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    if (handle.length < 2) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiProvider.notifier);
      final data = await api.searchUsersByHandle(handle);
      setState(() {
        _results = data
            .map<PrivateChatContact>((m) => PrivateChatContact(
                  id: (m['id'] as num?)?.toInt() ?? -1,
                  username: (m['username'] ?? '') as String,
                  email: m['email']?.toString(),
                  avatarUrl: m['avater']?.toString(),
                  language: m['nationality']?.toString(),
                ))
            .toList();
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
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Find People'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
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
                controller: _searchController,
                onChanged: (value) {
                  _searchDebouncer.run(() => _runSearch(value));
                },
                decoration: InputDecoration(
                  hintText: 'Search by @handle...',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
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
                style: TextStyle(color: Colors.red.shade300, fontSize: 14.sp),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'Search for friends, classmates, or teachers by @handle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : OptimizedListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final contact = _results[index];
                      return _buildResultTile(context, contact, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(
    BuildContext context,
    PrivateChatContact contact,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(4.w),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AfricanTheme.primaryGreen,
          child: Text(
            contact.username.isNotEmpty
                ? contact.username[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          [
            if (contact.email != null) contact.email!,
            if (contact.language != null) contact.language!,
          ].join(' • '),
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline_rounded,
          color: AfricanTheme.primaryGreen,
        ),
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: PrivateChatScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }
}


