import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/screens/grammar/grammar_exercise_screen.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'grammar_hub_screen.dart';

class GrammarLessonScreen extends HookConsumerWidget {
  final GrammarTopic topic;

  const GrammarLessonScreen({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(true);
    final grammarData = useState<Map<String, dynamic>?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      _loadGrammarLesson();
      return null;
    }, []);

    Future<void> _loadGrammarLesson() async {
      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.get(
            ApiContract.url('/api/grammar/explanations'),
            queryParameters: {
              'language': topic.language,
              'grammarPoint': topic.id,
            },
          );

          if (response.statusCode == 200 && response.data != null) {
            grammarData.value = response.data as Map<String, dynamic>;
          }
        },
        errorContext: 'loadGrammarLesson',
        showError: true,
      );
      isLoading.value = false;
    }

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
          child: isLoading.value
              ? Center(
                  child: CircularProgressIndicator(color: PolieColors.goldEmber),
                )
              : grammarData.value == null
                  ? Center(
                      child: Text(
                        'Grammar lesson not found',
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
                      ),
                    )
                  : _buildLessonContent(context, grammarData.value!, isDark),
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, Map<String, dynamic> data, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: PolieSpacing.lg),
          _buildExplanationSection(context, data, isDark),
          SizedBox(height: PolieSpacing.lg),
          _buildExamplesSection(context, data, isDark),
          SizedBox(height: PolieSpacing.lg),
          _buildRulesSection(context, data, isDark),
          SizedBox(height: PolieSpacing.lg),
          _buildCommonMistakesSection(context, data, isDark),
          SizedBox(height: PolieSpacing.xl),
          _buildPracticeButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
                topic.name,
                style: PolieTypography.h1(context).copyWith(
                  color: PolieColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: PolieSpacing.xs),
              Text(
                '${topic.difficulty.toUpperCase()} • ${topic.cefrLevel}',
                style: PolieTypography.body(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationSection(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final description = data['description']?.toString() ?? '';
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: PolieColors.goldEmber, size: 24),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Explanation',
                style: PolieTypography.h2(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            description,
            style: PolieTypography.body(context).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final examples = data['examples'] as List? ?? [];
    if (examples.isEmpty) return SizedBox.shrink();

    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: PolieColors.electricTeal, size: 24),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Examples',
                style: PolieTypography.h2(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          ...examples.map((example) {
            final ex = example as Map<String, dynamic>;
            return _buildExampleCard(context, ex, isDark);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExampleCard(BuildContext context, Map<String, dynamic> example, bool isDark) {
    final target = example['target_language']?.toString() ?? example['yoruba']?.toString() ?? '';
    final translation = example['english']?.toString() ?? example['translation']?.toString() ?? '';
    final explanation = example['explanation']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      padding: EdgeInsets.all(PolieSpacing.md),
      decoration: BoxDecoration(
        color: PolieColors.royalAmethyst.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.md),
        border: Border.all(
          color: PolieColors.royalAmethyst.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            target,
            style: PolieTypography.body(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          if (translation.isNotEmpty) ...[
            SizedBox(height: PolieSpacing.xs),
            Text(
              translation,
              style: PolieTypography.body(context).copyWith(
                color: PolieColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            SizedBox(height: PolieSpacing.xs),
            Text(
              explanation,
              style: PolieTypography.bodySmall(context).copyWith(
                color: PolieColors.electricTeal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final rules = data['rules'] as List? ?? [];
    if (rules.isEmpty) return SizedBox.shrink();

    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: PolieColors.royalAmethyst, size: 24),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Rules',
                style: PolieTypography.h2(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value.toString();
            return _buildRuleCard(context, index + 1, rule, isDark);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, int number, String rule, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.sm),
      padding: EdgeInsets.all(PolieSpacing.md),
      decoration: BoxDecoration(
        color: PolieColors.electricTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.md),
        border: Border.all(
          color: PolieColors.electricTeal.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: PolieColors.electricTeal,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Text(
              rule,
              style: PolieTypography.body(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonMistakesSection(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final mistakes = data['commonMistakes'] as List? ?? [];
    if (mistakes.isEmpty) return SizedBox.shrink();

    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: PolieColors.error, size: 24),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Common Mistakes',
                style: PolieTypography.h2(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          ...mistakes.map((mistake) {
            return Padding(
              padding: EdgeInsets.only(bottom: PolieSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.close_rounded, color: PolieColors.error, size: 20),
                  SizedBox(width: PolieSpacing.sm),
                  Expanded(
                    child: Text(
                      mistake.toString(),
                      style: PolieTypography.body(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPracticeButton(BuildContext context) {
    return PoliePrimaryButton(
      label: 'Start Practice',
      icon: Icons.fitness_center_rounded,
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => GrammarExerciseScreen(topic: topic),
          ),
        );
      },
    );
  }
}
