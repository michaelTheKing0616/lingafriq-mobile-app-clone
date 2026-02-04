import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/services/env_config.dart';

/// Assessment type options — Placement, Progress, Comprehensive.
const List<Map<String, dynamic>> kAssessmentTypes = [
  {'id': 'placement', 'label': 'Placement Test', 'icon': Icons.flag_rounded, 'desc': 'Discover your starting level'},
  {'id': 'progress', 'label': 'Progress Check', 'icon': Icons.trending_up_rounded, 'desc': 'See how far you\'ve come'},
  {'id': 'comprehensive', 'label': 'Comprehensive', 'icon': Icons.assessment_rounded, 'desc': 'Full skills overview'},
];

/// Proficiency Assessment — calm ceremonial layout, CEFR reveal animation, radar chart, learning path CTA.
class TutorAssessModeScreen extends HookConsumerWidget {
  const TutorAssessModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final assessmentType = useState<String>('placement');
    final isLoading = useState(false);
    final assessmentResult = useState<Map<String, dynamic>?>(null);
    final cefrRevealed = useState(false);
    final availableLanguages = AppLanguage.values;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<Map<String, dynamic>> _generateAssessmentWithGroq({
      required String language,
      required String type,
      String? knownCefrLevel,
    }) async {
      final groqKey = EnvConfig.groqApiKey;
      final useBackend = groqKey.isEmpty ||
          groqKey.trim().isEmpty ||
          groqKey == 'YOUR_GROQ_API_KEY' ||
          groqKey.startsWith('YOUR_');
      final prompt = '''
You are Polie, an elite African language tutor. Generate a proficiency assessment summary.
TARGET_LANGUAGE: $language
ASSESSMENT_TYPE: $type
${knownCefrLevel != null ? 'KNOWN_CEFR_LEVEL: $knownCefrLevel' : ''}

Return STRICT JSON ONLY (no markdown):
{
  "proficiencyLevel": "A1|A2|B1|B2|C1|C2",
  "strengths": ["..."],
  "weaknesses": ["..."],
  "recommendations": ["..."],
  "dimensions": {"listening": 0.0-1.0, "speaking": 0.0-1.0, "reading": 0.0-1.0, "writing": 0.0-1.0, "grammar": 0.0-1.0},
  "nextSteps": [{"title": "Actionable step", "detail": "How to do it"}, ...]
}
Keep lists practical. Use culturally appropriate examples.
''';

      if (useBackend) {
        final resp = await ApiService.post(
          '/api/ai/chat/completion',
          data: {
            'messages': [{'role': 'user', 'content': prompt}],
            'systemPrompt': 'You output only valid JSON. Never include markdown or commentary.',
            'temperature': 0.2,
            'max_tokens': 800,
          },
        );
        if (resp.statusCode != 200 || resp.data == null) {
          throw Exception('AI request failed. Please try again.');
        }
        final content = (resp.data is Map) ? (resp.data['content']?.toString() ?? '') : '';
        if (content.trim().isEmpty) throw Exception('AI returned an empty response.');
        try {
          return jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}');
          if (start >= 0 && end > start) {
            return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
          }
          rethrow;
        }
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 20),
      ));
      final resp = await dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.1-70b-versatile',
          'temperature': 0.2,
          'max_tokens': 800,
          'messages': [
            {'role': 'system', 'content': 'You output only valid JSON. Never include markdown or commentary.'},
            {'role': 'user', 'content': prompt},
          ],
        },
        options: Options(
          headers: {'Authorization': 'Bearer $groqKey', 'Content-Type': 'application/json'},
        ),
      );
      if (resp.statusCode != 200) throw Exception('AI request failed (${resp.statusCode}).');
      final content = (resp.data is Map) ? (resp.data['choices']?[0]?['message']?['content']?.toString() ?? '') : '';
      if (content.trim().isEmpty) throw Exception('AI returned an empty response.');
      try {
        return jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
        rethrow;
      }
    }

    Future<void> assessProficiency() async {
      isLoading.value = true;
      cefrRevealed.value = false;
      await safeAsync(
        context: context,
        operation: () async {
          String? knownCefr;
          try {
            final resp = await ApiService.get(
              '/api/cefr-assessment',
              queryParameters: {'language': selectedLanguage.value.name},
            );
            if (resp.statusCode == 200 && resp.data is Map) {
              final data = (resp.data as Map)['data'];
              if (data is Map && data['cefr_level'] != null) knownCefr = data['cefr_level']?.toString();
            }
          } catch (_) {}
          final result = await _generateAssessmentWithGroq(
            language: selectedLanguage.value.name,
            type: assessmentType.value,
            knownCefrLevel: knownCefr,
          );
          assessmentResult.value = result;
          // Trigger CEFR reveal after a short delay
          Future.delayed(const Duration(milliseconds: 400), () {
            cefrRevealed.value = true;
          });
        },
        errorContext: 'assessProficiency',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Preparing your assessment...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [PolieColors.primary, PolieColors.primaryDark, PolieColors.obsidian]
                  : [
                      PolieColors.primary.withOpacity(0.92),
                      PolieColors.primaryDark.withOpacity(0.88),
                      PolieColors.surfaceContainerLight,
                    ],
            ),
          ),
          child: SafeArea(
            child: assessmentResult.value == null
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(PolieSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Proficiency Assessment',
                          style: PolieTypography.h1(context).copyWith(color: PolieColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Text(
                          'Discover your level with calm, clear feedback. Choose your assessment type below.',
                          style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: PolieSpacing.xl),
                        PolieGlassCard(
                          padding: EdgeInsets.all(PolieSpacing.md),
                          child: DropdownButtonFormField<AppLanguage>(
                            value: selectedLanguage.value,
                            dropdownColor: PolieColors.surfaceContainer,
                            decoration: InputDecoration(
                              labelText: 'Language',
                              border: InputBorder.none,
                              labelStyle: PolieTypography.label(context),
                            ),
                            style: PolieTypography.body(context),
                            items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                              value: lang,
                              child: Text(lang.displayName),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                HapticFeedback.selectionClick();
                                selectedLanguage.value = value;
                              }
                            },
                          ),
                        ),
                        SizedBox(height: PolieSpacing.lg),
                        Text(
                          'Assessment Type',
                          style: PolieTypography.label(context),
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        ...kAssessmentTypes.map((t) {
                          final id = t['id'] as String;
                          final selected = assessmentType.value == id;
                          return Padding(
                            padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                            child: PolieGlassCard(
                              hasGlow: selected,
                              glowColor: PolieColors.royalAmethyst,
                              padding: EdgeInsets.all(PolieSpacing.md),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  assessmentType.value = id;
                                },
                                borderRadius: BorderRadius.circular(PolieRadius.lg),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(PolieSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: (t['icon'] != null) ? PolieColors.royalAmethyst.withOpacity(0.25) : null,
                                        borderRadius: BorderRadius.circular(PolieRadius.md),
                                      ),
                                      child: Icon(t['icon'] as IconData, color: PolieColors.royalAmethyst, size: 24.sp),
                                    ),
                                    SizedBox(width: PolieSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t['label'] as String, style: PolieTypography.label(context)),
                                          if (t['desc'] != null)
                                            Text(t['desc'] as String, style: PolieTypography.bodySmall(context)),
                                        ],
                                      ),
                                    ),
                                    if (selected) Icon(Icons.check_circle_rounded, color: PolieColors.electricTeal),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: PolieSpacing.xl),
                        PoliePrimaryButton(
                          label: 'Start Assessment',
                          icon: Icons.assessment_rounded,
                          loading: isLoading.value,
                          onPressed: isLoading.value ? null : assessProficiency,
                        ),
                      ],
                    ),
                  )
                : _AssessmentResultsView(
                    result: assessmentResult.value!,
                    isDark: isDark,
                    cefrRevealed: cefrRevealed.value,
                    onLearningPathTap: () {
                      HapticFeedback.mediumImpact();
                      // Navigate to Polie mode carousel or dashboard
                      Navigator.of(context).pop();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentResultsView extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isDark;
  final bool cefrRevealed;
  final VoidCallback onLearningPathTap;

  const _AssessmentResultsView({
    required this.result,
    required this.isDark,
    required this.cefrRevealed,
    required this.onLearningPathTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = result['proficiencyLevel']?.toString() ?? 'A1';
    final dimensions = result['dimensions'] is Map ? result['dimensions'] as Map<String, dynamic> : null;
    final nextSteps = result['nextSteps'] is List ? result['nextSteps'] as List : <dynamic>[];

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Results',
            style: PolieTypography.h2(context).copyWith(color: PolieColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.lg),
          // CEFR reveal (animated)
          AnimatedOpacity(
            opacity: cefrRevealed ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: AnimatedScale(
              scale: cefrRevealed ? 1 : 0.5,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: PolieGlassCard(
                hasGlow: true,
                glowColor: PolieColors.goldEmber,
                padding: EdgeInsets.symmetric(vertical: PolieSpacing.xl, horizontal: PolieSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Your level',
                      style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                    ),
                    SizedBox(height: PolieSpacing.sm),
                    Text(
                      level,
                      style: PolieTypography.h1(context).copyWith(
                        color: PolieColors.goldEmber,
                        fontSize: 48.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          // Radar chart (strengths & gaps)
          if (dimensions != null && dimensions.isNotEmpty) ...[
            Text('Strengths & gaps', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: SizedBox(
                height: 200.h,
                child: _RadarChart(dimensions: dimensions, isDark: isDark),
              ),
            ),
            SizedBox(height: PolieSpacing.lg),
          ],
          if (result['strengths'] != null && (result['strengths'] as List).isNotEmpty) ...[
            Text('Strengths', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            ...(result['strengths'] as List).map((s) => Padding(
                  padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18.sp, color: PolieColors.success),
                      SizedBox(width: PolieSpacing.sm),
                      Expanded(child: Text(s.toString(), style: PolieTypography.body(context))),
                    ],
                  ),
                )),
            SizedBox(height: PolieSpacing.md),
          ],
          if (result['weaknesses'] != null && (result['weaknesses'] as List).isNotEmpty) ...[
            Text('Areas to improve', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            ...(result['weaknesses'] as List).map((w) => Padding(
                  padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 18.sp, color: PolieColors.goldEmber),
                      SizedBox(width: PolieSpacing.sm),
                      Expanded(child: Text(w.toString(), style: PolieTypography.body(context))),
                    ],
                  ),
                )),
            SizedBox(height: PolieSpacing.md),
          ],
          if (nextSteps.isNotEmpty) ...[
            Text('Your learning path', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            ...nextSteps.take(3).map((step) {
              final m = step is Map ? step as Map<String, dynamic> : <String, dynamic>{};
              return Padding(
                padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                child: PolieGlassCard(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['title']?.toString() ?? 'Next step', style: PolieTypography.label(context)),
                      if (m['detail'] != null) ...[
                        SizedBox(height: PolieSpacing.xs),
                        Text(m['detail'].toString(), style: PolieTypography.bodySmall(context)),
                      ],
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: PolieSpacing.lg),
            PoliePrimaryButton(
              label: 'View learning path',
              icon: Icons.school_rounded,
              onPressed: onLearningPathTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple radar chart from dimensions map (e.g. listening, speaking, reading, writing, grammar).
class _RadarChart extends StatelessWidget {
  final Map<String, dynamic> dimensions;
  final bool isDark;

  const _RadarChart({required this.dimensions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final keys = dimensions.keys.toList();
    if (keys.isEmpty) return const SizedBox.shrink();
    final n = keys.length;
    final values = keys.map((k) {
      final v = dimensions[k];
      if (v is num) return v.toDouble().clamp(0.0, 1.0);
      return 0.5;
    }).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.w;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 200.h;
        return CustomPaint(
          size: Size(w, h),
          painter: _RadarChartPainter(
        labels: keys.map((k) => k.substring(0, 1).toUpperCase() + k.substring(1).toLowerCase()).toList(),
        values: values,
        isDark: isDark,
      ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final bool isDark;

  _RadarChartPainter({required this.labels, required this.values, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 * 0.75;
    final angleStep = (2 * math.pi) / n;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid and axes
    final gridPaint = Paint()
      ..color = (isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0.25; r <= 1.0; r += 0.25) {
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final a = -math.pi / 2 + i * angleStep;
        final x = center.dx + radius * r * math.cos(a);
        final y = center.dy + radius * r * math.sin(a);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angleStep;
      canvas.drawLine(center, Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a)), gridPaint);
    }

    // Data polygon
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angleStep;
      final r = radius * values[i];
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      if (i == 0) dataPath.moveTo(x, y);
      else dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = PolieColors.royalAmethyst.withOpacity(0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = PolieColors.royalAmethyst
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angleStep;
      final labelRadius = radius * 1.08;
      final x = center.dx + labelRadius * math.cos(a);
      final y = center.dy + labelRadius * math.sin(a);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10.sp,
          color: isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
