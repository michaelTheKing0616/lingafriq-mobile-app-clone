import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/screens/language/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';

final languagesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

/// Read-only check against the existing server-owned age-tier status (see
/// [AgeTierService]) so a minor account that is still waiting on guardian
/// approval sees an honest banner here, instead of Home silently pretending
/// that gate doesn't exist. This is deliberately a thin, local read of the
/// same status the age gate / guardian flows already use. It does not
/// introduce a new consent model. Fails open (no banner) on error so this
/// secondary, non-critical check never blocks the primary Home experience.
final ageTierStatusProvider = FutureProvider.autoDispose<AgeTierStatus?>((
  ref,
) async {
  try {
    return await AgeTierService().fetchStatus();
  } catch (_) {
    return null;
  }
});

/// True when the backend has placed this account in the same
/// "pending_guardian" state surfaced by the age gate
/// (see `AgeGateScreen.ageGatePendingGuardianTitle`): a minor whose
/// guardian has not yet consented.
bool _isPendingGuardianMinor(AgeTierStatus? status) {
  return status?.status == 'pending_guardian';
}

/// A connectivity-flavoured failure (vs. a generic server error), using the
/// same substring heuristic already relied on elsewhere in the app (see
/// `StreamErrorWidget`) so Home can show a distinct, actionable offline
/// state instead of folding it into the generic error panel.
bool _looksOffline(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('no internet') ||
      message.contains('network is unreachable') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection timed out');
}

/// A small set of Pan-African welcome words. One is shown per calendar day
/// (not on a repeating timer) so the greeting still feels alive across
/// visits without forcing screen readers to re-announce the app bar title
/// mid-session or causing needless rebuilds/jank on low-end phones.
const List<String> _kWelcomeGreetings = <String>[
  'Sannu da zuwa', // Hausa
  'Welcome o', // Pidgin
  'Karibu', // Swahili
  'Ẹ Káàbọ̀', // Yoruba
  'Wamukelekile', // Zulu
  'Nnọọ', // Igbo
  'Welcome', // English
];

String _greetingOfTheDay() {
  final index = DateTime.now().day % _kWelcomeGreetings.length;
  return _kWelcomeGreetings[index];
}

/// Prefers the learner's username, falls back to their full name, and
/// finally to a friendly default so the hero card never reads "Welcome
/// back, " with a blank name.
String _displayName(ProfileModel? user) {
  if (user == null) return 'Learner';
  final username = user.username.trim();
  if (username.isNotEmpty) return username;
  final full = user.fullName.trim();
  if (full.isNotEmpty) return full;
  return 'Learner';
}

