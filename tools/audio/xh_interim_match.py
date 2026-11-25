"""isiXhosa interim audio: FLEURS/WAXAL sentence match only (P5-069, CP-§7-xh-01/02/05)."""

from __future__ import annotations

import json
import re
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from tools.audio.f0_tone_proxy import nfc
from tools.audio.xh_voice_decision import (
    load_xh_voice_decision,
    validate_xh_voice_decision,
    xh_dynamic_tts_enabled,
    xh_interim_audio_sources,
)
from tools.content_engine.licences.register_schema import load_register_csv, register_index

CARD_ID = "P5-069"
LANGUAGE_ID = "xh"
LOCALE = "xh-ZA"
REQUIRED_LISTEN_SAMPLES = 100

_OWN_SENTENCES_SCOPE = "own_sentences_only"
_INTERIM_PROVIDERS = frozenset({"fleurs", "waxal"})
_FLEURS_LICENCE = "fleurs"
_WAXAL_REGISTER_ID = "waxal-other"
_ALLOWED_ASR_PROVIDERS = frozenset({"intron", "lelapa"})
_CLICK_LETTERS = re.compile(r"[cqx]", re.IGNORECASE)

_REPO_ROOT = Path(__file__).resolve().parents[2]


class XhInterimError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class InterimClip:
    clip_id: str
    provider: str
    language: str
    transcript: str
    audio_ref: str
    licence_id: str
    text_scope: str
    register_id: str | None = None
    subset_licence_verified: bool | None = None


@dataclass(frozen=True)
class InterimMatch:
    clip_id: str
    provider: str
    audio_ref: str
    transcript: str
    licence_id: str


@dataclass(frozen=True)
class ListenSample:
    sample_id: str
    source_text: str
    audio_ref: str
    linguist_pass: bool | None = None
    asr_transcript: str | None = None
    asr_provider: str = "intron"


def normalize_match_text(text: str) -> str:
    return " ".join(nfc(text).split())


def assert_no_commercial_dynamic_tts() -> None:
    if xh_dynamic_tts_enabled():
        raise XhInterimError("COMMERCIAL_TTS", "isiXhosa dynamic commercial TTS is forbidden (P5-068)")
    doc = load_xh_voice_decision()
    validate_xh_voice_decision(doc)
    if doc.get("voice_path", {}).get("no_commercial_dynamic_tts") is not True:
        raise XhInterimError("NO_VENDOR_TTS", "voice_path must forbid commercial dynamic TTS")


def _default_register_rows() -> list[Mapping[str, str]]:
    csv_path = _REPO_ROOT / "tools/content_engine/licences/register.csv"
    return load_register_csv(csv_path)


def assert_registered_licence(licence_id: str, register_rows: Sequence[Mapping[str, str]]) -> None:
    index = register_index(register_rows)
    if licence_id not in index:
        raise XhInterimError("LICENCE_UNREGISTERED", f"licence {licence_id} not in register.csv")


def assert_interim_pool_licence(
    clip: InterimClip,
    register_rows: Sequence[Mapping[str, str]] | None = None,
) -> None:
    rows = register_rows if register_rows is not None else _default_register_rows()
    if clip.language != LANGUAGE_ID:
        raise XhInterimError("LANGUAGE_MISMATCH", f"expected language {LANGUAGE_ID}")
    if clip.provider not in _INTERIM_PROVIDERS:
        raise XhInterimError("PROVIDER_NOT_INTERIM", f"provider {clip.provider} not allowed for xh interim")
    if clip.text_scope != _OWN_SENTENCES_SCOPE:
        raise XhInterimError("TEXT_SCOPE", "interim clips must be own_sentences_only")
    if clip.provider == "fleurs":
        if clip.licence_id != _FLEURS_LICENCE:
            raise XhInterimError("FLEURS_LICENCE_ID", f"expected licence_id {_FLEURS_LICENCE}")
        assert_registered_licence(_FLEURS_LICENCE, rows)
    if clip.provider == "waxal":
        if clip.register_id != _WAXAL_REGISTER_ID:
            raise XhInterimError("WAXAL_SUBSET_LICENCE", f"expected register_id {_WAXAL_REGISTER_ID}")
        if clip.subset_licence_verified is not True:
            raise XhInterimError("SUBSET_LICENCE_UNVERIFIED", "WAXAL subset licence must be verified")
        assert_registered_licence(_WAXAL_REGISTER_ID, rows)


