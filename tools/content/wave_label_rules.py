"""Waves 2–4 label rules and Expert L0 taste gates (P5-055, CURRICULUM §6)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.blind_sampler import aggregate_blind_error_rate, normalize_quality_label
from tools.content_pipeline.readiness import READINESS_LEVELS

CARD_ID = "P5-055"
GATE_ID = "G7"
EXPERT_STRATUM = "expert_reviewed"
WAVES_2_4_EXPERT_ERROR_CEILING = 0.02
_L0_TASTE_TRACK = "l0_taste"
_EXPERT_OR_BETTER = frozenset({"expert", "expert_reviewed", "native", "native_verified"})

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DEFAULT_REGISTRY = _REPO_ROOT / "assets/content/language_registry.json"


class WaveLabelRuleViolation(Exception):
    """A Waves 2–4 or L0 taste label rule failed."""

    def __init__(self, rule: str, item_id: str, message: str) -> None:
        self.rule = rule
        self.item_id = item_id
        self.message = message
        super().__init__(f"WaveLabelRuleViolation[{rule}] item={item_id}: {message}")


class WaveExpertVerificationError(Exception):
    """Waves 2–4 Expert verification cannot run."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _require_item_id(item: Mapping[str, Any]) -> str:
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise WaveLabelRuleViolation("ITEM_ID_MISSING", "<unknown>", "item id is required")
    return item_id.strip()


def language_id_from_item_id(item_id: str) -> str | None:
    prefix = item_id.split(".", 1)[0].strip().lower()
    return prefix if prefix else None


def load_language_wave_index(path: Path | None = None) -> dict[str, int]:
    p = path or _DEFAULT_REGISTRY
    if not p.is_file():
        raise WaveLabelRuleViolation("REGISTRY_MISSING", "<registry>", f"registry not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    entries = data.get("entries")
    if not isinstance(entries, list):
        raise WaveLabelRuleViolation("REGISTRY_INVALID", "<registry>", "entries must be an array")
    index: dict[str, int] = {}
    for row in entries:
        if not isinstance(row, dict):
            continue
        lang = row.get("language_id")
        wave = row.get("wave")
        if isinstance(lang, str) and isinstance(wave, int):
            index[lang.strip().lower()] = wave
    return index


def waves_2_4_language_ids(wave_index: Mapping[str, int] | None = None) -> frozenset[str]:
    index = wave_index if wave_index is not None else load_language_wave_index()
    return frozenset(lid for lid, wave in index.items() if wave in (2, 3, 4))


def is_below_l0(readiness_level: str | None) -> bool:
    """True until the language kit has reached L0 readiness (CURRICULUM §6 Waves 2–4)."""
    if readiness_level is None:
        return True
    if not isinstance(readiness_level, str) or not readiness_level.strip():
        return True
    return readiness_level.strip() not in READINESS_LEVELS


def has_lexicon_source(item: Mapping[str, Any]) -> bool:
    if item.get("lexicon_anchored") is True:
        return True
    direct = item.get("lexicon_source")
    if isinstance(direct, str) and direct.strip():
        return True
    prov = item.get("provenance")
    if isinstance(prov, Mapping):
        sources = prov.get("sources")
        if isinstance(sources, list):
            for src in sources:
                if not isinstance(src, Mapping):
                    continue
                kind = src.get("kind")
                if isinstance(kind, str) and kind.strip().casefold() == "lexicon":
                    return True
                name = src.get("name")
                if isinstance(name, str) and "lexicon" in name.casefold():
                    return True
                source_id = src.get("source_id")
                if isinstance(source_id, str) and source_id.strip().casefold().startswith("lexicon"):
                    return True
    return False


def is_l0_taste_item(item: Mapping[str, Any]) -> bool:
    track = item.get("content_track")
    if isinstance(track, str) and track.strip().casefold() == _L0_TASTE_TRACK:
        return True
    slice_tag = item.get("readiness_slice")
    return isinstance(slice_tag, str) and slice_tag.strip().casefold() == _L0_TASTE_TRACK


def assert_wave_beta_lexicon_when_below_l0(
    item: Mapping[str, Any],
    *,
    language_wave: int | None,
    language_readiness_level: str | None,
) -> None:
    """AC1: Wave 2–4 languages below L0 cannot ship Beta without a lexicon source."""
    if language_wave not in (2, 3, 4):
        return
    if not is_below_l0(language_readiness_level):
        return
    item_id = _require_item_id(item)
    label = normalize_quality_label(item.get("label"))
    if label != "beta":
        return
    if not has_lexicon_source(item):
        raise WaveLabelRuleViolation(
            "WAVE_BETA_NO_LEXICON",
            item_id,
            "Wave 2–4 Beta below L0 requires a lexicon source",
        )


def assert_l0_taste_expert_when_published(item: Mapping[str, Any], *, for_publish: bool) -> None:
    """AC2: L0 Taste content must be Expert-reviewed (or better) at publish."""
    if not for_publish or not is_l0_taste_item(item):
        return
    item_id = _require_item_id(item)
    label = normalize_quality_label(item.get("label"))
    if label not in _EXPERT_OR_BETTER:
        raise WaveLabelRuleViolation(
            "L0_TASTE_NOT_EXPERT",
            item_id,
            "L0 Taste content must be expert_reviewed or native_verified when published",
        )


def lint_wave_item(
    item: Mapping[str, Any],
    *,
    language_wave: int | None = None,
    language_readiness_level: str | None = None,
    for_publish: bool = False,
    wave_index: Mapping[str, int] | None = None,
) -> None:
    """Run Waves 2–4 label rules for one item."""
    item_id = _require_item_id(item)
    wave = language_wave
    if wave is None:
        lang = language_id_from_item_id(item_id)
        if lang is not None:
            index = wave_index if wave_index is not None else load_language_wave_index()
            wave = index.get(lang)
    assert_wave_beta_lexicon_when_below_l0(
        item,
        language_wave=wave,
        language_readiness_level=language_readiness_level,
    )
    assert_l0_taste_expert_when_published(item, for_publish=for_publish)


def _group_for_language(
    aggregated: Mapping[str, Any], language_id: str
) -> Mapping[str, Any] | None:
    for row in aggregated.get("groups", []):
        if not isinstance(row, Mapping):
            continue
        if row.get("language_id") == language_id and row.get("stratum") == EXPERT_STRATUM:
            return row
    return None


def _measure_language_expert(
    blind_reviews: Sequence[Mapping[str, Any]],
    language_id: str,
    *,
    as_of: date,
) -> dict[str, Any]:
    aggregated = aggregate_blind_error_rate(blind_reviews)
    group = _group_for_language(aggregated, language_id)

    if group is None:
        raise WaveExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {language_id}",
        )

    sample_size = int(group.get("sample_size") or 0)
    if sample_size <= 0:
        raise WaveExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {language_id}",
        )

    error_count = int(group.get("error_count") or 0)
    error_rate = group.get("error_rate")
    if not isinstance(error_rate, (int, float)) or isinstance(error_rate, bool):
        raise WaveExpertVerificationError("RATE_INVALID", "error_rate must be a number")

    rate = float(error_rate)
    passed = rate <= WAVES_2_4_EXPERT_ERROR_CEILING

    return {
        "language_id": language_id,
        "stratum": EXPERT_STRATUM,
        "wave_band": "2-4",
        "measurement_status": "measured_pilot",
        "measured_on": as_of.isoformat(),
        "sample_size": sample_size,
        "error_count": error_count,
        "error_rate": rate,
        "expert_error_ceiling": WAVES_2_4_EXPERT_ERROR_CEILING,
        "gate_passed": passed,
        "failure_code": None if passed else "WAVES_2_4_EXPERT_ERROR_EXCEEDED",
    }


