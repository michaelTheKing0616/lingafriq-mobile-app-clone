import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/micro_lesson.dart';
import '../../services/tutorials/micro_lesson_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';

class MicroLessonScreen extends StatefulWidget {
  const MicroLessonScreen({
    super.key,
    required this.lesson,
    required this.service,
  });

  final MicroLesson lesson;
  final MicroLessonService service;

  @override
  State<MicroLessonScreen> createState() => _MicroLessonScreenState();
}

class _MicroLessonScreenState extends State<MicroLessonScreen>
    with WidgetsBindingObserver {
  int _stepIndex = 0;
  bool _paused = false;
  bool _mediaLoading = false;
  MicroLessonMediaException? _mediaError;
  bool _initialized = false;

  MicroLesson get _lesson => widget.lesson;
  MicroLessonService get _service => widget.service;

  MicroLessonStepContent get _currentStep => _lesson.steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _service.validateContent(_lesson);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaError = MicroLessonMediaException(
          MicroLessonContentCodes.runtimeOutOfRange,
          e.toString(),
        );
        _initialized = true;
      });
      return;
    }

    final saved = await _service.loadSession(_lesson.id);
    if (saved != null && saved.lessonId == _lesson.id) {
      final clamped = saved.stepIndex.clamp(0, _lesson.steps.length - 1);
      _stepIndex = clamped;
      _paused = saved.paused;
    }
    if (!mounted) return;
    setState(() => _initialized = true);
    await _loadMediaForCurrentStep();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistSession(paused: true);
      if (mounted) setState(() => _paused = true);
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _paused = false);
      SemanticsService.announce(
        'Tutorial resumed at step ${_stepIndex + 1} of ${_lesson.steps.length}',
        TextDirection.ltr,
      );
    }
  }

  Future<void> _persistSession({required bool paused}) async {
    await _service.saveSession(
      MicroLessonSessionState(
        lessonId: _lesson.id,
        stepIndex: _stepIndex,
        paused: paused,
      ),
    );
  }

  Future<void> _loadMediaForCurrentStep() async {
    setState(() {
      _mediaLoading = true;
      _mediaError = null;
    });
    try {
      await _service.loadStepMedia(_currentStep);
      if (!mounted) return;
      setState(() => _mediaLoading = false);
    } on MicroLessonMediaException catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaLoading = false;
        _mediaError = e;
      });
    }
  }

  void _advanceStep() {
    if (_stepIndex >= _lesson.steps.length - 1) {
      _service.clearSession(_lesson.id);
      if (!mounted) return;
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _stepIndex++);
    _persistSession(paused: false);
    _loadMediaForCurrentStep();
    SemanticsService.announce(
      'Step ${_stepIndex + 1} of ${_lesson.steps.length}: ${_currentStep.kind.defaultTitle}',
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final step = _currentStep;
    final title = step.kind.defaultTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: LinearProgressIndicator(
            value: (_stepIndex + 1) / _lesson.steps.length,
            backgroundColor: PanAfricanColors.cardDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label:
                    'Tutorial step ${_stepIndex + 1} of ${_lesson.steps.length}. $title.',
                header: true,
                child: const SizedBox.shrink(),
              ),
              if (_paused) ...[
                SizedBox(height: 8.h),
                const Text(
                  'Paused',
                  style: TextStyle(color: PanAfricanColors.neutralMedium),
                ),
              ],
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mediaLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_mediaError != null)
                        _MediaErrorPanel(
                          error: _mediaError!,
                          onRetry: _loadMediaForCurrentStep,
                        )
                      else if (step.mediaKind != MicroLessonMediaKind.none &&
                          step.mediaUri != null)
                        _MediaPlaceholder(kind: step.mediaKind),
                      SizedBox(height: 16.h),
                      Text(step.body),
                    ],
                  ),
                ),
              ),
              PanAfricanButton(
                label: _stepIndex >= _lesson.steps.length - 1
                    ? 'Finish'
                    : 'Continue',
                onPressed: _mediaError != null ? null : _advanceStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.kind});

  final MicroLessonMediaKind kind;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      MicroLessonMediaKind.video => 'Video with captions',
      MicroLessonMediaKind.audio => 'Audio',
      MicroLessonMediaKind.image => 'Illustration',
      MicroLessonMediaKind.none => '',
    };
    return PanAfricanCard(
      child: SizedBox(
        height: 120.h,
        child: Center(
          child: Semantics(
            label: label,
            child: Icon(
              kind == MicroLessonMediaKind.video
                  ? Icons.play_circle_outline
                  : Icons.perm_media_outlined,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaErrorPanel extends StatelessWidget {
  const _MediaErrorPanel({
    required this.error,
    required this.onRetry,
  });

  final MicroLessonMediaException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PanAfricanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media error: ${error.code}',
            style: const TextStyle(color: PanAfricanColors.error),
          ),
          if (error.detail != null) Text(error.detail!),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
