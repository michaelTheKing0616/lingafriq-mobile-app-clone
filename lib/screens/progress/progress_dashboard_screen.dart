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
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: snap.when(
          loading: () => _Skeleton(label: l.pgLoading),
          error: (_, _) => Center(
            key: const Key('pg-error'),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: PanAfricanErrorState(
                title: l.pgErrorTitle,
                description: l.pgErrorBody,
                retryLabel: l.pgRetry,
                onRetry: () => ref.invalidate(progressSnapshotProvider),
              ),
            ),
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

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget box(double h) => Container(
      height: h,
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Semantics(
      key: const Key('pg-loading'),
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [box(200), box(150), box(72), box(72)],
        ),
      ),
    );
  }
}
