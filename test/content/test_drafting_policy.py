"""P4-131 human drafting with grounded LLM variants only."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.drafting_policy import (  # noqa: E402
    CARD_ID,
    DraftingPolicyError,
    apply_ai_assisted_for_save,
    review_llm_draft_submission,
    save_drafted_string,
    validate_ai_assisted_immutable,
    validate_draft_source_policy,
)
from tools.content_pipeline.grounded_prompt import (  # noqa: E402
    build_grounded_prompt,
    flag_out_of_lexicon_tokens,
)

_LEXICON = [
    {"form": "ẹ kú àárọ̀", "gloss": "good morning"},
    {"form": "báwo", "gloss": "how"},
]


@pytest.fixture(autouse=True)
def generation_model_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_GENERATION_MODEL", "gemini-3.1-pro-preview")


def _record() -> dict:
    return {
        "label": "beta",
        "provenance": {
            "sources": [
                {
                    "name": "kit-seed",
                    "licence": "internal",
                    "uri_or_citation": "language-kit:yo",
                    "retrieved_at": "2026-10-26",
                }
            ],
            "author": "writer-yo-01",
            "created_at": "2026-10-26T12:00:00Z",
            "ai_assisted": False,
        },
        "claims": [],
        "confidence": 0.5,
        "risk_tags": [],
        "audio": [],
    }


def test_card_id() -> None:
    assert CARD_ID == "P4-131"


def test_llm_core_item_rejected() -> None:
    result = review_llm_draft_submission("llm", "core")
    assert result["status"] == "rejected"
    assert result["code"] == "DRAFT_SOURCE_FORBIDDEN"


def test_llm_variant_accepted() -> None:
    result = review_llm_draft_submission("llm", "variant")
    assert result["status"] == "accepted"


def test_human_core_allowed() -> None:
    validate_draft_source_policy("human", "core")


def test_grounded_prompt_lists_lexicon_and_flags() -> None:
    prompt = build_grounded_prompt(
        language_id="yo",
        draft_role="distractor",
        human_core_text="ẹ kú àárọ̀",
        approved_lexicon=_LEXICON,
    )
    assert prompt["prompt_id"] == "human-draft-llm-variant-v1"
    assert prompt["routing"]["model"] == os.environ["CONTENT_ENGINE_GENERATION_MODEL"]
    assert flag_out_of_lexicon_tokens("báwo", _LEXICON) == []
    assert flag_out_of_lexicon_tokens("hello báwo", _LEXICON) == ["hello"]


def test_save_llm_variant_sets_ai_assisted() -> None:
    out = save_drafted_string(
        _record(),
        draft_source="llm",
        draft_role="variant",
        text="báwo",
        approved_lexicon=_LEXICON,
        language_id="yo",
        human_core_text="ẹ kú àárọ̀",
    )
    assert out["status"] == "saved"
    assert out["ai_assisted"] is True
    assert out["record"]["provenance"]["ai_assisted"] is True


def test_save_rejects_out_of_lexicon_llm_text() -> None:
    with pytest.raises(DraftingPolicyError) as exc:
        save_drafted_string(
            _record(),
            draft_source="llm",
            draft_role="distractor",
            text="hello",
            approved_lexicon=_LEXICON,
            language_id="yo",
            human_core_text="ẹ kú àárọ̀",
        )
    assert exc.value.code == "OUT_OF_LEXICON"


def test_ai_assisted_strip_forbidden() -> None:
    record = _record()
    record["provenance"]["ai_assisted"] = True
    after = apply_ai_assisted_for_save(record, draft_source="llm")
    after["provenance"]["ai_assisted"] = False
    with pytest.raises(DraftingPolicyError) as exc:
        validate_ai_assisted_immutable(record, after, draft_source="llm")
    assert exc.value.code == "AI_FLAG_STRIP_FORBIDDEN"


def test_apply_ai_assisted_sets_true_from_false() -> None:
    record = _record()
    record["provenance"]["ai_assisted"] = False
    saved = apply_ai_assisted_for_save(record, draft_source="llm")
    assert saved["provenance"]["ai_assisted"] is True
