import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ChallengeType {
  xpRace,
  lessonSprint,
  perfectScore,
  vocabularyMaster,
}

enum ChallengeDuration {
  oneDay,
  threeDays,
  oneWeek,
  twoWeeks,
}

class ChallengeFriendScreen extends HookConsumerWidget {
  final String? friendId;

  const ChallengeFriendScreen({
    super.key,
    this.friendId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFriend = useState<Map<String, dynamic>?>(null);
    final selectedChallengeType = useState<ChallengeType?>(null);
    final selectedDuration = useState<ChallengeDuration?>(null);
    final selectedCowries = useState<int>(0);
    final searchQuery = useState('');
    final friends = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final isSending = useState(false);
    final showSuccess = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> loadFriends() async {
      isLoading.value = true;
      try {
        final response = await ApiService.get(
          ApiContract.url('/api/social/friends'),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data is Map && data['friends'] is List) {
            friends.value = (data['friends'] as List)
                .map((f) => f as Map<String, dynamic>)
                .toList();
          } else if (data is List) {
            friends.value = data.map((f) => f as Map<String, dynamic>).toList();
          }
        }
      } catch (e) {
        friends.value = [];
      } finally {
        isLoading.value = false;
      }
    }

    void selectFriendById(String id, List<Map<String, dynamic>> friendsList) {
      final friend = friendsList.firstWhere(
        (f) => (f['id']?.toString() ?? f['_id']?.toString()) == id,
        orElse: () => {},
      );
      if (friend.isNotEmpty) {
        selectedFriend.value = friend;
      }
    }

    String challengeTypeToString(ChallengeType type) {
      switch (type) {
        case ChallengeType.xpRace:
          return 'xp_race';
        case ChallengeType.lessonSprint:
          return 'lesson_sprint';
        case ChallengeType.perfectScore:
          return 'perfect_score';
        case ChallengeType.vocabularyMaster:
          return 'vocabulary_master';
      }
    }

    int durationToDays(ChallengeDuration duration) {
      switch (duration) {
        case ChallengeDuration.oneDay:
          return 1;
        case ChallengeDuration.threeDays:
          return 3;
        case ChallengeDuration.oneWeek:
          return 7;
        case ChallengeDuration.twoWeeks:
          return 14;
      }
    }

    useEffect(() {
      loadFriends();
      if (friendId != null) {
        selectFriendById(friendId!, friends.value);
      }
      return null;
    }, []);

    Future<void> sendChallenge() async {
      if (selectedFriend.value == null ||
          selectedChallengeType.value == null ||
          selectedDuration.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all fields'),
            backgroundColor: PolieColors.error,
          ),
        );
        return;
      }

