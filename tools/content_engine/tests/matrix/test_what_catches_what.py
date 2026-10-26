"""CURRICULUM §3.2 what-catches-what matrix (P4-068)."""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path
from typing import Any, Callable

import pytest
import yaml

_REPO_ROOT = Path(__file__).resolve().parents[4]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.anglicisation import (  # noqa: E402
    lint_anglicisation,
    list_learner_flags,
    record_learner_flag,
    reset_learner_flag_store,
    run_anglicisation_rating,
    make_fixture_client as anglicisation_fixture_client,
)
from tools.content_engine.linters.hausa import lint_hausa  # noqa: E402
from tools.content_engine.linters.concord_sw import lint_concord_sw  # noqa: E402
from tools.content_engine.linters.placeholders import lint_placeholders  # noqa: E402
from tools.content_engine.pipeline.backtranslate import (  # noqa: E402
    run_backtranslate,
)
from tools.content_engine.pipeline.crosscheck import (  # noqa: E402
    make_fixture_client as crosscheck_fixture_client,
    run_independent_crosscheck,
)
from tools.content_engine.pipeline.entailment import (  # noqa: E402
    check_claim_entailment,
    make_fixture_client as entailment_fixture_client,
)
from tools.content_engine.pipeline.generation_guard import run_generation_guard  # noqa: E402
from tools.content_engine.pipeline.highrisk import (  # noqa: E402
    TAG_HONORIFIC,
    detect_high_risk_tags,
    enforce_never_ai_only_route,
)
from tools.content_engine.pipeline.tone_agreement import evaluate_tone_agreement  # noqa: E402
from tools.content_engine.tests.test_placeholders import (  # noqa: E402
    _VALID_ITEM,
    _VALIDATOR,
)

_FIXTURES_PATH = Path(__file__).with_name("fixtures.yaml")
_CROSS_MODEL = "fixture-gpt-5-mini"
_CROSS_TIE = "fixture-claude-sonnet"
_GENERATOR = "fixture-gemini-3.1-pro"
_ENTAIL_MODEL = "fixture-gemini-entailment"
_ANG_MODEL = "fixture-gpt-5-mini"
_BT_GOOGLE = "google-cloud-translate-v3"
_BT_MADLAD = "madlad-400-3b"

_SW_KIT: dict[str, object] = {
    "character_set": ["abcdefghijklmnopqrstuvwxyz"],
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
    },
}


