import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/hearts_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/gamification/hearts_widget.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Challenge Mode hub — reference: Duolingo optional “hard mode” (hearts only inside runs).
class ChallengeModeScreen extends ConsumerStatefulWidget {
  const ChallengeModeScreen({super.key});

  @override
  ConsumerState<ChallengeModeScreen> createState() => _ChallengeModeScreenState();
}

class _ChallengeModeScreenState extends ConsumerState<ChallengeModeScreen> {
  static const _roundsTotal = 5;
  int _roundIndex = 0;
  int _correct = 0;
  bool _runFinished = false;
  bool _ranOutOfHearts = false;
  String? _serverMessage;

  static const _prompts = [
    _ChallengePrompt('Ọmọ', 'Child'),
    _ChallengePrompt('Ilé', 'House'),
    _ChallengePrompt('Omi', 'Water'),
    _ChallengePrompt('Ọjà', 'Market'),
    _ChallengePrompt('Ẹ̀gbọ́n', 'Sibling'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hearts = ref.watch(heartsProvider);
    final notifier = ref.read(heartsProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Challenge Mode', style: PanAfricanTypography.titleLarge(context)),
        actions: [
          if (hearts.showHeartsUi)
            Padding(
              padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
              child: const HeartsWidget(compact: true),
            ),
        ],
      ),
      body: ResponsiveSafeArea(
        child: ListView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          children: [
            if (!hearts.challengeRunActive && !_runFinished) ...[
              Semantics(
                label: 'Challenge mode toggle',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
                  title: Text(
                    'Challenge Mode',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  subtitle: Text(
                    'Core lessons stay pressure-free. Hearts only apply inside Challenge runs you start here.',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  value: hearts.challengeModeEnabled,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    await notifier.syncChallengeModePreference(v);
                  },
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              if (hearts.challengeModeEnabled)
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    notifier.beginChallengeRun();
                    setState(() {
                      _roundIndex = 0;
                      _correct = 0;
                      _runFinished = false;
                      _ranOutOfHearts = false;
                      _serverMessage = null;
                    });
                  },
                  icon: const Icon(Icons.local_fire_department_rounded),
                  label: const Text('Start Challenge run'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(48.h),
                    backgroundColor: PanAfricanColors.primary,
                  ),
                ),
            ],
            if (hearts.challengeRunActive && !_runFinished) ...[
              Text(
                'Round ${_roundIndex + 1} of $_roundsTotal',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _PromptCard(prompt: _prompts[_roundIndex], isDark: isDark),
              SizedBox(height: PanAfricanSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _answer(correct: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                      ),
                      child: const Text('I missed it'),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _answer(correct: true),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        backgroundColor: PanAfricanColors.primary,
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ],
            if (_runFinished) ...[
              Icon(
                _ranOutOfHearts
                    ? Icons.favorite_border_rounded
                    : Icons.emoji_events_rounded,
                size: 56.sp,
                color: _ranOutOfHearts ? PanAfricanColors.tertiary : PanAfricanColors.primary,
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                _ranOutOfHearts
                    ? 'Run over — your lessons are still open'
                    : 'Challenge cleared!',
                style: PanAfricanTypography.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
              if (_serverMessage != null) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  _serverMessage!,
                  style: PanAfricanTypography.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: PanAfricanSpacing.lg),
              FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).maybePop();
                },
                style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                child: const Text('Back to Village'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _answer({required bool correct}) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(heartsProvider.notifier);

    if (!correct) {
      final canContinue = notifier.useHeart();
      if (!canContinue) {
        setState(() {
          _runFinished = true;
          _ranOutOfHearts = true;
        });
        await notifier.endChallengeRun(won: false);
        return;
      }
      ref.read(apiProvider.notifier).useHeart();
    } else {
      _correct++;
    }

    if (_roundIndex + 1 >= _roundsTotal) {
      final won = _correct >= 3 && ref.read(heartsProvider).currentHearts > 0;
      final result = await notifier.endChallengeRun(won: won);
      setState(() {
        _runFinished = true;
        _ranOutOfHearts = !won && ref.read(heartsProvider).currentHearts <= 0;
        if (result.won && result.badges.isNotEmpty) {
          _serverMessage = 'Badge unlocked: ${result.badges.join(', ')}';
        } else if (result.won && result.braggingRecorded) {
          _serverMessage = 'Bragging rights saved to your profile.';
        } else if (result.won && result.serverSyncFailed) {
          _serverMessage = 'Win recorded locally — we will sync when you are back online.';
        }
      });
      return;
    }

    setState(() => _roundIndex++);
  }
}

class _ChallengePrompt {
  final String target;
  final String gloss;

  const _ChallengePrompt(this.target, this.gloss);
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.isDark});

  final _ChallengePrompt prompt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            prompt.target,
            style: PanAfricanTypography.headlineMedium(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            prompt.gloss,
            style: PanAfricanTypography.bodyLarge(context).copyWith(
              color: isDark
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                  : PanAfricanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
