import 'package:flutter/material.dart';
import 'package:lingafriq/services/learner/lesson_pacing.dart';

String paceCopyForKey(String key) {
  switch (key) {
    case kPaceReasonBand:
      return 'Adjusted to keep success near 80–85%.';
    case kPaceReasonWeakSkill:
      return 'Added drills for a weak skill; other lessons stay open.';
    case kPaceReasonOverride:
      return 'You set a custom pace.';
    case kPaceReasonDefault:
    default:
      return 'Balanced from your recent practice.';
  }
}

/// Shows the recommended lesson pace, reason, override, and reset (P7-949).
class LessonSessionScreen extends StatefulWidget {
  const LessonSessionScreen({
    super.key,
    required this.engine,
    required this.reachableLessonIds,
    this.under16 = false,
  });

  final LessonPacingEngine engine;
  final List<String> reachableLessonIds;
  final bool under16;

  @override
  State<LessonSessionScreen> createState() => _LessonSessionScreenState();
}

class _LessonSessionScreenState extends State<LessonSessionScreen> {
  final LearnerPacingPreferences _preferences = LearnerPacingPreferences();
  late LessonPacingPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = _loadPlan();
  }

  LessonPacingPlan _loadPlan() {
    return widget.engine.recommend(
      reachableLessonIds: widget.reachableLessonIds,
      preferences: _preferences,
      under16: widget.under16,
    );
  }

  void _onOverride() {
    final gentler = LessonPacingPlan(
      itemCount: kPacingMinItems,
      newItemFraction: kPacingMinNewFraction,
      difficultyTarget: 0.35,
      focusSkillDrillIds: const [],
      reasonKey: kPaceReasonOverride,
      reasonDetail: 'Shorter, easier session.',
      reachableLessonIds: widget.reachableLessonIds,
    );
    _preferences.applyOverride(gentler);
    setState(() => _plan = _loadPlan());
  }

  void _onReset() {
    _preferences.reset();
    setState(() => _plan = _loadPlan());
  }

  @override
  Widget build(BuildContext context) {
    final reasonText = paceCopyForKey(_plan.reasonKey);
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson pace')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Pace reason',
              child: Text(
                reasonText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(_plan.reasonDetail),
            const SizedBox(height: 16),
            Text('Items: ${_plan.itemCount}'),
            Text(
              'New content: ${(100 * _plan.newItemFraction).round()}%',
            ),
            Text(
              'Difficulty: ${(_plan.difficultyTarget * 100).round()}%',
            ),
            if (_plan.focusSkillDrillIds.isNotEmpty)
              Text('Extra drills: ${_plan.focusSkillDrillIds.join(', ')}'),
            Text(
              'Lessons available: ${_plan.reachableLessonIds.length}',
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onOverride,
                    child: const Text('Override pace'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _preferences.hasOverride ? _onReset : null,
                    child: const Text('Reset pace'),
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
