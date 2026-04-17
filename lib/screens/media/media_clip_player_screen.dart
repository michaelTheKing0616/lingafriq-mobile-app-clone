import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/media_url_resolver.dart';
import 'package:lingafriq/widgets/editorial/audio_player_bar.dart';

class MediaClipPlayerScreen extends StatefulWidget {
  final String mediaId;
  final String title;
  final int? startMs;
  final int? endMs;

  const MediaClipPlayerScreen({
    super.key,
    required this.mediaId,
    required this.title,
    this.startMs,
    this.endMs,
  });

  @override
  State<MediaClipPlayerScreen> createState() => _MediaClipPlayerScreenState();
}

class _MediaClipPlayerScreenState extends State<MediaClipPlayerScreen> {
  final _player = AudioPlayer();
  bool _loading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _speed = 1.0;
  int? _clipStartMs;
  int? _clipEndMs;

  @override
  void initState() {
    super.initState();
    _clipStartMs = widget.startMs;
    _clipEndMs = widget.endMs;
    _init();
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
      final endMs = _clipEndMs;
      if (endMs != null && pos.inMilliseconds >= endMs) {
        _player.pause();
      }
    });
    _player.playerStateStream.listen((st) {
      if (!mounted) return;
      setState(() => _isPlaying = st.playing);
    });
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.initialize();
      final res = await ApiService.get(Api.mediaDetails(widget.mediaId));
      if (res.statusCode != 200 || res.data is! Map) {
        throw Exception('Failed to load media details');
      }
      final data = (res.data as Map)['data'];
      if (data is! Map) throw Exception('Invalid media response');
      final rawUrl = data['file_url']?.toString();
      final absUrl = resolveMediaUrl(rawUrl);
      if (absUrl == null || absUrl.isEmpty) {
        throw Exception('Media URL missing');
      }

      await _player.setUrl(absUrl);
      final dur = _player.duration ?? Duration.zero;
      final start = Duration(milliseconds: (_clipStartMs ?? 0).clamp(0, dur.inMilliseconds));
      await _player.seek(start);
      setState(() {
        _duration = dur;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : const SizedBox.shrink(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : AudioPlayerBar(
              title: widget.title,
              subtitle: 'Source clip',
              position: _position,
              duration: _duration,
              isPlaying: _isPlaying,
              playbackSpeed: _speed,
              onPlayPause: () async {
                if (_isPlaying) {
                  await _player.pause();
                } else {
                  final endMs = _clipEndMs;
                  if (endMs != null && _position.inMilliseconds >= endMs) {
                    await _player.seek(Duration(milliseconds: _clipStartMs ?? 0));
                  }
                  await _player.play();
                }
              },
              onSeek: (d) async {
                final start = _clipStartMs;
                final end = _clipEndMs;
                var target = d;
                if (start != null && target.inMilliseconds < start) {
                  target = Duration(milliseconds: start);
                }
                if (end != null && target.inMilliseconds > end) {
                  target = Duration(milliseconds: end);
                }
                await _player.seek(target);
              },
              onSpeedChange: (s) async {
                setState(() => _speed = s);
                await _player.setSpeed(s);
              },
            ),
    );
  }
}