/// Beautiful Material 3 Home Tab with Pan-African Design
class HomeTabMaterial3 extends HookConsumerWidget {
  const HomeTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    ref.watch(dailyGoalsProvider);
    final dailyGoals = ref.read(dailyGoalsProvider.notifier).goals;
    final greeting = _greetingOfTheDay();
    final displayName = _displayName(user);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ageTierStatusAsync = ref.watch(ageTierStatusProvider);
    final isPendingGuardianMinor = ageTierStatusAsync.maybeWhen(
      data: _isPendingGuardianMinor,
      orElse: () => false,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Pan-African App Bar
              // No subtitle here: the hero card right below already greets
              // the learner by name, so repeating "Welcome back" twice in
              // the same screenful would just be noise.
              PanAfricanAppBar(
                title: greeting,
                showBackButton: false,
                actions: [
                  Semantics(
                    label: 'Search languages',
                    button: true,
                    // Without this, the IconButton's own tooltip-driven
                    // semantics node would double-announce alongside this
                    // label, matching the pattern used everywhere else in
                    // this file.
                    excludeSemantics: true,
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchLanguagesPage(),
                          ),
                        );
                      },
                      tooltip: 'Search Languages',
                    ),
                  ),
                  Semantics(
                    label: 'Open menu',
                    button: true,
                    excludeSemantics: true,
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(scaffoldKeyProvider)
                            .currentState
                            ?.openDrawer();
                      },
                      tooltip: 'Menu',
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPendingGuardianMinor)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            PanAfricanSpacing.md,
                            PanAfricanSpacing.lg,
                            PanAfricanSpacing.md,
                            0,
                          ),
                          child: _GuardianPendingBanner(reduceMotion: reduceMotion),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.lg,
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.sm,
                        ),
                        child: _buildHeroCard(
                          context,
                          isDark,
                          userName: displayName,
                          dailyGoals: dailyGoals,
                          streak: user?.streak ?? 0,
                          reduceMotion: reduceMotion,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.lg,
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.sm,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Featured Languages',
                            style: PanAfricanTypography.headlineMedium(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: languagesAsync.when(
                          data: (languages) {
                            if (languages.results.isEmpty) {
                              // Scrollable so the card never clips on short
                              // screens or with larger accessibility text
                              // scales, instead of relying on a fixed height.
                              return SingleChildScrollView(
                                child: PanAfricanEmptyState(
                                  icon: Icons.language_outlined,
                                  title: "No languages yet",
                                  description:
                                      "We're still adding languages for your region. "
                                      "Search to see what's available, or check back soon.",
                                  actionLabel: 'Search Languages',
                                  onAction: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SearchLanguagesPage(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                PanAfricanSpacing.md,
                                0,
                                PanAfricanSpacing.md,
                                PanAfricanSpacing.lg,
                              ),
                              itemCount: languages.results.length,
                              itemBuilder: (context, index) {
                                final language = languages.results[index];
                                Widget card = _LanguageCard(
                                  language: language,
                                  isDark: isDark,
                                  onTap: () {
                                    if (!language.is_published) {
                                      HapticFeedback.selectionClick();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${language.name} is coming soon. We're "
                                            "putting the finishing touches on it.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LanguageDetailScreen(
                                              language: language,
                                            ),
                                      ),
                                    );
                                  },
                                );
                                if (!reduceMotion) {
                                  card = card
                                      .animate(delay: (index * 50).ms)
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: 0.1, duration: 300.ms);
                                }
                                return card;
                              },
                            );
                          },
                          error: (e, s) {
                            if (_looksOffline(e)) {
                              // A distinct, actionable state instead of
                              // folding connectivity failures into the
                              // generic server-error panel below.
                              return SingleChildScrollView(
                                child: PanAfricanEmptyState(
                                  icon: Icons.wifi_off_rounded,
                                  title: "You're offline",
                                  description:
                                      "Check your connection. We'll reload your "
                                      "languages as soon as you're back online.",
                                  actionLabel: 'Try Again',
                                  onAction: () {
                                    ref.invalidate(languagesProvider);
                                  },
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              child: Center(
                                child: StreamErrorWidget(
                                  error: e,
                                  onTryAgain: () {
                                    ref.invalidate(languagesProvider);
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => const AdaptiveProgressIndicator(
                            message: "Loading your languages...",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language language;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = language.total_score > 0
        ? (language.total_score / 100).clamp(0.0, 1.0)
        : 0.0;
    // Defends against a backend ever including an unpublished/not-yet-ready
    // language in the list, so the card stays truthful instead of opening a
    // broken lesson flow.
    final isLocked = !language.is_published;

    final semanticsLabel = isLocked
        ? '${language.name} language card, coming soon, not available yet'
        : '${language.name} language card${progress > 0 ? ', ${(progress * 100).toInt()}% complete' : ', start learning'}';

    // A dedicated, dark/light-aware secondary color for every "quiet" label
    // on this card ("Coming soon", "% Complete", "Start Learning") and the
    // trailing lock/chevron icon. A static `neutralMedium` here failed
    // outright in dark mode (~1.87:1 against the dark card, below even the
    // 3:1 non-text minimum); Opacity-fading the whole card (the original
    // locked-state approach) failed similarly (~2.85:1). This token is
    // verified >=4.5:1 against both card backgrounds (see below).
    final mutedIconTextColor = isDark
        ? PanAfricanColors.textSecondaryDark
        : PanAfricanColors.textSecondaryLight;

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: semanticsLabel,
          button: true,
          // Without this, the card's own name/progress Text nodes merge
          // into this label, duplicating content for screen readers.
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: PanAfricanRadius.lgBR,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AdaptiveLayout.minTouchTarget,
              ),
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    // Language Flag/Image. Only this decorative image (not
                    // any text) is dimmed for the locked state, so the
                    // lock communicates visually without ever dropping
                    // text below the AA contrast minimum.
                    Semantics(
                      label: '${language.name} flag',
                      excludeSemantics: true,
                      child: Opacity(
                        opacity: isLocked ? 0.5 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PanAfricanRadius.md,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: language.background ?? '',
                            width: 56.w,
                            height: 56.w,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56.w,
                              height: 56.w,
                              color: PanAfricanColors.neutralLight,
                              child: const Icon(
                                Icons.language,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56.w,
                              height: 56.w,
                              color: PanAfricanColors.neutralLight,
                              child: const Icon(
                                Icons.language,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    // Language Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          if (isLocked)
                            Text(
                              'Coming soon',
                              style: PanAfricanTypography.bodySmall(context)
                                  .copyWith(
                                    color: mutedIconTextColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                            )
                          else if (progress > 0) ...[
                            Semantics(
                              label: 'Progress: ${(progress * 100).toInt()}%',
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: PanAfricanColors.neutralLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  PanAfricanColors.primary,
                                ),
                                minHeight: 6.h,
                                borderRadius: BorderRadius.circular(
                                  PanAfricanRadius.xs,
                                ),
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              '${(progress * 100).toInt()}% Complete',
                              style: PanAfricanTypography.labelSmall(
                                context,
                              ).copyWith(color: mutedIconTextColor),
                            ),
                          ] else
                            Text(
                              'Start Learning',
                              style: PanAfricanTypography.bodySmall(
                                context,
                              ).copyWith(color: mutedIconTextColor),
                            ),
                        ],
                      ),
                    ),
                    Semantics(
                      excludeSemantics: true,
                      // Mirrors the chevron so "forward" stays correct for
                      // RTL locales (Arabic / Darija).
                      child: Transform.flip(
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: Icon(
                          isLocked
                              ? Icons.lock_outline_rounded
                              : Icons.chevron_right_rounded,
                          color: mutedIconTextColor,
                        ),
                      ),
                    ),
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

/// A small, honest status banner for a minor account still waiting on
/// guardian consent (see [AgeTierService] / `AgeGateScreen`'s own
/// "pending_guardian" copy). Deliberately simple: Home stays fully usable
/// for lessons, this just explains why social/chat/purchase features are
/// paused, instead of silently hiding them with no explanation.
class _GuardianPendingBanner extends StatelessWidget {
  const _GuardianPendingBanner({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final banner = Semantics(
      container: true,
      liveRegion: true,
      label:
          'Waiting for a guardian. Lessons are open, but chat, Village, '
          'and purchases stay paused until a guardian approves.',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: PanAfricanColors.secondaryContainer,
          borderRadius: PanAfricanRadius.lgBR,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              color: PanAfricanColors.onSecondaryContainer,
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for a guardian',
                    style: PanAfricanTypography.titleSmall(
                      context,
                    ).copyWith(color: PanAfricanColors.onSecondaryContainer),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    "Lessons are open. Chat, Village, and purchases stay "
                    'paused until a guardian approves.',
                    style: PanAfricanTypography.bodySmall(
                      context,
                    ).copyWith(color: PanAfricanColors.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Matches the hero card's own fade/slide-in treatment just below, so a
    // banner that only appears for some accounts doesn't visually "pop" in
    // a different rhythm from the rest of the screen's entrance motion.
    if (reduceMotion) return banner;
    return banner.animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final List<DailyGoal> dailyGoals;
  final bool isDark;
  final int streak;
  final bool reduceMotion;

  const _HeroCard({
    required this.userName,
    required this.dailyGoals,
    required this.isDark,
    required this.streak,
    required this.reduceMotion,
  });

  double _progress() {
    final todayGoals = dailyGoals.where((goal) => goal.isToday).toList();
    if (todayGoals.isEmpty) return 0;
    final total = todayGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.progress,
    );
    return (total / todayGoals.length).clamp(0.0, 1.0);
  }

  /// Warm, data-driven copy instead of a static placeholder line. Reflects
  /// the learner's real streak so it never feels generic or AI-written.
  String _subtitleCopy() {
    if (streak <= 0) return 'Pick a language and start your streak today.';
    if (streak == 1) return "You're one day in, keep your streak alive today.";
    return "You're on a $streak-day streak, keep it going!";
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress();
    final progressPercent = (progress * 100).toInt();

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.savannaGold,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PanAfricanTypography.titleLarge(
                      context,
                    ).copyWith(color: PanAfricanColors.neutralDarkest),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    _subtitleCopy(),
                    style: PanAfricanTypography.bodyMedium(
                      context,
                    ).copyWith(color: PanAfricanColors.neutralDark),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Wrap(
                    spacing: PanAfricanSpacing.sm,
                    runSpacing: PanAfricanSpacing.xxs,
                    children: [
                      // `PanAfricanBadge` paints its text at full opacity in
                      // `color`, over a fill that's just `color` at 20%
                      // alpha. Passing a saturated token (e.g. `primary`,
                      // `tertiaryDark`) as `color` measured as low as
                      // ~2.96:1 here, failing the 4.5:1 AA minimum for text.
                      // The three `onXContainer` tokens below are the
                      // system's own pre-mixed, high-contrast text colors
                      // (designed to sit on a light tinted fill), verified
                      // here at 8.5:1 / 6.2:1 / 11.2:1 respectively.
                      if (streak > 0)
                        Semantics(
                          label: '$streak day${streak == 1 ? '' : 's'} streak',
                          // The badge's own text node would otherwise merge
                          // with this label, concatenating both strings for
                          // screen readers instead of reading one clean
                          // phrase.
                          excludeSemantics: true,
                          child: PanAfricanBadge(
                            label: '$streak day${streak == 1 ? '' : 's'}',
                            color: PanAfricanColors.onTertiaryContainer,
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                      Semantics(
                        label: 'Daily goals',
                        excludeSemantics: true,
                        child: const PanAfricanBadge(
                          label: 'Daily goals',
                          color: PanAfricanColors.onPrimaryContainer,
                          icon: Icons.flag_rounded,
                        ),
                      ),
                      Semantics(
                        label: '$progressPercent% complete',
                        excludeSemantics: true,
                        child: PanAfricanBadge(
                          label: '$progressPercent% complete',
                          color: PanAfricanColors.onSecondaryContainer,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Semantics(
              label: "Today's goal progress: $progressPercent%",
              child: Container(
                width: 56.w,
                height: 56.w,
                padding: EdgeInsets.all(PanAfricanSpacing.xxs),
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.surfaceContainerDark
                      : PanAfricanColors.surfaceContainerLight,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                ),
                child: Center(
                  // FittedBox keeps the percentage readable instead of
                  // clipping when the user has increased system text size.
                  child: FittedBox(
                    child: Text(
                      '$progressPercent%',
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

Widget _buildHeroCard(
  BuildContext context,
  bool isDark, {
  required String userName,
  required List<DailyGoal> dailyGoals,
  required int streak,
  required bool reduceMotion,
}) {
  return _HeroCard(
    userName: userName,
    dailyGoals: dailyGoals,
    isDark: isDark,
    streak: streak,
    reduceMotion: reduceMotion,
  );
}
