import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/api_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skeleton_loader.dart';

/// Ancestral Tree - Visualize everyone you've helped
class AncestralTreeScreen extends ConsumerWidget {
  const AncestralTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<_AncestrySnapshot>(
      future: _loadTreeData(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
            appBar: AppBar(
              title: const Text('Ancestral Tree'),
              backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
              elevation: 0,
              leading: Semantics(
                label: 'Back',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            body: ListView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              children: List.generate(5, (_) => const SkeletonListCard()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
            appBar: AppBar(
              title: const Text('Ancestral Tree'),
              backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
              elevation: 0,
              leading: Semantics(
                label: 'Back',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            body: AppErrorState(
              message: 'Failed to load ancestry graph',
              onRetry: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AncestralTreeScreen()),
                );
              },
            ),
          );
        }

        final data = snapshot.data ?? _AncestrySnapshot.empty();

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Ancestral Tree'),
        backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
          icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        ),
        actions: [
          Semantics(
            label: 'About Ancestral Tree',
            button: true,
            child: IconButton(
            icon: const Icon(Icons.info_outline, semanticLabel: 'Info'),
            onPressed: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: PanAfricanRadius.lgBR,
                  ),
                  title: Text(
                    'Ancestral Tree',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  content: Text(
                    'This tree shows everyone you\'ve helped learn African languages. '
                    'Each person you gift lessons to or help appears here. '
                    'Watch your tree grow as you share knowledge!',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Got it',
                        style: TextStyle(color: PanAfricanColors.primary),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.forest,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Mentees',
                    value: '${data.mentees.length}',
                    icon: Icons.people,
                  ),
                  _StatItem(
                    label: 'Mentors',
                    value: '${data.mentors.length}',
                    icon: Icons.school,
                  ),
                  _StatItem(
                    label: 'Connections',
                    value: '${data.mentors.length + data.mentees.length}',
                    icon: Icons.hub,
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Tree visualization
            Text(
              'Your Ancestral Tree',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            if (data.mentors.isEmpty && data.mentees.isEmpty)
              AppEmptyState(
                icon: Icons.nature_people_rounded,
                title: 'No ancestry links yet',
                subtitle: 'As you connect with mentors or help other learners, your tree will grow here.',
              )
            else ...[
              if (data.mentors.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.school, size: 18.sp, color: PanAfricanColors.primary),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      'Mentors',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                ...data.mentors.map((person) => _TreeNodeCard(person: person)),
                SizedBox(height: PanAfricanSpacing.md),
              ],
              if (data.mentees.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.people, size: 18.sp, color: PanAfricanColors.primary),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      'Mentees',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                ...data.mentees.map((person) => _TreeNodeCard(person: person)),
              ],
            ],
          ],
        ),
      ),
    );
      },
    );
  }

  Future<_AncestrySnapshot> _loadTreeData(WidgetRef ref) async {
    final api = ref.read(apiProvider.notifier);
    final raw = await api.getAncestryMe();

    final mentorsRaw = (raw['mentors'] is List) ? (raw['mentors'] as List) : const [];
    final menteesRaw = (raw['mentees'] is List) ? (raw['mentees'] as List) : const [];

    List<_TreePerson> parsePeople(List rows, {required String kind, required String key}) {
      final out = <_TreePerson>[];
      for (final r in rows) {
        if (r is! Map) continue;
        final person = r[key];
        if (person is! Map) continue;
        out.add(
          _TreePerson(
            kind: kind,
            username: (person['username'] ?? person['global_id'] ?? 'Unknown').toString(),
            globalId: person['global_id']?.toString(),
            avatar: (person['avatar'] ?? person['avater'])?.toString(),
          ),
        );
      }
      return out;
    }

    return _AncestrySnapshot(
      mentors: parsePeople(mentorsRaw, kind: 'Mentor', key: 'mentor_id'),
      mentees: parsePeople(menteesRaw, kind: 'Mentee', key: 'mentee_id'),
    );
  }
}

class _TreePerson {
  final String kind; // Mentor | Mentee
  final String username;
  final String? avatar;
  final String? globalId;

  _TreePerson({
    required this.kind,
    required this.username,
    this.avatar,
    this.globalId,
  });
}

class _AncestrySnapshot {
  final List<_TreePerson> mentors;
  final List<_TreePerson> mentees;

  const _AncestrySnapshot({required this.mentors, required this.mentees});

  factory _AncestrySnapshot.empty() => const _AncestrySnapshot(mentors: [], mentees: []);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withOpacity(0.2),
            borderRadius: PanAfricanRadius.mdBR,
          ),
          child: Icon(icon, color: colorScheme.onPrimary, size: 20.sp),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          value,
          style: PanAfricanTypography.titleLarge(context).copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          style: PanAfricanTypography.labelLarge(context).copyWith(
            color: colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _TreeNodeCard extends StatelessWidget {
  final _TreePerson person;

  const _TreeNodeCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.selectionClick();
        },
        contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
        leading: CircleAvatar(
          radius: 24.w,
          backgroundColor: PanAfricanColors.primary,
          child: Text(
            person.username[0].toUpperCase(),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        title: Text(
          person.username,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: PanAfricanSpacing.xs),
            Wrap(
              spacing: PanAfricanSpacing.sm,
              runSpacing: PanAfricanSpacing.xs,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.sm,
                    vertical: PanAfricanSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: PanAfricanRadius.roundBR,
                  ),
                  child: Text(
                    person.kind,
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      color: PanAfricanColors.primary,
                    ),
                  ),
                ),
                if (person.globalId != null && person.globalId!.trim().isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.sm,
                      vertical: PanAfricanSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.textSecondary.withOpacity(0.1),
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      '@${person.globalId}',
                      style: PanAfricanTypography.labelLarge(context).copyWith(
                        color: PanAfricanColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

