import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Heritage Tree — reference: Duolingo Friends Quest tree / family progress motifs.
class HeritageTreeScreen extends ConsumerStatefulWidget {
  const HeritageTreeScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<HeritageTreeScreen> createState() => _HeritageTreeScreenState();
}

class _HeritageTreeScreenState extends ConsumerState<HeritageTreeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(gamificationProvider.notifier).refreshHeritageTree(widget.groupId),
    );
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'seed':
        return Icons.grain;
      case 'sprout':
        return Icons.eco_outlined;
      case 'sapling':
        return Icons.park_outlined;
      case 'tree':
        return Icons.forest_outlined;
      default:
        return Icons.park;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(gamificationProvider.notifier).heritageTree;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Heritage Tree', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [
            if (tree == null)
              Text('Growing your tree…', style: PanAfricanTypography.bodyMedium(context))
            else ...[
              Semantics(
                label:
                    'Heritage tree stage ${tree.stage}, ${tree.canDoCount} verified can-dos',
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _stageIcon(tree.stage),
                        size: 96.sp,
                        color: PanAfricanColors.primary,
                      ),
                      SizedBox(height: PanAfricanSpacing.md),
                      Text(
                        'Heritage Tree',
                        style: PanAfricanTypography.headlineSmall(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        '${tree.canDoCount} verified can-dos across your circle',
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.bodyLarge(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'Each branch grows when someone in your circle demonstrates a can-do with evidence — never from taps alone.',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text('Growing with you', style: PanAfricanTypography.titleSmall(context)),
              ...tree.members.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.slot),
                  trailing: m.isViewer ? const Icon(Icons.person_outline) : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
