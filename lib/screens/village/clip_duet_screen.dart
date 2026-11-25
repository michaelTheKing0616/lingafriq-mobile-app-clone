import 'dart:async';
import 'dart:convert';
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

/// Split-screen duet recorder — reference: TikTok duet layout + Instagram Reels remix.
enum _DuetFlowState { loading, recording, uploading, linked, blocked, error }

class ClipDuetScreen extends StatefulWidget {
  const ClipDuetScreen({
    super.key,
    required this.sourceClipId,
    required this.sourceCaption,
    required this.languageTag,
    this.prefetchAccess = true,
  });

  final String sourceClipId;
  final String sourceCaption;
  final String languageTag;
  final bool prefetchAccess;

  @override
  State<ClipDuetScreen> createState() => _ClipDuetScreenState();
}

class _ClipDuetScreenState extends State<ClipDuetScreen> {
  final _captionController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _picker = ImagePicker();

  _DuetFlowState _state = _DuetFlowState.loading;
  ClipMediaKind _mediaKind = ClipMediaKind.video;
  File? _mediaFile;
  double _durationSec = 0;
  String? _errorMessage;
  Timer? _recordTimer;
  DateTime? _recordStartedAt;
  bool _audioRecording = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.sourceCaption;
    if (widget.prefetchAccess) {
      unawaited(_prefetchAccess());
    } else {
      _state = _DuetFlowState.recording;
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _captionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _prefetchAccess() async {
    try {
      final response = await ApiService.get('/api/v2/clips/${widget.sourceClipId}/replies');
      final data = response.data;
      if (data is Map && data['ok'] != true) {
        final code = data['code'] as String? ?? '';
        if (code == 'DUET_BLOCKED') {
          if (!mounted) return;
          setState(() => _state = _DuetFlowState.blocked);
          return;
        }
      }
    } catch (_) {
      // Offline: still allow local record; post will queue fail with honest copy.
    }
    if (!mounted) return;
    setState(() => _state = _DuetFlowState.recording);
  }

  Future<void> _pickVideo() async {
    final clip = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
    if (clip == null || !mounted) return;
    final file = File(clip.path);
    const sec = 20.0;
    setState(() {
      _mediaFile = file;
      _mediaKind = ClipMediaKind.video;
      _durationSec = sec;
    });
  }

  Future<void> _toggleAudio() async {
    if (_audioRecording) {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();
      if (path == null || !mounted) return;
      setState(() {
        _audioRecording = false;
        _mediaFile = File(path);
        _mediaKind = ClipMediaKind.audio;
        _durationSec = _durationSec < ClipUploadService.minDurationSec
            ? ClipUploadService.minDurationSec.toDouble()
            : _durationSec;
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/duet_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: path);
    _recordStartedAt = DateTime.now();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordStartedAt == null) return;
      setState(() {
        _durationSec = DateTime.now().difference(_recordStartedAt!).inSeconds.toDouble();
      });
    });
    setState(() {
      _audioRecording = true;
      _durationSec = 0;
      _mediaKind = ClipMediaKind.audio;
    });
  }

