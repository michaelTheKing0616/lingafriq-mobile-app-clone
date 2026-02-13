import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen_with_tracking.dart';
import 'package:lingafriq/data/roleplay_dataset.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';

/// Conversation Practice Scenarios Screen
/// Curated real-world conversation scenarios with AI roleplay
class ConversationScenariosScreen extends ConsumerStatefulWidget {
  final String? language;
  final String? languageName;

  const ConversationScenariosScreen({
    Key? key,
    this.language,
    this.languageName,
  }) : super(key: key);

  @override
  ConsumerState<ConversationScenariosScreen> createState() => _ConversationScenariosScreenState();
}

class _ConversationScenariosScreenState extends ConsumerState<ConversationScenariosScreen> {
  List<ConversationScenario> _scenarios = [];
  Map<String, ScenarioProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
    _loadProgress();
  }

  Future<void> _loadScenarios() async {
    setState(() => _isLoading = true);
    
    // Load scenarios from backend or use default curated scenarios
    try {
      // TODO: Replace with actual API call
      // final scenarios = await contentService.getScenarios(widget.language);
      _scenarios = _getDefaultScenarios();
    } catch (e) {
      debugPrint('Error loading scenarios: $e');
      _scenarios = _getDefaultScenarios();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('scenario_progress') ?? '{}';
    // Parse progress JSON and populate _progressMap
    // For now, using empty map
  }

  Future<void> _saveProgress(String scenarioId, ScenarioProgress progress) async {
    _progressMap[scenarioId] = progress;
    final prefs = await SharedPreferences.getInstance();
    // Save progress to SharedPreferences
  }

  List<ConversationScenario> _getDefaultScenarios() {
    return [
      ConversationScenario(
        id: 'market',
        title: 'At the Market',
        description: 'Practice buying fruits, vegetables, and goods at a local market',
        difficulty: 'beginner',
        estimatedTime: 5,
        contextImage: 'assets/images/market.png',
        context: 'You are shopping at a busy African market. Practice negotiating prices and asking about products.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'meeting_people',
        title: 'Meeting New People',
        description: 'Learn how to introduce yourself and make new friends',
        difficulty: 'beginner',
        estimatedTime: 4,
        contextImage: 'assets/images/people.png',
        context: 'You are at a social gathering. Practice introducing yourself and having friendly conversations.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'restaurant',
        title: 'At a Restaurant',
        description: 'Order food, ask about dishes, and interact with waitstaff',
        difficulty: 'intermediate',
        estimatedTime: 6,
        contextImage: 'assets/images/restaurant.png',
        context: 'You are dining at a local restaurant. Practice ordering food and asking about ingredients.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'directions',
        title: 'Asking for Directions',
        description: 'Navigate the city by asking locals for directions',
        difficulty: 'beginner',
        estimatedTime: 4,
        contextImage: 'assets/images/directions.png',
        context: 'You are lost and need to find your way. Practice asking for directions politely.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'airport',
        title: 'At the Airport',
        description: 'Handle check-in, security, and travel conversations',
        difficulty: 'intermediate',
        estimatedTime: 7,
        contextImage: 'assets/images/airport.png',
        context: 'You are traveling and need to navigate the airport. Practice check-in and security conversations.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'job_interview',
        title: 'Job Interview',
        description: 'Practice professional conversations for job interviews',
        difficulty: 'advanced',
        estimatedTime: 10,
        contextImage: 'assets/images/interview.png',
        context: 'You are interviewing for a job. Practice answering questions professionally.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'doctor',
        title: 'Doctor Visit',
        description: 'Describe symptoms and communicate with healthcare providers',
        difficulty: 'intermediate',
        estimatedTime: 8,
        contextImage: 'assets/images/doctor.png',
        context: 'You are visiting a doctor. Practice describing symptoms and understanding medical advice.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'phone_call',
        title: 'Phone Call',
        description: 'Practice making and receiving phone calls',
        difficulty: 'beginner',
        estimatedTime: 5,
        contextImage: 'assets/images/phone.png',
        context: 'You are making a phone call. Practice phone etiquette and clear communication.',
        language: widget.language ?? 'sw',
      ),
      ConversationScenario(
        id: 'making_plans',
        title: 'Making Plans',
        description: 'Plan activities and coordinate with friends',
        difficulty: 'intermediate',
        estimatedTime: 6,
        contextImage: 'assets/images/plans.png',
        context: 'You are planning an activity with friends. Practice suggesting ideas and coordinating schedules.',
        language: widget.language ?? 'sw',
      ),
    ];
  }

  Future<void> _startScenario(ConversationScenario scenario) async {
    HapticFeedback.mediumImpact();
    
    final chat = ref.read(groqChatProvider.notifier);
    await chat.setModeAndLanguage(
      mode: PolieMode.roleplay,
      targetLanguage: widget.languageName ?? scenario.language,
    );
    
    // Set scenario context
    await chat.setRoleplayScenario(
      RoleplayEntry(
        id: DateTime.now().millisecondsSinceEpoch,
        language: widget.language ?? 'sw',
        mode: 'roleplay',
        scenario: scenario.title,
        userUtterance: scenario.context,
        assistantResponse: '',
        notes: scenario.description,
      ),
    );
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreenWithTracking(
            language: widget.language ?? 'sw',
            languageName: widget.languageName ?? 'Swahili',
            mode: 'roleplay',
            modeName: 'Roleplay',
            initialScenario: RoleplayEntry(
              id: DateTime.now().millisecondsSinceEpoch,
              language: widget.language ?? 'sw',
              mode: 'roleplay',
              scenario: scenario.title,
              userUtterance: scenario.context,
              assistantResponse: '',
              notes: scenario.description,
            ),
          ),
        ),
      ).then((_) {
        // Update progress after completion
        _updateScenarioProgress(scenario.id, completed: true);
      });
    }
  }

  void _updateScenarioProgress(String scenarioId, {required bool completed}) {
    final progress = _progressMap[scenarioId] ?? ScenarioProgress(
      scenarioId: scenarioId,
      completed: false,
      attempts: 0,
      lastAttempt: null,
    );
    
    _progressMap[scenarioId] = ScenarioProgress(
      scenarioId: scenarioId,
      completed: completed || progress.completed,
      attempts: progress.attempts + 1,
      lastAttempt: DateTime.now(),
    );
    
    _saveProgress(scenarioId, _progressMap[scenarioId]!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PolieColors.obsidian : PolieColors.surfaceLight,
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
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: PolieColors.electricTeal))
                    : _buildScenariosList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation Practice',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  'Real-world scenarios',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildScenariosList(BuildContext context) {
    if (_scenarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64.sp, color: PolieColors.textSecondary),
            SizedBox(height: PolieSpacing.md),
            Text(
              'No scenarios available',
              style: PolieTypography.h3(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: _scenarios.length,
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        final progress = _progressMap[scenario.id];
        return _ScenarioCard(
          scenario: scenario,
          progress: progress,
          onTap: () => _startScenario(scenario),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
    );
  }
}

