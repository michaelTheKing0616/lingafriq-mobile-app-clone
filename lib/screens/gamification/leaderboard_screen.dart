import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/leaderboard_entry_model.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/leaderboard_provider.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/gamification/tribe_selection_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider;
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/widgets/bidi_text.dart';

/// Device reachability; turns a fetch failure into the offline panel.
final leaderboardOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

const _navy = Color(0xFF2E3A87);
const _navyDeep = Color(0xFF1F2766);
const _gold = Color(0xFFFFC53D);
const _ink = Color(0xFF1F2340);
const _muted = Color(0xFF5B607A);
const _line = Color(0xFFE3E5EF);
const _up = Color(0xFF1B7F4B);
const _down = Color(0xFFB3261E);
const _medals = [Color(0xFFFFC53D), Color(0xFFB8C0CC), Color(0xFFD08A4E)];
const _discs = [
  Color(0xFF1B7F4B),
  Color(0xFF8C3B9E),
  Color(0xFF0B6E99),
  Color(0xFFB4462B),
  Color(0xFF6B5B00),
  Color(0xFF2E3A87),
];

/// Weekly leaderboard (social-circles 08/09/13, profile-progress 04):
/// scope chips, a champion hero with rays, a ranked list with medals and
/// rank movement, and your own row pinned at the bottom. Friendly, not
/// cut-throat: a weekly reset note, and minors never see or show names.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardType _type = LeaderboardType.global;
  bool _subscribed = false;

  String? get _tribe {
    final t = ref.read(gamificationProvider.notifier).gamification.tribe;
    return (t != null && t.trim().isNotEmpty) ? t : null;
  }

  String? get _country {
    final c = ref.read(userProvider)?.nationality;
    return (c != null && c.trim().isNotEmpty) ? c : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetch(LeaderboardType.global);
      final user = ref.read(userProvider);
      if (user != null) {
        ref.read(leaderboardProvider.notifier).fetchUserRanks('${user.id}');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribed || ref.read(userProvider) == null) return;
    _subscribed = true;
    final socket = ref.read(socketServiceProvider);
    socket.subscribeToLeaderboard('global:weekly');
    socket.onLeaderboardUpdate((_) {
      if (mounted) {
        ref
            .read(leaderboardProvider.notifier)
            .refresh(type: LeaderboardType.global);
      }
    });
  }

  Future<void> _fetch(LeaderboardType t) {
    final tribe = t == LeaderboardType.tribe ? _tribe : null;
    final country = t == LeaderboardType.country ? _country : null;
    if ((t == LeaderboardType.tribe && tribe == null) ||
        (t == LeaderboardType.country && country == null)) {
      return Future.value();
    }
    return ref
        .read(leaderboardProvider.notifier)
        .fetchLeaderboards(type: t, tribe: tribe, country: country);
  }

  Future<void> _refresh() {
    ref.invalidate(leaderboardOnlineProvider);
    final t = _type;
    return ref
        .read(leaderboardProvider.notifier)
        .refresh(
          type: t,
          tribe: t == LeaderboardType.tribe ? _tribe : null,
          country: t == LeaderboardType.country ? _country : null,
        );
  }

  void _select(LeaderboardType t) {
    if (t == _type) return;
    HapticFeedback.selectionClick();
    setState(() => _type = t);
    _fetch(t);
  }

  void _maybeLoadMore() {
    final n = ref.read(leaderboardProvider.notifier);
    final tribe = _type == LeaderboardType.tribe ? _tribe : null;
    final country = _type == LeaderboardType.country ? _country : null;
    if (!n.hasMore(type: _type, tribe: tribe, country: country)) return;
    if (n.isLoadingMore(type: _type, tribe: tribe, country: country)) return;
    n.loadMoreLeaderboard(type: _type, tribe: tribe, country: country);
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final state = ref.watch(leaderboardProvider);
    final n = ref.watch(leaderboardProvider.notifier);
    ref.watch(gamificationProvider);
    final user = ref.watch(userProvider);
    final online = ref.watch(leaderboardOnlineProvider).value ?? true;
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final child = tier == 'child';
    final minor = child || tier == 'teen';
    final me = user == null ? null : '${user.id}';

    final entries = switch (_type) {
      LeaderboardType.tribe => n.getTribeLeaderboard(_tribe ?? ''),
      LeaderboardType.country => n.getCountryLeaderboard(_country ?? ''),
      _ => n.getGlobalLeaderboard(),
    };

    Widget body;
    var showBoard = false;
    if (_type == LeaderboardType.tribe && _tribe == null) {
      body = _Panel(
        key: const Key('lb-no-tribe'),
        icon: Icons.groups_rounded,
        title: l.lbNoTribeTitle,
        body: l.lbNoTribeBody,
        action: l.lbPickTribe,
        actionKey: const Key('lb-pick-tribe'),
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TribeSelectionScreen()),
        ),
      );
    } else if (_type == LeaderboardType.country && _country == null) {
      body = _Panel(
        key: const Key('lb-no-country'),
        icon: Icons.public_rounded,
        title: l.lbNoCountryTitle,
        body: l.lbNoCountryBody,
      );
    } else if (entries.isEmpty && state.isLoading) {
      body = _Skeleton(label: l.lbLoading);
    } else if (entries.isEmpty && state.errorMessage != null) {
      body = _Panel(
        key: Key(online ? 'lb-error' : 'lb-offline'),
        icon: online ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
        title: online ? l.lbErrorTitle : l.lbOfflineTitle,
        body: online ? l.lbErrorBody : l.lbOfflineBody,
        action: l.lbRetry,
        actionKey: const Key('lb-retry'),
        onAction: _refresh,
      );
    } else if (entries.isEmpty) {
      body = _Panel(
        key: const Key('lb-empty'),
        icon: Icons.emoji_events_outlined,
        title: l.lbEmptyTitle,
        body: l.lbEmptyBody,
      );
    } else {
      showBoard = true;
      final tribe = _type == LeaderboardType.tribe ? _tribe : null;
      final country = _type == LeaderboardType.country ? _country : null;
      final loadingMore = n.isLoadingMore(
        type: _type,
        tribe: tribe,
        country: country,
      );
      String name(LeaderboardEntry e) {
        if (e.userId == me) return l.lbYou;
        return child ? l.lbLearner(e.rank) : e.username;
      }

      body = NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.pixels >= s.metrics.maxScrollExtent - 240) {
            _maybeLoadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          color: _navy,
          onRefresh: _refresh,
          child: ListView(
            key: Key('lb-list-${_type.name}'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _Champion(entry: entries.first, name: name(entries.first)),
              _narrow(
                Column(
                  children: [
                    if (!online)
                      _Note(
                        key: const Key('lb-offline-note'),
                        icon: Icons.wifi_off_rounded,
                        text: l.lbOfflineBody,
                      ),
                    if (minor)
                      _Note(
                        key: const Key('lb-minor-note'),
                        icon: Icons.lock_rounded,
                        text: child ? l.lbMinorChild : l.lbMinorTeen,
                      ),
                    _Note(
                      key: const Key('lb-friendly'),
                      icon: Icons.favorite_border_rounded,
                      text: l.lbFriendly,
                    ),
                    if (MediaQuery.textScalerOf(context).scale(10) <= 15)
                      const _ColumnHeader(),
                    for (final e in entries)
                      _RankRow(
                        entry: e,
                        name: name(e),
                        isMe: e.userId == me,
                        discName: e.userId == me ? user?.username : null,
                      ),
                  ],
                ),
              ),
              if (loadingMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Semantics(
                      label: l.lbMore,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final mine = entries.where((e) => e.userId == me).firstOrNull;
    final ranks = n.userRanks?['global:weekly'];
    final myRank = mine?.rank ?? (ranks?['rank'] as num?)?.toInt();
    final myXp = mine?.xp ?? (ranks?['score'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('lb-back'),
          tooltip: l.lbBack,
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l.lbTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _Scopes(
            type: _type,
            onSelect: _select,
            labels: [l.lbGlobal, l.lbTribe, l.lbCountry],
          ),
          Expanded(child: showBoard ? body : _narrow(body)),
          if (me != null && showBoard)
            _MeBar(
              rank: myRank,
              xp: myXp,
              label: l.lbYou,
              initial: (user?.username ?? 'Y'),
              seed: me,
            ),
        ],
      ),
    );
  }
}

/// Tablet: keep reading width; the navy hero and bars stay full-bleed.
Widget _narrow(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: child,
  ),
);

class _Scopes extends StatelessWidget {
  const _Scopes({
    required this.type,
    required this.onSelect,
    required this.labels,
  });
  final LeaderboardType type;
  final ValueChanged<LeaderboardType> onSelect;
  final List<String> labels;

  static const _types = [
    LeaderboardType.global,
    LeaderboardType.tribe,
    LeaderboardType.country,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navy,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, t) in _types.indexed)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Semantics(
                  selected: t == type,
                  button: true,
                  child: ChoiceChip(
                    key: Key('lb-tab-${t.name}'),
                    label: Text(labels[i]),
                    selected: t == type,
                    showCheckmark: false,
                    onSelected: (_) => onSelect(t),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: t == type ? _navyDeep : Colors.white,
                    ),
                    backgroundColor: _navy,
                    selectedColor: _gold,
                    side: BorderSide(color: t == type ? _gold : Colors.white70),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Champion extends StatelessWidget {
  const _Champion({required this.entry, required this.name});
  final LeaderboardEntry entry;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final compact = MediaQuery.textScalerOf(context).scale(10) > 15;
    if (compact) {
      return Container(
        key: const Key('lb-champion'),
        color: _navy,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Row(
          children: [
            _Disc(name: name, seed: entry.userId, size: 48, ring: _gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BidiText(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l.lbXp(entry.xp),
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      key: const Key('lb-champion'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Semantics(
        container: true,
        label: '${l.lbLeader}: $name, ${l.lbXp(entry.xp)}',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(
                l.lbLeader,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 150,
                height: 96,
                child: CustomPaint(
                  painter: _RaysPainter(),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _Disc(
                            name: name,
                            seed: entry.userId,
                            size: 72,
                            ring: _gold,
                          ),
                        ),
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: _gold,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              BidiText(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.lbXp(entry.xp),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 8);
    final p = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final side in [-1, 1]) {
      for (var i = -2; i <= 2; i++) {
        final a = (side == 1 ? 0 : math.pi) + i * 0.32;
        final r1 = 50.0, r2 = 66.0;
        canvas.drawLine(
          c + Offset(math.cos(a) * r1, math.sin(a) * r1 * 0.8),
          c + Offset(math.cos(a) * r2, math.sin(a) * r2 * 0.8),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.name,
    required this.seed,
    required this.size,
    this.ring,
  });
  final String name, seed;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final color = _discs[seed.hashCode.abs() % _discs.length];
    final t = name.trim();
    final initial = t.isEmpty ? '?' : t.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ring ?? Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F5FA),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _navy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: _ink)),
        ),
      ],
    ),
  );
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    const s = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: _muted,
      letterSpacing: 0.6,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Row(
          children: [
            SizedBox(width: 44, child: Text(l.lbColRank, style: s)),
            const SizedBox(width: 52),
            Expanded(child: Text(l.lbColLearner, style: s)),
            Text(l.lbColXp, style: s),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.name,
    required this.isMe,
    this.discName,
  });
  final LeaderboardEntry entry;
  final String name;
  final String? discName;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final prev = entry.previousRank;
    final delta = prev == null ? 0 : prev - entry.rank;
    final move = delta > 0
        ? l.lbUp(delta)
        : delta < 0
        ? l.lbDown(-delta)
        : null;
    final medal = entry.rank <= 3 ? _medals[entry.rank - 1] : null;
    final compact = MediaQuery.textScalerOf(context).scale(10) > 15;
    return Semantics(
      container: true,
      label: [l.lbRankN(entry.rank), name, l.lbXp(entry.xp), ?move].join(', '),
      child: ExcludeSemantics(
        child: Container(
          key: Key('lb-row-${entry.userId}'),
          constraints: const BoxConstraints(minHeight: 64),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFFF4D6) : null,
            borderRadius: BorderRadius.circular(14),
            border: const Border(bottom: BorderSide(color: _line)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Center(
                  child: medal != null
                      ? Icon(
                          entry.rank == 1
                              ? Icons.workspace_premium_rounded
                              : Icons.military_tech_rounded,
                          color: medal,
                          size: 28,
                        )
                      : Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _muted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              if (!compact) ...[
                _Disc(name: discName ?? name, seed: entry.userId, size: 44),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (compact)
                      Text(
                        l.lbXp(entry.xp),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _ink,
                        ),
                      )
                    else if (entry.dailyStreak > 0)
                      Text(
                        l.lbStreak(entry.dailyStreak),
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 8),
              if (!compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l.lbXp(entry.xp),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _ink,
                      ),
                    ),
                    if (delta != 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            delta > 0
                                ? Icons.arrow_drop_up_rounded
                                : Icons.arrow_drop_down_rounded,
                            color: delta > 0 ? _up : _down,
                            size: 22,
                          ),
                          Text(
                            '${delta.abs()}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: delta > 0 ? _up : _down,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeBar extends StatelessWidget {
  const _MeBar({
    required this.rank,
    required this.xp,
    required this.label,
    required this.initial,
    required this.seed,
  });
  final String seed;
  final int? rank;
  final int xp;
  final String label, initial;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final ranked = rank != null && rank! > 0;
    final compact = MediaQuery.textScalerOf(context).scale(10) > 15;
    return Container(
      key: const Key('lb-me'),
      decoration: const BoxDecoration(
        color: _navy,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (!compact) ...[
                _Disc(name: initial, seed: seed, size: 40, ring: _gold),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  ranked ? l.lbYourRank(rank!) : l.lbUnranked,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (ranked) ...[
                const SizedBox(width: 8),
                Text(
                  l.lbXp(xp),
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.actionKey,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? action;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFFEDEFF8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: _navy),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: _muted),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          FilledButton(
            key: actionKey,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              minimumSize: const Size(200, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onAction,
            child: Text(action!),
          ),
        ],
      ],
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, {Color c = _line}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      key: const Key('lb-loading'),
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(
              height: 190,
              decoration: const BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A559E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  bar(120, 16, c: const Color(0xFF4A559E)),
                  const SizedBox(height: 8),
                  bar(60, 12, c: const Color(0xFF4A559E)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    bar(24, 16),
                    const SizedBox(width: 20),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _line,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: bar(130, 14),
                      ),
                    ),
                    bar(50, 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
