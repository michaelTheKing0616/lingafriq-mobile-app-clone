import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// User Search by Global ID Screen
/// Allows users to find other users by their global_id (handle) in chat modes
class UserSearchGlobalIdScreen extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onUserSelected;
  final String? currentChatType; // 'global', 'community', 'tribe', 'private'

  const UserSearchGlobalIdScreen({
    Key? key,
    required this.onUserSelected,
    this.currentChatType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useTextEditingController();
    final searchResults = useState<List<Map<String, dynamic>>>([]);
    final isSearching = useState(false);
    final searchHistory = useState<List<String>>([]);
    final searchError = useState<String?>(null);
    final debounceTimer = useRef<Timer?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> searchUsers(String query) async {
      if (query.trim().isEmpty) {
        searchResults.value = [];
        return;
      }

      isSearching.value = true;
      searchError.value = null;
      try {
        final response = await ApiService.get(
          ApiContract.url(ApiContract.accounts.usersSearch),
          queryParameters: {
            'handle': query.trim(),
            'q': query.trim(),
          },
        );

        if (response.statusCode == 200) {
          final users = response.data;
          if (users is List) {
            searchResults.value = users.cast<Map<String, dynamic>>();
            
            // Add to search history
            if (!searchHistory.value.contains(query.trim())) {
              searchHistory.value = [query.trim(), ...searchHistory.value.take(4)];
            }
          }
        }
      } catch (e) {
        searchResults.value = [];
        searchError.value = 'Failed to search users. Please try again.';
      } finally {
        isSearching.value = false;
      }
    }

    void debouncedSearch(String query) {
      debounceTimer.value?.cancel();
      if (query.trim().isEmpty) {
        searchResults.value = [];
        searchError.value = null;
        return;
      }
      debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
        searchUsers(query);
      });
    }

    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Find User'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: PanAfricanTextField(
                  controller: searchQuery,
                  label: 'Search by @handle (global_id)',
                  hint: 'e.g., @username or username',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    if (value.length >= 2) {
                      debouncedSearch(value);
                    } else {
                      searchResults.value = [];
                      searchError.value = null;
                    }
                  },
                ),
              ),

              // Search History
              if (searchHistory.value.isNotEmpty && searchResults.value.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Searches',
                        style: PanAfricanTypography.titleSmall(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Wrap(
                        spacing: PanAfricanSpacing.sm,
                        children: searchHistory.value.map((term) {
                          return PanAfricanChip(
                            label: term,
                            icon: Icons.history,
                            onSelected: () {
                              searchQuery.text = term;
                              searchUsers(term);
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: PanAfricanSpacing.md),
                    ],
                  ),
                ),

              // Results
              Expanded(
                child: searchError.value != null
                    ? AppErrorState(
                        message: searchError.value!,
                        onRetry: () => searchUsers(searchQuery.text.trim()),
                      )
                    : isSearching.value
                        ? ListView.builder(
                            padding: EdgeInsets.all(PanAfricanSpacing.lg),
                            itemCount: 4,
                            itemBuilder: (_, __) => SkeletonListCard(),
                          )
                        : searchResults.value.isEmpty
                            ? AppEmptyState(
                                icon: Icons.person_search_rounded,
                                title: searchQuery.text.trim().isEmpty
                                    ? 'Search for users'
                                    : 'No contacts found',
                                subtitle: searchQuery.text.trim().isEmpty
                                    ? 'Enter an @handle to find users'
                                    : 'Try a different @handle or username',
                                actionLabel: searchQuery.text.trim().length >= 2
                                    ? 'Retry'
                                    : null,
                                onAction: searchQuery.text.trim().length >= 2
                                    ? () => searchUsers(searchQuery.text.trim())
                                    : null,
                              )
                        : OptimizedListView.builder(
                            padding: EdgeInsets.all(PanAfricanSpacing.lg),
                            itemCount: searchResults.value.length,
                            itemBuilder: (context, index) {
                              final user = searchResults.value[index];
                              return _UserResultCard(
                                user: user,
                                isDark: isDark,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  onUserSelected(user);
                                  Navigator.pop(context);
                                },
                              )
                                  .animate(delay: (index * 50).ms)
                                  .fadeIn(duration: 200.ms)
                                  .slideX(begin: -0.1);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onTap;

  const _UserResultCard({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final globalId = user['global_id'] ?? '';
    final username = user['username'] ?? 'Unknown';
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final avatar = user['avatar'] ?? user['avater'] ?? '';
    final nationality = user['nationality'] ?? '';

    return PanAfricanCard(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      onTap: onTap,
      hasHoverEffect: true,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: PanAfricanGradients.savannaGold,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: avatar.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Text(
                          username[0].toUpperCase(),
                          style: PanAfricanTypography.titleMedium(context)
                              .copyWith(color: PanAfricanColors.neutralDarkest),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          username[0].toUpperCase(),
                          style: PanAfricanTypography.titleMedium(context)
                              .copyWith(color: PanAfricanColors.neutralDarkest),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      username[0].toUpperCase(),
                      style: PanAfricanTypography.titleMedium(context)
                          .copyWith(color: PanAfricanColors.neutralDarkest),
                    ),
                  ),
          ),
          SizedBox(width: PanAfricanSpacing.md),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                    ),
                    if (globalId.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                        ),
                        child: Text(
                          '@${globalId}',
                          style: PanAfricanTypography.labelSmall(context)
                              .copyWith(color: PanAfricanColors.primary),
                        ),
                      ),
                  ],
                ),
                if (name.isNotEmpty) ...[
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    name,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
                if (nationality.isNotEmpty) ...[
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Row(
                    children: [
                      Icon(Icons.public, size: 12.sp, color: PanAfricanColors.neutralMedium),
                      SizedBox(width: PanAfricanSpacing.xxs),
                      Text(
                        nationality,
                        style: PanAfricanTypography.labelSmall(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action
          Icon(
            Icons.arrow_forward_ios,
            size: 16.sp,
            color: PanAfricanColors.neutralMedium,
          ),
        ],
      ),
    );
  }
}

