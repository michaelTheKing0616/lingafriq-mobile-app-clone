import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/lens/lens_language_chip.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copy key: [lens.permission.denied]
const String lensPermissionDeniedMessage =
    'Lens needs camera access to show what you are pointing at.';

const String _sessionLanguageKey = 'lens_session_language';

class LensDetection {
  const LensDetection({
    required this.boundingBox,
    required this.label,
  });

  /// Normalised rect in preview coordinates (0–1).
  final Rect boundingBox;
  final String label;
}

enum LensCameraPhase {
  loading,
  live,
  permissionDenied,
  noCamera,
}

class LensScreen extends ConsumerStatefulWidget {
  const LensScreen({
    super.key,
    required this.fallbackLanguage,
    this.debugPreview,
    this.debugDetections,
    this.skipCameraInit = false,
    this.onDetectionLabelTap,
  });

  final String fallbackLanguage;
  final Widget? debugPreview;
  final List<LensDetection>? debugDetections;
  final bool skipCameraInit;
  final void Function(String mlKitLabel)? onDetectionLabelTap;

  @override
  ConsumerState<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends ConsumerState<LensScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  LensCameraPhase _phase = LensCameraPhase.loading;
  List<LensDetection> _detections = const [];
  String _languageCode = 'yoruba';
  List<String> _profileCodes = const ['yoruba'];
  ObjectDetector? _detector;
  bool _processingFrame = false;
  DateTime _lastDetectAt = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = ref.read(userProvider);
    final codes = lensProfileLanguageCodes(profile: profile, prefs: prefs);
    _profileCodes = codes;
    final session = normalizeLensLanguageCode(
      prefs.getString(_sessionLanguageKey),
    );
    final route = normalizeLensLanguageCode(widget.fallbackLanguage);
    final initial = session != null && codes.contains(session)
        ? session
        : (route != null && codes.contains(route)
            ? route
            : codes.first);
    if (mounted) {
      setState(() => _languageCode = initial);
    }

    if (widget.debugDetections != null) {
      setState(() {
        _detections = widget.debugDetections!;
        _phase = LensCameraPhase.live;
      });
      return;
    }

    if (widget.skipCameraInit || widget.debugPreview != null) {
      setState(() => _phase = LensCameraPhase.live);
      return;
    }

    await _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() => _phase = LensCameraPhase.loading);

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _phase = LensCameraPhase.permissionDenied);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _phase = LensCameraPhase.noCamera);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      _detector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.stream,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );
      _controller = controller;
      if (!mounted) return;
      setState(() => _phase = LensCameraPhase.live);
      await controller.startImageStream(_onCameraImage);
    } catch (e, st) {
      debugPrint('LensScreen._initCamera: $e\n$st');
      if (mounted) setState(() => _phase = LensCameraPhase.noCamera);
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_processingFrame || _detector == null) return;
    final now = DateTime.now();
    if (now.difference(_lastDetectAt).inMilliseconds < 900) return;
    _lastDetectAt = now;
    _processingFrame = true;
    try {
      final input = _inputImageFromCamera(image, _controller!.description);
      if (input == null) return;
      final objects = await _detector!.processImage(input);
      final next = <LensDetection>[];
      for (final o in objects) {
        final label = o.labels.isNotEmpty ? o.labels.first.text.trim() : 'object';
        if (label.isEmpty) continue;
        final box = o.boundingBox;
        final size = _controller!.value.previewSize;
        if (size == null) continue;
        next.add(
          LensDetection(
            label: label,
            boundingBox: Rect.fromLTWH(
              box.left / size.width,
              box.top / size.height,
              box.width / size.width,
              box.height / size.height,
            ),
          ),
        );
      }
      if (mounted) setState(() => _detections = next.take(8).toList());
    } catch (_) {
      // Detection is best-effort; preview must stay live.
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image, CameraDescription desc) {
    final rotation = InputImageRotationValue.fromRawValue(desc.sensorOrientation);
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _persistSessionLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionLanguageKey, code);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed && _phase == LensCameraPhase.live) {
      controller.startImageStream(_onCameraImage);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: const Text('Lens'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LensLanguageChip(
              selectedCode: _languageCode,
              profileCodes: _profileCodes,
              onSelected: (code) {
                setState(() => _languageCode = code);
                _persistSessionLanguage(code);
              },
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case LensCameraPhase.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case LensCameraPhase.permissionDenied:
        return _PermissionDeniedState(
          onOpenSettings: () => openAppSettings(),
        );
      case LensCameraPhase.noCamera:
        return const Center(
          child: Text(
            'No camera is available on this device.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
      case LensCameraPhase.live:
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            LensDetectionOverlay(
              detections: _detections,
              reducedMotion: MediaQuery.disableAnimationsOf(context),
              onLabelTap: widget.onDetectionLabelTap,
            ),
          ],
        );
    }
  }

  Widget _buildPreview() {
    if (widget.debugPreview != null) return widget.debugPreview!;
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return CameraPreview(controller);
    }
    return const ColoredBox(color: Colors.black);
  }
}

class _PermissionDeniedState extends StatelessWidget {
  const _PermissionDeniedState({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              lensPermissionDeniedMessage,
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class LensDetectionOverlay extends StatelessWidget {
  const LensDetectionOverlay({
    super.key,
    required this.detections,
    required this.reducedMotion,
    this.onLabelTap,
  });

  final List<LensDetection> detections;
  final bool reducedMotion;
  final void Function(String mlKitLabel)? onLabelTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final d in detections)
              Positioned(
                left: d.boundingBox.left * constraints.maxWidth,
                top: d.boundingBox.top * constraints.maxHeight,
                width: d.boundingBox.width * constraints.maxWidth,
                height: d.boundingBox.height * constraints.maxHeight,
                child: BreathingDetectionBox(
                  label: d.label,
                  animate: !reducedMotion,
                  onTap: onLabelTap == null ? null : () => onLabelTap!(d.label),
                ),
              ),
          ],
        );
      },
    );
  }
}

class BreathingDetectionBox extends StatefulWidget {
  const BreathingDetectionBox({
    super.key,
    required this.label,
    required this.animate,
    this.onTap,
  });

  final String label;
  final bool animate;
  final VoidCallback? onTap;

  @override
  State<BreathingDetectionBox> createState() => _BreathingDetectionBoxState();
}

class _BreathingDetectionBoxState extends State<BreathingDetectionBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathingDetectionBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.animate
        ? Tween<double>(begin: 0.96, end: 1.04).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          )
        : const AlwaysStoppedAnimation(1.0);

    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: child,
        );
      },
      child: Semantics(
        button: widget.onTap != null,
        label: widget.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2,
                ),
                color: Colors.black.withValues(alpha: 0.25),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(6),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
