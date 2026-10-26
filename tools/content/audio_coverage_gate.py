"""Publish gate: every item has audio; synthetic is labelled; human text matches (P5-058)."""

from __future__ import annotations

import re
import unicodedata
from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.legacy.structure import audio_content_hash
from tools.content_pipeline.schema_loader import SYNTHETIC_VOICE_TAG

CARD_ID = "P5-058"
RULE_AC1 = "AC1"
RULE_AC2 = "AC2"
RULE_AC3 = "AC3"

_SYNTHETIC_KINDS = frozenset({"tts", "tts_synthetic"})
_HUMAN_KIND = "human"
_AUDIO_URI_HASH = re.compile(r"^audio/[a-z]{2,3}/([a-f0-9]+)\.[a-z0-9]+$")


class AudioCoverageError(Exception):
    """Audio coverage publish gate failure."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def _require_item_id(item: Mapping[str, Any]) -> str:
    item_id = item.get("id")
    if isinstance(item_id, str) and item_id.strip():
        return item_id.strip()
    return "<unknown>"


def item_spoken_text(item: Mapping[str, Any]) -> str | None:
    """Learner-facing surface used to validate licensed human audio (CP-§7-02)."""
    stimulus = item.get("stimulus")
    if isinstance(stimulus, Mapping):
        text = stimulus.get("text")
        if isinstance(text, str) and text.strip():
            return nfc(text)
    answer = item.get("answer_spec")
    if isinstance(answer, Mapping):
        correct = answer.get("correct")
        if isinstance(correct, str) and correct.strip():
            return nfc(correct)
    fallback = item.get("text")
    if isinstance(fallback, str) and fallback.strip():
        return nfc(fallback)
    return None


def _assert_human_matches_spoken(
    entry: Mapping[str, Any],
    spoken: str,
    *,
    item_id: str,
    index: int,
) -> None:
    for field in ("transcript", "source_text", "text"):
        raw = entry.get(field)
        if isinstance(raw, str) and raw.strip():
            if nfc(raw) != spoken:
                raise AudioCoverageError(
                    "AudioTextMismatch",
                    f"item={item_id} audio[{index}].{field} does not match item surface text",
                )
            return

    expected_hash = audio_content_hash(spoken)
    text_hash = entry.get("text_hash")
    if isinstance(text_hash, str) and text_hash.strip():
        if text_hash.strip() != expected_hash:
            raise AudioCoverageError(
                "AudioTextMismatch",
                f"item={item_id} audio[{index}].text_hash does not match item surface text",
            )
        return

    uri = entry.get("uri")
    if isinstance(uri, str):
        match = _AUDIO_URI_HASH.match(uri.strip())
        if match and match.group(1) == expected_hash:
            return

    raise AudioCoverageError(
        "AudioTextMismatch",
        f"item={item_id} audio[{index}] human clip has no text anchor matching item surface",
    )


def _check_audio_clip(
    entry: object,
    *,
    item_id: str,
    index: int,
    spoken: str | None,
) -> None:
    if not isinstance(entry, Mapping):
        raise AudioCoverageError(
            "AUDIO_MISSING",
            f"item={item_id} audio[{index}] must be an object",
        )
    kind = entry.get("kind")
    if not isinstance(kind, str) or not kind.strip():
        raise AudioCoverageError(
            "AUDIO_MISSING",
            f"item={item_id} audio[{index}].kind is required",
        )
    normalized_kind = kind.strip()
    uri = entry.get("uri")
    if not isinstance(uri, str) or not uri.strip():
        raise AudioCoverageError(
            "AUDIO_MISSING",
            f"item={item_id} audio[{index}].uri is required",
        )

    if normalized_kind in _SYNTHETIC_KINDS:
        tag = entry.get("synthetic_voice_tag")
        if tag != SYNTHETIC_VOICE_TAG:
            raise AudioCoverageError(
                "SYNTHETIC_TAG_MISSING",
                f'item={item_id} audio[{index}] requires synthetic_voice_tag "{SYNTHETIC_VOICE_TAG}"',
            )
        return

    if normalized_kind == _HUMAN_KIND:
        if spoken is None:
            raise AudioCoverageError(
                "AudioTextMismatch",
                f"item={item_id} has human audio but no item surface text to verify",
            )
        _assert_human_matches_spoken(entry, spoken, item_id=item_id, index=index)
        return

    raise AudioCoverageError(
        "AUDIO_KIND_INVALID",
        f"item={item_id} audio[{index}].kind must be human, tts, or tts_synthetic",
    )


def assert_published_item_audio(item: Mapping[str, Any]) -> None:
    """Block publish when audio coverage rules fail (AC1–AC3)."""
    item_id = _require_item_id(item)
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)) or len(audio) < 1:
        raise AudioCoverageError(
            "AUDIO_MISSING",
            f"item={item_id} must have at least one audio clip to publish",
        )
    spoken = item_spoken_text(item)
    for index, clip in enumerate(audio):
        _check_audio_clip(clip, item_id=item_id, index=index, spoken=spoken)


def evaluate_audio_coverage_gate(item: Mapping[str, Any]) -> dict[str, Any]:
    """Return a pass/fail report for CI dashboards."""
    item_id = _require_item_id(item)
    try:
        assert_published_item_audio(item)
    except AudioCoverageError as exc:
        return {
            "card_id": CARD_ID,
            "item_id": item_id,
            "passed": False,
            "code": exc.code,
            "message": str(exc),
        }
    return {
        "card_id": CARD_ID,
        "item_id": item_id,
        "passed": True,
        "clip_count": len(item.get("audio") or []),
    }


def assert_batch_published_audio(items: Sequence[Mapping[str, Any]]) -> None:
    """Fail fast on the first item that cannot publish under §7 audio rules."""
    for item in items:
        if not isinstance(item, Mapping):
            continue
        assert_published_item_audio(item)
