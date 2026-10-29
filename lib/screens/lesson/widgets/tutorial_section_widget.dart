import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/services/content/curriculum_audio_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';
import 'package:lingafriq/widgets/bidi_text.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import '../models/lesson_content.dart';

/// Speakers who present new phrases (bundled cast stills), picked per
/// section so a lesson feels like meeting people, not reading cards.
const List<String> kTutorialSpeakers = [
  'assets/images/cast_still_Amara.png',
  'assets/images/cast_still_Kofi.png',
  'assets/images/cast_still_Zuri.png',
  'assets/images/cast_still_Adisa.png',
];

/// Teach step (lesson-flow pack: character + speech bubble, play button,
/// example, one primary action). The body fills the viewport so short
/// content sits centred rather than floating over empty space.
class TutorialSectionWidget extends ConsumerStatefulWidget {
  final LessonContent content;
  final VoidCallback onContinue;
  final String? vocabAudioLanguage;
  final String? vocabAudioText;

  const TutorialSectionWidget({
    super.key,
    required this.content,
    required this.onContinue,
    this.vocabAudioLanguage,
    this.vocabAudioText,
  });

  @override
  ConsumerState<TutorialSectionWidget> createState() =>
      _TutorialSectionWidgetState();
}

class _TutorialSectionWidgetState extends ConsumerState<TutorialSectionWidget> {
  bool get _hasTts =>
      widget.vocabAudioLanguage != null &&
      (widget.vocabAudioText ?? '').trim().isNotEmpty;

  void _speak({required bool slow}) {
    ref
        .read(curriculumAudioServiceProvider)
        .speakPhrase(
          language: widget.vocabAudioLanguage!,
          text: widget.vocabAudioText!,
          slow: slow,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final c = widget.content;
    final hasAudio = (c.audioUrl ?? '').isNotEmpty;
    final hasVideo = (c.videoUrl ?? '').isNotEmpty;
    final hasImage = (c.imageUrl ?? '').isNotEmpty;
    final text = (c.text ?? '').trim();

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final gap = box.maxHeight < 420 ? 12.0 : 20.0;
              final speakerH = (box.maxHeight * 0.30).clamp(110.0, 240.0);
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: gap),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (box.maxHeight - gap * 2).clamp(0, 1e9),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Eyebrow(label: l.lessonNewPhrase),
                          SizedBox(height: gap),
                          if (hasVideo)
                            Semantics(
                              label: l.lessonTutorialVideo,
                              child: PanAfricanCard(
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: PanAfricanRadius.lgBR,
                                  child: PortraitPlayerPage(
                                    videoUrl: c.videoUrl!,
                                  ),
                                ),
                              ),
                            )
                          else if (hasImage)
                            ClipRRect(
                              borderRadius: PanAfricanRadius.lgBR,
                              child: CachedNetworkImage(
                                imageUrl: c.imageUrl!,
                                height: speakerH,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _speakerScene(speakerH),
                                errorWidget: (_, __, ___) =>
                                    _speakerScene(speakerH),
                              ),
                            ),
                          _PhraseBubble(
                            key: const Key('tutorial-phrase'),
                            speaker: hasVideo || hasImage
                                ? null
                                : kTutorialSpeakers[c.sectionId.abs() %
                                      kTutorialSpeakers.length],
                            speakerHeight: speakerH,
                            phrase: c.title,
                            onPlay: _hasTts ? () => _speak(slow: false) : null,
                            onPlaySlow: _hasTts
                                ? () => _speak(slow: true)
                                : null,
                          ),
                          if (hasAudio) ...[
                            SizedBox(height: gap),
                            Semantics(
                              label: l.lessonTutorialAudio,
                              child: PanAfricanCard(
                                padding: EdgeInsets.all(12.w),
                                child: AudioPlayerWidget(audioUrl: c.audioUrl!),
                              ),
                            ),
                          ],
                          if (text.isNotEmpty) ...[
                            SizedBox(height: gap),
                            _ExampleCard(
                              label: l.lessonExampleLabel,
                              text: text,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.w),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Semantics(
                  label: l.lessonContinueNext,
                  button: true,
                  child: PanAfricanButton(
                    width: double.infinity,
                    onPressed: widget.onContinue,
                    label: l.continueButton,
                    // arrow_forward_rounded sets matchTextDirection, so
                    // Flutter already points it left in RTL.
                    icon: Icons.arrow_forward_rounded,
                    // White on the deep brand green clears 4.5:1 in both
                    // themes; colorScheme.onPrimary can resolve dark.
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _speakerScene(double h) =>
      Container(height: h, color: PanAfricanColors.secondaryContainer);
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
          decoration: BoxDecoration(
            color: PanAfricanColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: PanAfricanColors.onTertiaryContainer,
              ),
              SizedBox(width: 6.w),
              Text(
                label.toUpperCase(),
                style: PanAfricanTypography.labelMedium(context).copyWith(
                  color: PanAfricanColors.onTertiaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A presenter (cast still) beside a speech bubble holding the phrase and
/// its play buttons.
class _PhraseBubble extends StatelessWidget {
  const _PhraseBubble({
    super.key,
    required this.speaker,
    required this.speakerHeight,
    required this.phrase,
    this.onPlay,
    this.onPlaySlow,
  });

  final String? speaker;
  final double speakerHeight;
  final String phrase;
  final VoidCallback? onPlay;
  final VoidCallback? onPlaySlow;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final bubble = Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        border: Border.all(color: PanAfricanColors.borderLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BidiText(
            phrase,
            style: PanAfricanTypography.headlineSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          if (onPlay != null) ...[
            SizedBox(height: 12.w),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PlayButton(
                  key: const Key('tutorial-play'),
                  icon: Icons.volume_up_rounded,
                  label: l.lessonListen,
                  onTap: onPlay!,
                  filled: true,
                ),
                _PlayButton(
                  key: const Key('tutorial-play-slow'),
                  icon: Icons.slow_motion_video_rounded,
                  label: l.lessonListenSlowly,
                  onTap: onPlaySlow!,
                  filled: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
    if (speaker == null) return bubble;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: speakerHeight * 0.42,
            height: speakerHeight,
            child: Image.asset(
              speaker!,
              fit: BoxFit.cover,
              key: const Key('tutorial-speaker'),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: speakerHeight * 0.25),
            child: bubble,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
    return filled
        ? FilledButton.icon(
            style: style.merge(
              FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.kenteBlue.withValues(
                  alpha: 1,
                ),
                foregroundColor: PanAfricanColors.neutralDarkest,
              ),
            ),
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            style: style,
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: PanAfricanColors.secondaryContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        border: const BorderDirectional(
          start: BorderSide(color: PanAfricanColors.secondaryDark, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PanAfricanTypography.labelLarge(context).copyWith(
              color: PanAfricanColors.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.w),
          BidiText(
            text,
            style: PanAfricanTypography.bodyLarge(
              context,
            ).copyWith(height: 1.5, color: PanAfricanColors.neutralDarkest),
          ),
        ],
      ),
    );
  }
}
