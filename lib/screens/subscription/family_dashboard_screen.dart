import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';

class FamilyDashboardScreen extends ConsumerStatefulWidget {
  const FamilyDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FamilyDashboardScreen> createState() =>
      _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState
    extends ConsumerState<FamilyDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _isAskingPolie = false;
  String? _polieSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final sub = ref.read(subscriptionProvider);
    if (sub.tier != SubscriptionTier.family) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final api = ref.read(apiProvider.notifier);
      final res = await api.getFamilyProgressDashboard();
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load family progress right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final isDark = context.isDarkMode;

    if (sub.tier != SubscriptionTier.family) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Dashboard')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.family_restroom_rounded,
                    size: 64.sp,
                    color: isDark
                        ? Colors.white70
                        : AfricanTheme.primaryGreen),
                SizedBox(height: 2.h),
                Text(
                  'Family Dashboard is available on the Family plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                )
              : _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final family = List<Map<String, dynamic>>.from(_data?['family'] ?? []);
    final aggregate = Map<String, dynamic>.from(_data?['aggregate'] ?? {});

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAggregateCard(aggregate, isDark)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1),
          SizedBox(height: 2.h),
          _buildPolieInsightsCard(aggregate, isDark)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05),
          SizedBox(height: 2.h),
          Text(
            'Family Members',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          ...family.map((m) => _buildMemberCard(m, isDark)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05)),
        ],
      ),
    );
  }

  Widget _buildAggregateCard(Map<String, dynamic> aggregate, bool isDark) {
    final totalMinutes = aggregate['totalMinutes'] ?? 0;
    final totalSessions = aggregate['totalSessions'] ?? 0;
    final wordsLearned = aggregate['wordsLearned'] ?? 0;
    final knownWords = aggregate['knownWords'] ?? 0;
    final listeningHours = (aggregate['listeningHours'] ?? 0).toString();
    final speakingHours = (aggregate['speakingHours'] ?? 0).toString();
    final languages =
        List<String>.from(aggregate['languagesStudied'] ?? const []);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AfricanTheme.primaryGreen,
            AfricanTheme.accentGold,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Overview',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildAggregateStat(
                'Study Minutes',
                totalMinutes.toString(),
              ),
              _buildAggregateStat(
                'Sessions',
                totalSessions.toString(),
              ),
              _buildAggregateStat(
                'Languages',
                languages.length.toString(),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildAggregateStat(
                'Words Learned',
                wordsLearned.toString(),
              ),
              _buildAggregateStat(
                'Known Words',
                knownWords.toString(),
              ),
              _buildAggregateStat(
                'Listening (h)',
                listeningHours,
              ),
              _buildAggregateStat(
                'Speaking (h)',
                speakingHours,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAggregateStat(String label, String value) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isDark) {
    final username = member['username']?.toString() ?? 'Learner';
    final globalId = member['globalId']?.toString();
    final summary = Map<String, dynamic>.from(member['summary'] ?? {});
    final languages =
        List<Map<String, dynamic>>.from(member['languages'] ?? const []);

    return Container(
      margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AfricanTheme.primaryGreen,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (globalId != null)
                    Text(
                      '@$globalId',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildMemberStat(
                'Minutes',
                (summary['totalMinutes'] ?? 0).toString(),
                isDark,
              ),
              _buildMemberStat(
                'Sessions',
                (summary['totalSessions'] ?? 0).toString(),
                isDark,
              ),
              _buildMemberStat(
                'Streak',
                (summary['currentStreak'] ?? 0).toString(),
                isDark,
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _buildMemberStat(
                'Words',
                (summary['wordsLearned'] ?? 0).toString(),
                isDark,
              ),
              _buildMemberStat(
                'Known',
                (summary['knownWords'] ?? 0).toString(),
                isDark,
              ),
              _buildMemberStat(
                'Listen h',
                (summary['listeningHours'] ?? 0).toString(),
                isDark,
              ),
              _buildMemberStat(
                'Speak h',
                (summary['speakingHours'] ?? 0).toString(),
                isDark,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Languages',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 2.h,
            children: languages.map((lang) {
              return Chip(
                backgroundColor: isDark
                    ? const Color(0xFF2A4A35)
                    : Colors.grey.shade100,
                label: Text(
                  '${lang['language']} • ${lang['level']} (${lang['score']})',
                  style: TextStyle(fontSize: 11.sp),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStat(
    String label,
    String value,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AfricanTheme.primaryGreen,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolieInsightsCard(Map<String, dynamic> aggregate, bool isDark) {
    final familySize = aggregate['familySize'] ?? 0;
    final totalMinutes = aggregate['totalMinutes'] ?? 0;
    final totalSessions = aggregate['totalSessions'] ?? 0;
    final wordsLearned = aggregate['wordsLearned'] ?? 0;
    final knownWords = aggregate['knownWords'] ?? 0;
    final listeningHours = aggregate['listeningHours'] ?? 0;
    final speakingHours = aggregate['speakingHours'] ?? 0;
    final languages =
        List<String>.from(aggregate['languagesStudied'] ?? const []);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102216) : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded),
              SizedBox(width: 2.w),
              Text(
                'Polie: Family Insights',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'A quick, AI‑generated summary of how your family is progressing. '
            'Polie looks at minutes, sessions, languages, and skills to suggest what to focus on next.',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (_polieSummary != null) ...[
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF163424) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              ),
              child: Text(
                _polieSummary!,
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isAskingPolie
                  ? null
                  : () async {
                      setState(() {
                        _isAskingPolie = true;
                      });
                      try {
                        final summary = StringBuffer()
                          ..writeln('Family size: $familySize')
                          ..writeln('Total minutes: $totalMinutes')
                          ..writeln('Total sessions: $totalSessions')
                          ..writeln('Words learned: $wordsLearned')
                          ..writeln('Known words: $knownWords')
                          ..writeln('Listening hours: $listeningHours')
                          ..writeln('Speaking hours: $speakingHours')
                          ..writeln('Languages: ${languages.join(', ')}');

                        final polieGenerator =
                            ref.read(polieContentGeneratorProvider);
                        final response =
                            await polieGenerator.generateClassroomActivities(
                          language: 'English',
                          classSummary: summary.toString(),
                        );

                        if (mounted) {
                          setState(() {
                            _polieSummary = response;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Polie is unavailable right now: $e',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isAskingPolie = false;
                          });
                        }
                      }
                    },
              icon: _isAskingPolie
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isAskingPolie ? 'Asking Polie…' : 'Ask Polie for insights',
              ),
            ),
          ),
        ],
      ),
    );
  }
}


