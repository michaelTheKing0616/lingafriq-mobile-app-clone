import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
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
/// mid-session or causing needless rebuilds/jank on low-end phones. Each
/// carries its language so the hero can teach the word, not just show it.
typedef WelcomeWord = ({
  String word,
  String Function(AppLocalizations)? language,
});

final List<WelcomeWord> kWelcomeWords = <WelcomeWord>[
  (word: 'Sannu da zuwa', language: (l) => l.homeLangHausa),
  (word: 'Welcome o', language: (l) => l.homeLangPidgin),
  (word: 'Karibu', language: (l) => l.homeLangSwahili),
  (word: 'Ẹ Káàbọ̀', language: (l) => l.homeLangYoruba),
  (word: 'Wamukelekile', language: (l) => l.homeLangZulu),
  (word: 'Nnọọ', language: (l) => l.homeLangIgbo),
  (word: 'Welcome', language: null),
];

/// Today's welcome word. [now] is injectable so tests and goldens are stable.
WelcomeWord welcomeWordFor(DateTime now) =>
    kWelcomeWords[now.day % kWelcomeWords.length];

/// Clock seam for the daily word; tests override it for stable goldens.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Prefers the learner's username, falls back to their full name, and
/// finally to a friendly default so the hero card never reads "Welcome
/// back, " with a blank name.
String _displayName(ProfileModel? user, AppLocalizations l) {
  if (user == null) return l.homeLearner;
  final username = user.username.trim();
  if (username.isNotEmpty) return username;
  final full = user.fullName.trim();
  if (full.isNotEmpty) return full;
  return l.homeLearner;
}

double _languageProgress(Language language) => language.total_score > 0
    ? (language.total_score / 100).clamp(0.0, 1.0)
    : 0.0;

/// The one language to resume: published, started, not finished, furthest
/// along. Null when there is nothing in progress (no fake "continue").
Language? pickContinueLanguage(List<Language> languages) {
  Language? best;
  for (final lang in languages) {
    final p = _languageProgress(lang);
    if (!lang.is_published || p <= 0 || p >= 1) continue;
    if (best == null || p > _languageProgress(best)) best = lang;
  }
  return best;
}

void _openLanguage(BuildContext context, Language language) {
  HapticFeedback.lightImpact();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LanguageDetailScreen(language: language),
    ),
  );
}

void _openSearch(BuildContext context) {
  HapticFeedback.lightImpact();
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SearchLanguagesPage()),
  );
}

/// Home: a summary-first "today" screen (reference pack home-dashboard:
/// greeting + hero number, one continue card, then the list), in one scroll
/// so nothing is squeezed on a 320 px phone at 200% text.
class HomeTabMaterial3 extends HookConsumerWidget {
  const HomeTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final languagesAsync = ref.watch(languagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    ref.watch(dailyGoalsProvider);
    final dailyGoals = ref.read(dailyGoalsProvider.notifier).goals;
    final word = welcomeWordFor(ref.watch(homeClockProvider)());
    final displayName = _displayName(user, l);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ageTierStatusAsync = ref.watch(ageTierStatusProvider);
    final isPendingGuardianMinor = ageTierStatusAsync.maybeWhen(
      data: _isPendingGuardianMinor,
      orElse: () => false,
    );
    final side = PanAfricanSpacing.md;

    Widget pad(Widget child, {double top = 0}) => SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(side, top, side, 0),
      sliver: SliverToBoxAdapter(child: child),
    );

