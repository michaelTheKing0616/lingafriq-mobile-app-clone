"""P4-113 Stage 1 vendor coverage and readiness target report."""

from __future__ import annotations

import json
import sys
from datetime import date, timedelta
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.coverage_check import (  # noqa: E402
    CARD_ID,
    CoverageError,
    level_due_date,
    list_l3_candidates,
    load_stage1_coverage,
    lookup_feature,
    overdue_readiness_gates,
    readiness_coverage_report,
    validate_stage1_coverage,
    with_stage_eval,
)
from tools.content_pipeline.language_registry import load_language_registry  # noqa: E402
from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS  # noqa: E402


def test_coverage_validates_and_matches_schema() -> None:
    data = load_stage1_coverage()
    validate_stage1_coverage(data)
    assert data["card_id"] == CARD_ID
    schema = json.loads(
        (_REPO_ROOT / "schemas/v2/vendor_coverage.schema.json").read_text(encoding="utf-8")
    )
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema).validate(data)
    assert {row["language_id"] for row in data["languages"]} == WAVE_1_LANGUAGE_IDS


def test_asr_tts_and_realtime_vendors() -> None:
    data = load_stage1_coverage()
    by_id = {row["language_id"]: row for row in data["languages"]}
    for lang in ("yo", "ig", "ha", "pcm", "sw"):
        assert by_id[lang]["asr"]["code_switching"] is True
        assert by_id[lang]["dynamic_tts"] == {"vendor": "intron", "enabled": True}
    assert by_id["xh"]["asr"]["code_switching"] is False
    assert by_id["zu"]["dynamic_tts"] == {"vendor": "azure", "enabled": True}
    assert by_id["yo"]["realtime_voice"]["mode"] == "gemini_live"
    assert by_id["ig"]["realtime_voice"]["mode"] == "cascade"
    assert all(row["tone_scoring"]["vendor"] == "inhouse" for row in data["languages"])


def test_xh_dynamic_tts_disabled_ext12() -> None:
    data = load_stage1_coverage()
    result = lookup_feature(data, "xh", "dynamic_tts")
    assert result["code"] == "FEATURE_DISABLED"
    assert result["available"] is False
    assert "EXT-12" in result["disabled_reason"]


def test_lookup_uncovered_language_and_feature() -> None:
    data = load_stage1_coverage()
    missing = lookup_feature(data, "ff", "asr")
    assert missing["code"] == "UNCOVERED"
    assert missing["available"] is False


def test_l3_candidates_require_both_eval_passes() -> None:
    data = load_stage1_coverage()
    assert list_l3_candidates(data) == []
    passed = with_stage_eval(data, "yo", realtime_voice="pass", persona="pass")
    assert list_l3_candidates(passed) == ["yo"]
    partial = with_stage_eval(data, "ha", realtime_voice="pass", persona="fail")
    assert list_l3_candidates(partial) == []


def test_overdue_gates_in_readiness_report() -> None:
    data = load_stage1_coverage()
    registry = load_language_registry()
    l1_due = level_due_date(data, "L1")
    report = readiness_coverage_report(
        data,
        registry["entries"],
        as_of=l1_due,
    )
    assert report["overdue_gates"] == []
    after = readiness_coverage_report(
        data,
        registry["entries"],
        as_of=l1_due + timedelta(days=1),
    )
    assert len(after["overdue_gates"]) == 7
    assert all(row["gate"] == "L1" for row in after["overdue_gates"])
    assert after["overdue_gates"][0]["code"] == "READINESS_GATE_OVERDUE"


def test_validate_rejects_wrong_card() -> None:
    data = load_stage1_coverage()
    data["card_id"] = "P4-000"
    with pytest.raises(CoverageError) as exc:
        validate_stage1_coverage(data)
    assert exc.value.code == "CARD_MISMATCH"
