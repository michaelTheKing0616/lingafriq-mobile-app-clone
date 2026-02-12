import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/conversation_analytics_model.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Conversation Analytics Screen - Polie Dark Theme
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

    useEffect(() {
      _loadAnalytics(analyticsService, analytics, isLoading);
      return null;
    }, []);

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
              _buildHeader(context, analyticsService, analytics, isLoading),
              Expanded(
                child: isLoading.value || analytics.value == null
                    ? _buildLoadingState(context)
                    : _buildContent(context, analytics.value!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ConversationAnalyticsService service,
    ValueNotifier<ConversationAnalytics?> analytics,
    ValueNotifier<bool> isLoading,
  ) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation Analytics',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  languageName,
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: Icons.refresh_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadAnalytics(service, analytics, isLoading);
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(PolieColors.royalAmethyst),
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Loading analytics...',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConversationAnalytics a) {
    final topTopics = a.getTopTopics(limit: 5);
    final topVocab = a.getTopVocabulary(limit: 10);

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverallStatsCard(analytics: a)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1),
          SizedBox(height: PolieSpacing.lg),
          _FluencyCard(analytics: a)
              .animate(delay: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.1),
          SizedBox(height: PolieSpacing.lg),
          if (topTopics.isNotEmpty)
            _TopTopicsCard(topics: topTopics)
                .animate(delay: 200.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.1),
          SizedBox(height: PolieSpacing.lg),
          if (topVocab.isNotEmpty)
            _TopVocabularyCard(vocabulary: topVocab)
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),
        ],
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

  const _OverallStatsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return _PolieGlassCard(
      child: Column(
        children: [
          Text(
            'Overall Statistics',
            style: PolieTypography.h2(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Sessions',
                value: '${analytics.sessions.length}',
                icon: Icons.chat_rounded,
                color: PolieColors.royalAmethyst,
              ),
              _StatItem(
                label: 'Messages',
                value: '${analytics.totalMessages}',
                icon: Icons.message_rounded,
                color: PolieColors.electricTeal,
              ),
              _StatItem(
                label: 'Words',
                value: '${analytics.totalWords}',
                icon: Icons.text_fields_rounded,
                color: PolieColors.goldEmber,
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          SizedBox(height: PolieSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Topics',
                value: '${analytics.allTopics.length}',
                icon: Icons.topic_rounded,
                color: PolieColors.royalAmethystLight,
              ),
              _StatItem(
                label: 'Avg Session',
                value: '${analytics.averageSessionLength.toStringAsFixed(1)}m',
                icon: Icons.timer_rounded,
                color: PolieColors.electricTealLight,
              ),
            ],
          ),
        ],
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
        Container(
          padding: EdgeInsets.all(PolieSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28.sp),
        ),
        SizedBox(height: PolieSpacing.sm),
        Text(
          value,
          style: PolieTypography.h2(context).copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.xs),
        Text(
          label,
          style: PolieTypography.bodySmall(context).copyWith(
            color: PolieColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FluencyCard extends StatelessWidget {
  final ConversationAnalytics analytics;

  const _FluencyCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final fluencyColor = _getFluencyColor(analytics.averageFluency);

    return _PolieGlassCard(
      glowColor: fluencyColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(PolieSpacing.sm),
                decoration: BoxDecoration(
                  color: fluencyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PolieRadius.sm),
                ),
                child: Icon(Icons.speed_rounded, color: fluencyColor, size: 24.sp),
              ),
              SizedBox(width: PolieSpacing.md),
              Text(
                'Fluency Score',
                style: PolieTypography.h2(context).copyWith(
                  color: PolieColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          Center(
            child: Text(
              '${analytics.averageFluency.toStringAsFixed(0)}%',
              style: PolieTypography.h1(context).copyWith(
                color: fluencyColor,
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(PolieRadius.pill),
            child: LinearProgressIndicator(
              value: analytics.averageFluency / 100.0,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(fluencyColor),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            _getFluencyDescription(analytics.averageFluency),
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFluencyColor(double fluency) {
    if (fluency >= 90) return PolieColors.success;
    if (fluency >= 75) return PolieColors.electricTeal;
    if (fluency >= 60) return PolieColors.goldEmber;
    if (fluency >= 40) return PolieColors.goldEmberLight;
    return PolieColors.error;
  }

  String _getFluencyDescription(double fluency) {
    if (fluency >= 90) return 'Excellent! You\'re very fluent!';
    if (fluency >= 75) return 'Great progress! Keep practicing!';
    if (fluency >= 60) return 'Good! You\'re improving steadily!';
    if (fluency >= 40) return 'Keep going! Practice makes perfect!';
    return 'Getting started! Every conversation helps!';
  }
}

class _TopTopicsCard extends StatelessWidget {
  final List<MapEntry<String, int>> topics;

  const _TopTopicsCard({required this.topics});

  @override
  Widget build(BuildContext context) {
    return _PolieGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(PolieSpacing.sm),
                decoration: BoxDecoration(
                  color: PolieColors.royalAmethyst.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PolieRadius.sm),
                ),
                child: Icon(Icons.topic_rounded, color: PolieColors.royalAmethyst, size: 24.sp),
              ),
              SizedBox(width: PolieSpacing.md),
              Text(
                'Most Discussed Topics',
                style: PolieTypography.h2(context).copyWith(
                  color: PolieColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          ...topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: PolieSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: PolieColors.royalAmethyst.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: PolieTypography.label(context).copyWith(
                          color: PolieColors.royalAmethyst,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: PolieSpacing.md),
                  Expanded(
                    child: Text(
                      topic.key,
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PolieSpacing.sm,
                      vertical: PolieSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: PolieColors.royalAmethyst.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(PolieRadius.pill),
                    ),
                    child: Text(
                      '${topic.value}',
                      style: PolieTypography.label(context).copyWith(
                        color: PolieColors.royalAmethyst,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopVocabularyCard extends StatelessWidget {
  final List<MapEntry<String, int>> vocabulary;

  const _TopVocabularyCard({required this.vocabulary});

  @override
  Widget build(BuildContext context) {
    return _PolieGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(PolieSpacing.sm),
                decoration: BoxDecoration(
                  color: PolieColors.electricTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PolieRadius.sm),
                ),
                child: Icon(Icons.book_rounded, color: PolieColors.electricTeal, size: 24.sp),
              ),
              SizedBox(width: PolieSpacing.md),
              Text(
                'Most Used Vocabulary',
                style: PolieTypography.h2(context).copyWith(
                  color: PolieColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          Wrap(
            spacing: PolieSpacing.sm,
            runSpacing: PolieSpacing.sm,
            children: vocabulary.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.md,
                  vertical: PolieSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: PolieColors.electricTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(PolieRadius.pill),
                  border: Border.all(
                    color: PolieColors.electricTeal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: PolieTypography.label(context).copyWith(
                        color: PolieColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: PolieSpacing.xs),
                    Text(
                      '${entry.value}',
                      style: PolieTypography.bodySmall(context).copyWith(
                        color: PolieColors.electricTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Reusable Polie glass card
class _PolieGlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;

  const _PolieGlassCard({
    required this.child,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: glowColor != null
            ? PolieElevation.level2(context, glowColor: glowColor)
            : PolieElevation.level1(context),
      ),
      child: child,
    );
  }
}

/// Glass icon button
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: PolieColors.surfaceContainerLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: PolieColors.textPrimary,
          size: 22.sp,
        ),
      ),
    );
  }
}
