import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/gamification/tribes_service.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Classroom: ${widget.tribeName}',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (widget.classroomCode != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy class code',
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: widget.classroomCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class code copied',
                      style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary),
                    ),
                    backgroundColor: PanAfricanColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: PanAfricanColors.primary,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64.sp,
                          color: PanAfricanColors.error,
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),
                        FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _load();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
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
      color: PanAfricanColors.primary,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAggregateCard(aggregate, isDark)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),
            SizedBox(height: PanAfricanSpacing.md),
            _buildPoliePromptCard(context, isDark),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Learners',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...classroom
                .map((m) => _buildMemberCard(context, m, isDark)
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.celebration,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Overview',
            style: PanAfricanTypography.titleLarge(context, color: colorScheme.onPrimary),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Row(
            children: [
              _buildAggregateStat(
                context,
                'Study Minutes',
                totalMinutes.toString(),
              ),
              _buildAggregateStat(
                context,
                'Sessions',
                totalSessions.toString(),
              ),
              _buildAggregateStat(
                context,
                'Learners',
                (aggregate['classSize'] ?? 0).toString(),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'Languages: ${languages.isEmpty ? 'None yet' : languages.join(', ')}',
            style: PanAfricanTypography.bodySmall(context, color: colorScheme.onPrimary.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregateStat(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: PanAfricanTypography.displaySmall(context, color: colorScheme.onPrimary),
          ),
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context, color: colorScheme.onPrimary.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member, bool isDark) {
    final username = member['username']?.toString() ?? 'Learner';
    final globalId = member['globalId']?.toString();
    final summary = Map<String, dynamic>.from(member['summary'] ?? {});
    final languages =
        List<Map<String, dynamic>>.from(member['languages'] ?? const []);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: PanAfricanColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: PanAfricanTypography.titleMedium(context, color: colorScheme.onPrimary),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    if (globalId != null && globalId.isNotEmpty)
                      Text(
                        '@$globalId',
                        style: PanAfricanTypography.labelSmall(context),
                      ),
                    SizedBox(height: PanAfricanSpacing.xxxs),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14.sp,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Text(
                          '${summary['totalMinutes'] ?? 0} min',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14.sp,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Text(
                          '${summary['totalSessions'] ?? 0} sessions',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (languages.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Wrap(
              spacing: PanAfricanSpacing.xs,
              runSpacing: PanAfricanSpacing.xs,
              children: languages
                  .map((lang) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.xs,
                          vertical: PanAfricanSpacing.xxxs,
                        ),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.primaryContainer,
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                        child: Text(
                          '${lang['language']} • ${lang['level'] ?? 'A1'}',
                          style: PanAfricanTypography.labelSmall(
                            context,
                            color: PanAfricanColors.onPrimaryContainer,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPoliePromptCard(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: PanAfricanColors.ankaraPurple.withOpacity(0.3),
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: PanAfricanColors.ankaraPurple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: PanAfricanColors.ankaraPurple,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Text(
                  'Polie: Class Activity Ideas',
                  style: PanAfricanTypography.titleSmall(context),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'Need an idea for today\'s session? Ask Polie to suggest a short warm-up or practice activity for ${widget.languageTag}.',
            style: PanAfricanTypography.bodySmall(context),
          ),
          if (_poliePrompt != null) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerHighDark
                    : PanAfricanColors.surfaceContainerHighLight,
                borderRadius: PanAfricanRadius.mdBR,
              ),
              child: Text(
                _poliePrompt!,
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.ankaraPurple,
              ),
              onPressed: _isAskingPolie
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _askPolieForActivity();
                    },
              icon: _isAskingPolie
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(Icons.auto_awesome_rounded, size: 18.sp),
              label: Text(
                _isAskingPolie ? 'Asking Polie…' : 'Ask Polie',
                style: PanAfricanTypography.labelMedium(context, color: colorScheme.onPrimary),
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


