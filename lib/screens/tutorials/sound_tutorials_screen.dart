import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/tutorials/sound_tutorial_repo.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/mouth_video_player.dart';

enum SoundTutorialsUiState { list, playing, comingSoon, error }

class SoundTutorialsScreen extends StatefulWidget {
  const SoundTutorialsScreen({
    super.key,
    required this.languageCode,
    this.repo,
    this.mouthVideoPlayerBuilder,
  });

  final String languageCode;
  final SoundTutorialRepo? repo;
  final Widget Function({
    required String videoUrl,
    required String caption,
    required bool offersSlowMotion,
  })? mouthVideoPlayerBuilder;

  @override
  State<SoundTutorialsScreen> createState() => _SoundTutorialsScreenState();
}

class _SoundTutorialsScreenState extends State<SoundTutorialsScreen> {
  late final SoundTutorialRepo _repo;
  SoundTutorialsUiState _uiState = SoundTutorialsUiState.list;
  SoundTutorialEntry? _selected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? const SoundTutorialRepo();
  }

  List<SoundTutorialEntry> get _entries =>
      _repo.forLanguage(widget.languageCode);

  void _openEntry(SoundTutorialEntry entry) {
    if (entry.hasNativeVideo) {
      final uri = entry.nativeVideoUri!.trim();
      final caption = entry.caption?.trim() ?? '';
      if (caption.isEmpty) {
        setState(() {
          _uiState = SoundTutorialsUiState.error;
          _errorMessage = 'Tutorial video is missing captions.';
          _selected = entry;
        });
        return;
      }
      setState(() {
        _selected = entry;
        _uiState = SoundTutorialsUiState.playing;
        _errorMessage = null;
      });
      return;
    }
    setState(() {
      _selected = entry;
      _uiState = SoundTutorialsUiState.comingSoon;
      _errorMessage = null;
    });
    SemanticsService.announce(kSoundComingSoonFallback, TextDirection.ltr);
  }

  void _backToList() {
    setState(() {
      _uiState = SoundTutorialsUiState.list;
      _selected = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        title: Text(
          'Sound tutorials',
          style: PanAfricanTypography.titleLarge(context),
        ),
        automaticallyImplyLeading: _uiState != SoundTutorialsUiState.list,
        leading: _uiState == SoundTutorialsUiState.list
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToList,
                tooltip: 'Back to list',
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_uiState) {
      case SoundTutorialsUiState.list:
        return _buildList(context);
      case SoundTutorialsUiState.playing:
        return _buildPlaying(context);
      case SoundTutorialsUiState.comingSoon:
        return _buildComingSoon(context);
      case SoundTutorialsUiState.error:
        return _buildError(context);
    }
  }

  Widget _buildList(BuildContext context) {
    final entries = _entries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No sound tutorials for this language yet.',
          style: PanAfricanTypography.bodyLarge(context),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final badge = entry.hasNativeVideo
            ? null
            : kSoundComingSoonFallback;
        return Semantics(
          button: true,
          label: '${entry.title}${badge != null ? ', $badge' : ''}',
          child: ListTile(
            minVerticalPadding: 12,
            title: Text(
              entry.title,
              style: PanAfricanTypography.titleMedium(context),
            ),
            trailing: badge != null
                ? Chip(
                    label: Text(
                      badge,
                      style: PanAfricanTypography.labelSmall(context),
                    ),
                  )
                : const Icon(Icons.play_circle_outline),
            onTap: () => _openEntry(entry),
          ),
        );
      },
    );
  }

  Widget _buildPlaying(BuildContext context) {
    final entry = _selected!;
    final uri = entry.nativeVideoUri!.trim();
    final caption = entry.caption!.trim();

    final player = widget.mouthVideoPlayerBuilder != null
        ? widget.mouthVideoPlayerBuilder!(
            videoUrl: uri,
            caption: caption,
            offersSlowMotion: entry.slowMotionAvailable,
          )
        : MouthVideoPlayer(
            videoUrl: uri,
            caption: caption,
            offersSlowMotion: entry.slowMotionAvailable,
            playerBuilder: null,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entry.title,
          style: PanAfricanTypography.headlineSmall(context),
        ),
        SizedBox(height: 12.h),
        Expanded(child: SingleChildScrollView(child: player)),
      ],
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    final entry = _selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entry.title,
          style: PanAfricanTypography.headlineSmall(context),
        ),
        SizedBox(height: 24.h),
        Icon(
          Icons.videocam_off_outlined,
          size: 64.sp,
          color: PanAfricanColors.neutralMedium,
        ),
        SizedBox(height: 16.h),
        Text(
          kSoundComingSoonFallback,
          style: PanAfricanTypography.titleMedium(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Native mouth video will appear here after recording. '
          'No stand-in clip is shown.',
          style: PanAfricanTypography.bodyMedium(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _selected?.title ?? 'Tutorial',
          style: PanAfricanTypography.headlineSmall(context),
        ),
        SizedBox(height: 16.h),
        Text(
          _errorMessage ?? 'Something went wrong.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
        SizedBox(height: 16.h),
        FilledButton(
          onPressed: _backToList,
          child: const Text('Back'),
        ),
      ],
    );
  }
}
