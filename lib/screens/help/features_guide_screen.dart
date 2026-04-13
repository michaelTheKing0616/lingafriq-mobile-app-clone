import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Comprehensive Features Guide Screen
/// Explains all modules, features, and how to use them
class FeaturesGuideScreen extends StatefulWidget {
  const FeaturesGuideScreen({super.key, this.initialTab = 0});

  /// Tab index 0–5: AI Chat, Games, Gamification, Progress, Social, Basics.
  final int initialTab;

  @override
  State<FeaturesGuideScreen> createState() => _FeaturesGuideScreenState();
}

class _FeaturesGuideScreenState extends State<FeaturesGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final idx = widget.initialTab.clamp(0, 5);
    _tabController = TabController(length: 6, vsync: this, initialIndex: idx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features Guide'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'AI Chat'),
            Tab(text: 'Games'),
            Tab(text: 'Gamification'),
            Tab(text: 'Progress'),
            Tab(text: 'Social'),
            Tab(text: 'Basics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIChatGuide(),
          _buildGamesGuide(),
          _buildGamificationGuide(),
          _buildProgressGuide(),
          _buildSocialGuide(),
          _buildBasicsGuide(),
        ],
      ),
    );
  }

  Widget _buildAIChatGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Meet Polie - Your AI Language Assistant', Icons.smart_toy_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'Translation Mode',
            icon: Icons.translate_rounded,
            description: 'Get instant, accurate translations with cultural context. Polie automatically corrects diacritics for tonal languages.',
            tips: [
              'Type "How do you say X" for translations',
              'Polie respects formal/informal registers',
              'Translations include cultural context',
            ],
          ),
          _buildFeatureCard(
            title: 'Tutor Mode',
            icon: Icons.school_rounded,
            description: 'Adaptive teaching that adjusts difficulty based on your performance. Get detailed explanations and cultural context.',
            tips: [
              'Difficulty adjusts automatically',
              'Get explanations for mistakes',
              'Learn cultural etiquette',
            ],
          ),
          _buildFeatureCard(
            title: 'Roleplay Mode',
            icon: Icons.theater_comedy_rounded,
            description: 'Practice real-world scenarios like market bargaining, doctor visits, and greetings. Native-reviewed scenarios.',
            tips: [
              'Choose scenarios from the menu',
              'Practice cultural interactions',
              'Get feedback on appropriateness',
            ],
          ),
          _buildFeatureCard(
            title: 'Conversation Mode',
            icon: Icons.chat_bubble_outline_rounded,
            description: 'Natural dialogue practice. Polie adapts to your level and keeps conversations engaging.',
            tips: [
              'Polie remembers context',
              'Conversations adapt to your level',
              'Practice everyday situations',
            ],
          ),
          _buildFeatureCard(
            title: '@Polie in social chats',
            icon: Icons.alternate_email_rounded,
            description:
                'In Global Chat, village chat, tribe chat, and private messages, type @Polie (case-insensitive) plus your question. Polie replies inline so the group or your contact sees the help too.',
            tips: [
              'Example: @Polie how do you say hello in Yoruba?',
              'Works in DMs after your message is sent; Polie replies are saved on this device for that chat',
              'About 10 @Polie calls per minute per chat are allowed to protect quality and cost',
              'Tribe chat uses the live socket when connected so others can see Polie; offline users still see Polie on their own screen',
            ],
          ),
          _buildFeatureCard(
            title: 'Vocab Mode',
            icon: Icons.book_rounded,
            description: 'Build vocabulary with spaced repetition. Words are reviewed at optimal intervals for retention.',
            tips: [
              'Uses SM-2 algorithm for optimal timing',
              'Words reviewed based on difficulty',
              'Track your vocabulary growth',
            ],
          ),
          _buildFeatureCard(
            title: 'Review Mode',
            icon: Icons.refresh_rounded,
            description: 'Review words and phrases you\'ve learned. SRS system ensures you don\'t forget.',
            tips: [
              'Review based on SRS schedule',
              'Focus on difficult words',
              'Track your retention rate',
            ],
          ),
          SizedBox(height: 24.h),
          _buildTerminologySection([
            {'term': 'CEFR', 'definition': 'Common European Framework of Reference - Language proficiency levels from A1 (beginner) to C2 (master)'},
            {'term': 'SRS', 'definition': 'Spaced Repetition System - Algorithm that schedules reviews at optimal intervals for memory retention'},
            {'term': 'Diacritics', 'definition': 'Accent marks and tone indicators in African languages (e.g., à, é, ọ, ẹ)'},
          ]),
        ],
      ),
    );
  }

  Widget _buildGamesGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('35 Language Games', Icons.games_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'Core Games (14)',
            icon: Icons.star_rounded,
            description: 'Essential games for language learning: WordMatch+Audio, Pronunciation Duel, Speed Round, Tone Trainer, Story Builder, and more.',
            tips: [
              'Each game integrates with SRS',
              'Earn XP and currencies',
              'Track your progress',
            ],
          ),
          _buildFeatureCard(
            title: 'Cultural Games (21)',
            icon: Icons.celebration_rounded,
            description: 'Unique African-themed games: Proverb Unlocker, Drum Rhythm, Market Bargaining, Taxi Survival, Food Quest, and more.',
            tips: [
              'Learn cultural context',
              'Practice real-world scenarios',
              'Earn special badges',
            ],
          ),
          _buildFeatureCard(
            title: 'Game Features',
            icon: Icons.settings_rounded,
            description: 'All games include pronunciation scoring, SRS integration, telemetry, and adaptive difficulty.',
            tips: [
              'Games adapt to your level',
              'Get pronunciation feedback',
              'Track accuracy and speed',
            ],
          ),
          SizedBox(height: 24.h),
          _buildTerminologySection([
            {'term': 'SRS Integration', 'definition': 'Games automatically update your spaced repetition schedule based on performance'},
            {'term': 'Telemetry', 'definition': 'Analytics that track your progress, accuracy, and learning patterns'},
            {'term': 'Pronunciation Scoring', 'definition': 'AI-powered feedback on your pronunciation accuracy'},
          ]),
        ],
      ),
    );
  }

  Widget _buildGamificationGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Gamification System', Icons.emoji_events_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'Three Currencies',
            icon: Icons.account_balance_wallet_rounded,
            description: 'Ngwenya (main currency), Cowries (daily rewards), and Ancestral Beads (rare achievements).',
            tips: [
              'Earn Ngwenya from all activities',
              'Cowries from daily check-ins',
              'Beads from special achievements',
            ],
          ),
          _buildFeatureCard(
            title: 'Levels & Titles',
            icon: Icons.trending_up_rounded,
            description: 'Progress from "Novice" to "Elder" with African-themed titles. Earn XP from all activities.',
            tips: [
              'XP from lessons, games, chats',
              'Level up for bonus rewards',
              'Unlock new titles',
            ],
          ),
          _buildFeatureCard(
            title: 'Streaks',
            icon: Icons.local_fire_department_rounded,
            description: 'Daily streaks with Ubuntu mode (never break - help others) and "Ask the Ancestors" freeze.',
            tips: [
              'Maintain daily streaks for bonuses',
              'Use freeze if you miss a day',
              'Ubuntu mode helps others',
            ],
          ),
          _buildFeatureCard(
            title: 'Badges',
            icon: Icons.workspace_premium_rounded,
            description: '50+ African-themed badges for various achievements. Collect them all!',
            tips: [
              'Earn badges from activities',
              'Special badges for cultural games',
              'Display your collection',
            ],
          ),
          _buildFeatureCard(
            title: 'Tribes',
            icon: Icons.people_rounded,
            description: 'Join a tribe (Yoruba, Zulu, etc.) and compete in Tribe vs Tribe events.',
            tips: [
              'Choose your tribe',
              'Compete in events',
              'Earn tribe-specific rewards',
            ],
          ),
          _buildFeatureCard(
            title: 'Quests',
            icon: Icons.flag_rounded,
            description: '"The Great Journey" - Complete chapters and unlock rewards. Boss battles included!',
            tips: [
              'Complete quests for XP',
              'Unlock new chapters',
              'Face boss battles',
            ],
          ),
          SizedBox(height: 24.h),
          _buildTerminologySection([
            {'term': 'Ngwenya', 'definition': 'Main currency earned from all activities. Use for purchases and upgrades.'},
            {'term': 'Cowries', 'definition': 'Traditional currency earned from daily check-ins and streaks.'},
            {'term': 'Ancestral Beads', 'definition': 'Rare currency from special achievements and cultural milestones.'},
            {'term': 'Ubuntu Streak', 'definition': 'A streak mode where breaking it helps others instead of resetting your progress.'},
            {'term': 'Ask the Ancestors', 'definition': 'Streak freeze that prevents losing your streak if you miss a day.'},
          ]),
        ],
      ),
    );
  }

  Widget _buildProgressGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Progress Tracking', Icons.analytics_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'CEFR Levels',
            icon: Icons.signal_cellular_alt_rounded,
            description: 'Track your proficiency from A1 (beginner) to C2 (master). Automatically assessed by Polie.',
            tips: [
              'A1-A2: Beginner',
              'B1-B2: Intermediate',
              'C1-C2: Advanced',
            ],
          ),
          _buildFeatureCard(
            title: 'Activity Tracking',
            icon: Icons.timer_rounded,
            description: 'Track time spent on listening, speaking, reading, and writing activities.',
            tips: [
              'See daily/weekly/monthly stats',
              'Track progress per language',
              'Identify strengths and weaknesses',
            ],
          ),
          _buildFeatureCard(
            title: 'Vocabulary Growth',
            icon: Icons.book_rounded,
            description: 'Track words learned, known words, and vocabulary by language.',
            tips: [
              'See your vocabulary size',
              'Track growth over time',
              'Review difficult words',
            ],
          ),
          SizedBox(height: 24.h),
          _buildTerminologySection([
            {'term': 'CEFR', 'definition': 'Common European Framework - International standard for language proficiency (A1-C2)'},
            {'term': 'SRS', 'definition': 'Spaced Repetition System - Algorithm for optimal review timing'},
          ]),
        ],
      ),
    );
  }

  Widget _buildSocialGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Social Features', Icons.people_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'Language Villages',
            icon: Icons.location_city_rounded,
            description: 'Join community spaces for your target language. Connect with other learners.',
            tips: [
              'Join villages for your language',
              'See active users',
              'Participate in discussions',
            ],
          ),
          _buildFeatureCard(
            title: 'Tribe vs Tribe',
            icon: Icons.groups_rounded,
            description: 'Competitive events where tribes compete for rewards. Earn points for your tribe!',
            tips: [
              'Join your tribe\'s events',
              'Earn points through activities',
              'Win tribe rewards',
            ],
          ),
          _buildFeatureCard(
            title: 'Leaderboards',
            icon: Icons.leaderboard_rounded,
            description: 'Global, tribe, and country leaderboards. See how you rank!',
            tips: [
              'Check global rankings',
              'See tribe rankings',
              'Country-specific leaderboards',
            ],
          ),
          _buildFeatureCard(
            title: 'Social Gifting',
            icon: Icons.card_giftcard_rounded,
            description: 'Send lessons to friends. Spread the love of learning!',
            tips: [
              'Gift lessons to friends',
              'Receive gifts from others',
              'Build your learning network',
            ],
          ),
          _buildFeatureCard(
            title: 'Where to open each space',
            icon: Icons.map_rounded,
            description:
                'Use the app menu (drawer) or these routes: Social Hub (/social-hub) for feed, friends, challenges, and tribe shortcuts. Language Villages: /villages-hub or /language-village. Tribe discovery: /tribe-discovery. Global chat: /global_chat. Private inbox: /private-chat-inbox. Classroom lobby (scheduled tribe rooms): /classroom-lobby. Live video classes: /live-classroom.',
            tips: [
              'Stitch hub (/stitch-hub) lists many deep links for QA',
              'Features Guide (this screen, route /features_guide) is the user-facing map',
              'Tap someone’s avatar or name in Global / Village / Tribe chat to open their profile when an id is available',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Getting Started', Icons.lightbulb_rounded),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            title: 'Daily Goals',
            icon: Icons.track_changes_rounded,
            description: 'Set and track daily learning goals. Maintain your streak!',
            tips: [
              'Set realistic goals',
              'Track your progress',
              'Earn rewards for completion',
            ],
          ),
          _buildFeatureCard(
            title: 'Lessons',
            icon: Icons.menu_book_rounded,
            description: 'Structured lessons with tutorials and quizzes. Progress through levels.',
            tips: [
              'Complete tutorials first',
              'Take quizzes to test knowledge',
              'Track lesson completion',
            ],
          ),
          _buildFeatureCard(
            title: 'Quizzes',
            icon: Icons.quiz_rounded,
            description: 'Test your knowledge with various quiz types. Instant feedback.',
            tips: [
              'Take random quizzes',
              'Language-specific quizzes',
              'History and culture quizzes',
            ],
          ),
          _buildFeatureCard(
            title: 'Culture Magazine',
            icon: Icons.article_rounded,
            description: 'Read articles about African cultures, history, and traditions.',
            tips: [
              'Browse by category',
              'Save favorites',
              'Learn cultural context',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28.sp, color: PanAfricanColors.primary),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required String description,
    required List<String> tips,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: PanAfricanColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Tips:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                ...tips.map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20.sp,
                            color: PanAfricanColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildTerminologySection(List<Map<String, String>> terms) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: PanAfricanColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'Terminology',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...terms.map((term) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term['term']!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: PanAfricanColors.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        term['definition']!,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

