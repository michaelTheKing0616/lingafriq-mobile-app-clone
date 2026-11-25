import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';

/// Copy key: `tutorial.pair.title`
const String kTutorialPairTitleKey = 'tutorial.pair.title';
const String kTutorialPairTitleFallback = 'Tone makes the meaning';

typedef MinimalPairAudioPlayer = Future<void> Function(String assetUri);

class MinimalPairWord {
  const MinimalPairWord({
    required this.optionId,
    required this.form,
    required this.glossEn,
    required this.audioUri,
    required this.sourceId,
  });

  final String optionId;
  final String form;
  final String glossEn;
  final String audioUri;
  final String sourceId;

  factory MinimalPairWord.fromJson(Map<String, dynamic> json) {
    return MinimalPairWord(
      optionId: json['option_id'] as String,
      form: json['form'] as String,
      glossEn: json['gloss_en'] as String,
      audioUri: json['audio_uri'] as String,
      sourceId: json['source_id'] as String,
    );
  }
}

class MinimalPairDemoSpec {
  const MinimalPairDemoSpec({
    required this.languageCode,
    required this.pairId,
    required this.titleEn,
    required this.introEn,
    required this.drillSourceId,
    required this.words,
  });

  final String languageCode;
  final String pairId;
  final String titleEn;
  final String introEn;
  final String drillSourceId;
  final List<MinimalPairWord> words;

  factory MinimalPairDemoSpec.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>;
    return MinimalPairDemoSpec(
      languageCode: json['language_code'] as String,
      pairId: json['pair_id'] as String,
      titleEn: json['title_en'] as String,
      introEn: json['intro_en'] as String,
      drillSourceId: json['drill_source_id'] as String,
      words: rawWords
          .map((e) => MinimalPairWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MinimalPairTutorialPack {
  const MinimalPairTutorialPack({
    required this.cardId,
    required this.demos,
    required this.signOffs,
    required this.publishStatus,
  });

  final String cardId;
  final List<MinimalPairDemoSpec> demos;
  final List<Map<String, dynamic>> signOffs;
  final String publishStatus;
}

MinimalPairTutorialPack parseMinimalPairTutorialPack(Map<String, dynamic> json) {
  final demos = (json['demos'] as List<dynamic>)
      .map((e) => MinimalPairDemoSpec.fromJson(e as Map<String, dynamic>))
      .toList();
  for (final demo in demos) {
    if (demo.words.length < 2) {
      throw FormatException('${demo.pairId}: minimal pair needs two words');
    }
    for (final w in demo.words) {
      if (w.sourceId.trim().isEmpty || w.audioUri.trim().isEmpty) {
        throw FormatException('${demo.pairId}: missing audio or source on ${w.optionId}');
      }
    }
  }
  return MinimalPairTutorialPack(
    cardId: json['card'] as String,
    demos: demos,
    signOffs: (json['native_reviewer_sign_offs'] as List<dynamic>? ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList(),
    publishStatus: json['publish_status'] as String? ?? 'draft',
  );
}

bool minimalPairPackPublishable(MinimalPairTutorialPack pack) {
  if (pack.signOffs.isEmpty) return false;
  return pack.publishStatus == 'published';
}

Future<MinimalPairTutorialPack> loadMinimalPairTutorialPack({
  String assetPath = 'assets/tutorials/minimal_pairs.json',
  Future<String> Function(String path)? assetLoader,
}) async {
  final loader = assetLoader ??
      ((path) async => rootBundle.loadString(path));
  final raw = await loader(assetPath);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return parseMinimalPairTutorialPack(json);
}

enum MinimalPairDemoPhase {
  loading,
  error,
  offline,
  pair,
  compare,
}

class MinimalPairDemoScreen extends StatefulWidget {
  const MinimalPairDemoScreen({
    super.key,
    this.languageCode = 'yo',
    this.packLoader,
    this.audioPlayer,
    this.isOffline = false,
    this.initialPack,
  });

  final String languageCode;
  final Future<MinimalPairTutorialPack> Function()? packLoader;
  final MinimalPairAudioPlayer? audioPlayer;
  final bool isOffline;
  final MinimalPairTutorialPack? initialPack;

  @override
  State<MinimalPairDemoScreen> createState() => _MinimalPairDemoScreenState();
}

class _MinimalPairDemoScreenState extends State<MinimalPairDemoScreen> {
  MinimalPairDemoPhase _phase = MinimalPairDemoPhase.loading;
  MinimalPairDemoSpec? _demo;
  String? _errorMessage;
  String? _audioError;
  String? _playingOptionId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.isOffline) {
      setState(() => _phase = MinimalPairDemoPhase.offline);
      return;
    }
    if (widget.initialPack != null) {
      _applyPack(widget.initialPack!);
      return;
    }
    try {
      final pack = await (widget.packLoader ?? () => loadMinimalPairTutorialPack())();
      if (!mounted) return;
      _applyPack(pack);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = MinimalPairDemoPhase.error;
        _errorMessage = 'Could not load the tone demo.';
      });
    }
  }

