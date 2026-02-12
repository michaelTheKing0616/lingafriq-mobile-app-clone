import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/providers/grammar_progress_provider.dart';
import 'package:lingafriq/screens/grammar/grammar_lesson_screen.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

class GrammarHubScreen extends HookConsumerWidget {
  const GrammarHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLevel = useState<String?>('A1');
    final isLoading = useState(false);
    final grammarTopics = useState<List<GrammarTopic>>([]);
    final progressMap = ref.watch(grammarProgressProvider);

    useEffect(() {
      _loadGrammarTopics(ref, selectedLevel.value ?? 'A1', grammarTopics, isLoading);
      return null;
    }, [selectedLevel.value]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildLevelFilter(context, selectedLevel, isDark),
              Expanded(
                child: isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: PolieColors.goldEmber,
                        ),
                      )
                    : _buildTopicsList(context, grammarTopics.value, progressMap, isDark),
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
          Semantics(
            label: 'Back to previous screen',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(width: PolieSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grammar Hub',
                  style: PolieTypography.h1(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.xs),
                Text(
                  'Master grammar step by step',
                  style: PolieTypography.body(context).copyWith(
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

  Widget _buildLevelFilter(BuildContext context, ValueNotifier<String?> selectedLevel, bool isDark) {
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = selectedLevel.value == level;
          return Semantics(
            label: 'Filter by level $level. ${isSelected ? 'Selected' : ''}',
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                selectedLevel.value = level;
              },
              child: Container(
                margin: EdgeInsets.only(right: PolieSpacing.sm),
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PolieColors.goldEmber.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(PolieRadius.pill),
                  border: Border.all(
                    color: isSelected ? PolieColors.goldEmber : PolieColors.textSecondary.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    level,
                    style: PolieTypography.label(context).copyWith(
                      color: isSelected ? PolieColors.goldEmber : PolieColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicsList(
    BuildContext context,
    List<GrammarTopic> topics,
    Map<String, GrammarMastery> progressMap,
    bool isDark,
  ) {
    if (topics.isEmpty) {
      return Center(
        child: Text(
          'No grammar topics available',
          style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.lg),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final mastery = progressMap[topic.id] ?? GrammarMastery(topicId: topic.id, masteryPercentage: 0);
        return _buildTopicCard(context, topic, mastery, isDark)
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    GrammarTopic topic,
    GrammarMastery mastery,
    bool isDark,
  ) {
    return Semantics(
      label: 'Grammar topic: ${topic.title}. ${mastery.masteryPercentage.toInt()} percent mastered. Tap to open.',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => GrammarLessonScreen(topic: topic),
            ),
          );
        },
        child: Container(
        margin: EdgeInsets.only(bottom: PolieSpacing.md),
        child: PolieGlassCard(
          padding: EdgeInsets.all(PolieSpacing.lg),
          child: Row(
            children: [
              _buildProgressRing(mastery.masteryPercentage),
              SizedBox(width: PolieSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: PolieTypography.h3(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Row(
                      children: [
                        _buildDifficultyBadge(topic.difficulty),
                        SizedBox(width: PolieSpacing.sm),
                        Text(
                          '${mastery.masteryPercentage.toInt()}% mastered',
                          style: PolieTypography.bodySmall(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: PolieColors.royalAmethyst,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildProgressRing(double percentage) {
    return SizedBox(
      width: 60.w,
      height: 60.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.w,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 6,
              backgroundColor: PolieColors.textSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(PolieColors.goldEmber),
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: PolieColors.goldEmber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = PolieColors.success;
        break;
      case 'intermediate':
        color = PolieColors.goldEmber;
        break;
      case 'advanced':
        color = PolieColors.error;
        break;
      default:
        color = PolieColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(PolieRadius.pill),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _loadGrammarTopics(WidgetRef ref, String level, ValueNotifier<List<GrammarTopic>> topicsNotifier, ValueNotifier<bool> isLoadingNotifier) async {
    isLoadingNotifier.value = true;
    try {
      final response = await ApiService.get(
        ApiContract.url('/api/grammar/topics'),
        queryParameters: {'level': level},
      );

      if (response.statusCode == 200 && response.data is List) {
        final topics = (response.data as List)
            .map((t) => GrammarTopic.fromJson(t as Map<String, dynamic>))
            .toList();
        topicsNotifier.value = topics;
      }
    } catch (e) {
      // Handle error - in production, show error message
      topicsNotifier.value = [];
    } finally {
      isLoadingNotifier.value = false;
    }
  }
}

class GrammarTopic {
  final String id;
  final String name;
  final String difficulty;
  final String cefrLevel;
  final String language;

  GrammarTopic({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.cefrLevel,
    required this.language,
  });

  factory GrammarTopic.fromJson(Map<String, dynamic> json) {
    return GrammarTopic(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['title']?.toString() ?? json['name']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'beginner',
      cefrLevel: json['cefrLevel']?.toString() ?? json['level']?.toString() ?? 'A1',
      language: json['language']?.toString() ?? 'yoruba',
    );
  }
}
