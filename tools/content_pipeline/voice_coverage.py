"""Voice-count gates for readiness levels (P4-133, ELEVATION §6.6)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_pipeline.readiness import L0_MIN_VOICES, L2_MIN_VOICES

CARD_ID = "P4-133"

_L0_L1_LEVELS = frozenset({"L0", "L1"})
_L2_PLUS_LEVELS = frozenset({"L2", "L3"})


class VoiceCoverageError(Exception):
    """Voice coverage gate failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class VoiceCoverageResult:
    target_level: str
    passed: bool
    distinct_voice_count: int
    code: str | None = None
    missing: tuple[str, ...] = ()


def _human_voice_id(entry: Mapping[str, Any]) -> str | None:
    if entry.get("kind") != "human":
        return None
    voice_id = entry.get("voice_id")
    if isinstance(voice_id, str) and voice_id.strip():
        return voice_id.strip()
    return None


def distinct_recorded_voice_ids(items: Sequence[Mapping[str, Any]]) -> set[str]:
    """Collect distinct human voice_ids that have recorded takes on pipeline items."""
    voices: set[str] = set()
    for item in items:
        audio = item.get("audio")
        if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)):
            continue
        for entry in audio:
            if not isinstance(entry, Mapping):
                continue
            vid = _human_voice_id(entry)
            if vid:
                voices.add(vid)
    return voices


def _profile_for_voice(
    voice_id: str,
    registry: Mapping[str, Mapping[str, Any]],
) -> Mapping[str, Any] | None:
    row = registry.get(voice_id)
    if isinstance(row, Mapping):
        return row
    return None


def _l2_spread_missing(profiles: Sequence[Mapping[str, Any]]) -> list[str]:
    missing: list[str] = []
    genders = {p.get("gender") for p in profiles if isinstance(p.get("gender"), str) and p["gender"].strip()}
    ages = {
        p.get("age_band")
        for p in profiles
        if isinstance(p.get("age_band"), str) and p["age_band"].strip()
    }
    regions = {
        p.get("region_tag")
        for p in profiles
        if isinstance(p.get("region_tag"), str) and p["region_tag"].strip()
    }
    if len(genders) < 2:
        missing.append("gender_spread")
    if len(ages) < 2:
        missing.append("age_spread")
    if len(regions) < 2:
        missing.append("region_spread")
    return missing


def check_voice_coverage(
    *,
    target_level: str,
    items: Sequence[Mapping[str, Any]],
    voice_registry: Mapping[str, Mapping[str, Any]],
) -> VoiceCoverageResult:
    """Enforce §6.6 voice-count gates for L0/L1 (≥2) and L2+ (≥4 with spread)."""
    level = target_level.strip().upper()
    if level not in _L0_L1_LEVELS | _L2_PLUS_LEVELS:
        raise VoiceCoverageError("TARGET_LEVEL_INVALID", f"unsupported target_level: {target_level!r}")

    voice_ids = sorted(distinct_recorded_voice_ids(items))
    count = len(voice_ids)
    min_required = L0_MIN_VOICES if level in _L0_L1_LEVELS else L2_MIN_VOICES

    if count < min_required:
        return VoiceCoverageResult(
            target_level=level,
            passed=False,
            distinct_voice_count=count,
            code="VOICE_COUNT_LOW",
            missing=(f"recorded_voices>={min_required}",),
        )

    if level in _L2_PLUS_LEVELS:
        profiles: list[Mapping[str, Any]] = []
        unregistered: list[str] = []
        for vid in voice_ids:
            profile = _profile_for_voice(vid, voice_registry)
            if profile is None:
                unregistered.append(vid)
            else:
                profiles.append(profile)
        missing: list[str] = []
        if unregistered:
            missing.append("voice_registry_missing")
        missing.extend(_l2_spread_missing(profiles))
        if missing:
            return VoiceCoverageResult(
                target_level=level,
                passed=False,
                distinct_voice_count=count,
                code="VOICE_COUNT_LOW",
                missing=tuple(missing),
            )

    return VoiceCoverageResult(target_level=level, passed=True, distinct_voice_count=count)


def enforce_voice_coverage(
    *,
    target_level: str,
    items: Sequence[Mapping[str, Any]],
    voice_registry: Mapping[str, Mapping[str, Any]],
) -> VoiceCoverageResult:
    """Raise VoiceCoverageError when the gate fails."""
    result = check_voice_coverage(
        target_level=target_level,
        items=items,
        voice_registry=voice_registry,
    )
    if not result.passed:
        detail = ", ".join(result.missing) if result.missing else "voice gate failed"
        raise VoiceCoverageError(result.code or "VOICE_COUNT_LOW", detail)
    return result


def sync_inventory_recorded_voice_ids(
    manifest: MutableMapping[str, Any],
    items: Sequence[Mapping[str, Any]],
) -> list[str]:
    """Write distinct recorded voice ids into manifest inventory for P4-110 gates."""
    inv = manifest.get("inventory")
    if inv is None:
        inv = {}
        manifest["inventory"] = inv
    if not isinstance(inv, MutableMapping):
        raise VoiceCoverageError("MANIFEST_INVALID", "inventory must be a mapping")
    ids = sorted(distinct_recorded_voice_ids(items))
    inv["recorded_voice_ids"] = ids
    return ids
