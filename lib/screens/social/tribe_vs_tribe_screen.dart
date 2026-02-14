import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/socket_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/tribe_vs_tribe_provider.dart';
import '../../providers/gamification_provider.dart';

/// Tribe vs Tribe Events Screen
class TribeVsTribeScreen extends ConsumerStatefulWidget {
  const TribeVsTribeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TribeVsTribeScreen> createState() => _TribeVsTribeScreenState();
}

class _TribeVsTribeScreenState extends ConsumerState<TribeVsTribeScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  Map<String, dynamic>? _currentCompetition;
  List<dynamic> _competitionResults = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to competition updates via Socket.io
    final socketService = ref.read(socketServiceProvider);
    socketService.onCompetitionUpdate((data) {
      if (mounted && data['competition_id'] == _currentCompetition?['_id']) {
        _loadCompetitionResults();
      }
    });
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final competitionsService = ref.read(competitionsServiceProvider);
      final competitions = await competitionsService.getCompetitions(
        status: 'active',
        type: 'tribe_vs_tribe',
      );
      
      if (competitions.isNotEmpty) {
        setState(() {
          _currentCompetition = competitions.first as Map<String, dynamic>;
        });
        await _loadCompetitionResults();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCompetitionResults() async {
    if (_currentCompetition == null) return;
    
    try {
      final competitionsService = ref.read(competitionsServiceProvider);
      final results = await competitionsService.getCompetitionResults(
        _currentCompetition!['_id'].toString(),
      );
      
      setState(() {
        _competitionResults = results['results'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = ref.watch(tribeVsTribeProvider.notifier);
    final currentEvent = eventProvider.currentEvent;
    final leaderboard = eventProvider.getLeaderboard();
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Tribe vs Tribe'),
          backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
          foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: List.generate(5, (_) => const SkeletonListCard()),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Tribe vs Tribe'),
          backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
          foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: AppErrorState(
          message: 'Failed to load competition',
          onRetry: _loadCompetitions,
        ),
      );
    }

    // Use API data if available, otherwise fallback to local provider
    final displayEvent = _currentCompetition != null 
        ? _currentCompetition 
        : (currentEvent != null ? {
            'name': currentEvent.name,
            'description': currentEvent.description,
            'isActive': currentEvent.isActive,
          } : null);

    if (displayEvent == null) {
      return Scaffold(
        backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Tribe vs Tribe'),
          backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
          foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadCompetitions();
              },
            ),
          ],
        ),
        body: AppEmptyState(
          icon: Icons.groups_rounded,
          title: 'No active event',
          subtitle: 'Check back soon for tribe vs tribe competitions',
          actionLabel: 'Retry',
          onAction: _loadCompetitions,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Tribe vs Tribe'),
        backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadCompetitions();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        children: [
          // Event header
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.forest,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Icon(Icons.emoji_events, color: colorScheme.onPrimary, size: 24.sp),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        displayEvent['name'] ?? 'Competition',
                        style: PanAfricanTypography.titleLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  displayEvent['description'] ?? '',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.sm,
                    vertical: PanAfricanSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: displayEvent['isActive'] == true 
                        ? PanAfricanColors.success.withOpacity(0.2)
                        : colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: PanAfricanRadius.roundBR,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        displayEvent['isActive'] == true ? Icons.bolt : Icons.timer,
                        size: 14.sp,
                        color: colorScheme.onPrimary,
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Text(
                        displayEvent['isActive'] == true
                            ? 'Active Competition'
                            : 'Upcoming Competition',
                        style: PanAfricanTypography.labelLarge(context).copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg),
          // Leaderboard
          Text(
            'Tribe Leaderboard',
            style: PanAfricanTypography.titleLarge(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          ...(_competitionResults.isNotEmpty
              ? _competitionResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final result = entry.value;
                  final tribeId = result['subject_id']?.toString() ?? '';
                  final isUserTribe = tribeId == gamification.tribe;
                  
                  return _buildTribeCard(
                    context,
                    index: index,
                    tribeId: tribeId,
                    points: result['points'] ?? 0,
                    isUserTribe: isUserTribe,
                  );
                })
              : leaderboard.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tribeEntry = entry.value;
                  final isUserTribe = tribeEntry.key == gamification.tribe;
                  
                  return _buildTribeCard(
                    context,
                    index: index,
                    tribeId: tribeEntry.key,
                    points: tribeEntry.value,
                    isUserTribe: isUserTribe,
                  );
                })),
          SizedBox(height: PanAfricanSpacing.md),
          // Your contribution
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: PanAfricanColors.primary, size: 20.sp),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      'Contribute to Your Tribe',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Every XP you earn contributes to your tribe\'s score! '
                  'Keep learning to help your tribe win!',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (gamification.tribe != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your XP automatically contributes to your tribe!'),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, '/tribe-selection');
                      }
                    },
                    child: Text(
                      gamification.tribe != null ? 'Learn Now' : 'Join a Tribe First',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 0) return Colors.amber;
    if (rank == 1) return Colors.grey;
    if (rank == 2) return Colors.brown;
    return Colors.blue;
  }

  String _getTribeName(String tribeId) {
    // Map tribe IDs to names
    final tribeNames = {
      'yoruba': 'Yoruba',
      'igbo': 'Igbo',
      'hausa': 'Hausa',
      'swahili': 'Swahili',
      'zulu': 'Zulu',
    };
    return tribeNames[tribeId] ?? tribeId;
  }

  Widget _buildTribeCard(
    BuildContext context, {
    required int index,
    required String tribeId,
    required int points,
    required bool isUserTribe,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isUserTribe
            ? PanAfricanColors.primary.withOpacity(0.1)
            : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: isUserTribe ? PanAfricanShadows.md : PanAfricanShadows.sm,
        border: isUserTribe
            ? Border.all(color: PanAfricanColors.primary, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.xs,
        ),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRankColor(index),
            boxShadow: [
              BoxShadow(
                color: _getRankColor(index).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        title: Text(
          _getTribeName(tribeId),
          style: PanAfricanTypography.titleMedium(context).copyWith(
            fontWeight: isUserTribe ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: isUserTribe
            ? Text(
                'Your Tribe',
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: PanAfricanColors.primary,
                ),
              )
            : null,
        trailing: Container(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.sm,
            vertical: PanAfricanSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: PanAfricanColors.gold.withOpacity(0.15),
            borderRadius: PanAfricanRadius.roundBR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16.sp, color: PanAfricanColors.gold),
              SizedBox(width: PanAfricanSpacing.xs),
              Text(
                '$points',
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: PanAfricanColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

