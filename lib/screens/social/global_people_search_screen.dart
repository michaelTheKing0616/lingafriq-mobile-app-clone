import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/screens/chat/private_chat_screen.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
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
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
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
                  avatarUrl: (m['avatar'] ?? m['avater'])?.toString(),
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
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Find People'),
        backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _searchDebouncer.run(() => _runSearch(value));
                },
                decoration: InputDecoration(
                  hintText: 'Search by @handle...',
                  hintStyle: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: PanAfricanColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                ),
                style: PanAfricanTypography.bodyMedium(context),
              ),
            ),
          ),
          Expanded(
            child: _error != null
                ? AppErrorState(
                    message: _error!,
                    onRetry: () => _runSearch(_searchController.text.trim()),
                  )
                : _isLoading
                    ? ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.md,
                          vertical: PanAfricanSpacing.sm,
                        ),
                        itemCount: 5,
                        itemBuilder: (_, __) => SkeletonListCard(),
                      )
                    : _results.isEmpty
                        ? AppEmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No contacts found',
                            subtitle:
                                'Search for friends, classmates, or teachers by @handle.',
                          )
                        : OptimizedListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.md,
                      vertical: PanAfricanSpacing.sm,
                    ),
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
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
        leading: CircleAvatar(
          radius: 24.w,
          backgroundColor: PanAfricanColors.primary,
          child: Text(
            contact.username.isNotEmpty
                ? contact.username[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        title: Text(
          contact.username,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (contact.email != null) contact.email!,
            if (contact.language != null) contact.language!,
          ].join(' • '),
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            color: PanAfricanColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline_rounded,
          color: PanAfricanColors.primary,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
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


