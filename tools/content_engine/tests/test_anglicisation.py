"""Spec tests for Pidgin anglicisation linter (P4-048). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.anglicisation import (  # noqa: E402
    AnglicisationError,
    EXT01_CITATION,
    lint_anglicisation,
    list_learner_flags,
    merge_verification_report,
    make_fixture_client,
    read_anglicisation_routing,
    record_learner_flag,
    reset_learner_flag_store,
    routing_from_rating,
    run_anglicisation_rating,
)
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402

_FIXTURE_MODEL = "fixture-gpt-5-mini"
_PCM_TEXT = "How you dey?"


def _item(
    item_id: str,
    text: str = _PCM_TEXT,
    *,
    verification: dict[str, Any] | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "id": item_id,
        "language": "pcm",
        "text": text,
    }
    if verification is not None:
        payload["verification"] = verification
    return payload


def _rating(naturalness: int, anglicised: bool) -> dict[str, Any]:
    return {"naturalness": naturalness, "anglicised": anglicised}


@pytest.fixture
def anglicisation_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_CROSSCHECK_MODEL", _FIXTURE_MODEL)


@pytest.fixture(autouse=True)
def _clear_flags() -> None:
    reset_learner_flag_store()


def test_read_routing_cites_ext01(anglicisation_env: None) -> None:
    routing = read_anglicisation_routing()
    assert routing["rating_model"] == _FIXTURE_MODEL
    assert routing["ext01_citation"] == EXT01_CITATION


def test_P4_048_AC1_rating_stored_on_verification_report(
    anglicisation_env: None,
) -> None:
    client = make_fixture_client({_FIXTURE_MODEL: _rating(4, False)})
    result = run_anglicisation_rating(_item("item-ac1"), client)
    report = merge_verification_report({"item_id": "item-ac1"}, result)
    assert report["anglicisation"]["naturalness"] == 4
    assert report["anglicisation"]["anglicised_flag"] is False
    assert report["features"]["cross_model_naturalness"] == 0.75


def test_P4_048_AC2_low_naturalness_routes_review_never_auto_publish(
    anglicisation_env: None,
) -> None:
    route = routing_from_rating(2, False)
    assert route["route"] == "review"
    assert route["can_auto_publish"] is False
    assert route["high_risk_tag"] == "anglicised_pidgin"

    rated = run_anglicisation_rating(
        _item("item-low"),
        make_fixture_client({_FIXTURE_MODEL: _rating(2, False)}),
    )
    assert rated["can_auto_publish"] is False
    assert rated["route"] == "review"


def test_P4_048_AC2_anglicised_flag_routes_review(
    anglicisation_env: None,
) -> None:
    rated = run_anglicisation_rating(
        _item("item-ang"),
        make_fixture_client({_FIXTURE_MODEL: _rating(5, True)}),
    )
    assert rated["can_auto_publish"] is False
    assert rated["route"] == "review"


def test_P4_048_AC3_learner_flag_stored_for_validators() -> None:
    record_learner_flag(
        "published-item",
        learner_id="learner-1",
        note="Sounds like English",
        published=True,
    )
    flags = list_learner_flags("published-item")
    assert len(flags) == 1
    assert flags[0]["queue"] == "native_validators"
    assert flags[0]["published"] is True


def test_lint_pass_with_good_rating() -> None:
    item = _item(
        "item-pass",
        verification={"anglicisation": _rating(4, False)},
    )
    result = lint_anglicisation(item, {})
    assert result.status == "pass"
    assert result.naturalness == 4


def test_lint_fail_low_naturalness() -> None:
    item = _item(
        "item-fail",
        verification={"anglicisation": _rating(2, False)},
    )
    result = lint_anglicisation(item, {})
    assert result.status == "fail"
    assert result.rule_id == "PCM_ANGLICISED"


def test_lint_missing_verification_fails() -> None:
    result = lint_anglicisation(_item("item-miss"), {})
    assert result.status == "fail"
    assert result.rule_id == "PCM_ANGLICISATION_MISSING"


def test_lint_non_pcm_skips() -> None:
    item = {"id": "yo-1", "language": "yo", "text": "Báwo ni"}
    result = lint_anglicisation(item, {})
    assert result.status == "pass"


def test_ci_exit_code_blocks_anglicised() -> None:
    fail_item = _item(
        "ci-fail",
        verification={"anglicisation": _rating(1, True)},
    )
    assert exit_code(run_linters(fail_item, {}, [lint_anglicisation])) == 1
    pass_item = _item(
        "ci-pass",
        verification={"anglicisation": _rating(5, False)},
    )
    assert exit_code(run_linters(pass_item, {}, [lint_anglicisation])) == 0


def test_model_not_configured_raises(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("CONTENT_ENGINE_CROSSCHECK_MODEL", raising=False)
    with pytest.raises(AnglicisationError) as exc_info:
        read_anglicisation_routing()
    assert exc_info.value.code == "MODEL_NOT_CONFIGURED"
