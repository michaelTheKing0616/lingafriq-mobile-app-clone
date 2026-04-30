import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/media_import_service.dart';
import 'package:lingafriq/services/offline/offline_service.dart';
import 'package:lingafriq/services/offline/point_and_say_queue_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/services/voice/voice_api_service.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/offline_fallback_policy.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/tts_play_button.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointAndSayScreen extends ConsumerStatefulWidget {
  final String language;
  const PointAndSayScreen({super.key, required this.language});

  @override
  ConsumerState<PointAndSayScreen> createState() => _PointAndSayScreenState();
}

class _PointAndSayScreenState extends ConsumerState<PointAndSayScreen> {
  final _rec = AudioRecordingService();
  late final VoiceApiService _voice;
  late final TranslationService _translate;
  late final TextEditingController _languageCtrl;

  bool _busy = false;
  String? _error;

  File? _imageFile;
  String? _ocrText;
  List<_DetectedThing> _things = const [];

  String? _targetText;
  String? _targetTextTranslated;
  List<String> _practicePhrases = const [];
  bool _phrasesLoading = false;
  bool _evaluateTone = false;
  bool _isRecording = false;
  String? _recordingPath;
  Map<String, dynamic>? _pronunciationQuick;
  Map<String, dynamic>? _toneResult;
  int _pendingQueue = 0;

