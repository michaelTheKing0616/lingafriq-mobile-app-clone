"""QA listen-through logging and UGC voice routing (P4-133, ELEVATION §6.6)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any, Literal, Mapping, MutableMapping

CARD_ID = "P4-133"

ListenResult = Literal["pass", "fail", "flag"]


class ListenQAError(Exception):
    """Listen-through QA failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def recording_id_for_audio(entry: Mapping[str, Any]) -> str:
    """Stable id for a human or synthetic take used in QA logs."""
    if not isinstance(entry, Mapping):
        raise ListenQAError("AUDIO_INVALID", "audio entry must be a mapping")
    blob = entry.get("blob_content_hash")
    if isinstance(blob, str) and blob.strip():
        return blob.strip()
    uri = entry.get("uri")
    if isinstance(uri, str) and uri.strip():
        return uri.strip()
    raise ListenQAError("RECORDING_ID_MISSING", "audio entry lacks blob_content_hash or uri")


def log_listen_through(
    *,
    recording_id: str,
    reviewer_id: str,
    result: ListenResult,
    reviewed_at: datetime | None = None,
) -> dict[str, Any]:
    """Store reviewer, result, and timestamp for a listen-through (AC3)."""
    if not recording_id.strip():
        raise ListenQAError("RECORDING_ID_MISSING", "recording_id is required")
    if not reviewer_id.strip():
        raise ListenQAError("REVIEWER_INVALID", "reviewer_id is required")
    if result not in ("pass", "fail", "flag"):
        raise ListenQAError("RESULT_INVALID", "result must be pass, fail, or flag")
    when = reviewed_at or datetime.now(UTC)
    return {
        "recording_id": recording_id.strip(),
        "reviewer_id": reviewer_id.strip(),
        "result": result,
        "reviewed_at": when.isoformat(),
        "provenance": "human",
    }


def append_listen_log(entry: MutableMapping[str, Any], log_row: Mapping[str, Any]) -> None:
    """Attach a listen-through log row to a human audio take."""
    logs = entry.get("listen_qa")
    if logs is None:
        entry["listen_qa"] = [dict(log_row)]
        return
    if not isinstance(logs, list):
        raise ListenQAError("LISTEN_QA_INVALID", "listen_qa must be a list")
    logs.append(dict(log_row))


def has_logged_listen_qa(entry: Mapping[str, Any]) -> bool:
    """True when at least one listen-through log exists on the take."""
    if entry.get("kind") != "human":
        return True
    logs = entry.get("listen_qa")
    if not isinstance(logs, list) or not logs:
        return False
    for row in logs:
        if not isinstance(row, Mapping):
            continue
        if (
            isinstance(row.get("reviewer_id"), str)
            and row.get("reviewer_id").strip()
            and isinstance(row.get("result"), str)
            and isinstance(row.get("reviewed_at"), str)
        ):
            return True
    return False


def assert_shippable_human_audio(entry: Mapping[str, Any]) -> None:
    """Unlogged human recordings cannot ship (AC3)."""
    if entry.get("kind") != "human":
        return
    if not has_logged_listen_qa(entry):
        rid = recording_id_for_audio(entry)
        raise ListenQAError("LISTEN_QA_MISSING", f"listen-through required for {rid}")


def assert_item_audio_shippable(item: Mapping[str, Any]) -> None:
    audio = item.get("audio")
    if not isinstance(audio, list):
        return
    for entry in audio:
        if isinstance(entry, Mapping):
            assert_shippable_human_audio(entry)


def route_ugc_voice_contribution(submission: Mapping[str, Any]) -> dict[str, Any]:
    """Route UGC voice through consent/licence checks; never auto-publish (AC4)."""
    if submission.get("source") != "ugc_voice":
        raise ListenQAError("UGC_SOURCE_INVALID", "source must be ugc_voice")
    consent = submission.get("consent_signed")
    licence = submission.get("licence_terms_signed")
    if consent is not True:
        raise ListenQAError("CONSENT_MISSING", "UGC voice requires consent_signed")
    if licence is not True:
        raise ListenQAError("LICENCE_MISSING", "UGC voice requires licence_terms_signed")
    voice_id = submission.get("voice_id")
    if not isinstance(voice_id, str) or not voice_id.strip():
        raise ListenQAError("VOICE_ID_MISSING", "voice_id is required")
    return {
        "status": "review_required",
        "auto_publish": False,
        "pipeline": CARD_ID,
        "voice_id": voice_id.strip(),
        "queue": "native_audio_review",
    }
