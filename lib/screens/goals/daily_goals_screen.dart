import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/games/games_screen_material3.dart';
import 'package:lingafriq/screens/tabs_view/home/take_quiz_screen.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/screens/vocabulary/vocabulary_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Snapshot of today's goals. The notifier keeps goals in private fields, so
/// this watches its state (bumped on refresh) and reads the getters.
class DailyGoalsView {
  const DailyGoalsView({
    required this.goals,
    required this.streak,
    this.loading = false,
    this.error,
  });
  final List<DailyGoal> goals;
  final int streak;
  final bool loading;
  final String? error;
}

final dailyGoalsViewProvider = Provider<DailyGoalsView>((ref) {
  final s = ref.watch(dailyGoalsProvider);
  final n = ref.read(dailyGoalsProvider.notifier);
  return DailyGoalsView(
    goals: n.goals.where((g) => g.isToday).toList(),
    streak: n.currentStreak,
    loading: s.isLoading,
    error: s.errorMessage,
  );
});

/// Re-syncs goals; overridable in tests.
final dailyGoalsRefreshProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(dailyGoalsProvider.notifier).refreshGoals(),
);

/// Languages offered when a goal needs one (lessons, quizzes).
final goalLanguagesProvider = Provider<Future<List<Language>> Function()>(
  (ref) =>
      () async => (await ref.read(apiProvider.notifier).getLanguages()).results,
);

/// Today's goals: streak hero + ring (ref profile-progress/02), then one
/// card per goal that opens the matching practice module.
class DailyGoalsScreen extends ConsumerStatefulWidget {
  const DailyGoalsScreen({super.key});

