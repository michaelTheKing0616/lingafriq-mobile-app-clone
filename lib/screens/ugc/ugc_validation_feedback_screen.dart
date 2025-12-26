import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UGC Validation Feedback UI
class UGCValidationFeedbackScreen extends HookConsumerWidget {
  final String contentId;
  final String contentType; // 'lesson', 'quiz', 'story'

  const UGCValidationFeedbackScreen({
    Key? key,
    required this.contentId,
    required this.contentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationResult = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> validateContent() async {
      isLoading.value = true;
      try {
        final response = await ApiService.post(
          AppConfig.ugcValidate,
          data: {
            'contentId': contentId,
            'contentType': contentType,
          },
        );

        if (response.statusCode == 200) {
          validationResult.value = response.data['data'];
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation failed: ${e.toString()}')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      validateContent();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Content Validation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: isLoading.value
            ? Center(child: CircularProgressIndicator())
            : validationResult.value == null
                ? Center(
                    child: Text(
                      'No validation results',
                      style: PanAfricanTypography.bodyLarge(context),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overall Score
                        _buildOverallScore(
                          context,
                          validationResult.value!,
                          isDark,
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Grammar Check
                        if (validationResult.value!['grammarCheck'] != null)
                          _buildCheckSection(
                            context,
                            'Grammar Check',
                            validationResult.value!['grammarCheck'],
                            PanAfricanColors.primary,
                            isDark,
                          ),
                        SizedBox(height: PanAfricanSpacing.md),

                        // Cultural Authenticity
                        if (validationResult.value!['culturalCheck'] != null)
                          _buildCheckSection(
                            context,
                            'Cultural Authenticity',
                            validationResult.value!['culturalCheck'],
                            PanAfricanColors.kenteRed,
                            isDark,
                          ),
                        SizedBox(height: PanAfricanSpacing.md),

                        // Canonical Check
                        if (validationResult.value!['canonicalCheck'] != null)
                          _buildCheckSection(
                            context,
                            'Canonical Form',
                            validationResult.value!['canonicalCheck'],
                            PanAfricanColors.kenteBlue,
                            isDark,
                          ),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Recommendations
                        if (validationResult.value!['recommendations'] != null)
                          _buildRecommendations(
                            context,
                            validationResult.value!['recommendations'],
                            isDark,
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildOverallScore(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
  ) {
    final score = (result['overallScore'] ?? 0.0) as double;
    final status = result['status'] ?? 'pending';

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          children: [
            Text(
              'Overall Score',
              style: PanAfricanTypography.titleLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            SizedBox(
              width: 150.w,
              height: 150.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150.w,
                    height: 150.w,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor: PanAfricanColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(score),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: PanAfricanTypography.displayMedium(context)
                            .copyWith(color: _getScoreColor(score)),
                      ),
                      Text(
                        '/ 100',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: _getStatusColor(status).withOpacity(0.2),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9));
  }

  Widget _buildCheckSection(
    BuildContext context,
    String title,
    Map<String, dynamic> check,
    Color color,
    bool isDark,
  ) {
    final passed = check['passed'] ?? false;
    final issues = check['issues'] as List? ?? [];
    final suggestions = check['suggestions'] as List? ?? [];

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: ExpansionTile(
        leading: Icon(
          passed ? Icons.check_circle : Icons.error,
          color: passed ? PanAfricanColors.success : PanAfricanColors.error,
        ),
        title: Text(title),
        subtitle: Text(passed ? 'All checks passed' : '${issues.length} issues found'),
        children: [
          if (issues.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issues',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  ...issues.map((issue) {
                    return Card(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      color: PanAfricanColors.error.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.warning, color: PanAfricanColors.error),
                        title: Text(issue['message'] ?? ''),
                        subtitle: issue['location'] != null
                            ? Text('Location: ${issue['location']}')
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  ...suggestions.map((suggestion) {
                    return Card(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      color: PanAfricanColors.info.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.lightbulb, color: PanAfricanColors.info),
                        title: Text(suggestion),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations(
    BuildContext context,
    List recommendations,
    bool isDark,
  ) {
    return Card(
      color: PanAfricanColors.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: PanAfricanColors.primary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Recommendations',
                  style: PanAfricanTypography.titleLarge(context),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...recommendations.map((rec) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: PanAfricanColors.primary),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        rec,
                        style: PanAfricanTypography.bodyMedium(context),
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

  Color _getScoreColor(double score) {
    if (score >= 80) return PanAfricanColors.success;
    if (score >= 60) return PanAfricanColors.secondary;
    if (score >= 40) return PanAfricanColors.warning;
    return PanAfricanColors.error;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return PanAfricanColors.success;
      case 'needs_revision':
        return PanAfricanColors.warning;
      case 'rejected':
        return PanAfricanColors.error;
      default:
        return PanAfricanColors.neutralMedium;
    }
  }
}

