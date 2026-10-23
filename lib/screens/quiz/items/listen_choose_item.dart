import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';
import 'package:lingafriq/utils/media_url_resolver.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Plays one item-bank audio ref. Tests pass their own implementation.
abstract class ItemAudio {
  Future<void> play(String ref);
  Future<void> dispose() async {}
}

class BankItemAudio implements ItemAudio {
  AudioPlayer? _player;

  @override
  Future<void> play(String ref) async {
    final url = resolveMediaUrl(ref);
    if (url == null || url.isEmpty) {
      throw StateError('audio ref is empty');
    }
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setUrl(url);
    await player.play();
  }

  @override
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}

class ListenChooseItem extends StatefulWidget {
  const ListenChooseItem({
    super.key,
    required this.audioRef,
    required this.options,
    required this.spec,
    this.audio,
  });

  final String audioRef;
  final List<String> options;
  final AnswerSpec spec;
  final ItemAudio? audio;

  @override
  State<ListenChooseItem> createState() => _ListenChooseItemState();
}

class _ListenChooseItemState extends State<ListenChooseItem> {
  late final ItemAudio _audio = widget.audio ?? BankItemAudio();
  String _phase = 'idle';
  ItemGrade? _grade;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_phase == 'playing' || _grade != null) return;
    setState(() => _phase = 'playing');
    try {
      await _audio.play(widget.audioRef);
      if (!mounted || _grade != null) return;
      setState(() => _phase = 'idle');
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = 'error');
    }
  }

  void _choose(String option) {
    if (_grade != null) return;
    final grade = gradeAnswer(response: option, spec: widget.spec);
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.listen',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: _phase == 'error' ? ItemCopy.retry : ItemCopy.listen,
            child: TextButton(
              onPressed: _play,
              child: Text(_phase == 'playing'
                  ? ItemCopy.playing
                  : _phase == 'error'
                      ? ItemCopy.audioError
                      : ItemCopy.listen),
            ),
          ),
          if (_grade != null)
            Text(
              _grade!.correct ? ItemCopy.correct : ItemCopy.wrong,
              style: TextStyle(color: _grade!.correct ? PanAfricanColors.success : PanAfricanColors.error),
            ),
          for (final option in widget.options)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
              child: Semantics(
                button: true,
                label: option,
                child: OutlinedButton(
                  onPressed: _grade == null ? () => _choose(option) : null,
                  child: Text(option),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
