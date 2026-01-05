import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/social_audio_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/social_audio/social_audio_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';

/// Following Screen - Manage following/followers for social audio
class FollowingScreen extends ConsumerStatefulWidget {
  final String? userId;
  final bool showFollowers;

  const FollowingScreen({
    Key? key,
    this.userId,
    this.showFollowers = false,
  }) : super(key: key);

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _following = [];
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(userProvider);
    final targetUserId = widget.userId ?? user?.id.toString();
    if (targetUserId == null) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(socialAudioServiceProvider);
      
      final following = await service.getFollowingList(userId: targetUserId);
      final followers = await service.getFollowersList(userId: targetUserId);
      
      setState(() {
        _following = following;
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(String targetUserId, bool isFollowing) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    try {
      final service = ref.read(socialAudioServiceProvider);
      
      if (isFollowing) {
        await service.unfollowUser(
          userId: user.id.toString(),
          targetUserId: targetUserId,
        );
      } else {
        await service.followUser(
          userId: user.id.toString(),
          targetUserId: targetUserId,
        );
      }
      
      // Reload data
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    final targetUserId = widget.userId ?? user?.id.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following & Followers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Followers'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUserList(_following, targetUserId, isDark, false),
            _buildUserList(_followers, targetUserId, isDark, true),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users,
    String? currentUserId,
    bool isDark,
    bool isFollowersList,
  ) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 2.h),
            Text(_error!),
            SizedBox(height: 4.h),
            FilledButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64.sp, color: PanAfricanColors.neutralMedium),
            SizedBox(height: 2.h),
            Text(
              isFollowersList ? 'No followers yet' : 'Not following anyone yet',
              style: TextStyle(fontSize: 16.sp, color: PanAfricanColors.neutralMedium),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final userData = users[index];
          final userId = userData['id']?.toString() ?? userData['user_id']?.toString() ?? '';
          final userName = userData['name'] ?? userData['username'] ?? 'Unknown';
          final userAvatar = userData['avatar'] ?? userData['avatar_url'];
          final isFollowing = userData['is_following'] as bool? ?? false;

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24.r,
                backgroundColor: PanAfricanColors.primary,
                backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                child: userAvatar == null
                    ? Text(
                        userName[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      )
                    : null,
              ),
              title: Text(
                userName,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              subtitle: userData['bio'] != null
                  ? Text(
                      userData['bio'],
                      style: TextStyle(fontSize: 12.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: userId != currentUserId
                  ? FilledButton(
                      onPressed: () => _toggleFollow(userId, isFollowing),
                      style: FilledButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.grey
                            : PanAfricanColors.primary,
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    )
                  : null,
              onTap: () {
                // Navigate to user profile
              },
            ),
          );
        },
      ),
    );
  }
}

