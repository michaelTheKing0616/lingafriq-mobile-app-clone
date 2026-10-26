"""Pipeline stage tests for deterministic linter execution (P4-060)."""

from __future__ import annotations

import copy
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.stage_lint import (  # noqa: E402
    StageLintError,
    planned_linter_ids,
    run_lint_stage,
)
from tools.content_engine.tests.test_placeholders import _VALID_ITEM  # noqa: E402

_LATIN = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
_UNICODE_KIT: dict[str, object] = {"character_set": [_LATIN, "\u00e9", "\u025b"]}

_SW_CONCORD_KIT: dict[str, object] = {
    "concord_table": {
        "m/wa": {
            "subject": ["m", "wa"],
            "object": ["m", "wa"],
            "adjective": ["m", "wa"],
        },
        "ki/vi": {
            "subject": ["ki", "vi"],
            "object": ["ki", "vi"],
            "adjective": ["ki", "vi"],
        },
    }
}

_ZUX_KIT: dict[str, object] = {
    "concord_table": {
        n: {
            "subject": [str(n)],
            "object": [str(n)],
            "adjective": [str(n)],
        }
        for n in range(1, 16)
    }
}


def _sw_kit() -> dict[str, object]:
    kit: dict[str, object] = {}
    kit.update(_UNICODE_KIT)
    kit.update(_SW_CONCORD_KIT)
    return kit


def _zu_kit() -> dict[str, object]:
    kit: dict[str, object] = {}
    kit.update(_UNICODE_KIT)
    kit.update(_ZUX_KIT)
    return kit


def _placeholder_item(item_id: str) -> dict[str, Any]:
    item = copy.deepcopy(_VALID_ITEM)
    item["id"] = item_id
    return item


_ITEM_ID = "yo.lex.0123456789ab"


def _sw_stage(item_id: str = _ITEM_ID) -> dict[str, object]:
    return {
        "id": item_id,
        "language": "sw",
        "lint_payloads": {
            "unicode": {"id": item_id, "text": "habari"},
            "claims": {
                "id": item_id,
                "section": "lesson",
                "text": "Market day is on Tuesday.",
            },
            "placeholders": _placeholder_item(item_id),
            "concord_sw": {
                "id": item_id,
                "noun": {"in_lexicon": True, "class_pair": "m/wa"},
                "subject": "wa",
                "object": "m",
                "adjective": "m",
            },
        },
    }


def test_P4_060_AC1_sw_runs_common_and_concord_linters() -> None:
    planned = planned_linter_ids("sw")
    assert "concord_sw" in planned
    assert "zulmorph" not in planned
    stage = run_lint_stage(_sw_stage(), _sw_kit())
    assert stage["executed_linters"] == list(planned)
    assert len(stage["linter_results"]) == len(planned)
    assert stage["route"] is None
    assert stage["can_publish"] is True
    assert stage["features"]["linter_results"] == 1.0


def test_P4_060_AC1_zu_runs_zulmorph_and_concord_zux() -> None:
    item_id = _ITEM_ID
    stage_input = {
        "id": item_id,
        "language": "zu",
        "lint_payloads": {
            "unicode": {"id": item_id, "text": "hamba"},
            "claims": {"id": item_id, "section": "lesson", "text": "Lesson note."},
            "placeholders": _placeholder_item(item_id),
            "concord_zux": {
                "id": item_id,
                "language": "zu",
                "noun_class": 1,
                "subject": "1",
                "object": "1",
                "adjective": "1",
                "has_prefixes": False,
                "surface": "ab",
            },
            "zulmorph": {"id": item_id, "language": "zu", "form": "hamba"},
        },
    }
    kit = _zu_kit()
    kit["external_zulmorph_fixture"] = lambda _form: True
    stage = run_lint_stage(stage_input, kit)
    assert stage["executed_linters"] == list(planned_linter_ids("zu"))
    assert "zulmorph" in stage["executed_linters"]
    assert stage["can_publish"] is True


def test_P4_060_AC2_hard_failure_routes_reject() -> None:
    broken = _sw_stage()
    payloads = broken["lint_payloads"]
    assert isinstance(payloads, dict)
    payloads["unicode"] = {"id": _ITEM_ID, "text": "e\u0301"}
    stage = run_lint_stage(broken, _sw_kit())
    assert stage["status"] == "fail"
    assert stage["route"] == "Reject"
    assert stage["can_publish"] is False
    assert stage["features"]["linter_results"] == 0.0


def test_stage_contract_happy_path() -> None:
    stage = run_lint_stage(_sw_stage(), _sw_kit())
    assert stage["card_id"] == "P4-060"
    assert stage["status"] == "ok"
    assert stage["route"] is None
    assert stage["linter_results"]


def test_missing_payload_is_typed_error() -> None:
    stage = _sw_stage()
    payloads = stage["lint_payloads"]
    assert isinstance(payloads, dict)
    del payloads["concord_sw"]
    with pytest.raises(StageLintError, match="missing lint payload") as exc:
        run_lint_stage(stage, _sw_kit())
    assert exc.value.code == "LINT_PAYLOAD_MISSING"


def test_planned_linter_ids_rejects_unknown_language() -> None:
    with pytest.raises(StageLintError, match="unsupported language"):
        planned_linter_ids("xx")
