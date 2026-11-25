"""P4-121 AI bootstrap stage."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.ai_bootstrap import (  # noqa: E402
    BootstrapError,
    CARD_ID,
    build_bootstrap_request,
    resolve_vendor_matrix,
    run_ai_bootstrap,
    validate_cultural_note_draft,
    wrap_bootstrap_asset,
)
from tools.content_pipeline.language_kit import (  # noqa: E402
    LanguageKitError,
    create_kit_for_language,
    import_seed_lexicon_entry,
    try_mark_complete,
    with_updated_section,
)
from tools.content_pipeline.tone_suggest import (  # noqa: E402
    finalize_tone_suggestion,
    suggest_yoruba_via_spitch,
    tone_suggester_for_language,
)

_REGISTER_FIXTURE: list[dict[str, str]] = [
    {
        "source_id": "test-ship-lex",
        "url": "https://example.test/lex",
        "licence": "CC0",
        "version_or_date": "2026-01-01",
        "display": "true",
        "evidence": "false",
        "training": "false",
        "attribution_text": "Test corpus",
        "owner_signoff": "counsel-ok",
        "counsel_status": "confirmed",
    },
]

_FIXTURE_MODEL = "gemini-3.1-pro-fixture"
_FIXTURE_SPITCH = "spitch-diacritics-fixture"


def _panel() -> list[dict]:
    return [
        {
            "reviewer_id": f"rev-{i}",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
        }
        for i in range(3)
    ]


def _ready_yo_kit() -> dict:
    from tools.content_pipeline.language_registry import load_language_registry

    yo = next(e for e in load_language_registry()["entries"] if e["entry_id"] == "yo")
    from tools.content_pipeline.language_kit import create_kit

    kit = create_kit(yo, started_at="2026-10-01")
    kit = with_updated_section(
        kit,
        "orthography",
        {
            "unicode_normalization": "NFC",
            "script": "Latn",
            "diacritics_policy": "full",
            "keyboard_layout": "yo-standard",
        },
    )
    kit = with_updated_section(kit, "dialect_standard", "Standard Yoruba")
    kit = with_updated_section(kit, "phone_inventory", ["a"])
    kit = with_updated_section(
        kit,
        "tone_system",
        {"register_levels": 3, "marking_convention_ref": "CURRICULUM.md#tone-yo"},
    )
    kit = with_updated_section(kit, "phoneme_viseme_table", [{"phoneme": "a", "viseme": "aa"}])
    kit = with_updated_section(kit, "reviewer_panel", _panel())
    import_seed_lexicon_entry(
        kit,
        {
            "lemma": "ọkọ̀",
            "provenance": {
                "author": "kit-import",
                "created_at": "2026-10-01",
                "sources": [
                    {
                        "source_id": "test-ship-lex",
                        "name": "Test",
                        "licence": "CC0",
                        "uri_or_citation": "https://example.test/lex",
                        "retrieved_at": "2026-10-01",
                    }
                ],
            },
        },
        register_rows=_REGISTER_FIXTURE,
    )
    try_mark_complete(kit)
    return kit


class _SpitchStub:
    def restore(self, language: str, text: str) -> str:
        assert language == "yo"
        if text == "oko":
            return "ọkọ̀"
        return text


@pytest.fixture(autouse=True)
def _env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_GENERATION_MODEL", _FIXTURE_MODEL)
    monkeypatch.setenv("CONTENT_ENGINE_SPITCH_DIACRITICS_MODEL", _FIXTURE_SPITCH)


def test_vendor_matrix_from_stack_doc() -> None:
    info = resolve_vendor_matrix()
    assert info["source"] == "stack_doc"
    assert info["draft_model"] == _FIXTURE_MODEL
    assert info["warnings"] == []


def test_vendor_matrix_fallback_reports_ext01(tmp_path: Path) -> None:
    missing = tmp_path / "no-stack.md"
    cov = tmp_path / "coverage.json"
    cov.write_text(
        json.dumps(
            {
                "charter": "v2",
                "card_id": "P4-113",
                "sources": ["docs/plan/LINGAFRIQ_AI_MODEL_STACK.md"],
                "level_targets": {
                    "program_start": "2026-01-01",
                    "l1_due_quarters": 1,
                    "l2_due_quarters": 2,
                },
                "languages": [
                    {
                        "language_id": "yo",
                        "asr": {"vendor": "intron", "code_switching": True},
                        "dynamic_tts": {"vendor": "intron", "enabled": True},
                        "realtime_voice": {"mode": "gemini_live"},
                        "tone_scoring": {"vendor": "inhouse"},
                        "stage_evals": {"realtime_voice": "not_run", "persona": "not_run"},
                    }
                ]
                * 7,
            }
        ),
        encoding="utf-8",
    )
    info = resolve_vendor_matrix(stack_path=missing, coverage_path=cov)
    assert info["source"] == "stage1_coverage"
    assert info["warnings"][0]["code"] == "EXT-01"
    assert "matrix" in info


def test_cultural_note_requires_citation() -> None:
    with pytest.raises(BootstrapError) as exc:
        validate_cultural_note_draft({"text": "note without source"})
    assert exc.value.code == "CITATION_MISSING"


def test_tone_yoruba_spitch_and_unanchored_flag() -> None:
    assert tone_suggester_for_language("yo") == "spitch"
    suggestion = suggest_yoruba_via_spitch("oko", _SpitchStub())
    anchored = finalize_tone_suggestion(suggestion, frozenset({"ọkọ̀"}))
    assert anchored["acceptance"] == "draft"
    assert anchored["lexicon_anchored"] is True
    unanchored = finalize_tone_suggestion(suggestion, frozenset())
    assert unanchored["acceptance"] == "linguist_review"
    assert unanchored.get("auto_accepted") is False


def test_run_ai_bootstrap_envelope_and_outputs() -> None:
    kit = _ready_yo_kit()
    draft = {
        "assets": [
            {"kind": "gloss", "lemma": "ọkọ̀", "text": "spouse"},
            {
                "kind": "cultural_note",
                "text": "Context from source.",
                "citation": {"source_id": "test-ship-lex", "locator": "p.1"},
            },
            {"kind": "dialogue_line", "text": "ọkọ̀"},
        ],
        "tone_plain": ["oko"],
    }
    result = run_ai_bootstrap(kit, draft, spitch=_SpitchStub())
    assert result["card_id"] == CARD_ID
    for row in result["outputs"]:
        assert row["label"] == "beta"
        assert row["provenance"]["ai_assisted"] is True
    kinds = {row["asset_kind"] for row in result["outputs"]}
    assert "cultural_note" in kinds
    assert "tone_suggestion" in kinds
    tone = next(r for r in result["outputs"] if r["asset_kind"] == "tone_suggestion")
    assert tone["body"]["acceptance"] == "draft"


def test_wrap_bootstrap_asset() -> None:
    row = wrap_bootstrap_asset({"x": 1}, model_id=_FIXTURE_MODEL, asset_kind="eval_item")
    assert row["provenance"]["model_id"] == _FIXTURE_MODEL
    assert row["provenance"]["prompt_id"]


def test_build_bootstrap_request_sw() -> None:
    kit = create_kit_for_language("sw", started_at="2026-10-01")
    with pytest.raises(LanguageKitError) as exc:
        build_bootstrap_request(kit)
    assert exc.value.code == "KIT_INCOMPLETE"