      isSending.value = true;
      try {
        final challengeData = {
          'friendId': selectedFriend.value!['id']?.toString() ?? selectedFriend.value!['_id']?.toString(),
          'type': challengeTypeToString(selectedChallengeType.value!),
          'duration': durationToDays(selectedDuration.value!),
          'cowriesStake': selectedCowries.value,
        };

        final response = await ApiService.post(
          ApiContract.url('/api/social/challenges/create'),
          data: challengeData,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          showSuccess.value = true;
          HapticFeedback.heavyImpact();

          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          throw Exception('Failed to send challenge');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending challenge: ${e.toString()}'),
              backgroundColor: PolieColors.error,
            ),
          );
        }
      } finally {
        isSending.value = false;
      }
    }

    String challengeTypeLabel(ChallengeType type) {
      switch (type) {
        case ChallengeType.xpRace:
          return 'XP Race';
        case ChallengeType.lessonSprint:
          return 'Lesson Sprint';
        case ChallengeType.perfectScore:
          return 'Perfect Score';
        case ChallengeType.vocabularyMaster:
          return 'Vocabulary Master';
      }
    }

    String challengeTypeDescription(ChallengeType type) {
      switch (type) {
        case ChallengeType.xpRace:
          return 'Who earns more XP this week';
        case ChallengeType.lessonSprint:
          return 'Who completes more lessons today';
        case ChallengeType.perfectScore:
          return 'Who gets more perfect quiz scores';
        case ChallengeType.vocabularyMaster:
          return 'Who learns more words';
      }
    }

    String durationLabel(ChallengeDuration duration) {
      switch (duration) {
        case ChallengeDuration.oneDay:
          return '1 Day';
        case ChallengeDuration.threeDays:
          return '3 Days';
        case ChallengeDuration.oneWeek:
          return '1 Week';
        case ChallengeDuration.twoWeeks:
          return '2 Weeks';
      }
    }

    if (showSuccess.value) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PolieColors.primary,
                PolieColors.primaryDark,
                PolieColors.obsidian,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 100.sp,
                    color: PolieColors.success,
                  )
                      .animate()
                      .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),
                  SizedBox(height: PolieSpacing.xl),
                  Text(
                    'Challenge Sent!',
                    style: PolieTypography.h1(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  SizedBox(height: PolieSpacing.md),
                  Text(
                    'Your friend will be notified',
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filteredFriends = friends.value.where((friend) {
      final name = friend['username']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.value.toLowerCase());
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(PolieSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFriendSelection(
                        context,
                        selectedFriend,
                        searchQuery,
                        filteredFriends,
                        isLoading.value,
                        isDark,
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      _buildChallengeTypeSelection(
                        context,
                        selectedChallengeType,
                        challengeTypeLabel,
                        challengeTypeDescription,
                        isDark,
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      _buildDurationSelection(
                        context,
                        selectedDuration,
                        durationLabel,
                        isDark,
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      _buildCowriesStake(
                        context,
                        selectedCowries,
                        isDark,
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      _buildPreviewCard(
                        context,
                        selectedFriend,
                        selectedChallengeType,
                        selectedDuration,
                        selectedCowries,
                        challengeTypeLabel,
                        durationLabel,
                        isDark,
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: isSending.value ? 'Sending challenge' : 'Send challenge to friend',
                          button: true,
                          enabled: !isSending.value &&
                              selectedFriend.value != null &&
                              selectedChallengeType.value != null &&
                              selectedDuration.value != null,
                          child: FilledButton(
                          onPressed: isSending.value ||
                                  selectedFriend.value == null ||
                                  selectedChallengeType.value == null ||
                                  selectedDuration.value == null
                              ? null
                              : sendChallenge,
                          style: FilledButton.styleFrom(
                            backgroundColor: PolieColors.goldEmber,
                            padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PolieRadius.md),
                            ),
                          ),
                          child: isSending.value
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(PolieColors.obsidian),
                                  ),
                                )
                              : Text(
                                  'Send Challenge',
                                  style: PolieTypography.button(context).copyWith(
                                    color: PolieColors.obsidian,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: PolieSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge a Friend',
                  style: PolieTypography.h1(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.xs),
                Text(
                  'Compete and have fun together',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendSelection(
    BuildContext context,
    ValueNotifier<Map<String, dynamic>?> selectedFriend,
    ValueNotifier<String> searchQuery,
    List<Map<String, dynamic>> filteredFriends,
    bool isLoading,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Friend',
          style: PolieTypography.h3(context).copyWith(
            color: PolieColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        if (selectedFriend.value != null)
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: PolieColors.royalAmethyst.withOpacity(0.2),
                  child: Text(
                    (selectedFriend.value!['username']?.toString() ?? 'U')[0].toUpperCase(),
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.royalAmethyst,
                    ),
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Text(
                    selectedFriend.value!['username']?.toString() ?? 'Friend',
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: PolieColors.textSecondary),
                  onPressed: () {
                    selectedFriend.value = null;
                  },
                ),
              ],
            ),
          )
        else ...[
          TextField(
            onChanged: (value) => searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: Icon(Icons.search, color: PolieColors.textSecondary),
              filled: true,
              fillColor: PolieColors.surfaceContainer.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PolieRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(color: PolieColors.goldEmber),
              ),
            )
          else if (filteredFriends.isEmpty)
            Padding(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Center(
                child: Text(
                  'No friends found',
                  style: PolieTypography.body(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(maxHeight: 200.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredFriends.length,
                itemBuilder: (context, index) {
                  final friend = filteredFriends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: PolieColors.royalAmethyst.withOpacity(0.2),
                      child: Text(
                        (friend['username']?.toString() ?? 'U')[0].toUpperCase(),
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.royalAmethyst,
                        ),
                      ),
                    ),
                    title: Text(
                      friend['username']?.toString() ?? 'Friend',
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      selectedFriend.value = friend;
                      searchQuery.value = '';
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildChallengeTypeSelection(
    BuildContext context,
    ValueNotifier<ChallengeType?> selectedType,
    String Function(ChallengeType) labelFn,
    String Function(ChallengeType) descriptionFn,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Challenge Type',
          style: PolieTypography.h3(context).copyWith(
            color: PolieColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        ...ChallengeType.values.map((type) {
          final isSelected = selectedType.value == type;
          return Padding(
            padding: EdgeInsets.only(bottom: PolieSpacing.sm),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                selectedType.value = type;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? PolieColors.royalAmethyst.withOpacity(0.2) : null,
                  border: Border.all(
                    color: isSelected ? PolieColors.royalAmethyst : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(PolieRadius.lg),
                ),
                child: PolieGlassCard(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelFn(type),
                            style: PolieTypography.body(context).copyWith(
                              color: PolieColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.xs),
                          Text(
                            descriptionFn(type),
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: PolieColors.royalAmethyst),
                  ],
                ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDurationSelection(
    BuildContext context,
    ValueNotifier<ChallengeDuration?> selectedDuration,
    String Function(ChallengeDuration) labelFn,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: PolieTypography.h3(context).copyWith(
            color: PolieColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        Wrap(
          spacing: PolieSpacing.sm,
          runSpacing: PolieSpacing.sm,
          children: ChallengeDuration.values.map((duration) {
            final isSelected = selectedDuration.value == duration;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                selectedDuration.value = duration;
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.lg,
                  vertical: PolieSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PolieColors.goldEmber
                      : PolieColors.surfaceContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(PolieRadius.md),
                  border: Border.all(
                    color: isSelected ? PolieColors.goldEmber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  labelFn(duration),
                  style: PolieTypography.body(context).copyWith(
                    color: isSelected ? PolieColors.obsidian : PolieColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCowriesStake(
    BuildContext context,
    ValueNotifier<int> selectedCowries,
    bool isDark,
  ) {
    final cowriesOptions = [0, 10, 25, 50, 100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cowries Stake (Optional)',
          style: PolieTypography.h3(context).copyWith(
            color: PolieColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.xs),
        Text(
          'Winner takes all cowries',
          style: PolieTypography.bodySmall(context).copyWith(
            color: PolieColors.textSecondary,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        Wrap(
          spacing: PolieSpacing.sm,
          runSpacing: PolieSpacing.sm,
          children: cowriesOptions.map((amount) {
            final isSelected = selectedCowries.value == amount;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                selectedCowries.value = amount;
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.lg,
                  vertical: PolieSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PolieColors.goldEmber
                      : PolieColors.surfaceContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(PolieRadius.md),
                  border: Border.all(
                    color: isSelected ? PolieColors.goldEmber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  amount == 0 ? 'None' : '$amount',
                  style: PolieTypography.body(context).copyWith(
                    color: isSelected ? PolieColors.obsidian : PolieColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    ValueNotifier<Map<String, dynamic>?> selectedFriend,
    ValueNotifier<ChallengeType?> selectedChallengeType,
    ValueNotifier<ChallengeDuration?> selectedDuration,
    ValueNotifier<int> selectedCowries,
    String Function(ChallengeType) labelFn,
    String Function(ChallengeDuration) durationLabelFn,
    bool isDark,
  ) {
    if (selectedFriend.value == null ||
        selectedChallengeType.value == null ||
        selectedDuration.value == null) {
      return const SizedBox.shrink();
    }

    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Preview',
            style: PolieTypography.h3(context).copyWith(
              color: PolieColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          _buildPreviewRow(
            context,
            'Friend',
            selectedFriend.value!['username']?.toString() ?? 'Friend',
          ),
          _buildPreviewRow(
            context,
            'Type',
            labelFn(selectedChallengeType.value!),
          ),
          _buildPreviewRow(
            context,
            'Duration',
            durationLabelFn(selectedDuration.value!),
          ),
          if (selectedCowries.value > 0)
            _buildPreviewRow(
              context,
              'Stake',
              '${selectedCowries.value} Cowries',
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: PolieTypography.bodySmall(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
