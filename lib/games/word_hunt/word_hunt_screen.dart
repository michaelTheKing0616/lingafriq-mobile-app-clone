import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/games/word_hunt/word_hunt_session.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_dictionary.dart';

typedef WordHuntClassifyFrame = Future<List<ObjectClassificationLabel>> Function();

/// Scavenger-style word hunt on the Point-and-Say classifier pipeline (P8-934).
/// Reference UX: Duolingo scavenger checklist over a live viewfinder (recoloured LingAfriq).
class WordHuntScreen extends ConsumerStatefulWidget {
  const WordHuntScreen({
    super.key,
    required this.language,
    this.session,
    this.dictionaryService,
    this.classifyFrame,
    this.debugPreview,
    this.hasInternet,
    this.onSpeakWord,
  });

  final String language;
  final WordHuntSession? session;
  final PointSayDictionaryService? dictionaryService;
  final WordHuntClassifyFrame? classifyFrame;
  final Widget? debugPreview;
  final Future<bool> Function()? hasInternet;
  final Future<void> Function(String word)? onSpeakWord;

  @override
  ConsumerState<WordHuntScreen> createState() => _WordHuntScreenState();
}

class _WordHuntScreenState extends ConsumerState<WordHuntScreen> {
  static const double _spacing = 16;
  static const double _radius = 12;
  static const double _minTap = 48;

