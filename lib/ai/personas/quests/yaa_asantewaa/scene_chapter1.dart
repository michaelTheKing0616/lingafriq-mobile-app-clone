// P11-017 — Yaa quest chapter 1 scene: ambience, Tone Lens greet, respectful posture.

import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/tutorials/speaking_try_client.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// copy_keys: quest.scene.alt, quest.tonelens.unsure
abstract final class QuestChapter1Copy {
  static const sceneAlt =
      'Illustrated Kumasi courtyard in 1900, market stalls and Queen Mother council porch.';
  static const ambientCaption =
      'Ambient: market murmur and talking drums. Mute anytime with the speaker control.';
  static const toneLensUnsure =
      'We could not read your tones clearly. No score is shown — try again when you are ready.';
  static const greetingPrompt =
      'Practice the Twi greeting sequence with Tone Lens once native reviewers unlock the surface forms.';
  static const greetingLocked =
      'Twi greeting text is awaiting native sign-off. Tone Lens will use the real scorer when the phrase is published.';
  static const respectTitle = 'How will you approach the Queen Mother?';
  static const respectKneelLabel = 'Kneel and greet with full honor';
  static const respectCasualLabel = 'Bow briefly and wave';
  static const confirmRespect = 'Confirm approach';
}

const String kQuestChapter1AmbientManifest =
    'assets/audio/quests/kumasi_ch1_ambient.json';

/// Body activity token for respectful kneel (wired to Rive L1 in P11-041).
const String kQuestCastActivityKneeling = 'kneeling';

const String kQuestCastActivityStanding = 'idle';

enum QuestRespectPostureChoice { respectfulKneel, casualBow }

/// Maps learner respect choice to cast activity enum (AC3: only respectful kneels).
String castActivityForRespectChoice(QuestRespectPostureChoice choice) {
  switch (choice) {
    case QuestRespectPostureChoice.respectfulKneel:
      return kQuestCastActivityKneeling;
    case QuestRespectPostureChoice.casualBow:
      return kQuestCastActivityStanding;
  }
}

bool learnerAvatarShowsKneeling(String castActivity) =>
    castActivity == kQuestCastActivityKneeling;

@immutable
class QuestChapter1AmbientManifest {
  const QuestChapter1AmbientManifest({
    required this.ambientId,
    this.assetPath,
    required this.captionEn,
    required this.loop,
    required this.defaultVolume,
    required this.licenceStatus,
  });

  final String ambientId;
  final String? assetPath;
  final String captionEn;
  final bool loop;
  final double defaultVolume;
  final String licenceStatus;

  static QuestChapter1AmbientManifest fromJson(Map<String, dynamic> json) {
    return QuestChapter1AmbientManifest(
      ambientId: json['ambient_id'] as String,
      assetPath: json['asset_path'] as String?,
      captionEn: json['caption_en'] as String,
      loop: json['loop'] as bool? ?? true,
      defaultVolume: (json['default_volume'] as num?)?.toDouble() ?? 0.35,
      licenceStatus: json['licence_status'] as String? ?? 'unknown',
    );
  }

