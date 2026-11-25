import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/leaderboard_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Weekly leagues hub — reference: Duolingo leagues (opt-in, learning XP only).
class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(leaderboardProvider.notifier).refreshLeagueMembership(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final enrolled = notifier.leagueEnrolled;
    final allowed = notifier.leagueAllowedKinds;
    final status = notifier.leagueStatusMessage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPublic = allowed.contains('public');

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Weekly leagues', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [
            if (status != null)
              Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                child: Text(status, style: PanAfricanTypography.bodyMedium(context)),
              ),
            if (!enrolled) ...[
              Text(
                'Leagues are optional. Join when you want friendly competition — rankings use learning XP only, never taps or purchases.',
                style: PanAfricanTypography.bodyLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              Semantics(
                label: 'Join weekly leagues',
                button: true,
                child: FilledButton(
                  onPressed: canPublic
                      ? () async {
                          HapticFeedback.mediumImpact();
                          final ok = await notifier.optInToLeagues(
                            timezone: DateTime.now().timeZoneName,
                            leagueKind: 'public',
                          );
                          if (ok && mounted) {
                            setState(() {});
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(48.h),
                    backgroundColor: PanAfricanColors.primary,
                  ),
                  child: Text(canPublic ? 'Join leagues' : 'Circle leagues only'),
                ),
              ),
              if (!canPublic) ...[
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'Ask your teacher or circle host for a class code to join a private league.',
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
            ] else ...[
              Text(
                'You are in this week\'s league. Keep learning — your rank updates from lessons, reviews, and speaking practice.',
                style: PanAfricanTypography.bodyLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              OutlinedButton(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  final ok = await notifier.optOutOfLeagues();
                  if (ok && mounted) setState(() {});
                },
                style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                child: const Text('Leave leagues'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
