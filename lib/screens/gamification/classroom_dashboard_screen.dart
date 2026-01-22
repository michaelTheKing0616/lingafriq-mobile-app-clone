import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/gamification/tribes_service.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';

class ClassroomDashboardScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;
  final String languageTag;
  final String? classroomCode;

  const ClassroomDashboardScreen({
    Key? key,
    required this.tribeId,
    required this.tribeName,
    required this.languageTag,
    this.classroomCode,
  }) : super(key: key);

  @override
  ConsumerState<ClassroomDashboardScreen> createState() =>
      _ClassroomDashboardScreenState();
}

class _ClassroomDashboardScreenState
    extends ConsumerState<ClassroomDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _isAskingPolie = false;
  String? _poliePrompt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final TribesService tribesService = ref.read(tribesServiceProvider);
      final res = await tribesService.getClassroomProgress(widget.tribeId);
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      setState(() {
        _error = 'Unable to load classroom progress right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Classroom: ${widget.tribeName}'),
        actions: [
          if (widget.classroomCode != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy class code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.classroomCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class code copied')),
                );
              },
            ),
        ],
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
    final classroom =
        List<Map<String, dynamic>>.from(_data?['classroom'] ?? []);
    final aggregate =
        Map<String, dynamic>.from(_data?['aggregate'] ?? const {});

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAggregateCard(aggregate, isDark)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),
            SizedBox(height: 2.h),
            _buildPoliePromptCard(isDark),
            SizedBox(height: 2.h),
            Text(
              'Learners',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            ...classroom
                .map((m) => _buildMemberCard(m, isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAggregateCard(Map<String, dynamic> aggregate, bool isDark) {
    final totalMinutes = aggregate['totalMinutes'] ?? 0;
    final totalSessions = aggregate['totalSessions'] ?? 0;
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
            'Class Overview',
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
                'Learners',
                (aggregate['classSize'] ?? 0).toString(),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Languages in this class: ${languages.join(', ')}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
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
                  if (globalId != null && globalId.isNotEmpty)
                    Text(
                      '@$globalId',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  Text(
                    '${summary['totalMinutes'] ?? 0} min • ${summary['totalSessions'] ?? 0} sessions',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: languages
                .map((lang) => Chip(
                      label: Text(
                        '${lang['language']} • ${lang['level'] ?? 'A1'}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF163424)
                          : Colors.green.shade50,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliePromptCard(bool isDark) {
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
                'Polie: Class Activity Ideas',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Need an idea for today\'s session? Ask Polie to suggest a short warm‑up or practice activity for ${widget.languageTag}.',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          if (_poliePrompt != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF163424) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              ),
              child: Text(
                _poliePrompt!,
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isAskingPolie ? null : _askPolieForActivity,
              icon: _isAskingPolie
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isAskingPolie ? 'Asking Polie…' : 'Ask Polie',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _askPolieForActivity() async {
    setState(() {
      _isAskingPolie = true;
    });
    try {
      // Summarise classroom profile for Polie
      final classroom =
          List<Map<String, dynamic>>.from(_data?['classroom'] ?? []);
      final aggregate =
          Map<String, dynamic>.from(_data?['aggregate'] ?? const {});
      final classSize =
          (aggregate['classSize'] ?? classroom.length ?? 0) as int;
      final totalMinutes = (aggregate['totalMinutes'] ?? 0) as int;
      final langs =
          List<String>.from(aggregate['languagesStudied'] ?? const []);

      // Rough per‑learner minutes (all‑time)
      final avgMinutes = classSize > 0 ? (totalMinutes / classSize).round() : 0;

      // CEFR distribution across all learners
      final Map<String, int> levelCounts = {};
      for (final member in classroom) {
        final memberLangs =
            List<Map<String, dynamic>>.from(member['languages'] ?? const []);
        for (final lang in memberLangs) {
          final level = (lang['level'] ?? '').toString();
          if (level.isEmpty) continue;
          levelCounts[level] = (levelCounts[level] ?? 0) + 1;
        }
      }
      final levelSummary = levelCounts.entries
          .map((e) => '${e.key}: ${e.value} learner${e.value == 1 ? '' : 's'}')
          .join(', ');

      final classSummary = StringBuffer()
        ..writeln('Class name: ${widget.tribeName}')
        ..writeln('Target language: ${widget.languageTag}')
        ..writeln('Learners: $classSize')
        ..writeln('Total study minutes (all time): $totalMinutes')
        ..writeln('Average minutes per learner (all time): $avgMinutes')
        ..writeln(
            'Languages studied in this class: ${langs.isEmpty ? 'unknown' : langs.join(', ')}')
        ..writeln(
            'Approximate CEFR distribution: ${levelSummary.isEmpty ? 'not yet assessed' : levelSummary}');

      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final ideas = await polieGenerator.generateClassroomActivities(
        language: widget.languageTag,
        classSummary: classSummary.toString(),
      );

      setState(() {
        _poliePrompt = ideas;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      // Fallback to a simple static hint if Polie fails
      setState(() {
        _poliePrompt =
            'Example warm‑up: In pairs, have learners greet each other in '
            '${widget.languageTag} and ask "How are you?" Then invite a few '
            'pairs to perform for the class and give gentle corrections.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAskingPolie = false;
        });
      }
    }
  }
}


