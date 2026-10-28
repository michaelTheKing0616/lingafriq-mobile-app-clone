import 'package:flutter/material.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_audio_client.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/lens/word_card_builder.dart';
import 'package:lingafriq/widgets/dialect_chips.dart';
import 'package:lingafriq/widgets/tone_contour_line.dart';
import 'package:lingafriq/screens/lens/see_it_in_the_wild.dart';
import 'package:lingafriq/widgets/tone_lens_contour.dart';

/// copy_keys: wordcard.ai_draft, wordcard.save, wordcard.practise (P7-922).
const String kWordCardAiDraftCopy = lensAiDraftHonestLabel;
const String kWordCardSaveLabel = 'Save';
const String kWordCardPractiseLabel = 'Practise';

const double kWordCardLemmaFontSize = 36;
const double kWordCardLemmaLineHeight = 1.45;

class WordCardSpeakerClip {
  const WordCardSpeakerClip({
    required this.voiceId,
    required this.uri,
    this.speed = 'natural',
    this.dialectTag,
  });

  final String voiceId;
  final String uri;
  final String speed;
  final String? dialectTag;
}

class WordCardExampleLine {
  const WordCardExampleLine({
    required this.text,
    this.audioUri,
  });

  final String text;
  final String? audioUri;
}

/// Parsed sheet payload for tests and UI (P7-922).
class WordCardSheetModel {
  WordCardSheetModel({
    required this.lexemeId,
    required this.language,
    required this.standardWord,
    required this.tonePattern,
    required this.syllables,
    required this.speakerClips,
    required this.examples,
    required this.dialectVariants,
    required this.showsAiDraftBadge,
    required this.gloss,
  });

  final String lexemeId;
  final String language;
  final String standardWord;
  final List<String> tonePattern;
  final List<String> syllables;
  final List<WordCardSpeakerClip> speakerClips;
  final List<WordCardExampleLine> examples;
  final List<LensDialectVariant> dialectVariants;
  final bool showsAiDraftBadge;
  final String? gloss;

  factory WordCardSheetModel.fromLexeme(
    VerifiedLexeme lexeme, {
    LexiconAudioBundle? audioBundle,
    bool showsAiDraftBadge = false,
  }) {
    final tone = lensLemmaToneFromEntry(lexeme.raw);
    return WordCardSheetModel(
      lexemeId: lexeme.lexemeId,
      language: lexeme.language,
      standardWord: lexeme.standardOrthography.isNotEmpty
          ? lexeme.standardOrthography
          : lexeme.lemma,
      tonePattern: tone.tonePattern,
      syllables: tone.syllables,
      speakerClips: wordCardSpeakerClipsFromEntry(
        lexeme.raw,
        audioBundle: audioBundle,
      ),
      examples: wordCardExamplesFromEntry(lexeme.raw),
      dialectVariants: lensParseDialectVariants(lexeme.raw),
      showsAiDraftBadge: showsAiDraftBadge,
      gloss: _firstGloss(lexeme.raw),
    );
  }
}

String? _firstGloss(Map<String, dynamic> entry) {
  final senses = entry['senses'];
  if (senses is! List || senses.isEmpty) return null;
  final first = senses.first;
  if (first is! Map) return null;
  final map = first.cast<String, dynamic>();
  return (map['gloss_en'] ?? map['gloss'])?.toString();
}

List<WordCardSpeakerClip> wordCardSpeakerClipsFromEntry(
  Map<String, dynamic> entry, {
  LexiconAudioBundle? audioBundle,
}) {
  if (audioBundle != null && audioBundle.recordings.isNotEmpty) {
    return audioBundle.recordings
        .where((r) => r.uri.trim().isNotEmpty)
        .map(
          (r) => WordCardSpeakerClip(
            voiceId: r.voiceId.isNotEmpty ? r.voiceId : 'speaker',
            uri: r.uri,
            speed: r.speed,
          ),
        )
        .toList();
  }
  final out = <WordCardSpeakerClip>[];
  final audio = entry['audio'];
  if (audio is! List) return out;
  for (final clip in audio) {
    if (clip is! Map) continue;
    final map = clip.cast<String, dynamic>();
    if (map['kind']?.toString() == 'tts_synthetic') continue;
    final uri = map['uri']?.toString().trim() ?? '';
    if (uri.isEmpty) continue;
    final voice = map['voice_id']?.toString().trim();
    out.add(
      WordCardSpeakerClip(
        voiceId: voice != null && voice.isNotEmpty ? voice : 'speaker_${out.length + 1}',
        uri: uri,
        speed: (map['speed'] ?? 'natural').toString(),
        dialectTag: map['dialect_tag']?.toString(),
      ),
    );
  }
  return out;
}

List<WordCardExampleLine> wordCardExamplesFromEntry(Map<String, dynamic> entry) {
  final out = <WordCardExampleLine>[];
  final senses = entry['senses'];
  if (senses is! List) return out;
  for (final sense in senses) {
    if (sense is! Map) continue;
    final map = sense.cast<String, dynamic>();
    final text = (map['example_target'] ?? '').toString().trim();
    if (text.isEmpty) continue;
    final uri = (map['example_audio_uri'] ?? map['example_uri'])?.toString().trim();
    out.add(WordCardExampleLine(text: text, audioUri: uri?.isNotEmpty == true ? uri : null));
  }
  return out;
}