    final listSlivers = languagesAsync.when<List<Widget>>(
      data: (languages) {
        if (languages.results.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: PanAfricanEmptyState(
                icon: Icons.language_outlined,
                title: l.homeNoLanguagesTitle,
                description: l.homeNoLanguagesBody,
                actionLabel: l.homeSearchLanguagesAction,
                onAction: () => _openSearch(context),
              ),
            ),
          ];
        }
        final resume = pickContinueLanguage(languages.results);
        return [
          if (resume != null)
            pad(
              _ContinueCard(
                language: resume,
                isDark: isDark,
                onTap: () => _openLanguage(context, resume),
              ),
              top: PanAfricanSpacing.md,
            ),
          pad(
            Semantics(
              header: true,
              child: Text(
                l.homeFeaturedLanguages,
                style: PanAfricanTypography.headlineMedium(context),
              ),
            ),
            top: PanAfricanSpacing.lg,
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              side,
              PanAfricanSpacing.sm,
              side,
              PanAfricanSpacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: languages.results.length,
              itemBuilder: (context, index) {
                final language = languages.results[index];
                Widget card = _LanguageCard(
                  language: language,
                  isDark: isDark,
                  onTap: () {
                    if (!language.is_published) {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.homeComingSoonSnack(language.name)),
                        ),
                      );
                      return;
                    }
                    _openLanguage(context, language);
                  },
                );
                if (!reduceMotion) {
                  card = card
                      .animate(delay: (index * 40).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08, duration: 300.ms);
                }
                return card;
              },
            ),
          ),
        ];
      },
      error: (e, s) {
        if (_looksOffline(e)) {
          // A distinct, actionable state instead of folding connectivity
          // failures into the generic server-error panel below.
          return [
            SliverToBoxAdapter(
              child: PanAfricanEmptyState(
                icon: Icons.wifi_off_rounded,
                title: l.homeOfflineTitle,
                description: l.homeOfflineBody,
                actionLabel: l.homeTryAgain,
                onAction: () => ref.invalidate(languagesProvider),
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: Center(
              child: StreamErrorWidget(
                error: e,
                onTryAgain: () => ref.invalidate(languagesProvider),
              ),
            ),
          ),
        ];
      },
      loading: () => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AdaptiveProgressIndicator(message: l.homeLoadingLanguages),
        ),
      ],
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
              // No subtitle here: the hero card right below already greets
              // the learner by name.
              PanAfricanAppBar(
                title: word.word,
                showBackButton: false,
                actions: [
                  Semantics(
                    label: l.homeSearchLanguagesLabel,
                    button: true,
                    // Avoids a double announcement with the tooltip node.
                    excludeSemantics: true,
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => _openSearch(context),
                      tooltip: l.homeSearchLanguagesAction,
                    ),
                  ),
                  Semantics(
                    label: l.homeOpenMenu,
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
                      tooltip: l.homeMenu,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      if (isPendingGuardianMinor)
                        pad(
                          _GuardianPendingBanner(reduceMotion: reduceMotion),
                          top: PanAfricanSpacing.lg,
                        ),
                      pad(
                        _HeroCard(
                          userName: displayName,
                          dailyGoals: dailyGoals,
                          isDark: isDark,
                          streak: user?.streak ?? 0,
                          reduceMotion: reduceMotion,
                          word: word,
                        ),
                        top: PanAfricanSpacing.lg,
                      ),
                      ...listSlivers,
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

/// The single main action on Home (pack: Busuu/Calm continue card): the
/// language you were last furthest into, its progress, one Continue button.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  final Language language;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final percent = (_languageProgress(language) * 100).toInt();
    final muted = isDark
        ? PanAfricanColors.textSecondaryDark
        : PanAfricanColors.textSecondaryLight;
    return Semantics(
      container: true,
      label: l.homeContinueLabel(language.name, percent),
      child: Container(
        key: const Key('home-continue-card'),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? PanAfricanColors.cardDark
              : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.sm,
          border: const BorderDirectional(
            start: BorderSide(color: PanAfricanColors.secondaryDark, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Text(
                l.homeContinueTitle(language.name),
                style: PanAfricanTypography.titleMedium(context),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: _languageProgress(language),
                minHeight: 8,
                backgroundColor: PanAfricanColors.neutralLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  PanAfricanColors.primary,
                ),
                borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            ExcludeSemantics(
              child: Text(
                l.homePercentComplete(percent),
                style: PanAfricanTypography.labelSmall(
                  context,
                ).copyWith(color: muted),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            FilledButton.icon(
              key: const Key('home-continue-button'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.continueButton),
            ),
          ],
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
    final l = l10nOf(context);
    final progress = _languageProgress(language);
    final percent = (progress * 100).toInt();
    // Defends against a backend ever including an unpublished/not-yet-ready
    // language in the list, so the card stays truthful instead of opening a
    // broken lesson flow.
    final isLocked = !language.is_published;

    final semanticsLabel = isLocked
        ? l.homeCardLocked(language.name)
        : progress > 0
        ? l.homeCardProgress(language.name, percent)
        : l.homeCardStart(language.name);

    // Dark/light-aware secondary colour for every quiet label and the
    // trailing icon, verified >=4.5:1 against both card backgrounds.
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
          // Without this, the card's own text nodes merge into the label.
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
                    // Only this decorative image (not any text) is dimmed
                    // for the locked state, so text keeps AA contrast.
                    Semantics(
                      label: l.homeFlag(language.name),
                      excludeSemantics: true,
                      child: Opacity(
                        opacity: isLocked ? 0.5 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PanAfricanRadius.md,
                          ),
                          child: (language.background ?? '').isEmpty
                              ? _flagFallback()
                              : CachedNetworkImage(
                                  imageUrl: language.background!,
                                  width: 56.w,
                                  height: 56.w,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      _flagFallback(),
                                  errorWidget: (context, url, error) =>
                                      _flagFallback(),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          if (isLocked)
                            Text(
                              l.homeComingSoon,
                              style: PanAfricanTypography.bodySmall(context)
                                  .copyWith(
                                    color: mutedIconTextColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                            )
                          else if (progress > 0) ...[
                            LinearProgressIndicator(
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
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              l.homePercentComplete(percent),
                              style: PanAfricanTypography.labelSmall(
                                context,
                              ).copyWith(color: mutedIconTextColor),
                            ),
                          ] else
                            Text(
                              l.homeStartLearning,
                              style: PanAfricanTypography.bodySmall(
                                context,
                              ).copyWith(color: mutedIconTextColor),
                            ),
                        ],
                      ),
                    ),
                    // chevron_right does not auto-mirror, so flip it for RTL.
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.chevron_right_rounded,
                        color: mutedIconTextColor,
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

  Widget _flagFallback() => Container(
    width: 56.w,
    height: 56.w,
    color: PanAfricanColors.neutralLight,
    child: const Icon(Icons.language, color: PanAfricanColors.neutralMedium),
  );
}

/// A small, honest status banner for a minor account still waiting on
/// guardian consent (see [AgeTierService]). Home stays fully usable for
/// lessons; this explains why social/chat/purchase features are paused.
class _GuardianPendingBanner extends StatelessWidget {
  const _GuardianPendingBanner({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final banner = Semantics(
      container: true,
      liveRegion: true,
      label: l.homeGuardianLabel,
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
                    l.homeGuardianTitle,
                    style: PanAfricanTypography.titleSmall(
                      context,
                    ).copyWith(color: PanAfricanColors.onSecondaryContainer),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    l.homeGuardianBody,
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

    if (reduceMotion) return banner;
    return banner.animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}

/// Summary-first hero (pack: Monzo/Revolut hero number + Headspace greeting):
/// the day's welcome word with its meaning, the learner's streak, and a
/// progress ring for today's goals that fills once on open.
class _HeroCard extends StatelessWidget {
  final String userName;
  final List<DailyGoal> dailyGoals;
  final bool isDark;
  final int streak;
  final bool reduceMotion;
  final WelcomeWord word;

  const _HeroCard({
    required this.userName,
    required this.dailyGoals,
    required this.isDark,
    required this.streak,
    required this.reduceMotion,
    required this.word,
  });

  double _progress() {
    final todayGoals = dailyGoals.where((goal) => goal.isToday).toList();
    if (todayGoals.isEmpty) return 0;
    final total = todayGoals.fold<double>(0, (sum, g) => sum + g.progress);
    return (total / todayGoals.length).clamp(0.0, 1.0);
  }

  String _subtitleCopy(AppLocalizations l) {
    if (streak <= 0) return l.homeStreakNone;
    if (streak == 1) return l.homeStreakOne;
    return l.homeStreakMany(streak);
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final progress = _progress();
    final percent = (progress * 100).toInt();
    final language = word.language?.call(l);

    final card = Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.savannaGold,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null) ...[
            Text(
              l.homeWordOfDay(word.word, language),
              key: const Key('home-word-of-day'),
              style: PanAfricanTypography.labelLarge(context).copyWith(
                color: PanAfricanColors.neutralDarkest,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeWelcomeBack(userName),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: PanAfricanTypography.titleLarge(
                        context,
                      ).copyWith(color: PanAfricanColors.neutralDarkest),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      _subtitleCopy(l),
                      style: PanAfricanTypography.bodyMedium(
                        context,
                      ).copyWith(color: PanAfricanColors.neutralDark),
                    ),
                  ],
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              _GoalRing(
                progress: progress,
                percent: percent,
                reduceMotion: reduceMotion,
                caption: l.homeGoalCaption,
                label: l.homeGoalRing(percent),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Wrap(
            spacing: PanAfricanSpacing.sm,
            runSpacing: PanAfricanSpacing.xxs,
            children: [
              // onXContainer tokens: pre-mixed high-contrast text colours,
              // measured 8.5:1 / 6.2:1 on the badge's tinted fill.
              if (streak > 0)
                Semantics(
                  label: l.homeStreakSemantics(streak),
                  excludeSemantics: true,
                  child: PanAfricanBadge(
                    label: l.homeStreakBadge(streak),
                    color: PanAfricanColors.onTertiaryContainer,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
              Semantics(
                label: l.homeDailyGoals,
                excludeSemantics: true,
                child: PanAfricanBadge(
                  label: l.homeDailyGoals,
                  color: PanAfricanColors.onPrimaryContainer,
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

/// Today's goal as a ring (the pack's "hero number"). Fills over 600 ms on
/// open; instant with Reduce Motion. Sized from the text so 200% still fits.
class _GoalRing extends StatelessWidget {
  const _GoalRing({
    required this.progress,
    required this.percent,
    required this.reduceMotion,
    required this.caption,
    required this.label,
  });

  final double progress;
  final int percent;
  final bool reduceMotion;
  final String caption;
  final String label;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(64).clamp(64.0, 96.0);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('home-goal-ring'),
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: PanAfricanColors.neutralDarkest.withValues(
                  alpha: 0.15,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  PanAfricanColors.neutralDarkest,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: PanAfricanTypography.titleSmall(context)
                            .copyWith(
                              color: PanAfricanColors.neutralDarkest,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        caption,
                        style: PanAfricanTypography.labelSmall(
                          context,
                        ).copyWith(color: PanAfricanColors.neutralDarkest),
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
