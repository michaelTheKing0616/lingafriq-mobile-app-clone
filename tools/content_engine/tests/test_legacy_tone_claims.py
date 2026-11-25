"""Spec tests for legacy tonal_note re-derivation (P4-084)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.tone_claims import (  # noqa: E402
    HIGH_RISK_TAG_TONE,
    REASON_NO_LEXICON_TONE,
    build_review_record,
    format_lexicon_tone_note,
    plan_tone_claim_change,
    run_tone_claims,
    TonalTarget,
)

_FIXTURE_PATTERN = "fixture-H-L"
_LEGACY_NOTE = "High tone on àárọ̀ marks respect"


def _lookup(kit_lang: str, form: str) -> dict[str, str] | None:
    if kit_lang == "yo" and form == "Ẹ kú àárọ̀":
        return {"tone_pattern": _FIXTURE_PATTERN}
    return None


def _mini_game(words: list[dict]) -> dict:
    return {"meta": {"version": "test"}, "words": words}


def _write_game(tmp_path: Path, payload: dict) -> Path:
    path = tmp_path / "assets/data/game_content.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_P4_084_format_lexicon_tone_note() -> None:
    assert format_lexicon_tone_note(_FIXTURE_PATTERN) == f"tone_pattern: {_FIXTURE_PATTERN}"


def test_P4_084_AC1_dry_run_lists_changes_without_writing(tmp_path: Path) -> None:
    payload = _mini_game(
        [
            {
                "id": 1,
                "language": "yoruba",
                "word": "Ẹ kú àárọ̀",
                "tonal_note": _LEGACY_NOTE,
            }
        ]
    )
    path = _write_game(tmp_path, payload)
    before = path.read_text(encoding="utf-8")
    result = run_tone_claims(
        tmp_path,
        dry_run=True,
        lexicon_lookup=_lookup,
        game_path=path,
    )
    assert len(result.changes) == 1
    assert result.changes[0].action == "derived"
    assert path.read_text(encoding="utf-8") == before


def test_P4_084_AC1_derives_from_lexicon_or_removes_no_lexicon(tmp_path: Path) -> None:
    path = _write_game(
        tmp_path,
        _mini_game(
            [
                {
                    "id": 1,
                    "language": "yoruba",
                    "word": "Ẹ kú àárọ̀",
                    "tonal_note": _LEGACY_NOTE,
                },
                {
                    "id": 2,
                    "language": "yoruba",
                    "word": "Ó dára",
                    "tonal_note": "uncited legacy claim",
                },
            ]
        ),
    )
    result = run_tone_claims(
        tmp_path,
        dry_run=False,
        lexicon_lookup=_lookup,
        game_path=path,
    )
    data = json.loads(path.read_text(encoding="utf-8"))
    w1 = data["words"][0]
    w2 = data["words"][1]
    assert w1["tonal_note"] == format_lexicon_tone_note(_FIXTURE_PATTERN)
    assert w2["tonal_note"] is None
    assert result.stats.derived == 1
    assert result.stats.removed == 1
    removed = next(c for c in result.changes if c.action == "removed")
    assert removed.reason == REASON_NO_LEXICON_TONE


def test_P4_084_AC2_derived_tone_claim_routes_high_risk() -> None:
    target = TonalTarget(
        "game_content#words[1]",
        "yoruba",
        "yo",
        "Ẹ kú àárọ̀",
        {"tonal_note": _LEGACY_NOTE},
        "tonal_note",
    )
    change = plan_tone_claim_change(target, _lookup)
    assert change is not None
    record = build_review_record(change)
    assert HIGH_RISK_TAG_TONE in record["high_risk_tags"]
    assert record["queue"] == "high_risk"
    assert record["route"] == "human"
    assert record["ai_only"] is False


def test_P4_084_integration_idempotent(tmp_path: Path) -> None:
    path = _write_game(
        tmp_path,
        _mini_game(
            [
                {
                    "id": 1,
                    "language": "yoruba",
                    "word": "Ẹ kú àárọ̀",
                    "tonal_note": _LEGACY_NOTE,
                }
            ]
        ),
    )
    first = run_tone_claims(
        tmp_path,
        dry_run=False,
        lexicon_lookup=_lookup,
        game_path=path,
    )
    second = run_tone_claims(
        tmp_path,
        dry_run=False,
        lexicon_lookup=_lookup,
        game_path=path,
    )
    assert first.stats.derived == 1
    assert second.stats.derived == 0
    assert second.stats.removed == 0
    assert not second.changed