bool wordCardSheetShowsAiDraft({
  required VerifiedLexeme lexeme,
  bool forceAiDraft = false,
}) {
  if (forceAiDraft) return true;
  final provenance = lexeme.raw['provenance'];
  if (provenance is Map && provenance['ai_assisted'] == true) {
    return true;
  }
  final status = lexeme.verificationStatus.trim().toLowerCase();
  return status == 'beta' || status == 'draft';
}

typedef WordCardAudioPlayHandler = void Function(String uri, {String? label});

Future<void> showWordCardSheet(
  BuildContext context, {
  required VerifiedLexeme lexeme,
  LexiconAudioBundle? audioBundle,
  bool showsAiDraftBadge = false,
  WordCardAudioPlayHandler? onPlayAudio,
  VoidCallback? onSave,
  VoidCallback? onPractise,
}) {
  final model = WordCardSheetModel.fromLexeme(
    lexeme,
    audioBundle: audioBundle,
    showsAiDraftBadge:
        showsAiDraftBadge || wordCardSheetShowsAiDraft(lexeme: lexeme),
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => WordCardSheet(
      model: model,
      onPlayAudio: onPlayAudio,
      onSave: onSave,
      onPractise: onPractise,
    ),
  );
}

class WordCardSheet extends StatefulWidget {
  const WordCardSheet({
    super.key,
    required this.model,
    this.onPlayAudio,
    this.onSave,
    this.onPractise,
  });

  final WordCardSheetModel model;
  final WordCardAudioPlayHandler? onPlayAudio;
  final VoidCallback? onSave;
  final VoidCallback? onPractise;

  @override
  State<WordCardSheet> createState() => _WordCardSheetState();
}

class _WordCardSheetState extends State<WordCardSheet> {
  String _dialectTag = DialectChips.standardTag;

  String get _displayWord => wordCardSurfaceForDialect(
        standardWord: widget.model.standardWord,
        variants: widget.model.dialectVariants,
        selectedTag: _dialectTag,
      );

  List<WordCardSpeakerClip> get _speakerClips {
    final clips = widget.model.speakerClips;
    if (_dialectTag == DialectChips.standardTag) {
      final standard = clips
          .where(
            (c) =>
                c.dialectTag == null ||
                c.dialectTag!.isEmpty ||
                c.dialectTag == 'standard',
          )
          .toList();
      return standard.isNotEmpty ? standard : clips;
    }
    final tagged = clips.where((c) => c.dialectTag == _dialectTag).toList();
    return tagged.isNotEmpty ? tagged : clips;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final lemmaStyle = const TextStyle(
      fontFamily: 'Noto Sans',
      fontFamilyFallback: [
        'NotoSans',
        'Roboto',
        'Arial Unicode MS',
      ],
      fontSize: kWordCardLemmaFontSize,
      height: kWordCardLemmaLineHeight,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.model.showsAiDraftBadge)
              const _AiDraftBadge(label: kWordCardAiDraftCopy),
            if (widget.model.gloss != null) ...[
              Text(
                widget.model.gloss!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Semantics(
              label: 'Lemma $_displayWord',
              child: Text(
                _displayWord,
                style: lemmaStyle,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: true,
                  applyHeightToLastDescent: true,
                ),
                strutStyle: StrutStyle(
                  height: kWordCardLemmaLineHeight,
                  forceStrutHeight: true,
                  fontFamily: lemmaStyle.fontFamily,
                  fontSize: lemmaStyle.fontSize,
                ),
              ),
            ),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: ToneLensContour(
                tonePattern: widget.model.tonePattern,
                syllables: widget.model.syllables.isNotEmpty
                    ? widget.model.syllables
                    : null,
                verified: !widget.model.showsAiDraftBadge,
              ),
            ),
            if (widget.model.dialectVariants.isNotEmpty) ...[
              const SizedBox(height: 12),
              DialectChips(
                standardLabel: 'Standard',
                variants: widget.model.dialectVariants,
                selectedTag: _dialectTag,
                onSelected: (tag) => setState(() => _dialectTag = tag),
              ),
            ],
            if (_speakerClips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Speakers', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final clip in _speakerClips)
                _AudioRow(
                  label: clip.voiceId,
                  sublabel: clip.speed,
                  onPlay: clip.uri.isNotEmpty
                      ? () => widget.onPlayAudio?.call(
                            clip.uri,
                            label: clip.voiceId,
                          )
                      : null,
                ),
            ],
            if (widget.model.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Examples', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final example in widget.model.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          example.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      _PlayIconButton(
                        enabled: example.audioUri != null,
                        semanticsLabel: 'Play example',
                        onPressed: example.audioUri == null
                            ? null
                            : () => widget.onPlayAudio?.call(
                                  example.audioUri!,
                                  label: 'example',
                                ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            SeeItInTheWildButton(
              language: widget.model.language,
              targetLexemeId: widget.model.lexemeId,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onSave,
                    child: const Text(kWordCardSaveLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onPractise,
                    child: const Text(kWordCardPractiseLabel),
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

class _AiDraftBadge extends StatelessWidget {
  const _AiDraftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.label,
    required this.sublabel,
    required this.onPlay,
  });

  final String label;
  final String sublabel;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _PlayIconButton(
            enabled: onPlay != null,
            semanticsLabel: 'Play $label',
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _PlayIconButton extends StatelessWidget {
  const _PlayIconButton({
    required this.enabled,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final bool enabled;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.volume_up_outlined),
        ),
      ),
    );
  }
}