  void _applyPack(MinimalPairTutorialPack pack) {
    final code = widget.languageCode.trim().toLowerCase();
    MinimalPairDemoSpec? demo;
    for (final d in pack.demos) {
      if (d.languageCode == code) {
        demo = d;
        break;
      }
    }
    if (demo == null) {
      setState(() {
        _phase = MinimalPairDemoPhase.error;
        _errorMessage = 'No tone demo is ready for this language yet.';
      });
      return;
    }
    setState(() {
      _demo = demo;
      _phase = MinimalPairDemoPhase.pair;
      _errorMessage = null;
      _audioError = null;
    });
  }

  void _openCompare() {
    setState(() => _phase = MinimalPairDemoPhase.compare);
    SemanticsService.announce(
      'Compare both words side by side',
      TextDirection.ltr,
    );
  }

  Future<void> _playWord(MinimalPairWord word) async {
    setState(() {
      _playingOptionId = word.optionId;
      _audioError = null;
    });
    final player = widget.audioPlayer ?? _defaultAudioPlayer;
    try {
      await player(word.audioUri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audioError =
            'We could not play that clip. Check your connection and try again.';
      });
      SemanticsService.announce(_audioError!, TextDirection.ltr);
    } finally {
      if (mounted) setState(() => _playingOptionId = null);
    }
  }

  static Future<void> _defaultAudioPlayer(String assetUri) async {
    // Native clips ship under assets/audio/ when licensed (P5-063).
    await rootBundle.load(assetUri);
  }

  Duration _motionDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 240);
  }

  @override
  Widget build(BuildContext context) {
    final title = _demo?.titleEn ?? kTutorialPairTitleFallback;
    return Scaffold(
      key: ValueKey('minimal-pair-demo-${_phase.name}'),
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        title: Text(title, style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: PanAfricanColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case MinimalPairDemoPhase.loading:
        return const Center(
          key: ValueKey('pair-demo-loading'),
          child: CircularProgressIndicator(),
        );
      case MinimalPairDemoPhase.offline:
        return _messagePanel(
          key: const ValueKey('pair-demo-offline'),
          title: 'You are offline',
          body: 'Reconnect to hear the tone contrast clips.',
          actionLabel: 'Try again',
          onAction: () {
            if (!widget.isOffline) _bootstrap();
          },
        );
      case MinimalPairDemoPhase.error:
        return _messagePanel(
          key: const ValueKey('pair-demo-error'),
          title: 'Demo unavailable',
          body: _errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: _bootstrap,
        );
      case MinimalPairDemoPhase.pair:
        return _pairIntro(context);
      case MinimalPairDemoPhase.compare:
        return _compareView(context);
    }
  }

  Widget _pairIntro(BuildContext context) {
    final demo = _demo!;
    final duration = _motionDuration(context);
    return SingleChildScrollView(
      key: const ValueKey('pair-demo-intro'),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          demo.introEn,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 20.h),
        ...demo.words.map((w) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _wordTile(context, w, expanded: false),
            )),
        if (_audioError != null) ...[
          Text(
            _audioError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          SizedBox(height: 12.h),
        ],
        SizedBox(height: 8.h),
        PanAfricanButton(
          label: 'Compare meanings',
          onPressed: _openCompare,
          width: double.infinity,
        ),
      ],
      ),
    ).animate().fadeIn(duration: duration);
  }

  Widget _compareView(BuildContext context) {
    final demo = _demo!;
    final duration = _motionDuration(context);
    return SingleChildScrollView(
      key: const ValueKey('pair-demo-compare'),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Same letters — different tone, different meaning.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PanAfricanColors.primary,
              ),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _wordTile(context, demo.words[0], expanded: true)),
            SizedBox(width: 12.w),
            Expanded(child: _wordTile(context, demo.words[1], expanded: true)),
          ],
        ),
        if (_audioError != null) ...[
          SizedBox(height: 12.h),
          Text(
            _audioError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        SizedBox(height: 24.h),
        PanAfricanButton(
          label: 'Done',
          onPressed: () => Navigator.maybePop(context),
          width: double.infinity,
        ),
      ],
      ),
    ).animate().fadeIn(duration: duration);
  }

  Widget _wordTile(
    BuildContext context,
    MinimalPairWord word, {
    required bool expanded,
  }) {
    final playing = _playingOptionId == word.optionId;
    return Material(
      color: PanAfricanColors.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              word.form,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: expanded ? TextAlign.center : TextAlign.start,
              semanticsLabel: 'Yoruba word ${word.form}',
            ),
            SizedBox(height: 8.h),
            Text(
              word.glossEn,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: expanded ? TextAlign.center : TextAlign.start,
            ),
            SizedBox(height: 12.h),
            Semantics(
              button: true,
              label: 'Play audio for ${word.form}, meaning ${word.glossEn}',
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: playing ? null : () => _playWord(word),
                  icon: playing
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.volume_up),
                  label: Text(playing ? 'Playing…' : 'Listen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messagePanel({
    required Key key,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 12.h),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 24.h),
        PanAfricanButton(
          label: actionLabel,
          onPressed: onAction,
          width: double.infinity,
        ),
      ],
    );
  }
}
