"""Per-item audio manifest, coverage gaps, and interim synthetic policy (P4-123)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal, Mapping, MutableMapping, Sequence

CARD_ID = "P4-123"

Speed = Literal["natural", "slow"]
REQUIRED_HUMAN_SPEEDS: frozenset[str] = frozenset({"natural", "slow"})


class AudioManifestError(Exception):
    """Manifest validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass
class ItemAudioManifest:
    item_id: str
    takes: list[dict[str, Any]] = field(default_factory=list)
    exposure_rank: int = 0

    def to_dict(self) -> dict[str, Any]:
        return {
            "item_id": self.item_id,
            "exposure_rank": self.exposure_rank,
            "takes": list(self.takes),
        }


def register_tts_synthetic_interim(
    item: MutableMapping[str, Any],
    *,
    uri: str,
    synthetic_voice_tag: str,
    exposure_rank: int,
) -> dict[str, Any]:
    """Allow labelled interim synthetic audio pending native replacement (AC3)."""
    if exposure_rank < 0:
        raise AudioManifestError("EXPOSURE_RANK_INVALID", "exposure_rank must be non-negative")
    entry: dict[str, Any] = {
        "kind": "tts_synthetic",
        "uri": uri,
        "synthetic_voice_tag": synthetic_voice_tag,
        "interim_d1": True,
        "native_replacement_rank": exposure_rank,
    }
    audio = item.get("audio")
    if audio is None:
        item["audio"] = [entry]
    elif isinstance(audio, list):
        audio.append(entry)
    else:
        raise AudioManifestError("ITEM_AUDIO_INVALID", "item.audio must be a list")
    return entry


def human_speeds_present(audio: Sequence[object]) -> set[str]:
    speeds: set[str] = set()
    for entry in audio:
        if not isinstance(entry, Mapping):
            continue
        if entry.get("kind") != "human":
            continue
        speed = entry.get("speed")
        if isinstance(speed, str):
            speeds.add(speed)
    return speeds


def coverage_gaps_for_item(item: Mapping[str, Any]) -> list[str]:
    """Return COVERAGE_GAP codes for missing natural or slow human takes (AC4)."""
    item_id = str(item.get("id", "?"))
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)):
        return [f"COVERAGE_GAP:{item_id}:natural", f"COVERAGE_GAP:{item_id}:slow"]
    present = human_speeds_present(audio)
    gaps: list[str] = []
    for speed in sorted(REQUIRED_HUMAN_SPEEDS - present):
        gaps.append(f"COVERAGE_GAP:{item_id}:{speed}")
    return gaps


def validate_human_take_coverage(item: Mapping[str, Any]) -> None:
    gaps = coverage_gaps_for_item(item)
    if gaps:
        raise AudioManifestError(gaps[0], "; ".join(gaps))


def build_item_manifest(item: Mapping[str, Any], *, exposure_rank: int = 0) -> ItemAudioManifest:
    item_id = str(item.get("id", ""))
    audio = item.get("audio")
    takes: list[dict[str, Any]] = []
    if isinstance(audio, Sequence) and not isinstance(audio, (str, bytes)):
        for entry in audio:
            if isinstance(entry, Mapping):
                takes.append(dict(entry))
    return ItemAudioManifest(item_id=item_id, takes=takes, exposure_rank=exposure_rank)


def interim_synthetic_entries(item: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)):
        return []
    out: list[Mapping[str, Any]] = []
    for entry in audio:
        if not isinstance(entry, Mapping):
            continue
        if entry.get("kind") == "tts_synthetic" and entry.get("interim_d1") is True:
            out.append(entry)
    return out