def parse_clip(row: Mapping[str, Any], index: int = 0) -> InterimClip:
    clip_id = row.get("clip_id") or row.get("id") or f"xh-{index + 1}"
    provider = row.get("provider")
    language = row.get("language")
    transcript = row.get("transcript") or row.get("source_text") or row.get("text")
    audio_ref = row.get("audio_ref") or row.get("audio_path") or row.get("audio")
    licence_id = row.get("licence_id") or ""
    text_scope = row.get("text_scope") or _OWN_SENTENCES_SCOPE
    if not isinstance(clip_id, str) or not clip_id.strip():
        raise XhInterimError("CLIP_ID", f"row {index} missing clip_id")
    if not isinstance(provider, str) or provider not in _INTERIM_PROVIDERS:
        raise XhInterimError("PROVIDER", f"clip={clip_id} invalid provider")
    if not isinstance(language, str) or language != LANGUAGE_ID:
        raise XhInterimError("LANGUAGE", f"clip={clip_id} must be language xh")
    if not isinstance(transcript, str) or not transcript.strip():
        raise XhInterimError("TRANSCRIPT_EMPTY", f"clip={clip_id} missing transcript")
    if not isinstance(audio_ref, str) or not audio_ref.strip():
        raise XhInterimError("AUDIO_REF_EMPTY", f"clip={clip_id} missing audio_ref")
    if not isinstance(licence_id, str) or not licence_id.strip():
        raise XhInterimError("LICENCE_ID", f"clip={clip_id} missing licence_id")
    register_id = row.get("register_id") or row.get("waxal_register_id")
    verified = row.get("subset_licence_verified")
    if verified is not None and not isinstance(verified, bool):
        raise XhInterimError("SUBSET_FLAG", f"clip={clip_id} subset_licence_verified must be bool")
    return InterimClip(
        clip_id=clip_id.strip(),
        provider=provider.strip(),
        language=language.strip(),
        transcript=transcript.strip(),
        audio_ref=audio_ref.strip(),
        licence_id=licence_id.strip(),
        text_scope=str(text_scope).strip(),
        register_id=register_id.strip() if isinstance(register_id, str) else None,
        subset_licence_verified=verified if isinstance(verified, bool) else None,
    )


def parse_clips(rows: Sequence[Mapping[str, Any]]) -> list[InterimClip]:
    return [parse_clip(row, i) for i, row in enumerate(rows)]


def lookup_interim_audio(
    requested_text: str,
    clips: Sequence[InterimClip],
    *,
    source_order: Sequence[str] | None = None,
    register_rows: Sequence[Mapping[str, str]] | None = None,
) -> InterimMatch:
    assert_no_commercial_dynamic_tts()
    needle = normalize_match_text(requested_text)
    if not needle:
        raise XhInterimError("REQUEST_EMPTY", "requested text is empty")
    order = list(source_order) if source_order is not None else xh_interim_audio_sources()
    for provider in order:
        if provider not in _INTERIM_PROVIDERS:
            raise XhInterimError("SOURCE_ORDER", f"unknown interim source {provider}")
        for clip in clips:
            if clip.provider != provider:
                continue
            if normalize_match_text(clip.transcript) != needle:
                continue
            assert_interim_pool_licence(clip, register_rows)
            return InterimMatch(
                clip_id=clip.clip_id,
                provider=clip.provider,
                audio_ref=clip.audio_ref,
                transcript=clip.transcript,
                licence_id=clip.licence_id,
            )
    raise XhInterimError("NO_MATCH", "no FLEURS/WAXAL clip for requested sentence")


def xh_click_inventory(text: str) -> list[str]:
    lower = nfc(text).lower()
    letters = sorted({m.group(0).lower() for m in _CLICK_LETTERS.finditer(lower)})
    return letters


def xh_text_contains_clicks(text: str) -> bool:
    return bool(xh_click_inventory(text))


def assert_asr_provider(provider: str) -> None:
    if provider not in _ALLOWED_ASR_PROVIDERS:
        raise XhInterimError("ASR_PROVIDER_FORBIDDEN", f"asr provider {provider} not allowed for xh")


def assert_click_inventory_matches(source_text: str, transcript: str) -> None:
    src = xh_click_inventory(source_text)
    if not src:
        return
    hyp = xh_click_inventory(transcript)
    if src != hyp:
        raise XhInterimError("CLICK_INVENTORY_MISMATCH", "click letters in ASR must match source")


