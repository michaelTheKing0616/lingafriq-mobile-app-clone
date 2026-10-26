"""Forced alignment stage for native takes (P4-123).

Production aligner: Omnilingual ASR CTC per ``LINGAFRIQ_AI_MODEL_STACK.md`` (Apache-2.0).
Tests inject a callable; failures must not invent timings (AC2).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Mapping, MutableMapping, Sequence

CARD_ID = "P4-123"

AlignerFn = Callable[[bytes, str, str], "AlignmentPayload"]


class ForcedAlignError(Exception):
    """Alignment failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class WordSpan:
    text: str
    start_ms: int
    end_ms: int


@dataclass(frozen=True)
class PhoneSpan:
    phone: str
    start_ms: int
    end_ms: int


@dataclass(frozen=True)
class AlignmentPayload:
    words: tuple[WordSpan, ...]
    phones: tuple[PhoneSpan, ...]


def _serialize_words(words: Sequence[WordSpan]) -> list[dict[str, Any]]:
    return [{"text": w.text, "start_ms": w.start_ms, "end_ms": w.end_ms} for w in words]


def _serialize_phones(phones: Sequence[PhoneSpan]) -> list[dict[str, Any]]:
    return [{"phone": p.phone, "start_ms": p.start_ms, "end_ms": p.end_ms} for p in phones]


def apply_alignment_to_audio_ref(
    audio_ref: MutableMapping[str, Any],
    payload: AlignmentPayload,
) -> None:
    audio_ref["alignment_status"] = "ok"
    audio_ref["aligned_words"] = _serialize_words(payload.words)
    audio_ref["aligned_phones"] = _serialize_phones(payload.phones)


def mark_alignment_failed(audio_ref: MutableMapping[str, Any], message: str) -> None:
    audio_ref["alignment_status"] = "ALIGN_FAILED"
    audio_ref["alignment_error"] = message
    audio_ref["aligned_words"] = []
    audio_ref["aligned_phones"] = []


def align_recording(
    *,
    audio_bytes: bytes,
    spoken_text: str,
    language: str,
    audio_ref: MutableMapping[str, Any],
    aligner: AlignerFn | None,
) -> None:
    """Run forced alignment on a single take; mutates ``audio_ref`` in place."""
    if aligner is None:
        mark_alignment_failed(audio_ref, "aligner not configured")
        return
    try:
        payload = aligner(audio_bytes, spoken_text, language)
    except ForcedAlignError as exc:
        mark_alignment_failed(audio_ref, exc.args[0])
        return
    except Exception as exc:  # noqa: BLE001 — surface as ALIGN_FAILED, no guessed timings
        mark_alignment_failed(audio_ref, str(exc))
        return
    if not payload.words or not payload.phones:
        mark_alignment_failed(audio_ref, "aligner returned empty boundaries")
        return
    apply_alignment_to_audio_ref(audio_ref, payload)


def align_item_takes(
    item: Mapping[str, Any],
    *,
    blob_loader: Callable[[Mapping[str, Any]], bytes],
    aligner: AlignerFn | None,
    language: str,
    spoken_text: str,
) -> list[MutableMapping[str, Any]]:
    """Align every human take on an item; returns mutated audio refs."""
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)):
        return []
    updated: list[MutableMapping[str, Any]] = []
    for entry in audio:
        if not isinstance(entry, MutableMapping):
            continue
        if entry.get("kind") != "human":
            continue
        blob = blob_loader(entry)
        align_recording(
            audio_bytes=blob,
            spoken_text=spoken_text,
            language=language,
            audio_ref=entry,
            aligner=aligner,
        )
        updated.append(entry)
    return updated
