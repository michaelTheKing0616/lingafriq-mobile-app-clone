import 'package:flutter/material.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/widgets/tone_contour_line.dart';

/// Copy keys: lens.card.mic, lens.card.unsure (P7-907).
const String lensCardMicLabel = 'Practice pronunciation';
const String lensCardUnsureLabel = 'Tone check unsure — try again';

const double _lensWordFontSize = 28;
const double _micMinTouch = 48;

/// Tap-to-flip Word Card surfaced from a Lens detection (P7-907).
class LensDetectionWordCard extends StatefulWidget {
  const LensDetectionWordCard({
    super.key,
    required this.card,
    required this.detectionLabel,
    this.tonePattern = const [],
    this.syllables = const [],
    this.onMicPressed,
    this.showUnsure = false,
    this.initiallyFlipped = false,
  });

  final LensWordCard card;
  final String detectionLabel;
  final List<String> tonePattern;
  final List<String> syllables;
  final VoidCallback? onMicPressed;
  final bool showUnsure;
  final bool initiallyFlipped;

  @override
  State<LensDetectionWordCard> createState() => _LensDetectionWordCardState();
}

class _LensDetectionWordCardState extends State<LensDetectionWordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.initiallyFlipped ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      if (_controller.value < 0.5) {
        _controller.value = 1;
      } else {
        _controller.value = 0;
      }
      return;
    }
    if (_controller.status == AnimationStatus.completed ||
        _controller.value > 0.5) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  bool get _noAudio =>
      widget.card.audio.kind == LensWordCardAudioKind.noRecordingYet;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(16);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 2,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _onTap,
        borderRadius: radius,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (reduced) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _controller.value > 0.5
                    ? _FlippedWordCardFace(
                        key: const ValueKey('back'),
                        card: widget.card,
                        tonePattern: widget.tonePattern,
                        syllables: widget.syllables,
                        noAudio: _noAudio,
                        showUnsure: widget.showUnsure,
                        onMicPressed: widget.onMicPressed,
                      )
                    : _DetectionFrontFace(
                        key: const ValueKey('front'),
                        label: widget.detectionLabel,
                      ),
              );
            }

            final angle = _controller.value * 3.141592653589793;
            final showBack = _controller.value >= 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.141592653589793),
                      child: _FlippedWordCardFace(
                        card: widget.card,
                        tonePattern: widget.tonePattern,
                        syllables: widget.syllables,
                        noAudio: _noAudio,
                        showUnsure: widget.showUnsure,
                        onMicPressed: widget.onMicPressed,
                      ),
                    )
                  : _DetectionFrontFace(label: widget.detectionLabel),
            );
          },
        ),
      ),
    );
  }
}

class _DetectionFrontFace extends StatelessWidget {
  const _DetectionFrontFace({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FlippedWordCardFace extends StatelessWidget {
  const _FlippedWordCardFace({
    super.key,
    required this.card,
    required this.tonePattern,
    required this.syllables,
    required this.noAudio,
    required this.showUnsure,
    this.onMicPressed,
  });

  final LensWordCard card;
  final List<String> tonePattern;
  final List<String> syllables;
  final bool noAudio;
  final bool showUnsure;
  final VoidCallback? onMicPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: card.word,
            child: Text(
              card.word,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.25),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: _lensWordFontSize,
                    height: 1.25,
                  ),
            ),
          ),
          if (tonePattern.isNotEmpty) ...[
            const SizedBox(height: 12),
            ToneContourLine(
              tonePattern: tonePattern,
              syllables: syllables.isNotEmpty ? syllables : null,
            ),
          ],
          if (noAudio)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No recording yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (showUnsure)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                lensCardUnsureLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              button: true,
              label: lensCardMicLabel,
              child: SizedBox(
                width: _micMinTouch,
                height: _micMinTouch,
                child: FilledButton(
                  onPressed: onMicPressed,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(_micMinTouch, _micMinTouch),
                    fixedSize: const Size(_micMinTouch, _micMinTouch),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.mic, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
