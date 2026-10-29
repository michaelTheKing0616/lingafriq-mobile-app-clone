import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/screens/tabs_view/home/home_parts.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/utils/games_prefetch_language.dart';
import 'package:lingafriq/widgets/points_and_profile_image_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/change_password_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/suggest_language_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/dialog_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/pan_african_design_system.dart';
import 'delete_account_dialogue.dart';

/// Wallet balances shown on the profile (overridable in tests).
final profileWalletProvider = Provider.autoDispose<(int, int, int)>((ref) {
  final g = ref.watch(gamificationProvider.notifier).gamification;
  return (g.ngwenya, g.cowries, g.ancestralBeads);
});

/// Connectivity for the profile's offline note (overridable in tests).
final profileOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

/// Profile (profile-progress pack 01/10: art header with name and actions,
/// handle line, Overview 2x2 stats, then grouped account rows). The header
/// wears the learner's language identity (palette + motif from Home).
class ProfileTab extends HookConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final user = ref.watch(userProvider);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    // null = not tried yet, true = fetching, false = fetch failed.
    final fetching = useState<bool?>(null);
    Future<void> load() async {
      fetching.value = true;
      try {
        await ref.read(userProvider.notifier).refreshUser();
      } catch (_) {
        // Fall through to the error state below.
      }
      if (context.mounted) fetching.value = false;
    }

    useEffect(() {
      if (user == null) Future.microtask(load);
      return null;
    }, const []);

    final Widget body;
    if (user == null && fetching.value == false) {
      body = Center(
        key: const Key('profile-error'),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: PanAfricanErrorState(
            title: l.profErrorTitle,
            description: l.profErrorBody,
            retryLabel: l.profRetry,
            onRetry: load,
          ),
        ),
      );
    } else if (user == null) {
      body = _ProfileSkeleton(label: l.profLoading);
    } else {
      body = _ProfileBody(user: user);
    }
    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: body,
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});
  final ProfileModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final private = tier == 'child' || tier == 'teen';
    final online = ref.watch(profileOnlineProvider).value ?? true;
    final wallet = ref.watch(profileWalletProvider);
    final slug = learningLanguageSlug(user.learningLanguage);
    final langName = slug == null
        ? null
        : (languageIdentity(slug).native ??
              '${slug[0].toUpperCase()}${slug.substring(1)}');
    final m = PanAfricanSpacing.md;
    final bigText = MediaQuery.textScalerOf(context).scale(10) > 13;
    final name = [
      user.first_name,
      user.last_name,
    ].where((s) => s.trim().isNotEmpty).join(' ');

    void open(Widget w) => ref.read(navigationProvider).navigateTo(w);

    final stats = <_Stat>[
      _Stat(
        Icons.local_fire_department_rounded,
        const Color(0xFFB4401A),
        user.streak > 0 ? l.profStreakDays(user.streak) : l.profStreakZero,
        l.profStreakLabel,
      ),
      _Stat(
        Icons.bolt_rounded,
        const Color(0xFF8C5A00),
        l.profXpValue(user.completed_point),
        l.profXpLabel,
      ),
      private
          ? _Stat(
              Icons.lock_rounded,
              scheme.onSurfaceVariant,
              l.profPrivateValue,
              l.profRankLabel,
              key: const Key('profile-private'),
            )
          : _Stat(
              Icons.emoji_events_rounded,
              PanAfricanColors.primary,
              user.rank == null ? l.profRankNone : l.profRankValue(user.rank!),
              l.profRankLabel,
              onTap: () => ref.read(tabIndexProvider.notifier).setIndex(2),
              a11yHint: l.profOpenLeaderboard,
              key: const Key('profile-rank'),
            ),
      _Stat(
        Icons.school_rounded,
        const Color(0xFF6A3FA0),
        (user.level ?? '').trim().isEmpty ? l.profLevelNone : user.level!,
        l.profLevelLabel,
      ),
    ];

    Widget section(String title) => Padding(
      padding: EdgeInsets.only(
        top: PanAfricanSpacing.lg,
        bottom: PanAfricanSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: PanAfricanTypography.labelLarge(context).copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            name: name.isEmpty ? user.username : name,
            slug: slug,
            onEdit: () => open(const ProfileEditScreen()),
            editLabel: l.profEdit,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(m, m, m, PanAfricanSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      [
                        '\u2066@${(user.global_id ?? '').trim().isNotEmpty ? user.global_id : user.username}\u2069',
                        if (langName != null) l.profLearning(langName),
                      ].join(' · ').toUpperCase(),
                      key: const Key('profile-handle'),
                      style: PanAfricanTypography.labelLarge(context).copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (!online) ...[
                      SizedBox(height: PanAfricanSpacing.sm),
                      _Note(
                        key: const Key('profile-offline'),
                        icon: Icons.cloud_off_rounded,
                        text: l.profOffline,
                      ),
                    ],
                    section(l.profOverview),
                    _StatsGrid(stats: stats, oneColumn: bigText),
                    if (private) ...[
                      SizedBox(height: PanAfricanSpacing.xs),
                      _Note(
                        icon: Icons.shield_rounded,
                        text: l.profPrivateHint,
                      ),
                    ],
                    section(l.profWallet),
                    _Wallet(
                      items: [
                        (
                          Icons.toll_rounded,
                          const Color(0xFF8C5A00),
                          wallet.$1,
                          l.profNgwenya,
                        ),
                        (
                          Icons.spa_rounded,
                          const Color(0xFFB4401A),
                          wallet.$2,
                          l.profCowries,
                        ),
                        (
                          Icons.diamond_rounded,
                          const Color(0xFF6A3FA0),
                          wallet.$3,
                          l.profBeads,
                        ),
                      ],
                      oneColumn: bigText,
                    ),
                    section(l.profAccount),
                    _Group(
                      rows: [
                        _Row(
                          Icons.edit_rounded,
                          l.profEdit,
                          () => open(const ProfileEditScreen()),
                        ),
                        _Row(
                          Icons.lock_reset_rounded,
                          l.profChangePassword,
                          () => open(const ChangePasswordScreen()),
                        ),
                        _Row(
                          Icons.forum_rounded,
                          l.profFeedback,
                          () => open(const SuggestLanguageScreen()),
                        ),
                        _Row(
                          Icons.diversity_3_rounded,
                          l.profAbout,
                          () => kLaunchUrl('${EnvConfig.appWebUrl}/#about-us'),
                        ),
                        _Row(
                          Icons.privacy_tip_rounded,
                          l.profPolicy,
                          () => kLaunchUrl(
                            '${EnvConfig.appWebUrl}/app-policy.html',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    _Group(
                      rows: [
                        _Row(
                          Icons.delete_forever_rounded,
                          l.profDelete,
                          () => _deleteAccount(context, ref, l.profDeleted),
                          danger: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _deleteAccount(
  BuildContext context,
  WidgetRef ref,
  String doneTitle,
) async {
  final result = await DeleteAccountDialog.showDeleteAccountDialog(context);
  if (result != true || !context.mounted) return;
  final typedPassword = await EnterPasswordDialog.show(context);
  if (typedPassword == null || typedPassword.isEmpty) return;
  final deleteResult = await ref.read(apiProvider.notifier).deleteUser({
    "current_password": typedPassword,
  });
  if (deleteResult != true) return;
  await ref.read(dialogProvider("")).showPlatformDialogue(title: doneTitle);
  ref.read(authProvider.notifier).signOut(deleteAccount: true);
}

/// Language-identity header: base colour gradient with its code-drawn motif,
/// name at the top, edit action, and the avatar on a cream disc.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.slug,
    required this.onEdit,
    required this.editLabel,
  });
  final String name;
  final String? slug;
  final VoidCallback onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final id = languageIdentity(slug ?? 'lingafriq');
    final base = slug == null ? PanAfricanColors.primary : id.base;
    final avatar = (MediaQuery.sizeOf(context).width * 0.30).clamp(96.0, 148.0);
    return DecoratedBox(
      key: const Key('profile-header'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [base, Color.lerp(base, Colors.black, 0.25)!],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: ClipRect(
                child: CustomPaint(painter: MotifPainter(id.motif, id.accent)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                PanAfricanSpacing.md,
                PanAfricanSpacing.sm,
                PanAfricanSpacing.xs,
                PanAfricanSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                          child: Semantics(
                            header: true,
                            child: Text(
                              name,
                              key: const Key('profile-name'),
                              style: PanAfricanTypography.headlineSmall(context)
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('profile-edit'),
                        tooltip: editLabel,
                        onPressed: onEdit,
                        constraints: const BoxConstraints(
                          minWidth: AdaptiveLayout.minTouchTarget,
                          minHeight: AdaptiveLayout.minTouchTarget,
                        ),
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kHeaderAvatarDisc,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    // Decorative: the name above already labels the header.
                    child: ExcludeSemantics(
                      child: ProfileImageBuilder(
                        size: Size(avatar, avatar),
                        showEditIcon: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(
    this.icon,
    this.color,
    this.value,
    this.label, {
    this.onTap,
    this.a11yHint,
    this.key,
  });
  final IconData icon;
  final Color color;
  final String value, label;
  final VoidCallback? onTap;
  final String? a11yHint;
  final Key? key;
}

/// Pack 01/10 "Overview": bordered 2x2 tiles, icon + big value + small label.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.oneColumn});
  final List<_Stat> stats;
  final bool oneColumn;

  @override
  Widget build(BuildContext context) {
    final gap = PanAfricanSpacing.xs;
    Widget tile(_Stat s) => _StatTile(stat: s);
    if (oneColumn) {
      return Column(
        children: [
          for (final s in stats) ...[tile(s), SizedBox(height: gap)],
        ],
      );
    }
    return Column(
      children: [
        for (var r = 0; r < stats.length; r += 2) ...[
          if (r > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(stats[r])),
                SizedBox(width: gap),
                Expanded(child: tile(stats[r + 1])),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = stat;
    final content = Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      child: Row(
        children: [
          Icon(s.icon, color: s.color, size: 28.sp),
          SizedBox(width: PanAfricanSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.value,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  s.label,
                  style: PanAfricanTypography.bodySmall(
                    context,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (s.onTap != null)
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
    return Semantics(
      key: s.key,
      button: s.onTap != null,
      hint: s.a11yHint,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AdaptiveLayout.minTouchTarget + 16,
          ),
          child: s.onTap == null
              ? content
              : InkWell(onTap: s.onTap, child: content),
        ),
      ),
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.items, required this.oneColumn});
  final List<(IconData, Color, int, String)> items;
  final bool oneColumn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell((IconData, Color, int, String) i) => MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
        child: Column(
          children: [
            Icon(i.$1, color: i.$2, size: 24.sp),
            SizedBox(height: PanAfricanSpacing.xxs),
            Text(
              '${i.$3}',
              style: PanAfricanTypography.titleMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
            ),
            Text(
              i.$4,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodySmall(
                context,
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
    return DecoratedBox(
      key: const Key('profile-wallet'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: oneColumn
          ? Column(children: [for (final i in items) cell(i)])
          : Row(
              children: [
                for (final (n, i) in items.indexed) ...[
                  if (n > 0)
                    SizedBox(
                      height: 40,
                      child: VerticalDivider(color: scheme.outlineVariant),
                    ),
                  Expanded(child: cell(i)),
                ],
              ],
            ),
    );
  }
}

class _Row {
  const _Row(this.icon, this.title, this.onTap, {this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            ListTile(
              minTileHeight: 56,
              leading: Icon(
                r.icon,
                color: r.danger ? scheme.error : PanAfricanColors.primary,
              ),
              title: Text(
                r.title,
                style: PanAfricanTypography.bodyLarge(context).copyWith(
                  color: r.danger ? scheme.error : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onTap: r.onTap,
            ),
          ],
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

/// Loading: the real layout in quiet placeholder blocks (no spinner jump).
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final block = scheme.surfaceContainerHighest;
    Widget box(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Semantics(
      key: const Key('profile-loading'),
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(height: 220, color: PanAfricanColors.primary),
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  box(16),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: box(72)),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Expanded(child: box(72)),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: box(72)),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Expanded(child: box(72)),
                    ],
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

class ProfileDetailsBuilder extends ConsumerWidget {
  final CrossAxisAlignment? crossAxisAlignment;
  const ProfileDetailsBuilder({super.key, this.crossAxisAlignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        // if (user?.rank.toString().isNotEmpty ?? false)
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        //     decoration: BoxDecoration(
        //       color: Colors.white.withOpacity(0.20),
        //       borderRadius: BorderRadius.circular(100),
        //     ),
        //     child: (user?.rank.toString().firstLetterUpperCase() ?? "Beginner").text.make(),
        //   ),
        if (user != null)
          user.username.text.color(context.adaptive).xl3.semiBold.make(),
        4.heightBox,
        if (user != null) user.email.text.color(context.adaptive).lg.make(),
        8.heightBox,
      ],
    ).pOnly(right: 12);
  }
}

class ProfileImageBuilder extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool showEditIcon;
  final Size? size;
  const ProfileImageBuilder({
    super.key,
    this.onTap,
    this.showEditIcon = true,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final current = kAvatarsList.containsKey(user?.avatar)
        ? kAvatarsList[user?.avatar]!
        : kAvatarsList.values.first;

    return Container(
      width: size?.width ?? 0.3.sw,
      height: size?.height ?? 0.3.sw,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.adaptive12,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(1000),
            child: Image.asset(
              current,
              width: 0.3.sw,
              height: 0.3.sw,
              // Until the avatar decodes (or if it fails) show the learner's
              // initial instead of an empty ring.
              frameBuilder: (context, child, frame, sync) =>
                  sync || frame != null ? child : _initial(context, user),
              errorBuilder: (context, _, __) => _initial(context, user),
            ),
          ).p8(),
          if (showEditIcon)
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: PanAfricanColors.tertiary,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _initial(BuildContext context, ProfileModel? user) {
  final first = (user?.first_name ?? '').trim();
  final name = first.isNotEmpty ? first : (user?.username ?? '').trim();
  return Container(
    key: const Key('avatar-initial'),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: PanAfricanColors.secondary,
    ),
    child: FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(6),
        // No name yet (signed out / still loading): a person glyph, never
        // a bare "?".
        child: name.isEmpty
            ? const Icon(
                Icons.person_rounded,
                key: Key('avatar-initial-glyph'),
                size: 28,
                color: PanAfricanColors.neutralDarkest,
              )
            : Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: PanAfricanColors.neutralDarkest,
                ),
              ),
      ),
    ),
  );
}
