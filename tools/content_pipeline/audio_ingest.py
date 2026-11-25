"""Native recording ingest (P4-123, ELEVATION §6.4.1 / §6.6)."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal, Mapping, MutableMapping

from tools.content_engine.legacy.structure import audio_content_hash

CARD_ID = "P4-123"

Speed = Literal["natural", "slow"]
_LANG_RE = re.compile(r"^[a-z]{2,3}$")


class AudioIngestError(Exception):
    """Ingest failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class IngestedRecording:
    """Stored blob plus v2 audio ref fields for pipeline items."""

    blob_path: Path
    content_hash: str
    audio_ref: dict[str, Any]


def _blob_content_hash(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def ingest_native_recording(
    *,
    data: bytes,
    language: str,
    spoken_text: str,
    voice_id: str,
    speed: Speed,
    consent_id: str,
    storage_root: Path,
    extension: str = "wav",
) -> IngestedRecording:
    """Store audio under its blob content hash; return human audio ref (AC1)."""
    if not data:
        raise AudioIngestError("RECORDING_EMPTY", "recording bytes are empty")
    lang = language.strip().lower()
    if not _LANG_RE.match(lang):
        raise AudioIngestError("LANGUAGE_INVALID", f"unsupported language code: {language!r}")
    if not voice_id.strip():
        raise AudioIngestError("VOICE_ID_MISSING", "voice_id is required")
    if speed not in ("natural", "slow"):
        raise AudioIngestError("SPEED_INVALID", "speed must be natural or slow")
    if not consent_id.strip():
        raise AudioIngestError("CONSENT_MISSING", "consent_id is required for human recordings")

    content_hash = _blob_content_hash(data)
    blob_dir = storage_root / content_hash
    blob_dir.mkdir(parents=True, exist_ok=True)
    blob_path = blob_dir / f"take.{extension.lstrip('.')}"
    if not blob_path.exists():
        blob_path.write_bytes(data)

    text_hash = audio_content_hash(spoken_text)
    uri = f"audio/{lang}/{text_hash}.{extension.lstrip('.')}"
    audio_ref: dict[str, Any] = {
        "kind": "human",
        "voice_id": voice_id.strip(),
        "speed": speed,
        "consent_id": consent_id.strip(),
        "uri": uri,
        "text_hash": text_hash,
        "transcript": spoken_text,
        "blob_content_hash": content_hash,
        "aligned_words": [],
        "aligned_phones": [],
    }
    return IngestedRecording(blob_path=blob_path, content_hash=content_hash, audio_ref=audio_ref)


def attach_audio_to_item(
    item: MutableMapping[str, Any],
    audio_ref: Mapping[str, Any],
) -> None:
    """Append an audio take to a pipeline item envelope."""
    audio = item.get("audio")
    if audio is None:
        item["audio"] = [dict(audio_ref)]
        return
    if not isinstance(audio, list):
        raise AudioIngestError("ITEM_AUDIO_INVALID", "item.audio must be a list")
    audio.append(dict(audio_ref))
