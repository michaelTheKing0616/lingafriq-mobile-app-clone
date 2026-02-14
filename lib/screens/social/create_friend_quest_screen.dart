import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/dio_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/pan_african_design_system.dart';
import '../../config/api_contract.dart';

class CreateFriendQuestScreen extends HookConsumerWidget {
  const CreateFriendQuestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dio = ref.read(client);

    final selectedQuestType = useState<String?>('complete_lessons');
    final targetController = useTextEditingController(text: '10');
    final selectedFriends = useState<Set<String>>({});
    final selectedDuration = useState<int>(7);
    final friends = useState<List<Map<String, dynamic>>>([]);
    final isLoadingFriends = useState<bool>(true);
    final isCreating = useState<bool>(false);

    Future<void> loadFriends() async {
      try {
        isLoadingFriends.value = true;
        final response = await dio.get(
          ApiContract.url(ApiContract.social.connections),
          queryParameters: {'status': 'accepted'},
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final connections = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
          friends.value = connections.map((conn) {
            final connectedUser = conn['connected_user_id'] as Map<String, dynamic>? ?? {};
            return {
              'id': connectedUser['_id']?.toString() ?? connectedUser['id']?.toString() ?? '',
              'username': connectedUser['username'] ?? '',
              'name': '${connectedUser['first_name'] ?? ''} ${connectedUser['last_name'] ?? ''}'.trim(),
              'avatar': connectedUser['avater'] ?? connectedUser['avatar'],
            };
          }).toList();
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      } finally {
        isLoadingFriends.value = false;
      }
    }

    useEffect(() {
      loadFriends();
      return null;
    }, []);

    Future<void> createQuest() async {
      if (selectedQuestType.value == null) {
        ErrorHandler.showError(context, 'Please select a quest type');
        return;
      }

      final target = int.tryParse(targetController.text);
      if (target == null || target <= 0) {
        ErrorHandler.showError(context, 'Please enter a valid target number');
        return;
      }

      if (selectedFriends.value.isEmpty) {
        ErrorHandler.showError(context, 'Please select at least one friend');
        return;
      }

      try {
        isCreating.value = true;
        final response = await dio.post(
          ApiContract.url(ApiContract.social.friendQuests),
          data: {
            'questType': selectedQuestType.value,
            'target': target,
            'friendIds': selectedFriends.value.toList(),
            'durationDays': selectedDuration.value,
          },
        );

        if (response.statusCode == 201 && response.data['success'] == true) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true);
        } else {
          ErrorHandler.showError(context, response.data['error'] ?? 'Failed to create quest');
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      } finally {
        isCreating.value = false;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Friend Quest'),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestTypeSelector(
              context,
              selectedQuestType,
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            _buildTargetInput(
              context,
              targetController,
              selectedQuestType.value ?? '',
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            _buildDurationSelector(
              context,
              selectedDuration,
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            _buildFriendsSelector(
              context,
              selectedFriends,
              friends.value,
              isLoadingFriends.value,
              isDark,
              loadFriends,
            ),
            SizedBox(height: PanAfricanSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCreating.value ? null : createQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: PanAfricanRadius.lgBR,
                  ),
                ),
                child: isCreating.value
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                        ),
                      )
                    : Text(
                        'Create Quest',
                        style: PanAfricanTypography.titleMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestTypeSelector(
    BuildContext context,
    ValueNotifier<String?> selectedType,
    bool isDark,
  ) {
    final questTypes = [
      {
        'type': 'complete_lessons',
        'label': 'Complete Lessons Together',
        'icon': Icons.school,
        'description': 'Complete a certain number of lessons together',
      },
      {
        'type': 'earn_xp',
        'label': 'Earn XP Together',
        'icon': Icons.stars,
        'description': 'Earn a certain amount of XP together',
      },
      {
        'type': 'practice_days',
        'label': 'Practice Daily Together',
        'icon': Icons.calendar_today,
        'description': 'Practice for a certain number of days together',
      },
      {
        'type': 'vocabulary_review',
        'label': 'Review Vocabulary Together',
        'icon': Icons.book,
        'description': 'Review a certain number of vocabulary words together',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quest Type',
          style: PanAfricanTypography.titleLarge(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        ...questTypes.map((type) => Container(
              margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                border: Border.all(
                  color: selectedType.value == type['type']
                      ? PanAfricanColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: PanAfricanShadows.sm,
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  selectedType.value = type['type'] as String;
                },
                borderRadius: PanAfricanRadius.lgBR,
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.sm),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.primary.withOpacity(0.1),
                          borderRadius: PanAfricanRadius.mdBR,
                        ),
                        child: Icon(
                          type['icon'] as IconData,
                          color: PanAfricanColors.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['label'] as String,
                              style: PanAfricanTypography.titleMedium(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              type['description'] as String,
                              style: PanAfricanTypography.bodySmall(context).copyWith(
                                color: PanAfricanColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedType.value == type['type'])
                        Icon(
                          Icons.check_circle,
                          color: PanAfricanColors.primary,
                          size: 24.sp,
                        ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTargetInput(
    BuildContext context,
    TextEditingController controller,
    String questType,
    bool isDark,
  ) {
    String hintText;
    switch (questType) {
      case 'complete_lessons':
        hintText = 'Number of lessons';
        break;
      case 'earn_xp':
        hintText = 'Amount of XP';
        break;
      case 'practice_days':
        hintText = 'Number of days';
        break;
      case 'vocabulary_review':
        hintText = 'Number of words';
        break;
      default:
        hintText = 'Target amount';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target',
          style: PanAfricanTypography.titleLarge(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            border: OutlineInputBorder(
              borderRadius: PanAfricanRadius.lgBR,
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
          ),
          style: PanAfricanTypography.bodyLarge(context),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(
    BuildContext context,
    ValueNotifier<int> selectedDuration,
    bool isDark,
  ) {
    final durations = [
      {'days': 3, 'label': '3 days'},
      {'days': 7, 'label': '1 week'},
      {'days': 14, 'label': '2 weeks'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: PanAfricanTypography.titleLarge(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Row(
          children: durations.map((duration) {
            final days = duration['days'] as int;
            final isSelected = selectedDuration.value == days;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: duration == durations.last ? 0 : PanAfricanSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.primary
                      : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                  borderRadius: PanAfricanRadius.lgBR,
                  border: Border.all(
                    color: isSelected ? PanAfricanColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: PanAfricanShadows.sm,
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    selectedDuration.value = days;
                  },
                  borderRadius: PanAfricanRadius.lgBR,
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Text(
                      duration['label'] as String,
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFriendsSelector(
    BuildContext context,
    ValueNotifier<Set<String>> selectedFriends,
    List<Map<String, dynamic>> friends,
    bool isLoading,
    bool isDark,
    VoidCallback onRefresh,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invite Friends',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedFriends.value.isNotEmpty)
              Text(
                '${selectedFriends.value.length} selected',
                style: PanAfricanTypography.bodySmall(context).copyWith(
                  color: PanAfricanColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.md),
        if (isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.xl),
              child: CircularProgressIndicator(color: PanAfricanColors.primary),
            ),
          )
        else if (friends.isEmpty)
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48.sp,
                  color: PanAfricanColors.textSecondary,
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'No friends yet',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Add friends to invite them to quests',
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...friends.map((friend) {
            final friendId = friend['id'] as String? ?? '';
            final isSelected = selectedFriends.value.contains(friendId);
            return Container(
              margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                border: Border.all(
                  color: isSelected ? PanAfricanColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: PanAfricanShadows.sm,
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final newSet = Set<String>.from(selectedFriends.value);
                  if (isSelected) {
                    newSet.remove(friendId);
                  } else {
                    newSet.add(friendId);
                  }
                  selectedFriends.value = newSet;
                },
                borderRadius: PanAfricanRadius.lgBR,
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.w,
                        backgroundColor: PanAfricanColors.primary,
                        child: Text(
                          (friend['name'] as String? ?? friend['username'] as String? ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend['name'] as String? ?? friend['username'] as String? ?? 'Unknown',
                              style: PanAfricanTypography.titleMedium(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (friend['username'] != null)
                              Text(
                                '@${friend['username']}',
                                style: PanAfricanTypography.bodySmall(context).copyWith(
                                  color: PanAfricanColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: PanAfricanColors.primary,
                          size: 24.sp,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
