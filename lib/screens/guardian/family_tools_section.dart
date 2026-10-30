import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Family hub entries: group approvals, messaging guide, circles, and per-learner
/// "who is messaging" views. Uses the named routes registered in `my_app.dart`.
class FamilyToolsSection extends StatelessWidget {
  const FamilyToolsSection({
    super.key,
    required this.activeChildIds,
    this.childNames = const {},
  });

  final List<int> activeChildIds;

  /// Real names by learner id (from the guardian's links); never "Learner #id".
  final Map<int, String> childNames;

  static const routeApprovals = '/guardian-approvals';
  static const routeGuide = '/guardian-messaging-guide';
  static const routeCircles = '/village-circles';
  static const routeChildMessages = '/guardian-child-messages';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget tile({
      required Key key,
      required IconData icon,
      required String title,
      String? sub,
      required VoidCallback onTap,
    }) {
      return Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          minVerticalPadding: 12,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          subtitle: sub == null ? null : Text(sub),
          trailing: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    return Column(
      key: const ValueKey('family-tools'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l.gfamToolsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final id in activeChildIds)
          tile(
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
        tile(
          key: const ValueKey('family-tools-approvals'),
          icon: Icons.verified_user_outlined,
          title: l.gfamToolsApprovals,
          sub: l.gfamToolsApprovalsSub,
          onTap: () => Navigator.of(context).pushNamed(routeApprovals),
        ),
        tile(
          key: const ValueKey('family-tools-guide'),
          icon: Icons.shield_outlined,
          title: l.gfamToolsGuide,
          sub: l.gfamToolsGuideSub,
          onTap: () => Navigator.of(context).pushNamed(routeGuide),
        ),
        tile(
          key: const ValueKey('family-tools-circles'),
          icon: Icons.groups_outlined,
          title: l.gfamToolsCircles,
          sub: l.gfamToolsCirclesSub,
          onTap: () => Navigator.of(context).pushNamed(routeCircles),
        ),
      ],
    );
  }
}
