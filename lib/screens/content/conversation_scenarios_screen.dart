import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen_with_tracking.dart';
import 'package:lingafriq/data/roleplay_dataset.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Conversation Practice Scenarios Screen
/// Curated real-world conversation scenarios with AI roleplay
class ConversationScenariosScreen extends ConsumerStatefulWidget {
  final String? language;
  final String? languageName;

  const ConversationScenariosScreen({
    super.key,
    this.language,
    this.languageName,
  });

  @override
  ConsumerState<ConversationScenariosScreen> createState() => _ConversationScenariosScreenState();
}

class _ConversationScenariosScreenState extends ConsumerState<ConversationScenariosScreen> {
  List<ConversationScenario> _scenarios = [];
  final Map<String, ScenarioProgress> _progressMap = {};
  bool _isLoading = true;
  String _selectedPracticeType = 'all';

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
      final fromApi = await _fetchScenariosFromApi();
      _scenarios = fromApi.isNotEmpty ? fromApi : _getDefaultScenarios();
    } catch (e) {
      debugPrint('Error loading scenarios: $e');
      _scenarios = _getDefaultScenarios();
    }
    
    setState(() => _isLoading = false);
  }

  Future<List<ConversationScenario>> _fetchScenariosFromApi() async {
    final language = widget.language ?? 'sw';
    final response = await Dio().get(
      '${ApiContract.baseUrl}/api/content/scenarios',
      queryParameters: {
        'language': language,
        'limit': 50,
      },
      options: Options(receiveTimeout: const Duration(seconds: 20)),
    );

    final payload = response.data;
    if (payload is! Map || payload['scenarios'] is! List) return const [];
    final list = (payload['scenarios'] as List)
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList();

    return list
        .map((item) {
          final id = (item['id'] ?? item['_id'])?.toString();
          final title = item['title']?.toString();
          final description = item['description']?.toString();
          if (id == null || title == null || description == null) return null;
          final difficulty = (item['difficulty']?.toString() ?? 'beginner').toLowerCase();
          final normalizedDifficulty = switch (difficulty) {
            'easy' => 'beginner',
            'medium' => 'intermediate',
            'hard' => 'advanced',
            _ => difficulty,
          };
          return ConversationScenario(
            id: id,
            title: title,
            description: description,
            difficulty: normalizedDifficulty,
            estimatedTime: (item['estimatedTime'] as num?)?.toInt() ?? 6,
            contextImage: item['contextImage']?.toString(),
            context: item['context']?.toString() ?? description,
            language: item['language']?.toString() ?? language,
            practiceType: _normalizePracticeType(item['practiceType']?.toString()),
          );
        })
        .whereType<ConversationScenario>()
        .toList();
  }

  String _normalizePracticeType(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'conversation' || normalized == 'chat') return 'conversation';
    if (normalized == 'debate') return 'debate';
    if (normalized == 'photo' || normalized == 'photo_context' || normalized == 'photo-context') {
      return 'photo';
    }
    return 'roleplay';
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('conversation_scenario_progress');
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final next = <String, ScenarioProgress>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final attempts = (value['attempts'] as num?)?.toInt() ?? 0;
        final completed = value['completed'] == true;
        final lastAttemptRaw = value['lastAttempt']?.toString();
        next[entry.key] = ScenarioProgress(
          scenarioId: entry.key,
          completed: completed,
          attempts: attempts,
          lastAttempt: lastAttemptRaw == null || lastAttemptRaw.isEmpty
              ? null
              : DateTime.tryParse(lastAttemptRaw),
        );
      }
      if (!mounted) return;
      setState(() {
        _progressMap
          ..clear()
          ..addAll(next);
      });
    } catch (e) {
      debugPrint('Error loading scenario progress: $e');
    }
  }

  Future<void> _saveProgress(String scenarioId, ScenarioProgress progress) async {
    _progressMap[scenarioId] = progress;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, Map<String, dynamic>>{};
      for (final entry in _progressMap.entries) {
        payload[entry.key] = {
          'completed': entry.value.completed,
          'attempts': entry.value.attempts,
          'lastAttempt': entry.value.lastAttempt?.toIso8601String(),
        };
      }
      await prefs.setString('conversation_scenario_progress', jsonEncode(payload));
    } catch (e) {
      debugPrint('Error saving scenario progress: $e');
    }
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
        practiceType: 'roleplay',
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
        practiceType: 'roleplay',
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
        practiceType: 'roleplay',
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
        practiceType: 'roleplay',
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
        practiceType: 'roleplay',
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
        practiceType: 'debate',
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
        practiceType: 'roleplay',
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
        practiceType: 'roleplay',
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
        practiceType: 'debate',
      ),
      ConversationScenario(
        id: 'photo_market_stall',
        title: 'Photo Context: Market Stall',
        description: 'Use visual clues from a market photo to drive the conversation',
        difficulty: 'intermediate',
        estimatedTime: 7,
        contextImage: 'assets/images/market.png',
        context: 'Describe what you see in the image, ask follow-up questions, and negotiate naturally using local expressions.',
        language: widget.language ?? 'sw',
        practiceType: 'photo',
      ),
    ];
  }

  Future<void> _startScenario(ConversationScenario scenario) async {
    HapticFeedback.mediumImpact();

    final practiceType = _normalizePracticeType(scenario.practiceType);
    final isRoleplay = practiceType == 'roleplay';
    final runtimeMode = isRoleplay ? PolieMode.roleplay : PolieMode.conversation;
    final runtimeModeName = isRoleplay ? 'Roleplay' : 'Conversation';
    final scenarioContext = <String, dynamic>{
      'isDebateContext': practiceType == 'debate',
      'isPhotoContext': practiceType == 'photo',
      'scenarioId': scenario.id,
      'scenarioTitle': scenario.title,
      'scenarioDescription': scenario.description,
      'scenarioImage': scenario.contextImage,
      'scenarioText': scenario.context,
    };

    final chat = ref.read(groqChatProvider.notifier);
    await chat.setModeAndLanguage(
      mode: runtimeMode,
      targetLanguage: widget.languageName ?? scenario.language,
    );

    final roleplayEntry = RoleplayEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      language: widget.language ?? 'sw',
      mode: 'roleplay',
      scenario: scenario.title,
      userUtterance: scenario.context,
      assistantResponse: '',
      notes: scenario.description,
    );

    if (isRoleplay) {
      await chat.setRoleplayScenario(roleplayEntry);
    } else {
      await chat.setScenarioContextHints(
        practiceType: practiceType,
        scenarioType: 'conversation_scenario',
        scenarioContext: scenarioContext,
      );
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(
            arguments: <String, dynamic>{
              'mode': runtimeMode.name,
              'scenarioType': 'conversation_scenario',
              'practiceType': practiceType,
              'scenarioContext': scenarioContext,
            },
          ),
          builder: (context) => AIChatScreenWithTracking(
            language: widget.language ?? 'sw',
            languageName: widget.languageName ?? 'Swahili',
            mode: runtimeMode.name,
            modeName: runtimeModeName,
            initialScenario: isRoleplay ? roleplayEntry : null,
            scenarioType: 'conversation_scenario',
            practiceType: practiceType,
            scenarioContext: scenarioContext,
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
                    : Column(
                        children: [
                          _buildPracticeTypeFilter(context),
                          Expanded(child: _buildScenariosList(context)),
                        ],
                      ),
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

  Widget _buildPracticeTypeFilter(BuildContext context) {
    final filters = const <Map<String, String>>[
      {'id': 'all', 'label': 'All'},
      {'id': 'roleplay', 'label': 'Roleplay'},
      {'id': 'debate', 'label': 'Debate'},
      {'id': 'photo', 'label': 'Photo'},
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final filter = filters[index];
          final isSelected = _selectedPracticeType == filter['id'];
          return ChoiceChip(
            selected: isSelected,
            label: Text(filter['label']!),
            selectedColor: PolieColors.electricTeal.withOpacity(0.25),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPracticeType = filter['id']!;
              });
            },
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: PolieSpacing.sm),
        itemCount: filters.length,
      ),
    );
  }

  Widget _buildScenariosList(BuildContext context) {
    final scenarios = _selectedPracticeType == 'all'
        ? _scenarios
        : _scenarios.where((s) => s.practiceType == _selectedPracticeType).toList();
    if (scenarios.isEmpty) {
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
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
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
  final String practiceType; // roleplay | debate | photo

  ConversationScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    this.contextImage,
    required this.context,
    required this.language,
    this.practiceType = 'roleplay',
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
                // Scenario illustration / loading state
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PolieSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PolieColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(PolieRadius.sm),
                            ),
                            child: Text(
                              scenario.practiceType.toUpperCase(),
                              style: PolieTypography.label(context).copyWith(
                                color: PolieColors.primary,
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
