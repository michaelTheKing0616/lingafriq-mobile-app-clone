import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/dio_provider.dart' show client;
import '../../services/ai_gateway_client.dart';
import '../../utils/pan_african_design_system.dart';
import 'story_chain_game.dart';
import 'story_playback.dart';

enum StoryChainPhase {
  loading,
  ready,
  playing,
  grammarSuggestion,
  waitingForPlayer,
  results,
  error,
  offline,
  practiceMode,
}

/// Flagship Griot's Story Chain (P8-925): circle turns, grammar check, playback.
class StoryChainScreen extends ConsumerStatefulWidget {
  const StoryChainScreen({
    super.key,
    required this.language,
    this.learnerId = 'learner-local',
    this.onBack,
    this.onOpenLegacyClanStory,
    this.initialCircle,
    this.initialPhase,
  });

  final String language;
  final String learnerId;
  final VoidCallback? onBack;
  final VoidCallback? onOpenLegacyClanStory;
  final StoryChainCircle? initialCircle;
  final StoryChainPhase? initialPhase;

  @override
  ConsumerState<StoryChainScreen> createState() => _StoryChainScreenState();
}

class _StoryChainScreenState extends ConsumerState<StoryChainScreen> {
  static const title = "Griot's Story Chain";
  static const instructions =
      'Take turns adding one sentence. Polie can suggest a grammar fix before your line joins the tale.';
  static const whyWrongCopy =
      'That line did not fit the circle rules. Wait for your turn or ask the host for a new invite.';
  static const practiceLabel =
      'Practice — story chains with friends need a host invite before anyone else can listen.';
  static const errorCopy =
      'We could not start this story circle. Check your connection and try again.';
  static const checkUnavailableCopy =
      'Grammar check unavailable — you can keep your sentence as written.';
  static const legacyLinkLabel = 'Classic clan lineage builder';