  @override
  ConsumerState<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends ConsumerState<DailyGoalsScreen> {
  bool _syncing = false;
  bool _syncFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _syncing = true;
      _syncFailed = false;
    });
    try {
      await ref.read(dailyGoalsRefreshProvider)();
    } catch (_) {
      if (mounted) setState(() => _syncFailed = true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  bool _compact(BuildContext c) => MediaQuery.textScalerOf(c).scale(10) > 15;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final view = ref.watch(dailyGoalsViewProvider);
    final cs = Theme.of(context).colorScheme;
    final compact = _compact(context);
    final goals = view.goals;
    final done = goals.where((g) => g.completed).length;
    final failed = _syncFailed || view.error != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.dgTitle, maxLines: 2),
        toolbarHeight: compact ? 72 : null,
        actions: [
          IconButton(
            key: const Key('dg-refresh'),
            tooltip: l.dgRefresh,
            onPressed: _syncing ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: _syncing || view.loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  key: const Key('dg-syncing'),
                  semanticsLabel: l.dgSyncing,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _Hero(streak: view.streak, done: done, total: goals.length),
                if (failed) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(onRetry: _refresh),
                ],
                const SizedBox(height: 24),
                Text(
                  l.dgToday,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (goals.isEmpty)
                  _Empty(onRefresh: _refresh)
                else ...[
                  if (done == goals.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        key: const Key('dg-all-done'),
                        color: cs.primaryContainer,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration_rounded,
                                color: cs.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l.dgAllDone,
                                  style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (final g in goals)
                    _GoalCard(
                      goal: g,
                      compact: compact,
                      onTap: () => _open(g.type),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(String type) {
    final navigation = ref.read(navigationProvider);
    switch (type) {
      case 'lessons':
        _pickLanguage(lessons: true);
      case 'quizzes':
        _pickLanguage(lessons: false);
      case 'games':
        navigation.navigateTo(const GamesScreenMaterial3());
      case 'chat_minutes':
        navigation.navigateTo(
          const AiChatLanguageSetupScreen(initialMode: PolieMode.translation),
        );
      case 'words_learned':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VocabularyScreen()),
        );
    }
  }

  void _pickLanguage({required bool lessons}) {
    final load = ref.read(goalLanguagesProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) => _LanguageSheet(
        title: lessons
            ? l10nOf(context).dgPickLessons
            : l10nOf(context).dgPickQuiz,
        load: load,
        onPick: (language) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          Navigator.pop(context); // leave daily goals for the module
          ref
              .read(navigationProvider)
              .navigateTo(
                lessons
                    ? LessonsListScreen(language: language)
                    : TakeQuizScreen(language: language),
              );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.streak, required this.done, required this.total});
  final int streak;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final compact = MediaQuery.textScalerOf(context).scale(10) > 15;
    const on = Colors.white;
    final ring = Semantics(
      label: l.dgRing(done, total),
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('dg-ring'),
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : done / total,
                strokeWidth: 8,
                backgroundColor: on.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(
                  PanAfricanColors.secondary,
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '$done/$total',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: on,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: PanAfricanColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.dgStreak(streak),
                key: const Key('dg-streak'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: on,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          streak > 0 ? l.dgStreakOn : l.dgStreakZero,
          style: TextStyle(color: on.withValues(alpha: 0.92)),
        ),
        const SizedBox(height: 6),
        Text(
          l.dgRing(done, total),
          style: const TextStyle(color: on, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Container(
      key: const Key('dg-hero'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ring, const SizedBox(height: 12), text],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                ring,
              ],
            ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const Key('dg-error'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.onErrorContainer),
          Text(l.dgError, style: TextStyle(color: cs.onErrorContainer)),
          TextButton(
            key: const Key('dg-retry'),
            onPressed: onRetry,
            child: Text(l.dgRetry),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('dg-empty'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.flag_rounded, size: 56, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            l.dgEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l.dgEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRefresh, child: Text(l.dgRefresh)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.compact,
    required this.onTap,
  });
  final DailyGoal goal;
  final bool compact;
  final VoidCallback onTap;

  static const _meta = <String, (IconData, Color)>{
    'lessons': (Icons.menu_book_rounded, Color(0xFF1B7F4B)),
    'quizzes': (Icons.track_changes_rounded, Color(0xFFB4541F)),
    'games': (Icons.sports_esports_rounded, Color(0xFF6B4BB8)),
    'chat_minutes': (Icons.forum_rounded, Color(0xFF1F6FB4)),
    'words_learned': (Icons.translate_rounded, Color(0xFFA8326E)),
  };

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final cs = Theme.of(context).colorScheme;
    final (icon, tint) =
        _meta[goal.type] ?? (Icons.check_circle_rounded, cs.primary);
    final title = switch (goal.type) {
      'lessons' => l.dgLessons,
      'quizzes' => l.dgQuizzes,
      'games' => l.dgGames,
      'chat_minutes' => l.dgChat,
      'words_learned' => l.dgWords,
      _ => l.dgGoal,
    };
    final cur = goal.current.clamp(0, goal.target);
    final progress = goal.type == 'chat_minutes'
        ? l.dgMinutes(cur, goal.target)
        : l.dgCount(cur, goal.target);
    final value = goal.target == 0 ? 0.0 : cur / goal.target;
    final status = goal.completed ? l.dgDone : l.dgStart;

    final badge = goal.completed
        ? Chip(
            avatar: const Icon(Icons.check_rounded, size: 18),
            label: Text(l.dgDone),
            visualDensity: VisualDensity.compact,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.dgStart,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                key: const Key('dg-chevron'),
                color: cs.primary,
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: l.dgGoalA11y(title, progress, status),
        excludeSemantics: true,
        child: Material(
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('dg-goal-${goal.type}'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: tint.withValues(alpha: 0.14),
                          child: Icon(icon, color: tint),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                progress,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) badge,
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          goal.completed ? cs.primary : tint,
                        ),
                      ),
                    ),
                    if (compact) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: badge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({
    required this.title,
    required this.load,
    required this.onPick,
  });
  final String title;
  final Future<List<Language>> Function() load;
  final ValueChanged<Language> onPick;
  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  late Future<List<Language>> _f = widget.load();

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Language>>(
              future: _f,
              builder: (c, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        key: Key('dg-lang-loading'),
                      ),
                    ),
                  );
                }
                if (s.hasError) {
                  return Column(
                    key: const Key('dg-lang-error'),
                    children: [
                      Text(l.dgLangError),
                      TextButton(
                        onPressed: () => setState(() {
                          _f = widget.load();
                        }),
                        child: Text(l.dgRetry),
                      ),
                    ],
                  );
                }
                final langs = s.data!.where((x) => x.is_published).toList();
                return Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final lang in langs)
                        ListTile(
                          key: Key('dg-lang-${lang.id}'),
                          leading: const Icon(Icons.language_rounded),
                          title: Text(
                            rtl ? '\u2068${lang.name}\u2069' : lang.name,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => widget.onPick(lang),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