def verify_waves_2_4_expert_gate(
    blind_reviews: Sequence[Mapping[str, Any]],
    *,
    wave_index: Mapping[str, int] | None = None,
    as_of: date | None = None,
) -> dict[str, Any]:
    """
    AC3: Expert-reviewed blind-sample error rate for each sampled Wave 2–4 language
    must be ≤2%.
    """
    index = wave_index if wave_index is not None else load_language_wave_index()
    wave_langs = waves_2_4_language_ids(index)
    sampled: set[str] = set()
    for row in blind_reviews:
        if not isinstance(row, Mapping):
            continue
        lang = row.get("language_id")
        if isinstance(lang, str) and lang.strip().lower() in wave_langs:
            sampled.add(lang.strip().lower())

    if not sampled:
        raise WaveExpertVerificationError(
            "NO_WAVE_SAMPLE",
            "no blind reviews for Wave 2–4 languages",
        )

    measured_on = as_of or datetime.now(UTC).date()
    languages: list[dict[str, Any]] = []
    for language_id in sorted(sampled):
        languages.append(
            _measure_language_expert(blind_reviews, language_id, as_of=measured_on)
        )

    gate_passed = all(row["gate_passed"] for row in languages)
    failed = [row["language_id"] for row in languages if not row["gate_passed"]]

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "stratum": EXPERT_STRATUM,
        "wave_band": "2-4",
        "measurement_status": "measured_pilot",
        "measured_on": measured_on.isoformat(),
        "languages": languages,
        "gate_passed": gate_passed,
        "failure_code": None if gate_passed else "WAVES_2_4_EXPERT_ERROR_EXCEEDED",
        "failed_language_ids": failed,
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> list[dict[str, Any]]:
    """Persist measured gate rows under store['waves_2_4_expert_verifications']."""
    if result.get("card_id") != CARD_ID:
        raise WaveExpertVerificationError("RESULT_INVALID", "result.card_id must be P5-055")
    rows = store.setdefault("waves_2_4_expert_verifications", [])
    if not isinstance(rows, list):
        raise WaveExpertVerificationError("STORE_INVALID", "waves_2_4_expert_verifications must be a list")

    appended: list[dict[str, Any]] = []
    for lang in result.get("languages", []):
        if not isinstance(lang, Mapping):
            continue
        row = {
            "card_id": CARD_ID,
            "gate": GATE_ID,
            "language_id": lang.get("language_id"),
            "stratum": lang.get("stratum"),
            "measured_on": lang.get("measured_on"),
            "sample_size": lang.get("sample_size"),
            "error_rate": lang.get("error_rate"),
            "gate_passed": lang.get("gate_passed"),
            "measurement_status": lang.get("measurement_status"),
        }
        rows.append(row)
        appended.append(row)
    return appended
