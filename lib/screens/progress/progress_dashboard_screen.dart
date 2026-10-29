import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_data.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider;
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Gold used for active days and bars (text-safe dark variant for labels).
const kProgressGold = Color(0xFFFFC53D);
const kProgressGoldText = Color(0xFF8C5A00);

/// Progress (profile-progress pack 01 stats grid, 02 streak calendar,
/// 03 weekly trend chart): this-week hero with trend, daily bars, 2x2 stats,
/// a 4-week activity calendar and time by activity. Local-first.
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final snap = ref.watch(progressSnapshotProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l.pgTitle,
          style: PanAfricanTypography.titleLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          key: const Key('pg-close'),
          tooltip: l.pgClose,
          icon: Icon(
            Navigator.of(context).canPop()
                ? Icons.arrow_back_rounded
                : Icons.close_rounded,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: snap.when(
          loading: () => _Skeleton(label: l.pgLoading),
          error: (_, _) => _ErrorPage(
            onRetry: () => ref.invalidate(progressSnapshotProvider),
          ),
          data: (s) => _Body(snap: s),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.snap});
  final ProgressSnapshot snap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final online = ref.watch(progressOnlineProvider).value ?? true;
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final private = tier == 'child' || tier == 'teen';
    final bigText = MediaQuery.textScalerOf(context).scale(10) > 13;
    final m = snap.metrics;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String h(double v) => l.pgHours(NumberFormat('0.#', locale).format(v));

    Widget section(String t) => Padding(
      padding: EdgeInsets.only(
        top: PanAfricanSpacing.lg,
        bottom: PanAfricanSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          t,
          style: PanAfricanTypography.titleMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
        ),
      ),
    );

    final children = <Widget>[
      if (!online)
        _Note(
          key: const Key('pg-offline'),
          icon: Icons.cloud_off_rounded,
          text: '${l.pgOffline} ${l.pgOfflineCount}',
        ),
      if (private) ...[
        if (!online) SizedBox(height: PanAfricanSpacing.xs),
        _Note(
          key: const Key('pg-private'),
          icon: Icons.shield_rounded,
          text: l.pgPrivate,
        ),
      ],
      if (snap.isEmpty) ...[
        SizedBox(height: PanAfricanSpacing.md),
        const _EmptyCard(key: Key('pg-empty')),
      ] else ...[
        if (!online || private) SizedBox(height: PanAfricanSpacing.md),
        StreakHero(snap: snap),
        SizedBox(height: PanAfricanSpacing.md),
        _WeekHero(snap: snap),
      ],
      section(l.pgCalendar),
      _Calendar(snap: snap),
      if (online) ...[
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          l.pgOfflineCount,
          style: PanAfricanTypography.bodySmall(
            context,
          ).copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
      section(l.pgOverviewTitle),
      _Grid(
        oneColumn: bigText,
        tiles: [
          _Tile(
            Icons.auto_stories_rounded,
            const Color(0xFF8C5A00),
            '${m.wordsLearned}',
            l.pgWordsLearned,
          ),
          _Tile(
            Icons.lightbulb_rounded,
            PanAfricanColors.primary,
            '${m.knownWords}',
            l.pgKnownWords,
          ),
          _Tile(
            Icons.headphones_rounded,
            const Color(0xFF1F5FA8),
            h(m.listeningHours),
            l.pgListening,
          ),
          _Tile(
            Icons.record_voice_over_rounded,
            const Color(0xFFB4401A),
            h(m.speakingHours),
            l.pgSpeaking,
          ),
        ],
      ),
      if (snap.activities.isNotEmpty) ...[
        section(l.pgActivities),
        _Activities(items: snap.activities, hours: h),
      ],
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.xs,
        PanAfricanSpacing.md,
        PanAfricanSpacing.xl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _card(ColorScheme scheme) => BoxDecoration(
  color: scheme.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: scheme.outlineVariant, width: 2),
);

/// Pack 03: one big number for the week, the trend, and a 7-day bar chart.
class _WeekHero extends StatelessWidget {
  const _WeekHero({required this.snap});
  final ProgressSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final diff = snap.thisWeekTotal - snap.lastWeekTotal;
    final trend = diff > 0
        ? l.pgVsUp(diff)
        : diff < 0
        ? l.pgVsDown(-diff)
        : l.pgVsSame;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final week = snap.thisWeek;
    final maxV = week.fold(1, (a, b) => b > a ? b : a);
    final barH = 96.0;
    return Container(
      key: const Key('pg-week'),
      decoration: _card(scheme),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pgThisWeek.toUpperCase(),
            style: PanAfricanTypography.labelLarge(context).copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            l.pgMinutes(snap.thisWeekTotal),
            key: const Key('pg-week-total'),
            style: PanAfricanTypography.headlineMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: scheme.onSurface),
          ),
          Row(
            children: [
              Icon(
                diff > 0
                    ? Icons.trending_up_rounded
                    : diff < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
                color: diff >= 0
                    ? PanAfricanColors.primary
                    : scheme.onSurfaceVariant,
                size: 20.sp,
              ),
              SizedBox(width: PanAfricanSpacing.xxs),
              Expanded(
                child: Text(
                  trend,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: diff >= 0
                        ? PanAfricanColors.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Semantics(
            label: l.pgDaily,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = snap.today.subtract(Duration(days: 6 - i));
                        final isToday = i == 6;
                        final v = week[i];
                        final name = DateFormat.E(locale).format(day);
                        return Semantics(
                          label: l.pgDayA11y(name, v),
                          container: true,
                          excludeSemantics: true,
                          child: Column(
                            children: [
                              SizedBox(
                                height: barH,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.55,
                                    heightFactor: v == 0
                                        ? 0.04
                                        : (v / maxV).clamp(0.08, 1.0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: v == 0
                                            ? scheme.outlineVariant
                                            : isToday
                                            ? PanAfricanColors.primary
                                            : kProgressGold,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: PanAfricanSpacing.xxs),
                              FittedBox(
                                child: Text(
                                  DateFormat('EEEEE', locale).format(day),
                                  style:
                                      PanAfricanTypography.labelMedium(
                                        context,
                                      ).copyWith(
                                        color: isToday
                                            ? PanAfricanColors.primary
                                            : scheme.onSurfaceVariant,
                                        fontWeight: isToday
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pack 02: 4-week grid; active days gold, today ringed.
class _Calendar extends StatelessWidget {
  const _Calendar({required this.snap});
  final ProgressSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final days = snap.dailyMinutes;
    return Semantics(
      key: const Key('pg-calendar'),
      container: true,
      label: l.pgCalA11y(l.pgActiveDays(snap.activeDays)),
      excludeSemantics: true,
      child: Container(
        decoration: _card(scheme),
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.pgActiveDays(snap.activeDays),
              style: PanAfricanTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: kProgressGoldText),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            for (var w = 0; w < 4; w++)
              Padding(
                padding: EdgeInsets.only(top: w == 0 ? 0 : 6),
                child: Row(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Expanded(
                        child: Center(
                          child: _Dot(
                            active: days[w * 7 + d] > 0,
                            today: w == 3 && d == 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.today});
  final bool active, today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? kProgressGold : scheme.surfaceContainerHighest,
        border: today
            ? Border.all(color: PanAfricanColors.primary, width: 3)
            : null,
      ),
      child: active
          ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF5C3B00))
          : null,
    );
  }
}

class _Tile {
  const _Tile(this.icon, this.color, this.value, this.label);
  final IconData icon;
  final Color color;
  final String value, label;
}

class _Grid extends StatelessWidget {
  const _Grid({required this.tiles, required this.oneColumn});
  final List<_Tile> tiles;
  final bool oneColumn;

  @override
  Widget build(BuildContext context) {
    final gap = PanAfricanSpacing.xs;
    Widget tile(_Tile t) => _TileView(t: t);
    if (oneColumn) {
      return Column(
        children: [
          for (final t in tiles) ...[tile(t), SizedBox(height: gap)],
        ],
      );
    }
    return Column(
      children: [
        for (var r = 0; r < tiles.length; r += 2) ...[
          if (r > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(tiles[r])),
                SizedBox(width: gap),
                Expanded(child: tile(tiles[r + 1])),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({required this.t});
  final _Tile t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Container(
        decoration: _card(scheme),
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        child: Row(
          children: [
            Icon(t.icon, color: t.color, size: 28.sp),
            SizedBox(width: PanAfricanSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.value,
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    t.label,
                    style: PanAfricanTypography.bodySmall(
                      context,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _activityName(AppLocalizations l, String key) => switch (key) {
  'lessons' => l.pgActLessons,
  'quizzes' => l.pgActQuizzes,
  'games' => l.pgActGames,
  'chat' => l.pgActChat,
  'stories' => l.pgActStories,
  'listening' => l.pgListening,
  'speaking' => l.pgSpeaking,
  'reading' => l.pgActReading,
  'writing' => l.pgActWriting,
  _ => l.pgActOther,
};

class _Activities extends StatelessWidget {
  const _Activities({required this.items, required this.hours});
  final List<MapEntry<String, double>> items;
  final String Function(double) hours;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final top = items.first.value;
    return Container(
      key: const Key('pg-activities'),
      decoration: _card(scheme),
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      child: Column(
        children: [
          for (final (i, e) in items.take(6).indexed) ...[
            if (i > 0) SizedBox(height: PanAfricanSpacing.sm),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _activityName(l, e.key),
                          style: PanAfricanTypography.bodyMedium(context)
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        hours(e.value),
                        style: PanAfricanTypography.bodyMedium(
                          context,
                        ).copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / top,
                      minHeight: 8,
                      color: i == 0 ? PanAfricanColors.primary : kProgressGold,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: _card(scheme),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: PanAfricanColors.primary, size: 40.sp),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.pgEmptyTitle,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  l.pgEmptyBody,
                  style: PanAfricanTypography.bodyMedium(
                    context,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20.sp, color: scheme.onSurfaceVariant),
            SizedBox(width: PanAfricanSpacing.xs),
            Expanded(
              child: Text(
                text,
                style: PanAfricanTypography.bodySmall(
                  context,
                ).copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pack 02/07 streak hero: illustrated flame on a kente-banded navy card,
/// the streak count, and progress to the next milestone. A one-shot
/// entrance (flame pops in) is skipped when the OS asks for reduced motion.
class StreakHero extends StatefulWidget {
  const StreakHero({super.key, required this.snap});
  final ProgressSnapshot snap;

  @override
  State<StreakHero> createState() => _StreakHeroState();
}

class _StreakHeroState extends State<StreakHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final s = widget.snap;
    final goal = s.nextMilestone;
    final hit = s.milestoneHit;
    final frac = (s.streak / goal).clamp(0.0, 1.0);
    final caption = s.streak == 0
        ? l.pgStreakStart
        : hit != null
        ? l.pgMilestoneHit(hit)
        : l.pgNextGoal(goal - s.streak, goal);
    const navy = Color(0xFF2E3A87);
    return Semantics(
      key: const Key('pg-streak'),
      container: true,
      label: '${l.pgStreakDays(s.streak)}. $caption',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: navy,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _c,
                        curve: Curves.elasticOut,
                      ),
                      child: const _Flame(size: 76),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.pgStreakTitle.toUpperCase(),
                            style: PanAfricanTypography.labelLarge(context)
                                .copyWith(
                                  color: const Color(0xFFC9D1FF),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                          ),
                          Text(
                            l.pgStreakDays(s.streak),
                            key: const Key('pg-streak-count'),
                            style: PanAfricanTypography.headlineMedium(context)
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: frac,
                              minHeight: 10,
                              color: kProgressGold,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          Row(
                            children: [
                              if (hit != null) ...[
                                const Icon(
                                  Icons.celebration_rounded,
                                  size: 18,
                                  color: kProgressGold,
                                ),
                                SizedBox(width: PanAfricanSpacing.xxs),
                              ],
                              Expanded(
                                child: Text(
                                  caption,
                                  key: const Key('pg-streak-caption'),
                                  style: PanAfricanTypography.bodySmall(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 14,
                width: double.infinity,
                child: CustomPaint(painter: _KentePainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Illustrated flame: gold disc, layered flame, a small kente diamond.
class _Flame extends StatelessWidget {
  const _Flame({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _FlamePainter()),
  );
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width, h = sz.height;
    final c = Offset(w / 2, h / 2);
    canvas.drawCircle(c, w / 2, Paint()..color = const Color(0x33FFC53D));
    canvas.drawCircle(c, w * 0.42, Paint()..color = kProgressGold);
    Path flame(double s, double dy) {
      final p = Path();
      final bx = w / 2, by = h * 0.80 + dy;
      p.moveTo(bx, h * (0.80 - 0.62 * s) + dy);
      p.cubicTo(
        bx + w * 0.30 * s,
        by - h * 0.32 * s,
        bx + w * 0.26 * s,
        by,
        bx,
        by,
      );
      p.cubicTo(
        bx - w * 0.26 * s,
        by,
        bx - w * 0.30 * s,
        by - h * 0.28 * s,
        bx - w * 0.06 * s,
        by - h * 0.46 * s,
      );
      p.close();
      return p;
    }

    canvas.drawPath(flame(1, 0), Paint()..color = const Color(0xFFD9481C));
    canvas.drawPath(flame(0.62, 0), Paint()..color = const Color(0xFFFF8A3D));
    canvas.drawPath(flame(0.30, 0), Paint()..color = const Color(0xFFFFF1C2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kente-style band: repeating gold/green/red/black blocks with a stripe.
class _KentePainter extends CustomPainter {
  const _KentePainter();

  @override
  void paint(Canvas canvas, Size sz) {
    const colors = [
      kProgressGold,
      Color(0xFF1E7B47),
      Color(0xFFC0392B),
      Color(0xFF1B1B1B),
    ];
    const bw = 18.0;
    var i = 0;
    for (var x = 0.0; x < sz.width; x += bw, i++) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, bw, sz.height),
        Paint()..color = colors[i % colors.length],
      );
      canvas.drawRect(
        Rect.fromLTWH(x, sz.height / 2 - 1.5, bw / 2, 3),
        Paint()..color = kProgressGold,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-page error: illustrated banner, reassurance, retry.
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const Key('pg-error'),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: _card(scheme),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: const Color(0xFF2E3A87),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: PanAfricanSpacing.lg,
                      ),
                      child: const ExcludeSemantics(
                        child: Center(
                          child: Opacity(
                            opacity: 0.55,
                            child: _Flame(size: 88),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                    child: CustomPaint(painter: _KentePainter()),
                  ),
                  Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.pgErrorTitle,
                            style: PanAfricanTypography.titleLarge(context)
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          l.pgErrorBody,
                          style: PanAfricanTypography.bodyMedium(
                            context,
                          ).copyWith(color: scheme.onSurface),
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        _Note(icon: Icons.local_fire_department_rounded, text: l.pgErrorSaved),
                        SizedBox(height: PanAfricanSpacing.md),
                        PanAfricanButton(
                          key: const Key('pg-retry'),
                          label: l.pgRetry,
                          icon: Icons.refresh_rounded,
                          onPressed: onRetry,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton mirroring the real layout: streak hero, week bars, 2x2 grid.
/// A soft shimmer sweeps across it unless reduced motion is requested.
class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.label});
  final String label;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating && _c.value == 0) {
      // A few gentle sweeps, then rest: loading is usually instant (local).
      _c.repeat(count: 4);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = scheme.surfaceContainerHighest;
    Widget bar(double w, double h, [Color? col]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: col ?? c,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
    Widget tile() => Expanded(
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    final onNavy = Colors.white.withValues(alpha: 0.22);
    final content = ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      children: [
        Container(
          key: const Key('pg-skel-hero'),
          height: 120,
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3A87),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: onNavy,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(90, 12, onNavy),
                    SizedBox(height: PanAfricanSpacing.xs),
                    bar(140, 24, onNavy),
                    SizedBox(height: PanAfricanSpacing.xs),
                    bar(double.infinity, 10, onNavy),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Container(
          key: const Key('pg-skel-bars'),
          height: 200,
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          decoration: _card(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(80, 12),
              SizedBox(height: PanAfricanSpacing.xs),
              bar(130, 24),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final f in const [.4, .7, .2, .5, .3, .9, .6])
                    Container(
                      width: 22,
                      height: 90 * f,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        bar(120, 16),
        SizedBox(height: PanAfricanSpacing.sm),
        Row(
          key: const Key('pg-skel-grid'),
          children: [
            tile(),
            SizedBox(width: PanAfricanSpacing.sm),
            tile(),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Row(
          children: [
            tile(),
            SizedBox(width: PanAfricanSpacing.sm),
            tile(),
          ],
        ),
      ],
    );
    return Semantics(
      key: const Key('pg-loading'),
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          child: content,
          builder: (context, child) {
            if (!_c.isAnimating) return child!;
            final x = -1.0 + 3.0 * _c.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x, 0),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ).createShader(r),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
