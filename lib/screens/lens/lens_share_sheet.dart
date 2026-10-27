import 'package:flutter/material.dart';
import 'package:lingafriq/services/lens/face_blur.dart';
import 'package:lingafriq/services/lens/lens_clip_service.dart';
import 'package:lingafriq/services/lens/lens_privacy_policy.dart';

/// Copy key: lens.share.blocked
const String lensShareBlockedMessage =
    'Sharing is blocked until faces are blurred safely. Try another photo.';

const String lensShareMinorBlockedMessage =
    'Village Clips need a guardian to turn on social sharing for under-18 accounts.';

class LensShareSheet extends StatefulWidget {
  const LensShareSheet({
    super.key,
    required this.draft,
    required this.privacy,
    this.guardianSocialConsentRecorded = false,
    this.clipService,
    this.faceDetector,
    this.uploader,
    this.onShared,
  });

  final LensClipDraft draft;
  final LensLearnerPrivacyContext privacy;
  final bool guardianSocialConsentRecorded;
  final LensClipService? clipService;
  final LensFaceDetector? faceDetector;
  final LensVillageClipUploader? uploader;
  final void Function(String clipId)? onShared;

  @override
  State<LensShareSheet> createState() => _LensShareSheetState();
}

class _LensShareSheetState extends State<LensShareSheet> {
  LensClipSharePhase _phase = LensClipSharePhase.idle;
  String? _blockedMessage;
  LensClipService? _service;

  @override
  void initState() {
    super.initState();
    final pre = lensClipSharePrecheck(
      LensClipShareRequest(
        draft: widget.draft,
        privacy: widget.privacy,
        guardianSocialConsentRecorded: widget.guardianSocialConsentRecorded,
      ),
    );
    if (pre == LensClipShareBlockReason.minorVillageSharingBlocked) {
      _phase = LensClipSharePhase.blocked;
      _blockedMessage = lensShareMinorBlockedMessage;
    }
  }

  LensClipService _buildService() {
    return widget.clipService ??
        LensClipService(
          faceDetector: widget.faceDetector ?? MlKitLensFaceDetector(),
          uploader: widget.uploader ?? _NoOpVillageClipUploader(),
        );
  }

  Future<void> _share() async {
    if (_phase == LensClipSharePhase.blocked) return;
    setState(() => _phase = LensClipSharePhase.blurring);
    _service = _buildService();
    final result = await _service!.shareToVillage(
      LensClipShareRequest(
        draft: widget.draft,
        privacy: widget.privacy,
        guardianSocialConsentRecorded: widget.guardianSocialConsentRecorded,
      ),
    );
    if (!mounted) return;
    switch (result.phase) {
      case LensClipSharePhase.done:
        setState(() => _phase = LensClipSharePhase.done);
        widget.onShared?.call(result.clipId!);
        Navigator.of(context).pop(true);
        return;
      case LensClipSharePhase.cancelled:
        setState(() => _phase = LensClipSharePhase.cancelled);
        Navigator.of(context).pop(false);
        return;
      case LensClipSharePhase.blocked:
        setState(() {
          _phase = LensClipSharePhase.blocked;
          _blockedMessage = _messageFor(result.blockReason);
        });
        return;
      case LensClipSharePhase.blurring:
      case LensClipSharePhase.uploading:
      case LensClipSharePhase.idle:
        setState(() => _phase = result.phase);
        return;
    }
  }

  String _messageFor(LensClipShareBlockReason? reason) {
    switch (reason) {
      case LensClipShareBlockReason.minorVillageSharingBlocked:
        return lensShareMinorBlockedMessage;
      case LensClipShareBlockReason.faceDetectionFailed:
      case LensClipShareBlockReason.faceDecodeFailed:
        return lensShareBlockedMessage;
      case LensClipShareBlockReason.uploadFailed:
        return 'Could not upload your Clip. Check your connection and try again.';
      case null:
        return lensShareBlockedMessage;
    }
  }

  void _cancel() {
    _service?.cancelShare();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = Image.memory(
      widget.draft.sourceJpegBytes,
      fit: BoxFit.contain,
      semanticLabel: 'Lens photo preview',
    );
    final overlay = widget.draft.phraseOverlay.isNotEmpty
        ? Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(
              widget.draft.phraseOverlay,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
              textAlign: TextAlign.center,
            ),
          )
        : const SizedBox.shrink();

    final busy = _phase == LensClipSharePhase.blurring ||
        _phase == LensClipSharePhase.uploading;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share Lens Clip', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: preview,
                  ),
                  overlay,
                  if (busy)
                    const ColoredBox(
                      color: Colors.black38,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            if (_blockedMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _blockedMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_phase == LensClipSharePhase.blocked || busy)
                        ? null
                        : _share,
                    child: Text(busy ? 'Preparing…' : 'Share to Village'),
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

class _NoOpVillageClipUploader implements LensVillageClipUploader {
  @override
  Future<LensVillageClipUploadResult> upload(LensClipUploadPayload payload) async {
    throw StateError('LensVillageClipUploader not configured');
  }
}

Future<bool?> showLensShareSheet({
  required BuildContext context,
  required LensClipDraft draft,
  required LensLearnerPrivacyContext privacy,
  bool guardianSocialConsentRecorded = false,
  LensClipService? clipService,
  LensFaceDetector? faceDetector,
  LensVillageClipUploader? uploader,
  void Function(String clipId)? onShared,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => LensShareSheet(
      draft: draft,
      privacy: privacy,
      guardianSocialConsentRecorded: guardianSocialConsentRecorded,
      clipService: clipService,
      faceDetector: faceDetector,
      uploader: uploader,
      onShared: onShared,
    ),
  );
}
