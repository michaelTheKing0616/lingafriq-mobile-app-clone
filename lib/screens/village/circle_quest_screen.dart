import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Circle / class quest hub — reference: Duolingo friend quests (group goal, learning XP only).
class CircleQuestScreen extends ConsumerStatefulWidget {
  const CircleQuestScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<CircleQuestScreen> createState() => _CircleQuestScreenState();
}

class _CircleQuestScreenState extends ConsumerState<CircleQuestScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(gamificationProvider.notifier).refreshCircleQuest(widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quest = ref.watch(gamificationProvider.notifier).circleQuest;
    final phrase = ref.watch(gamificationProvider.notifier).familyPhrase;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Circle quest', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [
            if (quest == null)
              Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                child: Text(
                  'Loading your circle quest…',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              )
            else if (quest.empty)
              Text(
                'Your circle has not set a learning goal yet. Hosts can choose a target based on lessons and reviews completed together.',
                style: PanAfricanTypography.bodyLarge(context),
              )
            else ...[
              Text(
                'Quest progress',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Semantics(
                label:
                    'Quest progress ${quest.progressXp} of ${quest.goalXp} learning XP',
                child: LinearProgressIndicator(
                  value: quest.goalXp > 0
                      ? (quest.progressXp / quest.goalXp).clamp(0.0, 1.0)
                      : 0,
                  minHeight: 12.h,
                  backgroundColor: PanAfricanColors.neutralLight,
                  color: PanAfricanColors.primary,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                '${quest.progressXp} / ${quest.goalXp} learning XP',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              if (quest.complete)
                Padding(
                  padding: EdgeInsets.only(top: PanAfricanSpacing.md),
                  child: Text(
                    'Goal reached — celebrate together in your circle chat.',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ),
              SizedBox(height: PanAfricanSpacing.lg),
              Text('Circle learners', style: PanAfricanTypography.titleSmall(context)),
              ...quest.members.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.slot),
                  trailing: m.isViewer ? const Icon(Icons.person_outline) : null,
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.xl),
            Text(
              'Phrase of the week',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            if (phrase == null)
              Text('Loading family phrase…', style: PanAfricanTypography.bodyMedium(context))
            else if (phrase.empty)
              Text(
                'Ask your circle host to pick a phrase everyone will practice teaching back.',
                style: PanAfricanTypography.bodyLarge(context),
              )
            else ...[
              Text(phrase.phrase, style: PanAfricanTypography.headlineSmall(context)),
              Text(phrase.gloss, style: PanAfricanTypography.bodyMedium(context)),
              SizedBox(height: PanAfricanSpacing.md),
              ...?quest?.members
                  .where((m) => !m.isViewer && m.userId != null)
                  .map(
                    (m) => Padding(
                      padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
                      child: Semantics(
                        label: 'Confirm ${m.slot} taught the phrase back',
                        button: true,
                        child: OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(gamificationProvider.notifier)
                                .confirmFamilyPhraseTeachBack(
                                  groupId: widget.groupId,
                                  learnerId: m.userId!,
                                );
                          },
                          style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                          child: Text('${m.slot} taught it back'),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
