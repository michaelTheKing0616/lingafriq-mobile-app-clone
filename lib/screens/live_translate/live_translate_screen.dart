import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/live_translate/live_translate_client.dart';
import 'package:lingafriq/services/live_translate/live_translate_phase.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

/// Hybrid live translation: on-device speech recognition streams text to the
/// backend over Socket.IO; cloud translates and returns optional TTS audio.
class LiveTranslateScreen extends ConsumerStatefulWidget {
  const LiveTranslateScreen({super.key});

  @override
  ConsumerState<LiveTranslateScreen> createState() =>
      _LiveTranslateScreenState();
}

class _LiveTranslateScreenState extends ConsumerState<LiveTranslateScreen> {
  final SpeechToText _speech = SpeechToText();
  final LiveTranslateRealtimeClient _rt = LiveTranslateRealtimeClient();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final Uuid _uuid = const Uuid();

  final TextEditingController _sourceLang =
      TextEditingController(text: 'english');
  final TextEditingController _targetLang =
      TextEditingController(text: 'yoruba');

  bool _speechReady = false;
  String? _sessionId;
  String? _error;
  LiveTranslatePhase _phase = LiveTranslatePhase.idle;

  String _activeSegmentId = '';
  String _sourceCaption = '';
  String _translationCaption = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _ttsPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed &&
          _phase == LiveTranslatePhase.playingTts) {
        setState(() {
          _phase = _speech.isListening
              ? LiveTranslatePhase.listening
              : LiveTranslatePhase.ready;
        });
      }
    });
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = e.errorMsg;
          _phase = LiveTranslatePhase.error;
        });
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          if (_phase == LiveTranslatePhase.listening) {
            setState(() => _phase = LiveTranslatePhase.ready);
          }
        }
      },
    );
    if (!mounted) return;
    setState(() => _speechReady = ok);
    if (!ok) {
      setState(() {
        _error = AppLocalizations.of(context)!.liveTranslateSpeechUnavailable;
        _phase = LiveTranslatePhase.error;
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _ttsPlayer.dispose();
    _rt.disconnect();
    _sourceLang.dispose();
    _targetLang.dispose();
    super.dispose();
  }

  Future<void> _ensureMic() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception(
        AppLocalizations.of(context)!.liveTranslateMicPermissionRequired,
      );
    }
  }

  Map<String, dynamic> _sessionBody() => {
        'mode': 'interpretation',
        'sourceLang': _sourceLang.text.trim().toLowerCase(),
        'targetLang': _targetLang.text.trim().toLowerCase(),
        'qualityMode': 'balanced',
        'output': {'captions': true, 'tts': true},
      };

  Future<void> _startSession() async {
    if (_phase == LiveTranslatePhase.creatingSession ||
        _phase == LiveTranslatePhase.connectingSocket) {
      return;
    }

    setState(() {
      _phase = LiveTranslatePhase.creatingSession;
      _error = null;
      _sourceCaption = '';
      _translationCaption = '';
    });

    try {
      final dio = ref.read(client);
      final session = await LiveTranslateRealtimeClient.createSession(
        dio,
        body: _sessionBody(),
      );

      if (session.sessionId.isEmpty || session.socketToken.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.liveTranslateInvalidSession);
      }

      _sessionId = session.sessionId;

      setState(() => _phase = LiveTranslatePhase.connectingSocket);

      _rt.connect(
        socketToken: session.socketToken,
        onServerEvent: _onServerEvent,
        onConnect: () {
          try {
            _rt.emitClientEvent({
              'type': 'session.join',
              'sessionId': _sessionId!,
            });
          } catch (_) {}
          if (mounted) {
            setState(() {
              _phase = LiveTranslatePhase.ready;
              _error = null;
            });
          }
        },
        onDisconnect: (_) {
          if (!mounted) return;
          setState(() {
            if (_sessionId != null) {
              _phase = LiveTranslatePhase.reconnecting;
              _error = AppLocalizations.of(context)!.liveTranslateConnectionLost;
            }
          });
        },
        onConnectError: (e) {
          if (!mounted) return;
          setState(() {
            _phase = LiveTranslatePhase.error;
            _error = AppLocalizations.of(context)!.liveTranslateSocketError(
              e?.toString() ?? 'unknown',
            );
          });
        },
        onAnyError: (e) {
          if (!mounted) return;
          setState(() => _error = e?.toString());
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = LiveTranslatePhase.error;
        _error = e.response?.data?.toString() ??
            e.message ??
            AppLocalizations.of(context)!.liveTranslateSessionFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = LiveTranslatePhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _reconnect() async {
    _rt.disconnect();
    await _ttsPlayer.stop();
    setState(() {
      _sessionId = null;
      _phase = LiveTranslatePhase.reconnecting;
      _error = null;
    });
    await _startSession();
  }

  Future<void> _playTts(String base64Audio, String mime) async {
    try {
      final bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final ext = mime.contains('wav') ? 'wav' : 'audio';
      final file = File(
        '${dir.path}/lingafriq_live_tts_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(bytes, flush: true);
      await _ttsPlayer.setFilePath(file.path);
      if (mounted) setState(() => _phase = LiveTranslatePhase.playingTts);
      await _ttsPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.liveTranslateCouldNotPlayAudio(
            e.toString(),
          );
        });
      }
    }
  }

  Future<void> _interruptPlaybackAndFloor() async {
    await _ttsPlayer.stop();
    final sid = _sessionId;
    if (sid != null && _rt.isConnected) {
      try {
        _rt.emitClientEvent({'type': 'control.bargeIn', 'sessionId': sid});
        _rt.emitClientEvent({'type': 'control.cancelTts', 'sessionId': sid});
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _phase = _speech.isListening
          ? LiveTranslatePhase.listening
          : LiveTranslatePhase.ready;
    });
  }

  void _onServerEvent(Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? '';
    if (type == 'session.error') {
      setState(() {
        _error = e['message']?.toString() ??
            AppLocalizations.of(context)!.liveTranslateSessionError;
        _phase = LiveTranslatePhase.error;
      });
      return;
    }
    if (type == 'mt.partial' || type == 'mt.final') {
      final text = e['text']?.toString() ?? '';
      if (text.isEmpty) return;
      setState(() => _translationCaption = text);
      return;
    }
    if (type == 'tts.audio') {
      final b64 = e['audioBase64']?.toString() ?? '';
      final mime = e['mime']?.toString() ??
          AppLocalizations.of(context)!.liveTranslateDefaultAudioMime;
      if (b64.isNotEmpty) {
        _playTts(b64, mime);
      }
      return;
    }
    if (type == 'session.ready') {
      setState(() {
        _error = null;
        if (_phase != LiveTranslatePhase.listening) {
          _phase = LiveTranslatePhase.ready;
        }
      });
    }
  }

  Future<void> _toggleListen() async {
    if (!_speechReady || _sessionId == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.liveTranslateStartSessionFirst;
        _phase = LiveTranslatePhase.error;
      });
      return;
    }

    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _phase = LiveTranslatePhase.ready);
      return;
    }

    await _ensureMic();
    _activeSegmentId = _uuid.v4();

    if (mounted) setState(() => _phase = LiveTranslatePhase.listening);

    await _speech.listen(
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
      onSoundLevelChange: (_) {},
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        try {
          _rt.emitClientEvent({
            'type': 'stt.segment',
            'sessionId': _sessionId!,
            'segmentId': _activeSegmentId,
            'isFinal': result.finalResult,
            'text': text,
          });
          if (mounted) setState(() => _sourceCaption = text);
          if (result.finalResult) {
            _activeSegmentId = _uuid.v4();
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = e.toString();
              _phase = LiveTranslatePhase.error;
            });
          }
        }
      },
    );
  }

  void _endSession() {
    _speech.stop();
    _ttsPlayer.stop();
    if (_sessionId != null && _rt.isConnected) {
      try {
        _rt.emitClientEvent({
          'type': 'session.leave',
          'sessionId': _sessionId!,
        });
      } catch (_) {}
    }
    _rt.disconnect();
    setState(() {
      _sessionId = null;
      _phase = LiveTranslatePhase.idle;
      _sourceCaption = '';
      _translationCaption = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canStart = _phase == LiveTranslatePhase.idle ||
        _phase == LiveTranslatePhase.error ||
        _phase == LiveTranslatePhase.reconnecting;
    final sessionActive = _sessionId != null &&
        _phase != LiveTranslatePhase.idle &&
        _phase != LiveTranslatePhase.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.liveTranslateTitle),
        actions: [
          if (sessionActive)
            TextButton(
              onPressed: _endSession,
              child: Text(l10n.liveTranslateEndSession),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.liveTranslateStatus(_phase.label),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sourceLang,
              decoration: InputDecoration(
                labelText: l10n.liveTranslateSourceLanguageLabel,
              ),
              enabled: !sessionActive,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetLang,
              decoration: InputDecoration(
                labelText: l10n.liveTranslateTargetLanguageLabel,
              ),
              enabled: !sessionActive,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (!canStart ||
                      _phase == LiveTranslatePhase.creatingSession ||
                      _phase == LiveTranslatePhase.connectingSocket)
                  ? null
                  : _startSession,
              child: Text(
                _phase == LiveTranslatePhase.creatingSession ||
                        _phase == LiveTranslatePhase.connectingSocket
                    ? l10n.liveTranslateStarting
                    : l10n.liveTranslateStartSession,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: (_phase == LiveTranslatePhase.reconnecting ||
                      _phase == LiveTranslatePhase.error)
                  ? _reconnect
                  : null,
              child: Text(l10n.liveTranslateReconnect),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: sessionActive &&
                      _phase != LiveTranslatePhase.creatingSession &&
                      _phase != LiveTranslatePhase.connectingSocket
                  ? _toggleListen
                  : null,
              child: Text(
                _speech.isListening
                    ? l10n.liveTranslateStopListening
                    : l10n.liveTranslateListen,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: sessionActive ? _interruptPlaybackAndFloor : null,
              child: Text(l10n.liveTranslateInterruptBargeIn),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.liveTranslateSource,
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _sourceCaption.isEmpty
                              ? l10n.liveTranslatePlaceholderDash
                              : _sourceCaption,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.liveTranslateTranslation,
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _translationCaption.isEmpty
                              ? l10n.liveTranslatePlaceholderDash
                              : _translationCaption,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Push helper for drawer / navigation.
Route<void> liveTranslateRoute() {
  return SmoothPageRoute.platform<void>(
    child: const LiveTranslateScreen(),
  );
}
