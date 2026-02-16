import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/utils.dart';

class FamilyDashboardScreen extends ConsumerStatefulWidget {
  const FamilyDashboardScreen({super.key});

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
    final subNotifier = ref.read(subscriptionProvider.notifier);
    if (!subNotifier.canAccessFamilyDashboard()) {
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
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      setState(() {
        _error = 'Unable to load family progress right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccessFamily =
        ref.read(subscriptionProvider.notifier).canAccessFamilyDashboard();
    final isDark = context.isDarkMode;

    if (!canAccessFamily) {
      return Scaffold(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        appBar: AppBar(
          title: Text('Family Dashboard', style: PanAfricanTypography.titleLarge(context)),
          backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
          leading: Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(PanAfricanIcons.back, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.family_restroom_rounded,
                    size: 64.sp,
                    color: isDark
                        ? PanAfricanColors.textSecondaryDark
                        : PanAfricanColors.primary),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'Family Dashboard is available on the Family plan.',
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodyLarge(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Family Dashboard', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
          leading: Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(PanAfricanIcons.back, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        body: _isLoading
          ? Center(child: CircularProgressIndicator(color: PanAfricanColors.primary))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.error),
                  ),
                )
              : _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final family = List<Map<String, dynamic>>.from(_data?['family'] ?? []);
    final aggregate = Map<String, dynamic>.from(_data?['aggregate'] ?? {});

    return SingleChildScrollView(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAggregateCard(aggregate, isDark)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1),
          SizedBox(height: PanAfricanSpacing.md),
          _buildPolieInsightsCard(aggregate, isDark)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            'Family Members',
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
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
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Overview',
            style: PanAfricanTypography.titleLarge(context, color: Theme.of(context).colorScheme.onPrimary),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
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
          SizedBox(height: PanAfricanSpacing.sm),
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
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
            ),
            Text(
              label,
              style: PanAfricanTypography.labelSmall(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
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
      margin: EdgeInsets.only(top: PanAfricanSpacing.xs, bottom: PanAfricanSpacing.xs),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: PanAfricanColors.primary,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  if (globalId != null)
                    Text(
                      '@$globalId',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
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
          SizedBox(height: PanAfricanSpacing.xxs),
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
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'Languages',
            style: PanAfricanTypography.labelLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Wrap(
            spacing: PanAfricanSpacing.sm,
            runSpacing: PanAfricanSpacing.xs,
            children: languages.map((lang) {
              return Chip(
                backgroundColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                label: Text(
                  '${lang['language']} • ${lang['level']} (${lang['score']})',
                  style: PanAfricanTypography.labelSmall(context),
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
            style: PanAfricanTypography.titleSmall(context, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.primary),
          ),
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context),
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
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: PanAfricanColors.primary),
              SizedBox(width: PanAfricanSpacing.sm),
              Text(
                'Polie: Family Insights',
                style: PanAfricanTypography.titleMedium(context),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'A quick, AI‑generated summary of how your family is progressing. '
            'Polie looks at minutes, sessions, languages, and skills to suggest what to focus on next.',
            style: PanAfricanTypography.bodySmall(context),
          ),
          if (_polieSummary != null) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.primaryDark.withOpacity(0.3) : PanAfricanColors.primaryContainer,
                borderRadius: PanAfricanRadius.lgBR,
              ),
              child: Text(
                _polieSummary!,
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: _isAskingPolie ? 'Asking Polie for insights' : 'Ask Polie for family insights',
              button: true,
              child: FilledButton.icon(
                onPressed: _isAskingPolie
                    ? null
                    : () async {
                      HapticFeedback.mediumImpact();
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
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _polieSummary = response;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ErrorHandler.showError(context, e);
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isAskingPolie = false;
                          });
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
              ),
              icon: _isAskingPolie
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(
                _isAskingPolie ? 'Asking Polie…' : 'Ask Polie for insights',
                style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}