  final _rng = Random();
  final _sentenceController = TextEditingController();
  StoryChainPhase _phase = StoryChainPhase.loading;
  StoryChainCircle? _circle;
  StoryGrammarSuggestion? _pendingGrammar;
  StoryChainSentence? _pendingSentence;
  StoryPlaybackPlan? _playback;
  String? _loadError;
  int _playbackIndex = 0;
  bool _grammarLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhase != null) {
      _phase = widget.initialPhase!;
      _circle = widget.initialCircle;
    } else {
      unawaited(_bootstrap());
    }
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _circle = createLocalCircle(
        hostId: widget.learnerId,
        languageCode: widget.language,
        extraMembers: const ['elder-griot'],
        random: _rng,
      );
      setState(() => _phase = StoryChainPhase.ready);
    } catch (_) {
      setState(() {
        _phase = StoryChainPhase.error;
        _loadError = errorCopy;
      });
    }
  }

  Future<StoryGrammarSuggestion> _requestGrammarCheck(String text) async {
    try {
      final gateway = AiGatewayClient(ref.read(client));
      final response = await gateway.completeChat(
        mode: 'tutor_correct',
        messages: [
          {
            'role': 'user',
            'content': jsonEncode({
              'learner_text': text,
              'target_language': widget.language,
            }),
          },
        ],
        languageCode: widget.language,
        maxTokens: 400,
      );
      final content = response['content']?.toString() ??
          response['answer']?.toString() ??
          '';
      if (content.isEmpty) {
        return StoryGrammarSuggestion.unavailableState;
      }
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        parsed = response;
      }
      final corrected =
          parsed['corrected_text']?.toString() ?? text;
      final explanation =
          parsed['explanation']?.toString() ?? 'Polie suggests a small grammar tweak.';
      final category = parsed['category']?.toString() ?? 'grammar';
      if (corrected.trim() == text.trim()) {
        return StoryGrammarSuggestion(
          suggestedText: text,
          explanation: 'Your sentence looks good for this beat.',
          category: category,
        );
      }
      return StoryGrammarSuggestion(
        suggestedText: corrected,
        explanation: explanation,
        category: category,
      );
    } catch (_) {
      return StoryGrammarSuggestion.unavailableState;
    }
  }

  Future<void> _submitSentence() async {
    final circle = _circle;
    if (circle == null) return;
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;
    if (!circle.isMembersTurn(widget.learnerId)) {
      setState(() => _phase = StoryChainPhase.waitingForPlayer);
      return;
    }
    setState(() => _grammarLoading = true);
    final grammar = await _requestGrammarCheck(text);
    final sentenceId = 's-${circle.sentences.length}';
    final draft = StoryChainSentence(
      id: sentenceId,
      authorId: widget.learnerId,
      text: text,
      turnIndex: circle.sentences.length,
      audioAssetKey: 'learner-recording-$sentenceId',
      illustrationKey: 'illustration.story.${circle.sentences.length}',
    );
    setState(() {
      _grammarLoading = false;
      _pendingGrammar = grammar;
      _pendingSentence = draft;
      _phase = StoryChainPhase.grammarSuggestion;
    });
  }

  void _finalizeSentence({required bool acceptSuggestion}) {
    final circle = _circle;
    final draft = _pendingSentence;
    final grammar = _pendingGrammar;
    if (circle == null || draft == null || grammar == null) return;
    final finalized = applyGrammarChoice(
      sentence: draft,
      acceptSuggestion: acceptSuggestion,
      suggestion: grammar,
    );
    try {
      appendSentence(
        circle: circle,
        playerId: widget.learnerId,
        sentenceId: finalized.id,
        text: finalized.text,
        audioAssetKey: finalized.audioAssetKey,
        illustrationKey: finalized.illustrationKey,
      );
      final idx = circle.sentences.length - 1;
      circle.sentences[idx] = finalized;
    } on StateError {
      setState(() => _phase = StoryChainPhase.waitingForPlayer);
      return;
    }
    _sentenceController.clear();
    _pendingGrammar = null;
    _pendingSentence = null;
    if (circle.completed) {
      _playback = buildPlaybackPlan(circle);
      setState(() {
        _playbackIndex = 0;
        _phase = StoryChainPhase.results;
      });
      return;
    }
    setState(() {
      _phase = circle.isMembersTurn(widget.learnerId)
          ? StoryChainPhase.playing
          : StoryChainPhase.waitingForPlayer;
    });
  }

  void _copyInvite() {
    final code = _circle?.inviteCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code copied: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_circle != null)
            IconButton(
              onPressed: _copyInvite,
              tooltip: 'Copy invite code',
              icon: const Icon(Icons.group_add),
            ),
          if (widget.onOpenLegacyClanStory != null)
            TextButton(
              onPressed: widget.onOpenLegacyClanStory,
              child: const Text(legacyLinkLabel),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 200),
          child: _bodyForPhase(context),
        ),
      ),
    );
  }

  Widget _bodyForPhase(BuildContext context) {
    switch (_phase) {
      case StoryChainPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case StoryChainPhase.error:
        return _StateMessage(
          key: const ValueKey('error'),
          message: _loadError ?? errorCopy,
          actionLabel: 'Try again',
          onAction: () {
            setState(() => _phase = StoryChainPhase.loading);
            unawaited(_bootstrap());
          },
        );
      case StoryChainPhase.offline:
        return _StateMessage(
          key: const ValueKey('offline'),
          message:
              'You are offline. Your sentences stay on this device until you reconnect.',
          actionLabel: 'Back',
          onAction: widget.onBack ?? () => Navigator.of(context).pop(),
        );
      case StoryChainPhase.results:
        return _buildResults(context);
      case StoryChainPhase.waitingForPlayer:
        return _StateMessage(
          key: const ValueKey('wait'),
          message:
              'Waiting for ${_circle?.activePlayerId() ?? 'the next storyteller'}…',
          actionLabel: 'Back to story',
          onAction: () => setState(() => _phase = StoryChainPhase.playing),
        );
      case StoryChainPhase.grammarSuggestion:
        return _grammarPanel(context);
      default:
        return Padding(
          key: ValueKey(_phase.name),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PracticeBanner(label: practiceLabel),
              Text(
                instructions,
                style: PanAfricanTypography.bodyMedium(context),
              ),
              if (_circle != null) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Invite: ${_circle!.inviteCode} · ${_circle!.sentences.length}/${_circle!.maxTurns} beats',
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.md),
              Expanded(child: _storyScroll(context)),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: _sentenceController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your sentence',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PanAfricanRadius.md),
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              FilledButton(
                onPressed: _grammarLoading ? null : _submitSentence,
                child: _grammarLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add my sentence'),
              ),
            ],
          ),
        );
    }
  }

  Widget _storyScroll(BuildContext context) {
    final lines = _circle?.sentences ?? const [];
    if (lines.isEmpty) {
      return Center(
        child: Text(
          'The griot opens the circle. Add the first line when you are ready.',
          style: PanAfricanTypography.bodyMedium(context),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      itemCount: lines.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
      itemBuilder: (context, index) {
        final line = lines[index];
        return Semantics(
          label: 'Story beat ${index + 1}',
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.playbackText,
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                  if (line.moderation == StorySentenceModeration.flagged)
                    Text(
                      'Held for review',
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: PanAfricanColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _grammarPanel(BuildContext context) {
    final grammar = _pendingGrammar ?? StoryGrammarSuggestion.unavailableState;
    final draft = _pendingSentence;
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            grammar.unavailable ? checkUnavailableCopy : grammar.explanation,
            style: PanAfricanTypography.bodyMedium(context),
          ),
          if (!grammar.unavailable && draft != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            Text('Your line', style: PanAfricanTypography.labelLarge(context)),
            Text(draft.text),
            SizedBox(height: PanAfricanSpacing.sm),
            Text('Suggestion', style: PanAfricanTypography.labelLarge(context)),
            Text(grammar.suggestedText),
          ],
          const Spacer(),
          FilledButton(
            onPressed: () => _finalizeSentence(acceptSuggestion: true),
            child: const Text('Use suggestion'),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          OutlinedButton(
            onPressed: () => _finalizeSentence(acceptSuggestion: false),
            child: const Text('Keep my sentence'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final plan = _playback;
    final beats = plan?.beats ?? const [];
    final beat = beats.isEmpty
        ? null
        : beats[_playbackIndex.clamp(0, beats.length - 1)];
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your chain is ready',
            style: PanAfricanTypography.headlineSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          if (beat != null)
            Semantics(
              label: 'Playback beat ${_playbackIndex + 1}',
              child: Card(
                color: PanAfricanColors.primaryContainer,
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  child: Text(
                    beat.text,
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                ),
              ),
            ),
          if ((plan?.excludedAuthorIds ?? []).isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
              child: Text(
                'Some lines were held back for safety. The author was notified.',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          const Spacer(),
          if (beats.length > 1)
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous beat',
                  onPressed: _playbackIndex > 0
                      ? () => setState(() => _playbackIndex -= 1)
                      : null,
                  icon: const Icon(Icons.skip_previous),
                ),
                Expanded(
                  child: Text(
                    'Beat ${_playbackIndex + 1} of ${beats.length}',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Next beat',
                  onPressed: _playbackIndex < beats.length - 1
                      ? () => setState(() => _playbackIndex += 1)
                      : null,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          FilledButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}

class GriotStoryChainPreview extends StatelessWidget {
  const GriotStoryChainPreview({
    super.key,
    required this.phaseLabel,
    required this.hintEn,
    required this.body,
  });

  final String phaseLabel;
  final String hintEn;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(phaseLabel, style: theme.textTheme.titleMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(hintEn, style: theme.textTheme.bodyMedium),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PanAfricanColors.secondaryContainer,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Text(
            label,
            style: PanAfricanTypography.bodySmall(context),
          ),
        ),
      ),
    );
  }
}