  Future<void> _submitDuet() async {
    final file = _mediaFile;
    if (file == null) {
      setState(() {
        _state = _DuetFlowState.error;
        _errorMessage = 'Record your response after the original plays.';
      });
      return;
    }

    final durationCode = ClipUploadService.validateDurationSec(_durationSec);
    if (durationCode != null) {
      setState(() {
        _state = _DuetFlowState.error;
        _errorMessage =
            'Your response needs to be between ${ClipUploadService.minDurationSec} and ${ClipUploadService.maxDurationSec} seconds.';
      });
      return;
    }

    setState(() => _state = _DuetFlowState.uploading);

    try {
      final bytes = await file.readAsBytes();
      final response = await ApiService.post(
        '/api/v2/clips/${widget.sourceClipId}/duet',
        data: {
          'durationSec': _durationSec,
          'languageTag': widget.languageTag,
          'caption': _captionController.text.trim().isEmpty
              ? widget.sourceCaption
              : _captionController.text.trim(),
          'mediaKind': _mediaKind.apiValue,
          'mediaBase64': base64Encode(bytes),
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] == true) {
        if (!mounted) return;
        setState(() {
          _state = _DuetFlowState.linked;
          _errorMessage = null;
        });
        return;
      }
      if (data is Map && data['code'] == 'DUET_BLOCKED') {
        if (!mounted) return;
        setState(() => _state = _DuetFlowState.blocked);
        return;
      }
      if (!mounted) return;
      setState(() {
        _state = _DuetFlowState.error;
        _errorMessage = data is Map
            ? (data['message'] as String? ?? 'We could not link your duet right now.')
            : 'We could not link your duet right now.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _DuetFlowState.error;
        _errorMessage = 'You are offline. Your take stays here until you reconnect.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10nDuetStart = 'Start duet'; // copy_keys: duet.start
    final l10nDuetBlocked = 'Duet unavailable'; // copy_keys: duet.blocked
    final l10nTryAgain = 'Try Again';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          l10nDuetStart,
          style: PanAfricanTypography.titleLarge(context).copyWith(color: Colors.white),
        ),
      ),
      body: ResponsiveSafeArea(
        child: switch (_state) {
          _DuetFlowState.loading => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          _DuetFlowState.blocked => _messagePanel(
              icon: Icons.block_flipped,
              title: l10nDuetBlocked,
              subtitle: 'The creator has limited who can respond to this clip.',
            ),
          _DuetFlowState.linked => _messagePanel(
              icon: Icons.link_rounded,
              title: 'Linked to the original',
              subtitle: 'Your say-it-after-me take sits under their clip in the Village.',
              action: FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Done'),
              ),
            ),
          _DuetFlowState.uploading => _messagePanel(
              icon: Icons.cloud_upload_outlined,
              title: 'Linking your duet…',
              subtitle: 'We are checking your take to keep the Village kind and safe.',
            ),
          _DuetFlowState.error => _messagePanel(
              icon: Icons.error_outline,
              title: 'Could not link',
              subtitle: _errorMessage ?? l10nTryAgain,
              action: TextButton(
                onPressed: () => setState(() => _state = _DuetFlowState.recording),
                child: Text(l10nTryAgain),
              ),
            ),
          _DuetFlowState.recording => Column(
              children: [
                Expanded(
                  flex: 5,
                  child: _originalPane(context),
                ),
                Expanded(
                  flex: 5,
                  child: _responsePane(context, cs, l10nDuetStart),
                ),
              ],
            ),
        },
      ),
    );
  }

  Widget _originalPane(BuildContext context) {
    return Semantics(
      label: 'Original clip preview',
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          border: Border.all(color: Colors.white24),
          gradient: LinearGradient(
            colors: [
              PanAfricanColors.primary.withValues(alpha: 0.45),
              Colors.black87,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 56, color: Colors.white),
            SizedBox(height: PanAfricanSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
              child: Text(
                widget.sourceCaption,
                textAlign: TextAlign.center,
                style: PanAfricanTypography.bodyLarge(context).copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsePane(BuildContext context, ColorScheme cs, String duetStartLabel) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        0,
        PanAfricanSpacing.md,
        PanAfricanSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your turn',
            style: PanAfricanTypography.titleMedium(context).copyWith(color: Colors.white),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a warm caption',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(PanAfricanRadius.md)),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: _mediaFile != null
                  ? Icon(
                      _mediaKind == ClipMediaKind.video ? Icons.videocam_rounded : Icons.mic_rounded,
                      size: 48,
                      color: Colors.white70,
                    )
                  : Text(
                      '${_durationSec.round()}s',
                      style: PanAfricanTypography.headlineSmall(context).copyWith(color: Colors.white70),
                    ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Record video duet response',
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Record audio duet response',
                  child: OutlinedButton.icon(
                    onPressed: _toggleAudio,
                    icon: Icon(_audioRecording ? Icons.stop_rounded : Icons.mic_none_rounded),
                    label: Text(_audioRecording ? 'Stop' : 'Audio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Semantics(
            button: true,
            label: duetStartLabel,
            child: FilledButton(
              onPressed: _submitDuet,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: PanAfricanColors.primary,
              ),
              child: Text(duetStartLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagePanel({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.titleLarge(context).copyWith(color: Colors.white),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyMedium(context).copyWith(color: Colors.white70),
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
}
