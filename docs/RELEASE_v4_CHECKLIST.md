# Release v4.0.0 checklist

## Pre-build

- [ ] `curriculum_bundle_version` = `4.0.0` in `lib/providers/curriculum_provider.dart`
- [ ] C2 visible in curriculum picker (`authentic_curriculum_entry_screen.dart`)
- [ ] `dart run tool/validate_content_schemas.dart` passes
- [ ] `dart run tool/tts_purity_gate.dart` passes
- [ ] `dart run tool/i18n_gate.dart` passes
- [ ] Backend: `PUT /api/v2/content-packs/:language/manifest` smoke-tested
- [ ] `tts-mms-service`, `whisper-asr-service` healthy on staging

## Functional QA

- [ ] AI Chat: multi-turn context, streaming bubbles, English translation toggle, mic STT, no `-` placeholders
- [ ] TTS: Authentic Path lesson audio uses Gold/Silver (not generic en-US)
- [ ] Games: all hub games load content; traditional games (Ayo, Suwe, Ludo, Snakes, Whot) completable
- [ ] Authentic Path: A1–C2 lessons open offline after first download

## Store

- [ ] Version code/name bumped in `pubspec.yaml`
- [ ] Release notes mention C2 curriculum, African TTS, games revamp, Polie conversation streaming
- [ ] Play Console + App Store screenshots updated for conversation UI

## Post-release monitoring

- [ ] Telemetry dashboards: `polie_conversation_success`, `tts_resolution` tier mix, `game_session`, `lesson_complete`
- [ ] Error budget: ASR 502 rate, TTS silver fallback rate
