"""Language readiness levels L0–L3 and promotion gates (P4-110, ELEVATION §6.4)."""

from __future__ import annotations

from collections.abc import Mapping, MutableMapping, Sequence
from copy import deepcopy
from typing import Any

from tools.content_pipeline.schema_loader import SYNTHETIC_VOICE_TAG

CARD_ID = "P4-110"

READINESS_LEVELS: tuple[str, ...] = ("L0", "L1", "L2", "L3")
_NEXT_LEVEL: dict[str, str] = {"L0": "L1", "L1": "L2", "L2": "L3"}

L0_WORD_MIN = 50
L0_WORD_MAX = 100
L0_MIN_CULTURE_CARDS = 1
L0_MIN_VOICES = 2
L2_MIN_VOICES = 4

_COVERAGE_COMPLETE = "complete"
_PROMOTABLE_LABELS = frozenset({"beta", "expert_reviewed"})


class ReadinessError(Exception):
    """Readiness or promotion failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class GateResult:
    __slots__ = ("level", "passed", "code", "missing")

    def __init__(
        self,
        level: str,
        *,
        passed: bool,
        code: str | None = None,
        missing: Sequence[str] = (),
    ) -> None:
        self.level = level
        self.passed = passed
        self.code = code
        self.missing = tuple(missing)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise ReadinessError(code, f"{label} must be a mapping")
    return value


def _inventory(manifest: Mapping[str, Any]) -> Mapping[str, Any]:
    return _require_mapping(manifest.get("inventory"), "MANIFEST_INVALID", "inventory")


def _coverage(manifest: Mapping[str, Any]) -> Mapping[str, Any]:
    raw = manifest.get("coverage")
    if raw is None:
        return {}
    return _require_mapping(raw, "MANIFEST_INVALID", "coverage")


def _features(manifest: Mapping[str, Any]) -> Mapping[str, Any]:
    raw = manifest.get("features")
    if raw is None:
        return {}
    return _require_mapping(raw, "MANIFEST_INVALID", "features")


def _evals(manifest: Mapping[str, Any]) -> Mapping[str, Any]:
    raw = manifest.get("evals")
    if raw is None:
        return {}
    return _require_mapping(raw, "MANIFEST_INVALID", "evals")


def _items(manifest: Mapping[str, Any]) -> tuple[Mapping[str, Any], ...]:
    raw = manifest.get("items")
    if raw is None:
        return ()
    if not isinstance(raw, Sequence) or isinstance(raw, (str, bytes)):
        raise ReadinessError("MANIFEST_INVALID", "items must be a sequence")
    out: list[Mapping[str, Any]] = []
    for index, row in enumerate(raw):
        out.append(_require_mapping(row, "MANIFEST_INVALID", f"items[{index}]"))
    return tuple(out)


def _audio_passes_d6_gate(audio: Mapping[str, Any]) -> bool:
    kind = audio.get("kind")
    if kind == "human":
        uri = audio.get("uri")
        return isinstance(uri, str) and bool(uri.strip())
    if kind == "tts_synthetic":
        uri = audio.get("uri")
        tag = audio.get("synthetic_voice_tag")
        return (
            isinstance(uri, str)
            and bool(uri.strip())
            and tag == SYNTHETIC_VOICE_TAG
        )
    return False


def _item_has_gated_audio(item: Mapping[str, Any]) -> bool:
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)) or not audio:
        return False
    for entry in audio:
        if not isinstance(entry, Mapping):
            return False
        if not _audio_passes_d6_gate(entry):
            return False
    return True


def _item_has_native_recorded_audio(item: Mapping[str, Any]) -> bool:
    audio = item.get("audio")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)) or not audio:
        return False
    for entry in audio:
        if not isinstance(entry, Mapping):
            return False
        if entry.get("kind") != "human":
            return False
        uri = entry.get("uri")
        if not isinstance(uri, str) or not uri.strip():
            return False
    return True


def _two_native_approval(item: Mapping[str, Any]) -> bool:
    review = item.get("review")
    if not isinstance(review, Mapping):
        return False
    reviewers = review.get("reviewers")
    if not isinstance(reviewers, Sequence):
        return False
    native_ids: set[str] = set()
    for row in reviewers:
        if not isinstance(row, Mapping):
            continue
        if row.get("approved") is not True or row.get("role") != "native":
            continue
        rid = row.get("reviewer_id")
        if isinstance(rid, str) and rid.strip():
            native_ids.add(rid.strip())
    return len(native_ids) >= 2


def gate_l0(manifest: Mapping[str, Any]) -> GateResult:
    inv = _inventory(manifest)
    missing: list[str] = []
    if inv.get("has_greetings") is not True:
        missing.append("greetings")
    if inv.get("has_numbers") is not True:
        missing.append("numbers")
    word_count = inv.get("word_count")
    if not isinstance(word_count, int) or word_count < L0_WORD_MIN:
        missing.append(f"words>={L0_WORD_MIN}")
    elif word_count > L0_WORD_MAX:
        missing.append(f"words<={L0_WORD_MAX}")
    culture = inv.get("culture_card_count")
    if not isinstance(culture, int) or culture < L0_MIN_CULTURE_CARDS:
        missing.append(f"culture_cards>={L0_MIN_CULTURE_CARDS}")
    voices = inv.get("recorded_voice_ids")
    voice_count = len(voices) if isinstance(voices, Sequence) and not isinstance(voices, (str, bytes)) else 0
    if voice_count < L0_MIN_VOICES:
        missing.append(f"recorded_voices>={L0_MIN_VOICES}")
    if missing:
        return GateResult("L0", passed=False, code="READINESS_L0_FAIL", missing=missing)
    return GateResult("L0", passed=True)


def gate_l1(manifest: Mapping[str, Any]) -> GateResult:
    missing: list[str] = []
    cov = _coverage(manifest)
    if cov.get("A1") != _COVERAGE_COMPLETE:
        missing.append("A1_coverage_complete")
    items = _items(manifest)
    for item in items:
        if not _item_has_gated_audio(item):
            missing.append(f"item_audio:{item.get('id', '?')}")
    feats = _features(manifest)
    if feats.get("asr_understood_feedback") is not True:
        missing.append("asr_understood_feedback")
    if missing:
        return GateResult("L1", passed=False, code="READINESS_L1_FAIL", missing=missing)
    return GateResult("L1", passed=True)


def gate_l2(manifest: Mapping[str, Any]) -> GateResult:
    missing: list[str] = []
    cov = _coverage(manifest)
    for level in ("A1", "A2"):
        if cov.get(level) != _COVERAGE_COMPLETE:
            missing.append(f"{level}_coverage_complete")
    feats = _features(manifest)
    for flag in ("tone_scoring", "pronunciation_scoring", "dynamic_tts", "ai_tutor_modes"):
        if feats.get(flag) is not True:
            missing.append(flag)
    inv = _inventory(manifest)
    voices = inv.get("recorded_voice_ids")
    voice_count = len(voices) if isinstance(voices, Sequence) and not isinstance(voices, (str, bytes)) else 0
    if voice_count < L2_MIN_VOICES:
        missing.append(f"recorded_voices>={L2_MIN_VOICES}")
    if missing:
        return GateResult("L2", passed=False, code="READINESS_L2_FAIL", missing=missing)
    return GateResult("L2", passed=True)


def gate_l3(manifest: Mapping[str, Any]) -> GateResult:
    missing: list[str] = []
    cov = _coverage(manifest)
    for level in ("A1", "A2", "B1"):
        if cov.get(level) != _COVERAGE_COMPLETE:
            missing.append(f"{level}_coverage_complete")
    feats = _features(manifest)
    for flag in ("realtime_voice", "personas", "credential_checkpoints"):
        if feats.get(flag) is not True:
            missing.append(flag)
    ev = _evals(manifest)
    if ev.get("realtime_voice") != "pass":
        missing.append("eval_realtime_voice_pass")
    if ev.get("persona") != "pass":
        missing.append("eval_persona_pass")
    if missing:
        return GateResult("L3", passed=False, code="READINESS_L3_FAIL", missing=missing)
    return GateResult("L3", passed=True)


_LEVEL_GATES: dict[str, Any] = {
    "L0": gate_l0,
    "L1": gate_l1,
    "L2": gate_l2,
    "L3": gate_l3,
}


def gate_readiness(manifest: Mapping[str, Any], level: str) -> GateResult:
    """Evaluate promotion gates for a target readiness level."""
    if level not in _LEVEL_GATES:
        raise ReadinessError("LEVEL_INVALID", f"unknown readiness level {level}")
    _require_mapping(manifest, "MANIFEST_INVALID", "manifest")
    return _LEVEL_GATES[level](manifest)


def evaluate_all_gates(manifest: Mapping[str, Any]) -> dict[str, GateResult]:
    return {level: gate_readiness(manifest, level) for level in READINESS_LEVELS}


def request_promotion(manifest: MutableMapping[str, Any]) -> dict[str, Any]:
    """Promote one level when all gates for the next level pass (AC5)."""
    current = manifest.get("readiness_level")
    if current not in _NEXT_LEVEL and current != "L3":
        raise ReadinessError("LEVEL_INVALID", "readiness_level must be L0, L1, L2, or L3")
    if current == "L3":
        return {
            "card_id": CARD_ID,
            "promoted": False,
            "readiness_level": "L3",
            "code": "ALREADY_AT_MAX",
            "message": "already at L3",
        }
    target = _NEXT_LEVEL[str(current)]
    result = gate_readiness(manifest, target)
    if not result.passed:
        return {
            "card_id": CARD_ID,
            "promoted": False,
            "readiness_level": current,
            "code": "PROMOTION_BLOCKED",
            "target_level": target,
            "failing_gate": result.code,
            "missing": list(result.missing),
        }
    manifest["readiness_level"] = target
    return {
        "card_id": CARD_ID,
        "promoted": True,
        "readiness_level": target,
        "previous_level": current,
    }


def promote_native_verified(items: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    """Move beta/expert_reviewed objects to native_verified when audio and review gates pass (AC6)."""
    updated: list[dict[str, Any]] = []
    for index, item in enumerate(items):
        row = _require_mapping(item, "ITEM_INVALID", f"items[{index}]")
        label = row.get("label")
        if label == "native_verified":
            updated.append(dict(row))
            continue
        if label not in _PROMOTABLE_LABELS:
            raise ReadinessError(
                "NATIVE_VERIFY_BLOCKED",
                f"item {row.get('id')} label {label} cannot be promoted",
            )
        if not _item_has_native_recorded_audio(row):
            raise ReadinessError(
                "NATIVE_VERIFY_BLOCKED",
                f"item {row.get('id')} requires native-recorded audio on every clip",
            )
        if not _two_native_approval(row):
            raise ReadinessError(
                "NATIVE_VERIFY_BLOCKED",
                f"item {row.get('id')} requires two approved native reviewers",
            )
        copy = deepcopy(dict(row))
        copy["label"] = "native_verified"
        updated.append(copy)
    return updated
