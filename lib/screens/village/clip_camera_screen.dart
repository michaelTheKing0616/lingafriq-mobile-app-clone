import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingafriq/services/clips/clip_upload_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Village clip capture — reference: Instagram Reels record flow + WhatsApp status compose.
enum _ClipFlowState {
  recording,
  review,
  uploading,
  heldForReview,
  posted,
  error,
}

class ClipCameraScreen extends StatefulWidget {
  const ClipCameraScreen({super.key, this.loadCirclesOnInit = true});

  /// Disable in widget tests to avoid outbound API timers.
  final bool loadCirclesOnInit;

  @override
  State<ClipCameraScreen> createState() => _ClipCameraScreenState();
}

class _ClipCameraScreenState extends State<ClipCameraScreen> {
  static const _languageOptions = ['yo', 'ig', 'ha', 'pcm', 'sw', 'zu', 'xh', 'tw'];

  final _captionController = TextEditingController();
  final _uploadService = ClipUploadService();
  final _audioRecorder = AudioRecorder();
  final _picker = ImagePicker();

  _ClipFlowState _state = _ClipFlowState.recording;
  ClipMediaKind _mediaKind = ClipMediaKind.video;
  String _languageTag = 'yo';
  ClipVisibility _visibility = ClipVisibility.publicFeed;
  String? _circleId;
  List<Map<String, dynamic>> _circles = [];
  File? _mediaFile;
  double _durationSec = 0;
  String? _errorMessage;
  Timer? _recordTimer;
  DateTime? _recordStartedAt;
  bool _audioRecording = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadCirclesOnInit) {
      unawaited(_loadCircles());
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _captionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadCircles() async {
    try {
      final res = await ApiService.get('/api/v2/circles');
      final data = res.data;
      if (data is Map && data['circles'] is List) {
        setState(() {
          _circles = (data['circles'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {
      // Offline: circle-only posts need reconnect; public still works for adults.
    }
  }

  void _setError(String message) {
    setState(() {
      _state = _ClipFlowState.error;
      _errorMessage = message;
    });
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final clip = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: ClipUploadService.maxDurationSec),
      );
      if (clip == null) return;
      final file = File(clip.path);
      final duration = await _probeDurationSec(file, fallback: 30);
      _applyCapturedMedia(file, ClipMediaKind.video, duration);
    } catch (_) {
      _setError('We could not open the camera. Check permissions and try again.');
    }
  }

  Future<void> _startAudioRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      _setError('Microphone access is needed to record an audio clip.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/clip_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000),
      path: path,
    );
    _recordStartedAt = DateTime.now();
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _recordStartedAt == null) return;
      final elapsed = DateTime.now().difference(_recordStartedAt!).inMilliseconds / 1000;
      setState(() => _durationSec = elapsed);
      if (elapsed >= ClipUploadService.maxDurationSec) {
        unawaited(_stopAudioRecording());
      }
    });
    setState(() {
      _state = _ClipFlowState.recording;
      _mediaKind = ClipMediaKind.audio;
      _durationSec = 0;
      _errorMessage = null;
      _audioRecording = true;
    });
  }

  Future<void> _stopAudioRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    final started = _recordStartedAt;
    _recordStartedAt = null;
    setState(() => _audioRecording = false);
    if (path == null || started == null) return;
    final elapsed = DateTime.now().difference(started).inMilliseconds / 1000;
    _applyCapturedMedia(File(path), ClipMediaKind.audio, elapsed);
  }

  Future<double> _probeDurationSec(File file, {required double fallback}) async {
    // Gallery/camera metadata is not always available; use fallback when unknown.
    return fallback;
  }

  void _applyCapturedMedia(File file, ClipMediaKind kind, double durationSec) {
    final code = ClipUploadService.validateDurationSec(durationSec);
    if (code != null) {
      setState(() {
        _state = _ClipFlowState.recording;
        _mediaFile = null;
        _durationSec = durationSec;
        _errorMessage =
            'Clips must be at least ${ClipUploadService.minDurationSec} seconds and no longer than ${ClipUploadService.maxDurationSec}.';
      });
      return;
    }
    setState(() {
      _mediaFile = file;
      _mediaKind = kind;
      _durationSec = durationSec;
      _state = _ClipFlowState.review;
      _errorMessage = null;
    });
  }

  Future<void> _submitPost() async {
    final file = _mediaFile;
    if (file == null) {
      _setError('Record a clip before you post.');
      return;
    }
    setState(() => _state = _ClipFlowState.uploading);
    final result = await _uploadService.postClip(
      mediaFile: file,
      durationSec: _durationSec,
      languageTag: _languageTag,
      caption: _captionController.text,
      visibility: _visibility,
      circleId: _circleId,
      mediaKind: _mediaKind,
    );
    if (!mounted) return;
    if (!result.ok) {
      _setError(result.message ?? 'Something went wrong. Try again in a moment.');
      return;
    }
    setState(() {
      _state = result.heldForReview
          ? _ClipFlowState.heldForReview
          : _ClipFlowState.posted;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Share a clip',
          style: PanAfricanTypography.titleLarge(context).copyWith(color: Colors.white),
        ),
      ),
      body: ResponsiveSafeArea(
        child: Column(
          children: [
            Expanded(child: _previewArea(context, cs)),
            _controlPanel(context, cs),
          ],
        ),
      ),
    );
  }

  Widget _previewArea(BuildContext context, ColorScheme cs) {
    switch (_state) {
      case _ClipFlowState.uploading:
        return _statusPanel(
          icon: Icons.cloud_upload_outlined,
          title: 'Uploading your clip…',
          subtitle: 'We are checking your clip to keep the Village kind and safe.',
        );
      case _ClipFlowState.heldForReview:
        return _statusPanel(
          icon: Icons.hourglass_top_rounded,
          title: 'Held for a quick review',
          subtitle:
              'Your clip is saved. A moderator will take a look before it appears for others.',
        );
      case _ClipFlowState.posted:
        return _statusPanel(
          icon: Icons.check_circle_outline,
          title: 'Posted!',
          subtitle: 'Nice work — your clip is live for your chosen audience.',
          action: FilledButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Done'),
          ),
        );
      case _ClipFlowState.error:
        return _statusPanel(
          icon: Icons.error_outline,
          title: 'Could not post',
          subtitle: _errorMessage ?? 'Try again.',
          action: TextButton(
            onPressed: () => setState(() => _state = _ClipFlowState.recording),
            child: const Text('Back to record'),
          ),
        );
      case _ClipFlowState.review:
      case _ClipFlowState.recording:
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    PanAfricanColors.primary.withValues(alpha: 0.35),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: _mediaFile != null
                    ? Icon(
                        _mediaKind == ClipMediaKind.video
                            ? Icons.videocam_rounded
                            : Icons.mic_rounded,
                        size: 72,
                        color: Colors.white70,
                      )
                    : Icon(
                        _mediaKind == ClipMediaKind.video
                            ? Icons.videocam_outlined
                            : Icons.mic_none_rounded,
                        size: 72,
                        color: Colors.white54,
                      ),
              ),
            ),
            Positioned(
              top: PanAfricanSpacing.md,
              left: PanAfricanSpacing.md,
              right: PanAfricanSpacing.md,
              child: Text(
                _formatDuration(_durationSec),
                semanticsLabel: 'Recording length ${_formatDuration(_durationSec)}',
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (_errorMessage != null && _state == _ClipFlowState.recording)
              Positioned(
                bottom: PanAfricanSpacing.lg,
                left: PanAfricanSpacing.md,
                right: PanAfricanSpacing.md,
                child: Material(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(PanAfricanSpacing.sm),
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _controlPanel(BuildContext context, ColorScheme cs) {
    if (_state == _ClipFlowState.posted ||
        _state == _ClipFlowState.heldForReview ||
        _state == _ClipFlowState.uploading) {
      return const SizedBox.shrink();
    }

    if (_state == _ClipFlowState.review) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          PanAfricanSpacing.md,
          PanAfricanSpacing.md,
          PanAfricanSpacing.md,
          PanAfricanSpacing.lg,
        ),
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _languageTag,
              dropdownColor: cs.surface,
              decoration: const InputDecoration(
                labelText: 'Language',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: _languageOptions
                  .map((tag) => DropdownMenuItem(value: tag, child: Text(tag.toUpperCase())))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _languageTag = v);
              },
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Caption',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'What did you learn in this clip?',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            SegmentedButton<ClipVisibility>(
              segments: const [
                ButtonSegment(
                  value: ClipVisibility.publicFeed,
                  label: Text('Village feed'),
                  icon: Icon(Icons.public),
                ),
                ButtonSegment(
                  value: ClipVisibility.circle,
                  label: Text('Circle'),
                  icon: Icon(Icons.groups_2_outlined),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (set) => setState(() => _visibility = set.first),
            ),
            if (_visibility == ClipVisibility.circle) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              DropdownButtonFormField<String>(
                value: _circleId,
                hint: const Text('Choose circle', style: TextStyle(color: Colors.white70)),
                dropdownColor: cs.surface,
                items: _circles
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String? ?? c['_id'] as String?,
                        child: Text(c['name'] as String? ?? 'Circle'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _circleId = v),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _state = _ClipFlowState.recording;
                    _mediaFile = null;
                  }),
                  child: const Text('Retake'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _submitPost,
                  child: const Text('Post clip'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.sm,
        PanAfricanSpacing.md,
        PanAfricanSpacing.lg,
      ),
      color: Colors.black.withValues(alpha: 0.9),
      child: Column(
        children: [
          SegmentedButton<ClipMediaKind>(
            segments: const [
              ButtonSegment(value: ClipMediaKind.video, label: Text('Video'), icon: Icon(Icons.videocam)),
              ButtonSegment(value: ClipMediaKind.audio, label: Text('Audio'), icon: Icon(Icons.mic)),
            ],
            selected: {_mediaKind},
            onSelectionChanged: (set) => setState(() => _mediaKind = set.first),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
              ),
              SizedBox(width: PanAfricanSpacing.lg),
              Semantics(
                button: true,
                label: _mediaKind == ClipMediaKind.video ? 'Record video clip' : 'Record audio clip',
                child: GestureDetector(
                  onTap: () {
                    if (_mediaKind == ClipMediaKind.video) {
                      unawaited(_pickVideoFromCamera());
                    } else if (_audioRecording) {
                      unawaited(_stopAudioRecording());
                    } else {
                      unawaited(_startAudioRecording());
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _audioRecording
                              ? cs.error
                              : PanAfricanColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            '${ClipUploadService.minDurationSec}–${ClipUploadService.maxDurationSec} sec · hold Village kindness',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statusPanel({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              title,
              style: PanAfricanTypography.headlineSmall(context).copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              subtitle,
              style: PanAfricanTypography.bodyMedium(context).copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(double sec) {
    final s = sec.floor().clamp(0, 999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }
}
