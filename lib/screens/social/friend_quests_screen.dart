import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/api_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/pan_african_design_system.dart';
import '../../config/api_contract.dart';
import '../../services/deep_link_service.dart';
import 'create_friend_quest_screen.dart';

class FriendQuestsScreen extends HookConsumerWidget {
  const FriendQuestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);
    final apiProvider = ref.read(apiProviderProvider.notifier);
    final quests = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState<bool>(true);
    final selectedTab = useState<int>(0); // 0: active, 1: completed

    useEffect(() {
      _loadQuests();
      return null;
    }, []);

    Future<void> _loadQuests() async {
      try {
        isLoading.value = true;
        final response = await apiProvider.client.get(
          ApiContract.url(ApiContract.social.friendQuests),
          queryParameters: {
            'status': selectedTab.value == 0 ? 'active' : 'completed',
            'page': 1,
            'limit': 50,
          },
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          quests.value = List<Map<String, dynamic>>.from(response.data['quests'] ?? []);
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Friend Quests'),
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
          _buildTabBar(context, selectedTab, _loadQuests),
          Expanded(
            child: isLoading.value
                ? Center(child: CircularProgressIndicator(color: PanAfricanColors.primary))
                : quests.value.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : RefreshIndicator(
                        onRefresh: _loadQuests,
                        color: PanAfricanColors.primary,
                        child: ListView.builder(
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          itemCount: quests.value.length,
                          itemBuilder: (context, index) {
                            return _buildQuestCard(
                              context,
                              quests.value[index],
                              isDark,
                              ref,
                              _loadQuests,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateFriendQuestScreen(),
            ),
          ).then((_) => _loadQuests());
        },
        backgroundColor: PanAfricanColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Quest'),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ValueNotifier<int> selectedTab, VoidCallback onTabChange) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context,
              'Active',
              0,
              selectedTab.value == 0,
              () {
                selectedTab.value = 0;
                onTabChange();
              },
            ),
          ),
          Expanded(
            child: _buildTab(
              context,
              'Completed',
              1,
              selectedTab.value == 1,
              () {
                selectedTab.value = 1;
                onTabChange();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    int index,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? PanAfricanColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            color: isSelected
                ? PanAfricanColors.primary
                : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80.sp,
            color: PanAfricanColors.textSecondary,
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            'No quests yet',
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: PanAfricanColors.textSecondary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'Create a quest with friends to start learning together!',
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: PanAfricanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    Map<String, dynamic> quest,
    bool isDark,
    WidgetRef ref,
    VoidCallback onRefresh,
  ) {
    final questType = quest['questType'] as String? ?? '';
    final target = quest['target'] as num? ?? 0;
    final totalProgress = quest['totalProgress'] as num? ?? 0;
    final userProgress = quest['userProgress'] as Map<String, dynamic>?;
    final status = quest['status'] as String? ?? 'active';
    final expiresAt = quest['expiresAt'] != null
        ? DateTime.parse(quest['expiresAt'])
        : null;
    final participants = List<Map<String, dynamic>>.from(quest['participants'] ?? []);
    final progressList = List<Map<String, dynamic>>.from(quest['progress'] ?? []);
    final rewardXP = quest['rewardXP'] as num? ?? 100;

    final progressPercent = target > 0 ? (totalProgress / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = status == 'completed';
    final timeRemaining = expiresAt != null
        ? expiresAt.difference(DateTime.now())
        : const Duration(days: 0);

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
        border: isCompleted
            ? Border.all(color: PanAfricanColors.success, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.primary.withOpacity(0.1),
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Icon(
                        _getQuestTypeIcon(questType),
                        color: PanAfricanColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getQuestTypeLabel(questType),
                            style: PanAfricanTypography.titleMedium(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Target: $target',
                            style: PanAfricanTypography.bodySmall(context).copyWith(
                              color: PanAfricanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.sm,
                          vertical: PanAfricanSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.success,
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                        child: Text(
                          'Completed',
                          style: PanAfricanTypography.labelSmall(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        final questId = quest['id'] as String? ?? '';
                        final link = DeepLinkService.questLink(questId);
                        Share.share('Join my friend quest on LingAfriq! $link');
                      },
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.md),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: PanAfricanColors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? PanAfricanColors.success : PanAfricanColors.primary,
                  ),
                  minHeight: 8.h,
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${totalProgress.toInt()} / ${target.toInt()}',
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCompleted && expiresAt != null)
                      Text(
                        _formatTimeRemaining(timeRemaining),
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: PanAfricanColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Row(
                  children: [
                    Text(
                      'Participants: ',
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: PanAfricanColors.textSecondary,
                      ),
                    ),
                    ...participants.take(3).map((p) => Padding(
                          padding: EdgeInsets.only(right: PanAfricanSpacing.xs),
                          child: CircleAvatar(
                            radius: 12.w,
                            backgroundColor: PanAfricanColors.primary,
                            child: Text(
                              (p['name'] as String? ?? p['username'] as String? ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                    if (participants.length > 3)
                      Text(
                        ' +${participants.length - 3}',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: PanAfricanColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (userProgress != null) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'Your progress: ${userProgress['current']} / $target',
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: PanAfricanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (isCompleted) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.sm),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.success.withOpacity(0.1),
                      borderRadius: PanAfricanRadius.mdBR,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: PanAfricanColors.success, size: 20.sp),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Text(
                          'Reward: +$rewardXP XP',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuestTypeIcon(String questType) {
    switch (questType) {
      case 'complete_lessons':
        return Icons.school;
      case 'earn_xp':
        return Icons.stars;
      case 'practice_days':
        return Icons.calendar_today;
      case 'vocabulary_review':
        return Icons.book;
      default:
        return Icons.emoji_events;
    }
  }

  String _getQuestTypeLabel(String questType) {
    switch (questType) {
      case 'complete_lessons':
        return 'Complete Lessons Together';
      case 'earn_xp':
        return 'Earn XP Together';
      case 'practice_days':
        return 'Practice Daily Together';
      case 'vocabulary_review':
        return 'Review Vocabulary Together';
      default:
        return 'Friend Quest';
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'Expired';
    if (duration.inDays > 0) return '${duration.inDays}d remaining';
    if (duration.inHours > 0) return '${duration.inHours}h remaining';
    return '${duration.inMinutes}m remaining';
  }
}
