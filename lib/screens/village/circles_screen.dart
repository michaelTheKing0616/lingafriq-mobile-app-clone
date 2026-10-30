import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/screens/chat/tribe_chat_screen.dart';
import 'package:lingafriq/screens/classroom/class_code_join_sheet.dart';

/// Village circles list. Reference pack: docs/design/references/circles (recoloured, own copy).
/// Uses the app theme text styles so it matches the screens around it.
class CirclesScreen extends HookConsumerWidget {
  const CirclesScreen({super.key, this.fetchCircles});

  /// Test seam; defaults to `GET /api/v2/circles`.
  final Future<Object?> Function()? fetchCircles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = useState<List<Map<String, dynamic>>>([]);
    final loading = useState(true);
    // Error kind: 'load' or 'offline'; text is resolved at build time.
    final error = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> load() async {
      loading.value = true;
      error.value = null;
      try {
        final data = fetchCircles != null
            ? await fetchCircles!()
            : (await ApiService.get('/api/v2/circles')).data;
        if (data is Map && data['ok'] == true && data['circles'] is List) {
          circles.value = (data['circles'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          error.value = 'load';
        }
      } catch (_) {
        error.value = 'offline';
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.backgroundDark
          : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.gcirTitle ?? 'Your circles'),
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: _body(
            context,
            loading.value,
            error.value,
            circles.value,
            load,
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    bool loading,
    String? error,
    List<Map<String, dynamic>> circles,
    Future<void> Function() reload,
  ) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    const pad = EdgeInsets.all(16);
    if (loading && circles.isEmpty) {
      // Skeleton rows at the final card height.
      return Semantics(
        key: const ValueKey('gcir-loading'),
        label: l.gcirLoading,
        liveRegion: true,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pad,
          children: List.generate(
            4,
            (_) => Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
            ),
          ),
        ),
      );
    }
    if (error != null && circles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pad,
        children: [
          Container(
            key: const ValueKey('gcir-error'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: error == 'offline'
                  ? scheme.secondaryContainer
                  : scheme.errorContainer,
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  error == 'offline'
                      ? Icons.cloud_off_outlined
                      : Icons.error_outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error == 'offline' ? l.gcirOffline : l.gcirLoadError,
                    style: text.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  reload();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l.gcirRetry),
              ),
            ),
          ),
        ],
      );
    }
    if (circles.isEmpty) {
      return ListView(
        key: const ValueKey('gcir-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              l.gcirEmptyTitle,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.gcirEmpty,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: FilledButton.icon(
              key: const ValueKey('gcir-join-code'),
              onPressed: () =>
                  ClassCodeJoinSheet.show(context, onJoined: reload),
              icon: const Icon(Icons.vpn_key_outlined),
              label: Text(l.gcirJoinWithCode),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: OutlinedButton.icon(
              key: const ValueKey('gcir-explore'),
              onPressed: () => Navigator.of(context).pushNamed('/villages'),
              icon: const Icon(Icons.explore_outlined),
              label: Text(l.gcirExplore),
            ),
          ),
        ],
      );
    }
    final palette = [
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
    ];
    final onPalette = [
      scheme.onPrimaryContainer,
      scheme.onSecondaryContainer,
      scheme.onTertiaryContainer,
    ];
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: pad,
      itemCount: circles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = circles[index];
        final name = c['name']?.toString() ?? l.gcirFallbackName;
        final status = c['status']?.toString() ?? 'draft';
        final count = (c['member_count'] as num?)?.toInt() ?? 0;
        final max = (c['max_members'] as num?)?.toInt() ?? 50;
        final minOpen = (c['min_open'] as num?)?.toInt() ?? 5;
        final id = c['id']?.toString() ?? '';
        final open = status == 'open';
        final subtitle = open
            ? l.gcirOpen(count, max)
            : status == 'full'
            ? l.gcirFull(count)
            : l.gcirOpensAt(count, minOpen);
        final pill = open
            ? l.gcirPillOpen
            : status == 'full'
            ? l.gcirPillFull
            : l.gcirPillSoon;
        final tile = palette[index % palette.length];
        final onTile = onPalette[index % onPalette.length];

        return Semantics(
          button: true,
          label: '$name, $subtitle, $pill',
          excludeSemantics: true,
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: id.isEmpty
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TribeChatScreen(
                            tribeId: id,
                            tribeName: name,
                            circleMode: true,
                          ),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tile,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        name.characters.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?',
                        style: text.titleLarge?.copyWith(
                          color: onTile,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: open
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  open
                                      ? Icons.lock_open_outlined
                                      : Icons.lock_outline,
                                  size: 16,
                                  color: open
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pill,
                                  style: text.labelMedium?.copyWith(
                                    color: open
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