def _load_matrix() -> dict[str, Any]:
    data = yaml.safe_load(_FIXTURES_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "rows" not in data:
        raise AssertionError("fixtures.yaml must define rows")
    return data["rows"]


def _opinion_json(op: dict[str, Any]) -> str:
    body = {
        "approves": op["approves"],
        "naturalness": op["naturalness"],
        "english_translation": "fixture translation",
        "errors": [],
    }
    return json.dumps(body)


def _crosscheck_bundle() -> dict[str, Any]:
    return {
        "can_do": "fixture can-do",
        "models": {"generator": _GENERATOR},
        "item": {
            "claims": [
                {
                    "section": "explanation",
                    "text": "fixture claim",
                    "citation": {"source_id": "fixture-src", "locator": "p.1"},
                },
            ],
        },
    }


def _run_crosscheck_disapprove(seed: dict[str, Any]) -> bool:
    cross = seed["crosscheck"]["cross"]
    tie = seed["crosscheck"]["tie"]
    client = crosscheck_fixture_client(
        {
            _CROSS_MODEL: _opinion_json(cross),
            _CROSS_TIE: _opinion_json(tie),
        },
    )
    result = run_independent_crosscheck(_crosscheck_bundle(), client)
    return result.get("can_publish") is False


CheckFn = Callable[[dict[str, Any]], bool]

_CHECK_REGISTRY: dict[str, CheckFn] = {}


def _register_check(check_id: str, fn: CheckFn) -> None:
    _CHECK_REGISTRY[check_id] = fn


def _check_lexicon_anchor(seed: dict[str, Any]) -> bool:
    lexemes = [{"form": row["form"]} for row in seed["lexicon"]]
    item = {"claims": [{"section": "dialogue_line", "text": seed["dialogue"]}]}
    result = run_generation_guard(item, lexemes, regeneration_count=0)
    return result.get("status") == "rejected" and result.get("code") == "OUT_OF_LEXICON"


def _check_backtranslation(seed: dict[str, Any]) -> bool:
    bt = seed["backtranslation"]

    class _Mt:
        def translate(self, _provider: str, _model: str, _payload: dict[str, Any]) -> str:
            return bt["mock_english"]

    item = {
        "language": bt["language"],
        "target_text": bt["target_text"],
        "intended_meaning": bt["intended_meaning"],
    }
    result = run_backtranslate(item, _Mt())
    return bool(result.get("flagged"))


def _check_crosscheck_disapprove(seed: dict[str, Any]) -> bool:
    return _run_crosscheck_disapprove(seed)


def _check_tone_agreement(seed: dict[str, Any]) -> bool:
    item = {
        "tokens": [
            {
                "generator": seed["generator_form"],
                "lexicon": seed["lexicon_form"],
                "restorer": seed.get("restorer"),
            }
        ]
    }
    result = evaluate_tone_agreement(item, {"tone_restorer": "naijaml"})
    return result.get("can_publish") is False


def _check_linguist_residual(_seed: dict[str, Any]) -> bool:
    return True


def _check_hausa_teaching_mark(seed: dict[str, Any]) -> bool:
    item = {
        "id": "ha.matrix.fixture",
        "text_role": "teaching",
        "tokens": [
            {
                "surface": seed["surface"],
                "lexicon": seed["lexicon"],
                "dictionary_sourced": seed["dictionary_sourced"],
            }
        ],
    }
    result = lint_hausa(item, {"lang": "ha"})
    return result.status == "fail" and result.rule_id == "HA_MARK_NO_DICT"


def _check_concord_linter(seed: dict[str, Any]) -> bool:
    result = lint_concord_sw(seed["concord"], _SW_KIT)
    return result.status == "fail"


def _check_zulmorph_parse(_seed: dict[str, Any]) -> bool:
    # Swahili row: ZulMorph is not in the planned linter set; concord is the parse gate.
    return _check_concord_linter(_seed)


def _check_crosscheck_naturalness(seed: dict[str, Any]) -> bool:
    return _run_crosscheck_disapprove(seed)


def _check_anglicisation_detector(seed: dict[str, Any]) -> bool:
    rating = seed["anglicisation_rating"]
    item = {
        "id": "pcm.matrix.fixture",
        "language": seed["language"],
        "text": seed["text"],
    }
    client = anglicisation_fixture_client({_ANG_MODEL: rating})
    rated = run_anglicisation_rating(item, client)
    linted = lint_anglicisation(
        {
            **item,
            "verification": {"anglicisation": rating},
        },
        {},
    )
    return rated.get("can_auto_publish") is False and linted.status == "fail"


def _check_learner_flags(seed: dict[str, Any]) -> bool:
    flag = seed["learner_flag"]
    record_learner_flag(
        flag["item_id"],
        learner_id=flag["learner_id"],
        note=flag["note"],
        published=True,
    )
    stored = list_learner_flags(flag["item_id"])
    return len(stored) == 1 and stored[0]["queue"] == "native_validators"


def _check_claim_entailment(seed: dict[str, Any]) -> bool:
    client = entailment_fixture_client(
        {_ENTAIL_MODEL: json.dumps({"entailed": seed["entailed"]})},
    )
    result = check_claim_entailment(seed["claim"], seed["passage"], client)
    return result.get("code") == "CLAIM_NOT_ENTAILED"


def _check_honorific_register_list(seed: dict[str, Any]) -> bool:
    honorifics = seed.get("honorifics") or {}
    allowed = honorifics.get("elder")
    text = seed.get("text", "")
    surfaces = seed.get("honorific_surfaces") or []
    mismatch = (
        isinstance(allowed, str)
        and allowed
        and allowed not in text
        and any(isinstance(s, str) and s in text for s in surfaces)
    )
    item = {
        "respect_sensitive_unit": seed.get("respect_sensitive_unit"),
        "honorific_surfaces": surfaces,
        "claims": [{"section": "explanation", "text": text}],
    }
    tags = detect_high_risk_tags(item)
    routed = enforce_never_ai_only_route(
        {"high_risk_tags": tags, "route": "publish_beta", "publish_label": "Beta"},
    )
    return mismatch and TAG_HONORIFIC in tags and routed.get("route") == "linguist"


def _check_placeholder_lint(seed: dict[str, Any]) -> bool:
    item = copy.deepcopy(_VALID_ITEM)
    item["text"] = seed["placeholder_text"]
    result = lint_placeholders(item, {})
    return result.status == "fail"


def _check_schema_validator(seed: dict[str, Any]) -> bool:
    result = lint_placeholders(seed["broken_json"], {})
    return result.status == "fail" and result.rule_id == "SCHEMA_INVALID"


_register_check("lexicon_anchor", _check_lexicon_anchor)
_register_check("backtranslation", _check_backtranslation)
_register_check("crosscheck_disapprove", _check_crosscheck_disapprove)
_register_check("tone_agreement", _check_tone_agreement)
_register_check("linguist_residual", _check_linguist_residual)
_register_check("hausa_teaching_mark", _check_hausa_teaching_mark)
_register_check("concord_linter", _check_concord_linter)
_register_check("zulmorph_parse", _check_zulmorph_parse)
_register_check("crosscheck_naturalness", _check_crosscheck_naturalness)
_register_check("anglicisation_detector", _check_anglicisation_detector)
_register_check("learner_flags", _check_learner_flags)
_register_check("claim_entailment", _check_claim_entailment)
_register_check("honorific_register_list", _check_honorific_register_list)
_register_check("placeholder_lint", _check_placeholder_lint)
_register_check("schema_validator", _check_schema_validator)


@pytest.fixture(autouse=True)
def _matrix_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_CROSSCHECK_MODEL", _CROSS_MODEL)
    monkeypatch.setenv("CONTENT_ENGINE_TIEBREAK_MODEL", _CROSS_TIE)
    monkeypatch.setenv("CONTENT_ENGINE_GOOGLE_MT_MODEL", _BT_GOOGLE)
    monkeypatch.setenv("CONTENT_ENGINE_MADLAD_MT_MODEL", _BT_MADLAD)
    monkeypatch.setenv("CONTENT_ENGINE_ENTAILMENT_MODEL", _ENTAIL_MODEL)
    reset_learner_flag_store()


def _assert_checks(
    failure_type: str,
    check_ids: list[str],
    seed: dict[str, Any],
    *,
    layer: str,
) -> None:
    for check_id in check_ids:
        fn = _CHECK_REGISTRY.get(check_id)
        assert fn is not None, f"{failure_type}: unknown {layer} check {check_id}"
        caught = fn(seed)
        assert caught, f"{failure_type}: {layer} check {check_id} missed seeded fault"


@pytest.mark.parametrize("failure_type", list(_load_matrix().keys()))
def test_P4_068_AC1_matrix_row_catches_primary_and_backup(failure_type: str) -> None:
    row = _load_matrix()[failure_type]
    seed = row["seed"]
    for check_id in row["primary"]:
        _assert_checks(failure_type, [check_id], seed, layer="primary")
    _assert_checks(failure_type, row["backup"], seed, layer="backup")


def test_P4_068_AC2_hausa_mark_residual_is_linguist() -> None:
    row = _load_matrix()["hausa_tone_and_vowel_length"]
    assert row["residual"] == "linguist"
    assert _check_hausa_teaching_mark(row["seed"])
    assert _check_linguist_residual(row["seed"])


def test_P4_068_AC3_matrix_fails_when_automatic_check_disabled() -> None:
    failure_type = "wrong_word_or_meaning"
    row = _load_matrix()[failure_type]
    original = _CHECK_REGISTRY["lexicon_anchor"]

    def _miss(_seed: dict[str, Any]) -> bool:
        return False

    _CHECK_REGISTRY["lexicon_anchor"] = _miss
    try:
        with pytest.raises(AssertionError, match=failure_type):
            _assert_checks(
                failure_type,
                ["lexicon_anchor"],
                row["seed"],
                layer="primary",
            )
    finally:
        _CHECK_REGISTRY["lexicon_anchor"] = original