def assert_asr_round_trip(
    *,
    source_text: str,
    transcript: str,
    asr_provider: str,
) -> None:
    assert_asr_provider(asr_provider)
    ref = normalize_match_text(source_text)
    hyp = normalize_match_text(transcript)
    if not ref:
        raise XhInterimError("SOURCE_TEXT_EMPTY", "source text empty")
    if ref != hyp:
        raise XhInterimError("ASR_TEXT_MISMATCH", "ASR transcript must match source (NFC)")
    assert_click_inventory_matches(source_text, transcript)


def parse_listen_batch(rows: Sequence[Mapping[str, Any]]) -> list[ListenSample]:
    out: list[ListenSample] = []
    for index, row in enumerate(rows):
        sample_id = row.get("sample_id") or row.get("id") or f"xh-listen-{index + 1}"
        text = row.get("source_text") or row.get("text")
        audio = row.get("audio_ref") or row.get("audio_path") or row.get("audio")
        if not isinstance(sample_id, str) or not sample_id.strip():
            raise XhInterimError("SAMPLE_ID_MISSING", f"row {index} missing sample_id")
        if not isinstance(text, str) or not text.strip():
            raise XhInterimError("SOURCE_TEXT_EMPTY", f"sample={sample_id} missing text")
        if not isinstance(audio, str) or not audio.strip():
            raise XhInterimError("AUDIO_REF_EMPTY", f"sample={sample_id} missing audio_ref")
        verdict = row.get("linguist_pass")
        if verdict is not None and not isinstance(verdict, bool):
            raise XhInterimError("VERDICT_INVALID", f"sample={sample_id} linguist_pass must be bool")
        asr_transcript = row.get("asr_transcript")
        if asr_transcript is not None and not isinstance(asr_transcript, str):
            raise XhInterimError("ASR_TRANSCRIPT_INVALID", f"sample={sample_id} asr_transcript must be str")
        asr_provider = row.get("asr_provider") or "intron"
        if not isinstance(asr_provider, str):
            raise XhInterimError("ASR_PROVIDER_INVALID", f"sample={sample_id} asr_provider must be str")
        out.append(
            ListenSample(
                sample_id=sample_id.strip(),
                source_text=text.strip(),
                audio_ref=audio.strip(),
                linguist_pass=verdict,
                asr_transcript=asr_transcript.strip() if isinstance(asr_transcript, str) else None,
                asr_provider=asr_provider.strip(),
            )
        )
    return out


def listen_batch_approved(
    samples: Sequence[ListenSample],
    *,
    required: int = REQUIRED_LISTEN_SAMPLES,
) -> bool:
    try:
        assert_listen_batch_approved(samples, required=required)
        return True
    except XhInterimError:
        return False


def assert_listen_batch_approved(
    samples: Sequence[ListenSample],
    *,
    required: int = REQUIRED_LISTEN_SAMPLES,
) -> None:
    if len(samples) < required:
        raise XhInterimError("SAMPLE_SHORTFALL", f"need {required} samples, got {len(samples)}")
    reviewed = [s for s in samples if s.linguist_pass is not None]
    if len(reviewed) < required:
        raise XhInterimError("REVIEW_SHORTFALL", f"need {required} linguist verdicts, got {len(reviewed)}")
    for sample in reviewed[:required]:
        if sample.linguist_pass is not True:
            raise XhInterimError("LISTEN_CHECK_FAILED", f"sample {sample.sample_id} failed listen-check")
        if sample.asr_transcript:
            assert_asr_round_trip(
                source_text=sample.source_text,
                transcript=sample.asr_transcript,
                asr_provider=sample.asr_provider,
            )
        elif xh_text_contains_clicks(sample.source_text):
            raise XhInterimError("CLICK_ASR_MISSING", "click sentences require ASR transcript in listen batch")


def load_clips_json(payload: str) -> list[InterimClip]:
    data = json.loads(payload)
    if not isinstance(data, list):
        raise XhInterimError("CLIPS_SHAPE", "clips payload must be a JSON array")
    return parse_clips(data)


def summary_payload(samples: Sequence[ListenSample]) -> dict[str, Any]:
    passed = sum(1 for s in samples if s.linguist_pass is True)
    failed = sum(1 for s in samples if s.linguist_pass is False)
    pending = sum(1 for s in samples if s.linguist_pass is None)
    return {
        "card_id": CARD_ID,
        "language_id": LANGUAGE_ID,
        "locale": LOCALE,
        "required_samples": REQUIRED_LISTEN_SAMPLES,
        "total": len(samples),
        "passed": passed,
        "failed": failed,
        "pending": pending,
        "approved": listen_batch_approved(samples),
        "interim_sources": xh_interim_audio_sources(),
        "dynamic_tts_enabled": xh_dynamic_tts_enabled(),
    }