  static Future<QuestChapter1AmbientManifest> load() async {
    final raw = await rootBundle.loadString(kQuestChapter1AmbientManifest);
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

typedef AmbientPlayerFactory = AudioPlayer Function();

/// Chapter 1 interactive scene (§8.2 narrative + language beats).
class YaaQuestChapter1Scene extends StatefulWidget {
  const YaaQuestChapter1Scene({
    super.key,
    required this.chapter,
    this.twiSurfaceLocked = true,
    this.greetingExpectedText,
    this.greetingLanguageCode = 'tw',
    this.speakingClient,
    this.dio,
    this.ambientFactory,
    this.onChapterComplete,
  });

  final PersonaQuestChapter chapter;
  final bool twiSurfaceLocked;
  final String? greetingExpectedText;
  final String greetingLanguageCode;
  final SpeakingTryClient? speakingClient;
  final Dio? dio;
  final AmbientPlayerFactory? ambientFactory;
  final VoidCallback? onChapterComplete;

  @override
  State<YaaQuestChapter1Scene> createState() => _YaaQuestChapter1SceneState();
}

class _YaaQuestChapter1SceneState extends State<YaaQuestChapter1Scene> {
  late final SpeakingTryClient _speakingClient;
  AudioPlayer? _ambientPlayer;
  QuestChapter1AmbientManifest? _ambient;
  bool _ambientMuted = false;
  bool _ambientLoaded = false;

  QuestRespectPostureChoice? _pendingRespect;
  QuestRespectPostureChoice? _confirmedRespect;
  String _learnerCastActivity = kQuestCastActivityStanding;

  bool _toneLensEnabled = true;
  SpeakingTryPhase _speakPhase = SpeakingTryPhase.idle;
  List<SyllableToneOverlayRow> _syllables = const [];
  String? _speakError;

  @override
  void initState() {
    super.initState();
    _speakingClient = widget.speakingClient ?? const SpeakingTryClient();
    _bootstrapAmbient();
  }

  Future<void> _bootstrapAmbient() async {
    try {
      _ambient = await QuestChapter1AmbientManifest.load();
      final player = (widget.ambientFactory ?? AudioPlayer.new)();
      _ambientPlayer = player;
      final path = _ambient!.assetPath;
      if (path != null && path.isNotEmpty && !_ambientMuted) {
        await player.setReleaseMode(
          _ambient!.loop ? ReleaseMode.loop : ReleaseMode.stop,
        );
        await player.setVolume(_ambient!.defaultVolume);
        await player.play(AssetSource(path.replaceFirst('assets/', '')));
      }
    } catch (_) {
      _ambient = null;
    }
    if (mounted) setState(() => _ambientLoaded = true);
  }

  @override
  void dispose() {
    _ambientPlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    setState(() => _ambientMuted = !_ambientMuted);
    final player = _ambientPlayer;
    if (player == null) return;
    if (_ambientMuted) {
      await player.stop();
    } else {
      final path = _ambient?.assetPath;
      if (path != null && path.isNotEmpty) {
        await player.play(AssetSource(path.replaceFirst('assets/', '')));
      }
    }
    SemanticsService.announce(
      _ambientMuted ? 'Ambient sound muted' : 'Ambient sound on',
      TextDirection.ltr,
    );
  }

  Future<void> _scoreGreeting(String audioPath) async {
    final expected = widget.greetingExpectedText?.trim() ?? '';
    if (widget.twiSurfaceLocked || expected.isEmpty) {
      setState(() {
        _speakPhase = SpeakingTryPhase.error;
        _speakError = QuestChapter1Copy.greetingLocked;
      });
      return;
    }
    final dio = widget.dio;
    if (dio == null) {
      setState(() {
        _speakPhase = SpeakingTryPhase.error;
        _speakError = kTutorialTryErrorCopy;
      });
      return;
    }
    final result = await _speakingClient.scoreAttempt(
      post: (p, data) => dio.post(p, data: data),
      audioPath: audioPath,
      expectedText: expected,
      language: widget.greetingLanguageCode,
    );
    _syllables = result.syllables;
    _speakError = result.errorMessage;
    setState(() => _speakPhase = result.phase);
    if (mounted) {
      SemanticsService.announce(
        speakingTryAccessibilitySummary(result),
        TextDirection.ltr,
      );
    }
  }

  void _confirmRespect() {
    final choice = _pendingRespect;
    if (choice == null) return;
    _confirmedRespect = choice;
    _learnerCastActivity = castActivityForRespectChoice(choice);
    HapticFeedback.mediumImpact();
    setState(() {});
    widget.onChapterComplete?.call();
  }

  ToneOverlayStatus get _overlayStatus {
    switch (_speakPhase) {
      case SpeakingTryPhase.recording:
        return ToneOverlayStatus.loading;
      case SpeakingTryPhase.result:
        return ToneOverlayStatus.scored;
      case SpeakingTryPhase.unsure:
        return ToneOverlayStatus.unsure;
      case SpeakingTryPhase.error:
        return ToneOverlayStatus.error;
      default:
        return ToneOverlayStatus.loading;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);

    return Semantics(
      label: QuestChapter1Copy.sceneAlt,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SceneIllustration(
              reducedMotion: reducedMotion,
              drumsActive: _ambientLoaded && !_ambientMuted,
              learnerKneeling: learnerAvatarShowsKneeling(_learnerCastActivity),
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    _ambient?.captionEn ?? QuestChapter1Copy.ambientCaption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PanAfricanColors.neutralMedium,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: _ambientMuted ? 'Unmute ambient sound' : 'Mute ambient sound',
                  child: IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _ambientMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              widget.chapter.objectiveEn,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            if (_toneLensEnabled) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tone Lens'),
                value: _toneLensEnabled,
                onChanged: (v) => setState(() => _toneLensEnabled = v),
              ),
              Text(
                QuestChapter1Copy.greetingPrompt,
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.twiSurfaceLocked)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    QuestChapter1Copy.greetingLocked,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PanAfricanColors.secondaryDark,
                    ),
                  ),
                ),
              if (_speakPhase != SpeakingTryPhase.idle)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: ToneOverlayView(
                    status: _overlayStatus,
                    syllables: _syllables,
                    errorMessage: _speakError,
                    height: 132.h,
                  ),
                ),
              if (_speakPhase == SpeakingTryPhase.unsure)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(QuestChapter1Copy.toneLensUnsure),
                ),
              SizedBox(height: 12.h),
              _GreetingPracticeStub(
                enabled: !widget.twiSurfaceLocked &&
                    (widget.greetingExpectedText?.isNotEmpty ?? false),
                onSimulateScore: _scoreGreeting,
                onPhaseChanged: (p) => setState(() => _speakPhase = p),
              ),
            ],
            SizedBox(height: 24.h),
            Text(
              QuestChapter1Copy.respectTitle,
              style: theme.textTheme.titleSmall,
            ),
            SizedBox(height: 8.h),
            _RespectOptionTile(
              label: QuestChapter1Copy.respectKneelLabel,
              selected: _pendingRespect == QuestRespectPostureChoice.respectfulKneel,
              onTap: () => setState(
                () => _pendingRespect = QuestRespectPostureChoice.respectfulKneel,
              ),
            ),
            _RespectOptionTile(
              label: QuestChapter1Copy.respectCasualLabel,
              selected: _pendingRespect == QuestRespectPostureChoice.casualBow,
              onTap: () => setState(
                () => _pendingRespect = QuestRespectPostureChoice.casualBow,
              ),
            ),
            SizedBox(height: 12.h),
            FilledButton(
              onPressed: _pendingRespect == null ? null : _confirmRespect,
              child: Text(QuestChapter1Copy.confirmRespect),
            ),
            if (_confirmedRespect != null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  learnerAvatarShowsKneeling(_learnerCastActivity)
                      ? 'You kneel with respect — the Queen Mother nods.'
                      : 'You keep a lighter bow — posture noted.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SceneIllustration extends StatelessWidget {
  const _SceneIllustration({
    required this.reducedMotion,
    required this.drumsActive,
    required this.learnerKneeling,
  });

  final bool reducedMotion;
  final bool drumsActive;
  final bool learnerKneeling;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: CustomPaint(
          painter: _KumasiCourtyardPainter(
            reducedMotion: reducedMotion,
            drumsActive: drumsActive,
            learnerKneeling: learnerKneeling,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _KumasiCourtyardPainter extends CustomPainter {
  _KumasiCourtyardPainter({
    required this.reducedMotion,
    required this.drumsActive,
    required this.learnerKneeling,
  });

  final bool reducedMotion;
  final bool drumsActive;
  final bool learnerKneeling;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFF87CEEB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.42), sky);

    final ground = Paint()..color = const Color(0xFFC4A574);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.58),
      ground,
    );

    final porch = Paint()..color = PanAfricanColors.primaryDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.18, size.width * 0.38, size.height * 0.35),
        const Radius.circular(8),
      ),
      porch,
    );

    final stall = Paint()..color = PanAfricanColors.secondary;
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (0.05 + i * 0.14),
          size.height * 0.48,
          size.width * 0.12,
          size.height * 0.22,
        ),
        stall,
      );
    }

    if (drumsActive && !reducedMotion) {
      final drum = Paint()..color = const Color(0xFF5D4037);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.22, size.height * 0.72),
          width: size.width * 0.1,
          height: size.height * 0.06,
        ),
        drum,
      );
    }

    final learnerY = learnerKneeling ? size.height * 0.62 : size.height * 0.55;
    final learner = Paint()..color = PanAfricanColors.primary;
    canvas.drawCircle(Offset(size.width * 0.72, learnerY), size.width * 0.04, learner);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.72, learnerY + size.height * 0.08),
          width: size.width * 0.05,
          height: learnerKneeling ? size.height * 0.04 : size.height * 0.1,
        ),
        const Radius.circular(4),
      ),
      learner,
    );
  }

  @override
  bool shouldRepaint(covariant _KumasiCourtyardPainter oldDelegate) {
    return oldDelegate.drumsActive != drumsActive ||
        oldDelegate.learnerKneeling != learnerKneeling ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}