  String get _draftPrefsKey =>
      'point_and_say_draft:${widget.language.trim().toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceApiServiceProvider);
    _translate = TranslationService();
    _languageCtrl = TextEditingController(
      text: widget.language.trim().toLowerCase(),
    );
    _initQueueCount();
    _loadDraft();
    _languageCtrl.addListener(_persistDraft);
  }

  Future<void> _initQueueCount() async {
    await PointAndSayQueueService.instance.ensureOpen();
    setState(
      () => _pendingQueue = PointAndSayQueueService.instance.pendingCount,
    );
  }

  @override
  void dispose() {
    _languageCtrl.removeListener(_persistDraft);
    _languageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftPrefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return;

      final language = (parsed['language'] as String?)?.trim();
      final targetRaw = (parsed['targetRaw'] as String?)?.trim();
      final targetTranslated = (parsed['targetTranslated'] as String?)?.trim();
      final recordingPath = (parsed['recordingPath'] as String?)?.trim();
      final evaluateTone = parsed['evaluateTone'] is bool
          ? parsed['evaluateTone'] as bool
          : null;

      if (language != null && language.isNotEmpty) {
        _languageCtrl.text = language;
      }
      setState(() {
        _targetText = targetRaw?.isEmpty ?? true ? null : targetRaw;
        _targetTextTranslated = targetTranslated?.isEmpty ?? true
            ? null
            : targetTranslated;
        _evaluateTone = evaluateTone ?? _evaluateTone;
      });

      if (recordingPath != null &&
          recordingPath.isNotEmpty &&
          await File(recordingPath).exists()) {
        setState(() => _recordingPath = recordingPath);
      }
    } catch (_) {
      // Ignore corrupt draft.
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftPrefsKey);
    } catch (_) {}
  }

  Future<void> _persistDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = _languageCtrl.text.trim().toLowerCase();
      final recordingPath = _recordingPath;
      final targetRaw = _targetText;
      final targetTranslated = _targetTextTranslated;
      final hasAnything =
          language.isNotEmpty ||
          (recordingPath != null && recordingPath.isNotEmpty) ||
          (targetRaw != null && targetRaw.trim().isNotEmpty) ||
          (targetTranslated != null && targetTranslated.trim().isNotEmpty);
      if (!hasAnything) {
        await prefs.remove(_draftPrefsKey);
        return;
      }
      await prefs.setString(
        _draftPrefsKey,
        jsonEncode({
          'language': language,
          'targetRaw': targetRaw,
          'targetTranslated': targetTranslated,
          'recordingPath': recordingPath,
          'evaluateTone': _evaluateTone,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_busy) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _imageFile = null;
      _ocrText = null;
      _things = const [];
      _targetText = null;
      _targetTextTranslated = null;
      _recordingPath = null;
      _pronunciationQuick = null;
      _toneResult = null;
    });
    await _persistDraft();

    try {
      final svc = ref.read(mediaImportServiceProvider);
      // Downscale camera shots to reduce ML Kit / detector memory pressure (iOS crashes).
      final res = await svc.pickImage(
        source: MediaSource.camera,
        performOCR: false,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (!mounted) return;
      if (!res.success || res.file == null || !(await res.file!.exists())) {
        throw Exception(res.error ?? 'Failed to capture image.');
      }
      final file = res.file!;

      final ocr = await svc.extractTextFromImage(file);
      if (!mounted) return;
      final ocrText = (ocr['text'] ?? '').trim();
      final ocrLang = (ocr['language'] ?? 'unknown').toString();

      // Object detection is best-effort; failures must not crash the screen.
      final things = <_DetectedThing>[];
      try {
        final detector = ObjectDetector(
          options: ObjectDetectorOptions(
            mode: DetectionMode.single,
            classifyObjects: true,
            multipleObjects: true,
          ),
        );
        try {
          final input = InputImage.fromFile(file);
          final objects = await detector.processImage(input);
          for (final o in objects) {
            for (final l in o.labels) {
              final text = l.text.trim();
              if (text.isEmpty) continue;
              final conf = (l.confidence * 100).clamp(0, 100);
              things.add(
                _DetectedThing(label: text, confidencePct: conf.toDouble()),
              );
            }
          }
        } finally {
          await detector.close();
        }
      } catch (_) {
        // Keep OCR + preview even if ML Kit object detection fails on this device/image.
      }
      things.sort((a, b) => b.confidencePct.compareTo(a.confidencePct));

      if (!mounted) return;
      setState(() {
        _imageFile = file;
        _ocrText = ocrText.isEmpty ? null : ocrText;
        _things = things.take(12).toList();
      });

      // Pre-translate OCR text (best effort) for fast "use as target" experience.
      if (ocrText.isNotEmpty && mounted) {
        try {
          final targetLang = _languageCtrl.text.trim().toLowerCase();
          if (targetLang.isNotEmpty &&
              ocrLang != 'unknown' &&
              ocrLang != targetLang) {
            final tr = await _translate.translate(
              text: ocrText.length > 500 ? ocrText.substring(0, 500) : ocrText,
              sourceLang: ocrLang,
              targetLang: targetLang,
              includePhraseBreakdown: false,
            );
            if (mounted) {
              setState(() {
                // keep as "suggested target", user explicitly selects to use it.
                _targetTextTranslated = tr.translation.trim().isEmpty
                    ? null
                    : tr.translation.trim();
              });
            }
          }
        } catch (_) {
          // Ignore translation failures; OCR text is still useful.
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setTargetFromOcr() async {
    final t = (_ocrText ?? '').trim();
    if (t.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _targetText = t.length > 120 ? t.substring(0, 120) : t;
      _pronunciationQuick = null;
      _toneResult = null;
      _recordingPath = null;
    });
    await _persistDraft();
    await _refreshPracticePhrases();
  }

  Future<void> _setTargetFromLabel(String label) async {
    HapticFeedback.lightImpact();
    final raw = label.trim();
    if (raw.isEmpty) return;
    setState(() {
      _targetText = raw;
      _targetTextTranslated = null;
      _practicePhrases = const [];
      _pronunciationQuick = null;
      _toneResult = null;
      _recordingPath = null;
    });
    await _persistDraft();

    // Translate label from English -> target language (best effort).
    try {
      final targetLang = _languageCtrl.text.trim().toLowerCase();
      if (targetLang.isNotEmpty && targetLang != 'english') {
        final tr = await _translate.translate(
          text: raw,
          sourceLang: 'english',
          targetLang: targetLang,
          includePhraseBreakdown: false,
        );
        final translated = tr.translation.trim();
        if (!mounted) return;
        if (translated.isNotEmpty) {
          setState(() => _targetTextTranslated = translated);
        }
      }
    } catch (_) {}

    await _refreshPracticePhrases();
  }

  String? _effectiveTarget() {
    final v = (_targetTextTranslated ?? _targetText) ?? '';
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _refreshPracticePhrases() async {
    final target = _effectiveTarget();
    if (target == null) {
      if (mounted) setState(() => _practicePhrases = const []);
      return;
    }
    final lang = _languageCtrl.text.trim().toLowerCase();
    if (lang.isEmpty) return;

    setState(() {
      _phrasesLoading = true;
      _practicePhrases = const [];
    });
    try {
      final baseEnglish = <String>[
        'This is $target.',
        'I see $target.',
        'Where is $target?',
        'Please give me $target.',
        'Do you have $target?',
      ];

      // If language is English, keep as-is.
      if (lang == 'english') {
        setState(() {
          _practicePhrases = baseEnglish;
          _phrasesLoading = false;
        });
        return;
      }

      // Translate each phrase (best effort, cached by TranslationService).
      final out = <String>[];
      for (final p in baseEnglish) {
        final tr = await _translate.translate(
          text: p,
          sourceLang: 'english',
          targetLang: lang,
          includePhraseBreakdown: false,
        );
        final translated = tr.translation.trim();
        if (translated.isNotEmpty) out.add(translated);
      }

      if (!mounted) return;
      setState(() {
        _practicePhrases = out.isEmpty ? baseEnglish : out;
        _phrasesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _practicePhrases = const [];
        _phrasesLoading = false;
      });
    }
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_isRecording) {
      HapticFeedback.mediumImpact();
      final path = await _rec.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      await _persistDraft();
      return;
    }

    final ok = await _rec.checkPermission();
    if (!ok) {
      final granted = await _rec.requestPermission();
      if (!granted) {
        setState(() => _error = 'Microphone permission is required.');
        return;
      }
    }
    HapticFeedback.mediumImpact();
    final path = await _rec.startRecording(sampleRate: 16000, numChannels: 1);
    if (path == null) {
      setState(() => _error = 'Failed to start recording.');
      return;
    }
    setState(() {
      _error = null;
      _pronunciationQuick = null;
      _recordingPath = null;
      _isRecording = true;
    });
    await _persistDraft();
  }

  Future<void> _quickCheck() async {
    if (_busy || _isRecording) return;
    final target = ((_targetTextTranslated ?? _targetText) ?? '').trim();
    if (target.isEmpty) {
      setState(() => _error = 'Pick a target (text or object) first.');
      return;
    }
    final path = _recordingPath;
    if (path == null || !(await File(path).exists())) {
      setState(() => _error = 'Record audio first.');
      return;
    }
    final language = _languageCtrl.text.trim().toLowerCase();
    if (language.isEmpty) {
      setState(() => _error = 'Enter a language (e.g., yoruba).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _pronunciationQuick = null;
      _toneResult = null;
    });
    try {
      final healthy = await _voice.checkVoiceServiceHealth();
      if (!healthy) {
        final decision = OfflineFallbackPolicy.decide(
          Exception('voice_service_unavailable'),
        );
        if (decision.shouldQueue) {
          await PointAndSayQueueService.instance.enqueue(
            language: language,
            expectedText: target,
            audioPath: path,
            evaluateTone: _evaluateTone,
            context: {
              'targetRaw': _targetText,
              'targetTranslated': _targetTextTranslated,
              'hasOcr': _ocrText != null,
              'hasImage': _imageFile != null,
              'voiceHealth': 'unhealthy',
            },
          );
          await PointAndSayQueueService.instance.ensureOpen();
          setState(() {
            _pendingQueue = PointAndSayQueueService.instance.pendingCount;
            _error =
                decision.userMessage ??
                'Voice service is unavailable. Queued for sync.';
          });
          OfflineService().queueSync(() async {
            await PointAndSayQueueService.instance.flushPending(
              voiceApi: _voice,
            );
          });
          return;
        }
        throw Exception(
          'Voice service is unavailable. Please try again later.',
        );
      }

      final res = await _voice.quickPronunciationCheck(
        audioPath: path,
        expectedText: target,
        language: language,
      );
      if (res == null) throw Exception('Pronunciation check failed.');
      setState(() => _pronunciationQuick = res);

      if (_evaluateTone) {
        await ApiService.initialize();
        final toneRes = await ApiService.uploadFile(
          ApiContract.learningV2.toneTrainer,
          path,
          fileFieldName: 'audio',
          additionalData: {'expectedText': target, 'language': language},
        );
        if (toneRes.statusCode == 200 && toneRes.data is Map) {
          setState(
            () => _toneResult = (toneRes.data as Map).cast<String, dynamic>(),
          );
        }
      }
      await _clearDraft();
    } catch (e) {
      final decision = OfflineFallbackPolicy.decide(e);
      if (decision.shouldQueue) {
        try {
          await PointAndSayQueueService.instance.enqueue(
            language: language,
            expectedText: target,
            audioPath: path,
            evaluateTone: _evaluateTone,
            context: {
              'targetRaw': _targetText,
              'targetTranslated': _targetTextTranslated,
              'hasOcr': _ocrText != null,
              'hasImage': _imageFile != null,
            },
          );
          await PointAndSayQueueService.instance.ensureOpen();
          setState(() {
            _pendingQueue = PointAndSayQueueService.instance.pendingCount;
            _error = decision.userMessage;
          });
          OfflineService().queueSync(() async {
            await PointAndSayQueueService.instance.flushPending(
              voiceApi: _voice,
            );
          });
          return;
        } catch (_) {
          // Fall through to show the original error below.
        }
      }
      setState(() => _error = decision.userMessage ?? e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _syncQueuedNow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final removed = await PointAndSayQueueService.instance.flushPending(
        voiceApi: _voice,
        batchSize: 10,
      );
      setState(() {
        _pendingQueue = PointAndSayQueueService.instance.pendingCount;
        _error = removed > 0 ? 'Synced $removed item(s).' : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Point & Say'),
        backgroundColor: isDark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
        actions: [
          IconButton(
            tooltip: 'Capture',
            icon: const Icon(Icons.center_focus_strong_rounded),
            onPressed: _busy ? null : _capture,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(
            'Point your camera at an object or sign, capture a frame, then practice saying it.',
            style: PanAfricanTypography.bodyMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          if (_pendingQueue > 0) ...[
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: (isDark
                    ? PanAfricanColors.cardDark
                    : PanAfricanColors.cardLight),
                borderRadius: PanAfricanRadius.lgBR,
                border: Border.all(
                  color: isDark
                      ? PanAfricanColors.borderDark
                      : PanAfricanColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: Text(
                      '$_pendingQueue queued attempt(s) ready to sync.',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _syncQueuedNow,
                    child: const Text('Sync now'),
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
          ],
          Text('Language', style: PanAfricanTypography.titleSmall(context)),
          SizedBox(height: PanAfricanSpacing.xxs),
          TextField(
            controller: _languageCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'yoruba / swahili / hausa ...',
            ),
            onChanged: (_) async {
              // If the teacher changes target language, regenerate practice phrases.
              await _refreshPracticePhrases();
            },
          ),
          SizedBox(height: PanAfricanSpacing.md),
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: PanAfricanRadius.lgBR,
              child: Image.file(_imageFile!, fit: BoxFit.cover),
            ),
            SizedBox(height: PanAfricanSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: _busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_busy ? 'Working…' : 'Capture'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              _error!,
              style: PanAfricanTypography.bodySmall(
                context,
              ).copyWith(color: PanAfricanColors.error),
            ),
          ],
          if (_ocrText != null) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Detected text',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.cardDark
                    : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Text(
                _ocrText!,
                style: PanAfricanTypography.bodyMedium(context),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            OutlinedButton.icon(
              onPressed: _setTargetFromOcr,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Use as target phrase'),
            ),
            if (_targetTextTranslated != null &&
                _targetTextTranslated!.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                'Suggested translation',
                style: PanAfricanTypography.titleSmall(context),
              ),
              SizedBox(height: PanAfricanSpacing.xxs),
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.cardDark
                      : PanAfricanColors.cardLight,
                  borderRadius: PanAfricanRadius.lgBR,
                  boxShadow: PanAfricanShadows.sm,
                ),
                child: Text(
                  _targetTextTranslated!,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _targetText = _targetTextTranslated!;
                    _pronunciationQuick = null;
                    _toneResult = null;
                    _recordingPath = null;
                  });
                },
                icon: const Icon(Icons.flag_circle_rounded),
                label: const Text('Use translated target'),
              ),
            ],
          ],
          if (_things.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Detected objects',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _things.map((t) {
                return ActionChip(
                  label: Text(
                    '${t.label} ${t.confidencePct.toStringAsFixed(0)}%',
                  ),
                  onPressed: () => _setTargetFromLabel(t.label),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.lg),
          Text('Target', style: PanAfricanTypography.titleMedium(context)),
          SizedBox(height: PanAfricanSpacing.xxs),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.cardDark
                  : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
              border: Border.all(
                color: isDark
                    ? PanAfricanColors.borderDark
                    : PanAfricanColors.borderLight,
              ),
            ),
            child: Text(
              ((_targetTextTranslated ?? _targetText) == null ||
                      (_targetTextTranslated ?? _targetText)!.trim().isEmpty)
                  ? 'Tap an object chip or use detected text.'
                  : (_targetTextTranslated ?? _targetText)!,
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          if (((_targetTextTranslated ?? _targetText) ?? '')
              .trim()
              .isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.volume_up_rounded),
                SizedBox(width: PanAfricanSpacing.xxs),
                Text(
                  'Hear it',
                  style: PanAfricanTypography.titleSmall(context),
                ),
                const Spacer(),
                TtsPlayButton(
                  text: (_targetTextTranslated ?? _targetText)!.trim(),
                  languageName: _languageCtrl.text.trim().toLowerCase(),
                  iconSize: 26,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.sm),
          ],

          if (_effectiveTarget() != null) ...[
            Row(
              children: [
                Text(
                  'Practice phrases',
                  style: PanAfricanTypography.titleMedium(context),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_busy || _phrasesLoading)
                      ? null
                      : _refreshPracticePhrases,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            if (_phrasesLoading)
              LinearProgressIndicator(
                minHeight: 3,
                color: PanAfricanColors.primary,
                backgroundColor: cs.surfaceContainerHighest.withOpacity(0.4),
              ),
            if (!_phrasesLoading && _practicePhrases.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _practicePhrases.map((p) {
                  return ActionChip(
                    label: Text(
                      p,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _targetText = p;
                        _targetTextTranslated = null;
                        _pronunciationQuick = null;
                        _toneResult = null;
                        _recordingPath = null;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                'Tap a phrase to set it as the target, then Hear → Record → Quick check.',
                style: PanAfricanTypography.bodySmall(
                  context,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.sm),
          ],

          SwitchListTile(
            value: _evaluateTone,
            onChanged: _busy
                ? null
                : (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _evaluateTone = v);
                  },
            title: const Text('Also analyze tone & rhythm'),
            subtitle: const Text(
              'Recommended for tonal languages and short phrases.',
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleRecord,
                  icon: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  ),
                  label: Text(_isRecording ? 'Stop' : 'Record'),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _quickCheck,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Quick check'),
                ),
              ),
            ],
          ),
          if (_pronunciationQuick != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.cardDark
                    : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick result',
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    (_pronunciationQuick!['message'] ??
                            _pronunciationQuick!['feedback'] ??
                            'Done')
                        .toString(),
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ],
              ),
            ),
          ],
          if (_toneResult != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.cardDark
                    : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tone & rhythm',
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    'Accuracy: ${_toneResult!['accuracy'] ?? '—'}',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  if (_toneResult!['meaningRisk'] == true) ...[
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      'Meaning risk: high',
                      style: PanAfricanTypography.bodySmall(
                        context,
                      ).copyWith(color: Colors.orange.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.lg),
        ],
      ),
    );
  }
}

class _DetectedThing {
  final String label;
  final double confidencePct;
  const _DetectedThing({required this.label, required this.confidencePct});
}
