import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';

/// Family hub entries: group approvals, messaging guide, circles, and per-learner
/// "who is messaging" views, as a 2-column grid (a single column at large
/// text sizes). Uses the named routes registered in `my_app.dart`.
/// Reference pack: docs/design/references/family-hub ("Family tools" grid).
class FamilyToolsSection extends StatelessWidget {
  const FamilyToolsSection({
    super.key,
    required this.activeChildIds,
    this.childNames = const {},
    this.pendingApprovals = 0,
  });

  final List<int> activeChildIds;

  /// Real names by learner id (from the guardian's links); never "Learner #id".
  final Map<int, String> childNames;

  /// Requests waiting for this guardian; shown as a badge on Approvals.
  final int pendingApprovals;

  static const routeApprovals = '/guardian-approvals';
  static const routeGuide = '/guardian-messaging-guide';
  static const routeCircles = '/village-circles';
  static const routeChildMessages = '/guardian-child-messages';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tiles = <Widget>[
      _ToolTile(
        key: const ValueKey('family-tools-approvals'),
        icon: Icons.verified_user_outlined,
        title: l.gfamToolsApprovals,
        sub: l.gfamToolsApprovalsSub,
        badge: pendingApprovals,
        onTap: () => Navigator.of(context).pushNamed(routeApprovals),
      ),
      for (final id in activeChildIds)
        _ToolTile(
          key: ValueKey('family-tools-messages-$id'),
          icon: Icons.forum_outlined,
          title: childNames[id] == null
              ? l.gfamWhoMessagesYours
              : l.gfamWhoMessagesName(childNames[id]!),
          onTap: () => Navigator.of(context).pushNamed(
            routeChildMessages,
            arguments: {
              'childUserId': id,
              if (childNames[id] != null) 'childName': childNames[id],
            },
          ),
        ),
      _ToolTile(
        key: const ValueKey('family-tools-guide'),
        icon: Icons.shield_outlined,
        title: l.gfamToolsGuide,
        sub: l.gfamToolsGuideSub,
        onTap: () => Navigator.of(context).pushNamed(routeGuide),
      ),
      _ToolTile(
        key: const ValueKey('family-tools-circles'),
        icon: Icons.groups_outlined,
        title: l.gfamToolsCircles,
        sub: l.gfamToolsCirclesSub,
        onTap: () => Navigator.of(context).pushNamed(routeCircles),
      ),
    ];

    return Column(
      key: const ValueKey('family-tools'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            l.gfamToolsTitle,
            style: LingAfriqFonts.displayStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
            final cols = big || c.maxWidth < 300 ? 1 : 2;
            if (cols == 1) {
              return Column(
                key: const ValueKey('family-tools-list'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final t in tiles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: t,
                    ),
                ],
              );
            }
            return Column(
              key: const ValueKey('family-tools-grid'),
              children: [
                for (var i = 0; i < tiles.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tiles[i]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: i + 1 < tiles.length
                                ? tiles[i + 1]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.badge = 0,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: [title, ?sub, if (badge > 0) '$badge'].join('. '),
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: scheme.onPrimaryContainer),
                        ),
                        const Spacer(),
                        if (badge > 0)
                          Container(
                            key: const ValueKey('family-tools-badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$badge',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
