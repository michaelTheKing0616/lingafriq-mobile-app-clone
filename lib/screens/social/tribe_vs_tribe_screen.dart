import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification/competitions_service.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import '../../providers/tribe_vs_tribe_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/social/tribe_vs_tribe_card.dart';

/// Tribe vs Tribe Events Screen
class TribeVsTribeScreen extends ConsumerStatefulWidget {
  const TribeVsTribeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TribeVsTribeScreen> createState() => _TribeVsTribeScreenState();
}

class _TribeVsTribeScreenState extends ConsumerState<TribeVsTribeScreen> {
  bool _isLoading = false;
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
    setState(() => _isLoading = true);
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
      debugPrint('Error loading competitions: $e');
      // Fallback to local provider
    } finally {
      setState(() => _isLoading = false);
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
      debugPrint('Error loading competition results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = ref.watch(tribeVsTribeProvider.notifier);
    final currentEvent = eventProvider.currentEvent;
    final leaderboard = eventProvider.getLeaderboard();
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    if (_isLoading) {
      return const Scaffold(
        body: DynamicLoadingScreen(),
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
        appBar: AppBar(
          title: const Text('Tribe vs Tribe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No active event'),
        ),
      );
    }

    final isActive = displayEvent['isActive'] == true;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1F1A),
              Color(0xFF102B24),
              Color(0xFF081317),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Futuristic header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Tribe vs Tribe Arena',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadCompetitions,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    children: [
                      // Event header using the rich TribeVsTribeCard
                      TribeVsTribeCard(
                        eventName: displayEvent['name'] ?? 'Competition',
                        participatingTribes: _competitionResults.isNotEmpty
                            ? _competitionResults
                                .map<String>((r) => r['subject_name']?.toString() ?? 'Tribe')
                                .toList()
                            : leaderboard.keys.toList(),
                        tribeScores: _competitionResults.isNotEmpty
                            ? {
                                for (final r in _competitionResults)
                                  (r['subject_name']?.toString() ?? 'Tribe'):
                                      (r['points'] as int? ?? 0),
                              }
                            : leaderboard.map((k, v) => MapEntry(k, v)),
                        startDate: DateTime.now(),
                        endDate: DateTime.now().add(const Duration(days: 7)),
                        isActive: isActive,
                        onTap: () {},
                      ),
                      SizedBox(height: 2.h),
          // Leaderboard
          Text(
            'Tribe Leaderboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          // Your contribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribute to Your Tribe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every XP you earn contributes to your tribe\'s score! '
                    'Keep learning to help your tribe win!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (gamification.tribe != null)
                    FilledButton(
                      onPressed: () {
                        // XP contribution happens automatically via gamification
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your XP automatically contributes to your tribe!'),
                          ),
                        );
                      },
                      child: const Text('Learn Now'),
                    )
                  else
                    FilledButton(
                      onPressed: () {
                        // Navigate to tribe selection
                        Navigator.pushNamed(context, '/tribe-selection');
                      },
                      child: const Text('Join a Tribe First'),
                    ),
                ],
              ),
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

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildTribeCard(
    BuildContext context, {
    required int index,
    required String tribeId,
    required int points,
    required bool isUserTribe,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUserTribe ? 4 : 1,
      color: isUserTribe
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(index),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _getTribeName(tribeId),
          style: TextStyle(
            fontWeight: isUserTribe ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '$points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