class ConversationScenario {
  final String id;
  final String title;
  final String description;
  final String difficulty; // beginner, intermediate, advanced
  final int estimatedTime; // minutes
  final String? contextImage;
  final String context;
  final String language;

  ConversationScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    this.contextImage,
    required this.context,
    required this.language,
  });
}

class ScenarioProgress {
  final String scenarioId;
  final bool completed;
  final int attempts;
  final DateTime? lastAttempt;

  ScenarioProgress({
    required this.scenarioId,
    required this.completed,
    required this.attempts,
    this.lastAttempt,
  });
}

class _ScenarioCard extends StatelessWidget {
  final ConversationScenario scenario;
  final ScenarioProgress? progress;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    this.progress,
    required this.onTap,
  });

  Color _getDifficultyColor() {
    switch (scenario.difficulty) {
      case 'beginner':
        return PolieColors.success;
      case 'intermediate':
        return PolieColors.goldEmber;
      case 'advanced':
        return PolieColors.error;
      default:
        return PolieColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final difficultyColor = _getDifficultyColor();

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(
          color: difficultyColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: difficultyColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: 'Conversation scenario: ${scenario.title}. ${scenario.difficulty}. Tap to start.',
          button: true,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(PolieRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: scenario.contextImage != null
                      ? CachedNetworkImage(
                          imageUrl: scenario.contextImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: difficultyColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image_outlined,
                            color: difficultyColor,
                            size: 32.sp,
                          ),
                        )
                      : Icon(
                          Icons.chat_bubble_outline,
                          color: difficultyColor,
                          size: 32.sp,
                        ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scenario.title,
                              style: PolieTypography.h3(context).copyWith(
                                color: PolieColors.textPrimary,
                              ),
                            ),
                          ),
                          if (progress?.completed == true)
                            Icon(
                              Icons.check_circle,
                              color: PolieColors.success,
                              size: 20.sp,
                            ),
                        ],
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        scenario.description,
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: PolieSpacing.sm),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PolieSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(PolieRadius.sm),
                            ),
                            child: Text(
                              scenario.difficulty.toUpperCase(),
                              style: PolieTypography.label(context).copyWith(
                                color: difficultyColor,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: PolieSpacing.sm),
                          Icon(
                            Icons.access_time,
                            size: 14.sp,
                            color: PolieColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${scenario.estimatedTime} min',
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
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: PolieColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
