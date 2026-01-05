import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/conversation_analytics_model.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Conversation Analytics Screen
/// Shows conversation metrics, fluency trends, and topic coverage
class ConversationAnalyticsScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const ConversationAnalyticsScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.read(conversationAnalyticsServiceProvider);
    final analytics = useState<ConversationAnalytics?>(null);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load analytics
    useEffect(() {
      _loadAnalytics(analyticsService, analytics, isLoading);
      return null;
    }, []);

    if (isLoading.value || analytics.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Conversation Analytics')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final a = analytics.value!;
    final topTopics = a.getTopTopics(limit: 5);
    final topVocab = a.getTopVocabulary(limit: 10);

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadAnalytics(analyticsService, analytics, isLoading),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Stats
                _OverallStatsCard(analytics: a, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Fluency Score
                _FluencyCard(analytics: a, isDark: isDark)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Top Topics
                if (topTopics.isNotEmpty)
                  _TopTopicsCard(topics: topTopics, isDark: isDark)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Top Vocabulary
                if (topVocab.isNotEmpty)
                  _TopVocabularyCard(vocabulary: topVocab, isDark: isDark)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAnalytics(
    ConversationAnalyticsService service,
    ValueNotifier<ConversationAnalytics?> analytics,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final a = await service.loadAnalytics(languageName);
      analytics.value = a;
    } catch (e) {
      debugPrint('Error loading conversation analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _OverallStatsCard extends StatelessWidget {
  final ConversationAnalytics analytics;
  final bool isDark;

  const _OverallStatsCard({
    required this.analytics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          children: [
            Text(
              'Overall Statistics',
              style: PanAfricanTypography.titleLarge(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Sessions',
                  value: '${analytics.sessions.length}',
                  icon: Icons.chat,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Messages',
                  value: '${analytics.totalMessages}',
                  icon: Icons.message,
                  color: PanAfricanColors.secondary,
                ),
                _StatItem(
                  label: 'Words',
                  value: '${analytics.totalWords}',
                  icon: Icons.text_fields,
                  color: PanAfricanColors.accent,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Topics',
                  value: '${analytics.allTopics.length}',
                  icon: Icons.topic,
                  color: PanAfricanColors.tertiary,
                ),
                _StatItem(
                  label: 'Avg Session',
                  value: '${analytics.averageSessionLength.toStringAsFixed(1)}m',
                  icon: Icons.timer,
                  color: PanAfricanColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          value,
          style: PanAfricanTypography.titleMedium(context)?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context),
        ),
      ],
    );
  }
}

class _FluencyCard extends StatelessWidget {
  final ConversationAnalytics analytics;
  final bool isDark;

  const _FluencyCard({
    required this.analytics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: PanAfricanColors.accent),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Fluency Score',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              '${analytics.averageFluency.toStringAsFixed(0)}%',
              style: PanAfricanTypography.displaySmall(context)?.copyWith(
                fontWeight: FontWeight.bold,
                color: PanAfricanColors.accent,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            LinearProgressIndicator(
              value: analytics.averageFluency / 100.0,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.accent),
              minHeight: 8.h,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              _getFluencyDescription(analytics.averageFluency),
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getFluencyDescription(double fluency) {
    if (fluency >= 90) return 'Excellent! You\'re very fluent! 🌟';
    if (fluency >= 75) return 'Great progress! Keep practicing! 💪';
    if (fluency >= 60) return 'Good! You\'re improving steadily! 📈';
    if (fluency >= 40) return 'Keep going! Practice makes perfect! 🎯';
    return 'Getting started! Every conversation helps! 🌱';
  }
}

class _TopTopicsCard extends StatelessWidget {
  final List<MapEntry<String, int>> topics;
  final bool isDark;

  const _TopTopicsCard({
    required this.topics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: PanAfricanColors.primary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Most Discussed Topics',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...topics.asMap().entries.map((entry) {
              final index = entry.key;
              final topic = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: PanAfricanColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: PanAfricanTypography.labelSmall(context)?.copyWith(
                            color: PanAfricanColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        topic.key,
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                    Chip(
                      label: Text('${topic.value}'),
                      backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                      labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                        color: PanAfricanColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TopVocabularyCard extends StatelessWidget {
  final List<MapEntry<String, int>> vocabulary;
  final bool isDark;

  const _TopVocabularyCard({
    required this.vocabulary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: PanAfricanColors.secondary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Most Used Vocabulary',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Wrap(
              spacing: PanAfricanSpacing.sm,
              runSpacing: PanAfricanSpacing.sm,
              children: vocabulary.map((entry) {
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.key),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Text(
                        '${entry.value}',
                        style: PanAfricanTypography.labelSmall(context)?.copyWith(
                          color: PanAfricanColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: PanAfricanColors.secondary.withOpacity(0.1),
                  labelStyle: PanAfricanTypography.bodySmall(context)?.copyWith(
                    color: PanAfricanColors.secondary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

