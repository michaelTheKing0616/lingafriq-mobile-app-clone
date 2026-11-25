"""Shared provenance, label, and audio-kind envelope (P4-100)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.schema_loader import (  # noqa: E402
    SYNTHETIC_VOICE_TAG,
    CommonSchemaError,
    common_validator,
    load_common_schema,
    validate_content_envelope,
)


def _envelope(**overrides: Any) -> dict[str, Any]:
    base: dict[str, Any] = {
        "id": "yo.item.envelope.1",
        "label": "beta",
        "provenance": {
            "author": "content-engine",
            "created_at": "2026-10-21T00:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "licence-register",
                    "licence": "CC BY 4.0",
                    "uri_or_citation": "tools/content_engine/licences/register.csv",
                    "retrieved_at": "2026-10-21T00:00:00Z",
                }
            ],
        },
        "claims": [{"kind": "factual", "source_ref": "register:asp"}],
        "confidence": 0.85,
        "risk_tags": [],
        "audio": [],
    }
    base.update(overrides)
    return base


def test_schema_document_is_valid() -> None:
    from jsonschema import Draft202012Validator

    Draft202012Validator.check_schema(load_common_schema())


def test_valid_envelope_passes() -> None:
    validate_content_envelope(_envelope())


def test_provenance_missing_sources() -> None:
    body = _envelope()
    body["provenance"]["sources"] = []
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "PROVENANCE_MISSING"


def test_claim_invalid_kind() -> None:
    body = _envelope()
    body["claims"] = [{"kind": "myth", "source_ref": "x"}]
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "CLAIM_INVALID"


def test_label_missing_no_default() -> None:
    body = _envelope()
    del body["label"]
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body, validator=common_validator())
    assert exc.value.code == "LABEL_MISSING"


def test_label_invalid_value() -> None:
    body = _envelope(label="Beta")
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "LABEL_MISSING"


def test_tts_requires_synthetic_voice_tag() -> None:
    body = _envelope(
        audio=[{"kind": "tts_synthetic", "uri": "audio/synth.ogg"}],
    )
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "AUDIO_KIND_INVALID"


def test_tts_with_synthetic_voice_tag_passes() -> None:
    validate_content_envelope(
        _envelope(
            audio=[
                {
                    "kind": "tts_synthetic",
                    "uri": "audio/synth.ogg",
                    "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
                }
            ],
        )
    )


def test_ai_assisted_requires_model_and_prompt() -> None:
    body = _envelope()
    body["provenance"]["ai_assisted"] = True
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "AI_FLAG_MISSING"


def test_ai_assisted_with_ids_passes() -> None:
    body = _envelope()
    body["provenance"]["ai_assisted"] = True
    body["provenance"]["model_id"] = "gemini-2.0-flash"
    body["provenance"]["prompt_id"] = "content-engine/generate/v1"
    validate_content_envelope(body)


def test_missing_ai_assisted_flag() -> None:
    body = _envelope()
    del body["provenance"]["ai_assisted"]
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "AI_FLAG_MISSING"


def test_native_verified_requires_two_natives_and_linguist() -> None:
    body = _envelope(label="native_verified", review={"reviewers": []})
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "NATIVE_VERIFIED_REQUIRES_TWO_NATIVES"


def test_native_verified_with_reviewers_passes() -> None:
    validate_content_envelope(
        _envelope(
            label="native_verified",
            review={
                "reviewers": [
                    {"role": "native", "reviewer_id": "n1", "approved": True},
                    {"role": "native", "reviewer_id": "n2", "approved": True},
                    {"role": "linguist", "reviewer_id": "l1", "approved": True},
                ]
            },
        )
    )


def test_risk_tag_allowlist() -> None:
    body = _envelope(risk_tags=["not_a_real_tag"])
    with pytest.raises(CommonSchemaError) as exc:
        validate_content_envelope(body)
    assert exc.value.code == "CLAIM_INVALID"