  WordHuntSession? _session;
  PointSayDictionaryService? _dictionary;
  bool _bootstrapping = true;
  bool _scanning = false;
  bool _offlineOnly = false;
  String? _bannerMessage;
  WordHuntFrameOutcomeKind? _lastOutcome;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.session != null && widget.dictionaryService != null) {
      final online =
          await (widget.hasInternet ?? ConnectivityService.hasInternet)();
      if (!mounted) return;
      setState(() {
        _session = widget.session;
        _dictionary = widget.dictionaryService;
        _offlineOnly = !online;
        _bootstrapping = false;
      });
      return;
    }
    final dictionary = widget.dictionaryService ?? await createPointSayDictionaryService();
    final set = await AfricanObjectSet.loadFromBundle();
    final mapper = ObjectSetMapper(set);
    final targets = WordHuntSession.defaultTargetsFromObjectSet(set);
    if (!mounted) return;
    final online = await (widget.hasInternet ?? ConnectivityService.hasInternet)();
    if (!mounted) return;
    setState(() {
      _dictionary = dictionary;
      _session = widget.session ??
          WordHuntSession(targets: targets, mapper: mapper);
      _offlineOnly = !online;
      _bootstrapping = false;
    });
  }

  Future<void> _scan() async {
    final session = _session;
    final dictionary = _dictionary;
    if (session == null || dictionary == null || _scanning) return;

    final online = await (widget.hasInternet ?? ConnectivityService.hasInternet)();
    if (!mounted) return;
    setState(() => _offlineOnly = !online);
    if (!online) {
      assert(session.uploadAttempts == 0);
    }

    setState(() {
      _scanning = true;
      _bannerMessage = null;
    });

    try {
      final top3 = await (widget.classifyFrame ?? _defaultClassify)();
      final listed = session.pickListedLabel(top3);
      if (listed == null) {
        if (!mounted) return;
        setState(() => _scanning = false);
        return;
      }

      if (!session.isMappedInDictionary(listed)) {
        final outcome = session.applyDictionaryResult(
          classifierLabel: listed,
          dictionaryHit: false,
        );
        _announceOutcome(outcome);
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _lastOutcome = outcome.kind;
          _bannerMessage = wordHuntNotInDictionaryMessage;
        });
        return;
      }

      final entry = await dictionary.resolveEntry(
        mlKitLabel: listed,
        learnerLanguageCode: widget.language,
      );
      final hit = entry != null;
      final spoken = entry?.playbackHit.word;
      final outcome = session.applyDictionaryResult(
        classifierLabel: listed,
        dictionaryHit: hit,
        spokenWord: spoken,
      );
      _announceOutcome(outcome);

      if (hit && spoken != null && spoken.isNotEmpty) {
        if (widget.onSpeakWord != null) {
          await widget.onSpeakWord!(spoken);
        } else {
          await dictionary.playEntry(entry!);
        }
      }

      if (!mounted) return;
      setState(() {
        _scanning = false;
        _lastOutcome = outcome.kind;
        _bannerMessage = outcome.kind == WordHuntFrameOutcomeKind.huntComplete
            ? wordHuntCompleteMessage
            : (outcome.kind == WordHuntFrameOutcomeKind.found
                ? '$wordHuntFoundAnnouncement: $spoken'
                : null);
      });
    } finally {
      if (mounted && _scanning) {
        setState(() => _scanning = false);
      }
    }
  }

  void _announceOutcome(WordHuntFrameOutcome outcome) {
    switch (outcome.kind) {
      case WordHuntFrameOutcomeKind.found:
      case WordHuntFrameOutcomeKind.huntComplete:
        SemanticsService.announce(
          '${wordHuntFoundAnnouncement} ${outcome.spokenWord ?? outcome.matchedLabel ?? ''}',
          TextDirection.ltr,
        );
        break;
      case WordHuntFrameOutcomeKind.notInDictionary:
        SemanticsService.announce(
          wordHuntNotInDictionaryMessage,
          TextDirection.ltr,
        );
        break;
      default:
        break;
    }
  }

  Future<List<ObjectClassificationLabel>> _defaultClassify() async {
    return const [
      ObjectClassificationLabel(label: 'Cup', score: 0.05),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disableMotion = MediaQuery.disableAnimationsOf(context);

    if (_bootstrapping) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _session!;
    final progress = session.progress();
    final complete = session.isComplete;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Word hunt'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 5,
              child: Padding(
              padding: const EdgeInsets.all(_spacing),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight.clamp(120.0, 280.0);
                    return SizedBox(
                      height: height,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.debugPreview ??
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colorScheme.primaryContainer
                                          .withValues(alpha: 0.35),
                                      colorScheme.surfaceContainerHighest,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                  semanticLabel: 'Camera viewfinder',
                                ),
                              ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            ),
            if (_offlineOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _spacing),
                child: Text(
                  'On-device scan only — no photos are uploaded.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_bannerMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _spacing),
                child: Material(
                  color: _lastOutcome == WordHuntFrameOutcomeKind.notInDictionary
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(_radius),
                  child: Padding(
                    padding: const EdgeInsets.all(_spacing),
                    child: Text(
                      _bannerMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _lastOutcome == WordHuntFrameOutcomeKind.notInDictionary
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_spacing, _spacing, _spacing, 8),
              child: Text(
                'Find these around you',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: _spacing),
                itemCount: progress.length,
                itemBuilder: (context, index) {
                  final row = progress[index];
                  final found = row.status == WordHuntItemStatus.found;
                  final label = row.spokenWord ?? row.target.displayLabel;
                  return Semantics(
                    button: true,
                    label: found ? 'Found $label' : 'Still looking for ${row.target.displayLabel}',
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      minVerticalPadding: (_minTap - 24) / 2,
                      leading: AnimatedScale(
                        scale: found && !disableMotion ? 1.05 : 1,
                        duration: disableMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        child: Icon(
                          found ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: found ? colorScheme.primary : colorScheme.outline,
                        ),
                      ),
                      title: Text(row.target.displayLabel),
                      subtitle: found && row.spokenWord != null
                          ? Text(label, style: theme.textTheme.labelLarge)
                          : null,
                      trailing: found && !disableMotion
                          ? const Icon(Icons.volume_up_outlined, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_spacing),
              child: SizedBox(
                height: _minTap,
                child: FilledButton.icon(
                  onPressed: complete || _scanning ? null : _scan,
                  icon: _scanning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.center_focus_strong),
                  label: Text(complete ? 'Hunt complete' : 'Scan object'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
