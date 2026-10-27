import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/pan_african_design_system.dart';
import '../../widgets/responsive_safe_area.dart';
import 'circle_goal_service.dart';

/// Circle co-op word goal — reference: Duolingo friend quests (collective bar, no in-circle ranks).
class CircleGoalScreen extends StatefulWidget {
  const CircleGoalScreen({
    super.key,
    required this.groupId,
    this.service,
    this.initialSnapshot,
  });

  final String groupId;
  final CircleGoalService? service;
  final CircleWordGoalSnapshot? initialSnapshot;

  @override
  State<CircleGoalScreen> createState() => _CircleGoalScreenState();
}

class _CircleGoalScreenState extends State<CircleGoalScreen> {
  CircleWordGoalSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    if (_snapshot == null) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final svc = widget.service;
    if (svc == null) {
      setState(() {
        _loading = false;
        _offline = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });
    try {
      final snap = await svc.fetchGoal(widget.groupId);
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _offline = e is StateError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bg = isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Circle word goal', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            children: [
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.lg),
                  child: Center(
                    child: Semantics(
                      label: 'Loading circle word goal',
                      child: CircularProgressIndicator(
                        strokeWidth: reduceMotion ? 2 : 3,
                      ),
                    ),
                  ),
                )
              else if (_offline)
                _messageCard(
                  context,
                  title: 'You are offline',
                  body:
                      'Circle progress syncs when you are back online. Practice words in Arcade and we will add them to your circle total.',
                  action: TextButton(onPressed: _load, child: const Text('Try again')),
                )
              else if (_error != null)
                _messageCard(
                  context,
                  title: 'Could not load goal',
                  body:
                      'Something went wrong fetching your circle total. Pull to refresh or try again in a moment.',
                  action: TextButton(onPressed: _load, child: const Text('Retry')),
                )
              else
                _readyBody(context, _snapshot!, reduceMotion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readyBody(BuildContext context, CircleWordGoalSnapshot snap, bool reduceMotion) {
    if (snap.empty) {
      return _messageCard(
        context,
        title: 'Set a circle goal',
        body:
            'Pick how many new words your circle will learn together this week. Only real learned words count — practice mode stays at zero.',
      );
    }

    final progressLabel =
        'Circle learned ${snap.progressWords} of ${snap.goalWords} new words this week';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Learn together',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          'Every new word a circle member truly learns adds to this shared bar. There is no ranking inside your circle — just collective progress.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Semantics(
          label: progressLabel,
          value: '${(snap.progressFraction * 100).round()} percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: LinearProgressIndicator(
              value: snap.progressFraction,
              minHeight: 14.h,
              backgroundColor: PanAfricanColors.neutralLight.withValues(alpha: 0.35),
              color: PanAfricanColors.primary,
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          '${snap.progressWords} / ${snap.goalWords} words learned',
          style: PanAfricanTypography.bodyLarge(context),
        ),
        if (snap.complete)
          Padding(
            padding: EdgeInsets.only(top: PanAfricanSpacing.md),
            child: Row(
              children: [
                Icon(Icons.celebration_outlined, color: PanAfricanColors.secondary, size: 28.sp),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    'Goal reached — share the win in your circle chat.',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: PanAfricanSpacing.lg),
        Text('Circle learners', style: PanAfricanTypography.titleSmall(context)),
        SizedBox(height: PanAfricanSpacing.xs),
        ...snap.members.map(
          (m) => ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: PanAfricanSpacing.sm,
            title: Text(m.slot),
            trailing: m.isViewer ? const Icon(Icons.person_outline) : null,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text(
          'Practice mode never counts toward this goal.',
          style: PanAfricanTypography.bodySmall(context)?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required String title,
    required String body,
    Widget? action,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PanAfricanTypography.titleMedium(context)),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(body, style: PanAfricanTypography.bodyMedium(context)),
            if (action != null) ...[
              SizedBox(height: PanAfricanSpacing.md),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
