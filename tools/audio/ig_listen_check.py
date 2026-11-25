"""Igbo TTS linguist listen-check ledger (P5-061, AC3: 200 samples before use)."""

from __future__ import annotations

import json
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any

CARD_ID = "P5-061"
REQUIRED_SAMPLES = 200

# CP-§7-ig-03 / P5-027: Igbo is H/L + downstep (igbo_hl_downstep). The automated F0 gate
# in P5-059 still buckets contours into H/M/L (same runner as Yoruba). That proxy is weaker
# for Igbo than for Yoruba H/M/L, so the linguist listen batch is 200 samples (Yoruba: 100).
IGBO_TONE_PROXY_WEAKER_NOTE = (
    "ASR round-trip and F0 tone proxy use tools.audio.gate_runner (P5-059); "
    "Igbo F0 uses H/M/L bucketing while the pedagogical model is H/L + downstep — weaker proxy."
)


class ListenCheckError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ListenSample:
    sample_id: str
    source_text: str
    audio_ref: str
    linguist_pass: bool | None = None


def parse_batch(rows: Sequence[Mapping[str, Any]]) -> list[ListenSample]:
    out: list[ListenSample] = []
    for index, row in enumerate(rows):
        sample_id = row.get("sample_id") or row.get("id") or f"ig-{index + 1}"
        text = row.get("source_text") or row.get("text")
        audio = row.get("audio_ref") or row.get("audio_path") or row.get("audio")
        if not isinstance(sample_id, str) or not sample_id.strip():
            raise ListenCheckError("SAMPLE_ID_MISSING", f"row {index} missing sample_id")
        if not isinstance(text, str) or not text.strip():
            raise ListenCheckError("SOURCE_TEXT_EMPTY", f"sample={sample_id} missing text")
        if not isinstance(audio, str) or not audio.strip():
            raise ListenCheckError("AUDIO_REF_EMPTY", f"sample={sample_id} missing audio_ref")
        verdict = row.get("linguist_pass")
        if verdict is not None and not isinstance(verdict, bool):
            raise ListenCheckError("VERDICT_INVALID", f"sample={sample_id} linguist_pass must be bool")
        out.append(
            ListenSample(
                sample_id=sample_id.strip(),
                source_text=text.strip(),
                audio_ref=audio.strip(),
                linguist_pass=verdict,
            )
        )
    return out


def batch_approved(samples: Sequence[ListenSample], *, required: int = REQUIRED_SAMPLES) -> bool:
    if len(samples) < required:
        return False
    reviewed = [s for s in samples if s.linguist_pass is not None]
    if len(reviewed) < required:
        return False
    return all(s.linguist_pass is True for s in reviewed[:required])


def assert_batch_approved(samples: Sequence[ListenSample], *, required: int = REQUIRED_SAMPLES) -> None:
    if len(samples) < required:
        raise ListenCheckError(
            "SAMPLE_SHORTFALL",
            f"need {required} samples, got {len(samples)}",
        )
    reviewed = [s for s in samples if s.linguist_pass is not None]
    if len(reviewed) < required:
        raise ListenCheckError(
            "REVIEW_SHORTFALL",
            f"need {required} linguist verdicts, got {len(reviewed)}",
        )
    failures = [s.sample_id for s in reviewed[:required] if not s.linguist_pass]
    if failures:
        raise ListenCheckError(
            "LISTEN_CHECK_FAILED",
            f"failed samples: {', '.join(failures[:5])}",
        )


def load_batch_json(payload: str) -> list[ListenSample]:
    data = json.loads(payload)
    if not isinstance(data, list):
        raise ListenCheckError("BATCH_SHAPE", "batch must be a JSON array")
    return parse_batch(data)


def summary_payload(samples: Sequence[ListenSample]) -> dict[str, Any]:
    passed = sum(1 for s in samples if s.linguist_pass is True)
    failed = sum(1 for s in samples if s.linguist_pass is False)
    pending = sum(1 for s in samples if s.linguist_pass is None)
    return {
        "card_id": CARD_ID,
        "required_samples": REQUIRED_SAMPLES,
        "tone_proxy_note": IGBO_TONE_PROXY_WEAKER_NOTE,
        "total": len(samples),
        "passed": passed,
        "failed": failed,
        "pending": pending,
        "approved": batch_approved(samples),
    }