class _RespectOptionTile extends StatelessWidget {
  const _RespectOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ListTile(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: selected ? PanAfricanColors.primary : PanAfricanColors.neutralLight,
            width: selected ? 2 : 1,
          ),
        ),
        title: Text(label),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? PanAfricanColors.primary : null,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Test hook: simulates hold-to-speak without microphone in widget/golden tests.
class _GreetingPracticeStub extends StatelessWidget {
  const _GreetingPracticeStub({
    required this.enabled,
    required this.onSimulateScore,
    required this.onPhaseChanged,
  });

  final bool enabled;
  final Future<void> Function(String audioPath) onSimulateScore;
  final ValueChanged<SpeakingTryPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Hold to practice greeting with Tone Lens',
      child: PanAfricanCard(
        child: SizedBox(
          height: 56.h,
          child: Center(
            child: TextButton(
              onPressed: enabled
                  ? () async {
                      onPhaseChanged(SpeakingTryPhase.recording);
                      await Future<void>.delayed(const Duration(milliseconds: 16));
                      onPhaseChanged(SpeakingTryPhase.idle);
                      final stubPath =
                          '${Directory.systemTemp.path}/quest_greet.wav';
                      if (!File(stubPath).existsSync()) {
                        await File(stubPath).writeAsBytes(const [0]);
                      }
                      await onSimulateScore(stubPath);
                    }
                  : null,
              child: Text(
                enabled ? 'Hold to speak greeting' : 'Greeting practice locked',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
