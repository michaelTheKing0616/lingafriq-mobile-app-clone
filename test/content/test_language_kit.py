"""P4-120 language kit generator (week 0–1)."""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.language_kit import (  # noqa: E402
    CARD_ID,
    LanguageKitError,
    WEEK_TARGET_DAYS,
    apply_timeline_fields,
    assert_ai_bootstrap_allowed,
    assert_source_licensed_for_seed,
    compute_open_tasks,
    create_kit,
    create_kit_for_language,
    enrich_provenance_from_register,
    evaluate_week_timeline,
    import_seed_lexicon_entry,
    panel_meets_requirements,
    try_mark_complete,
    validate_language_kit,
    with_updated_section,
)
from tools.content_pipeline.language_registry import (  # noqa: E402
    LanguageRegistryError,
    load_language_registry,
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
    {
        "source_id": "test-evidence-only",
        "url": "https://example.test/ev",
        "licence": "public-domain",
        "version_or_date": "2026-01-01",
        "display": "false",
        "evidence": "true",
        "training": "false",
        "attribution_text": "PD evidence",
        "owner_signoff": "",
    },
    {
        "source_id": "test-blocked",
        "url": "https://example.test/blocked",
        "licence": "CC BY-NC 4.0",
        "version_or_date": "2026-01-01",
        "display": "false",
        "evidence": "false",
        "training": "false",
        "attribution_text": "NC",
        "owner_signoff": "",
    },
]


def _yo_entry() -> dict:
    data = load_language_registry()
    return next(e for e in data["entries"] if e["entry_id"] == "yo")


def _minimal_kit() -> dict:
    return create_kit(_yo_entry(), started_at="2026-10-01")


def _qualified_panel() -> list[dict]:
    return [
        {
            "reviewer_id": f"rev-{i}",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
        }
        for i in range(3)
    ]


def _fill_kit_sections(kit: dict) -> dict:
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
    kit = with_updated_section(kit, "phone_inventory", ["a", "e", "o"])
    kit = with_updated_section(
        kit,
        "tone_system",
        {"register_levels": 3, "marking_convention_ref": "CURRICULUM.md#tone-yo"},
    )
    kit = with_updated_section(
        kit,
        "phoneme_viseme_table",
        [{"phoneme": "a", "viseme": "aa"}],
    )
    kit = with_updated_section(kit, "reviewer_panel", _qualified_panel())
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


def test_schema_and_skeleton_open_tasks() -> None:
    schema = json.loads(
        (_REPO_ROOT / "schemas/v2/language_kit.schema.json").read_text(encoding="utf-8")
    )
    Draft202012Validator.check_schema(schema)
    kit = _minimal_kit()
    assert kit["card_id"] == CARD_ID
    assert kit["week_target_days"] == WEEK_TARGET_DAYS
    assert "orthography" in kit["open_tasks"]
    assert "tone_system" in kit["open_tasks"]
    validate_language_kit(kit)
    Draft202012Validator(schema).validate(kit)


def test_create_kit_for_language_yoruba() -> None:
    kit = create_kit_for_language("yo", started_at="2026-10-05")
    assert kit["language_id"] == "yo"
    assert kit["is_tonal"] is True


def test_consent_gate_from_registry() -> None:
    data = load_language_registry()
    ngh = next(e for e in data["entries"] if e["language_id"] == "ngh")
    with pytest.raises(LanguageRegistryError):
        create_kit(ngh, started_at="2026-10-01", consent_recorded=False)


def test_seed_lexicon_licence_enrichment_and_rejection() -> None:
    kit = _minimal_kit()
    import_seed_lexicon_entry(
        kit,
        {
            "lemma": "word",
            "provenance": {
                "author": "a",
                "created_at": "2026-10-01",
                "sources": [
                    {
                        "source_id": "test-evidence-only",
                        "name": "PD",
                        "licence": "public-domain",
                        "uri_or_citation": "cite",
                        "retrieved_at": "2026-10-01",
                    }
                ],
            },
        },
        register_rows=_REGISTER_FIXTURE,
    )
    assert kit["seed_lexicon"][0]["provenance"]["sources"][0]["licence"] == "public-domain"

    with pytest.raises(LanguageKitError) as exc:
        assert_source_licensed_for_seed("test-blocked", _REGISTER_FIXTURE)
    assert exc.value.code == "SOURCE_UNLICENSED"

    with pytest.raises(LanguageKitError) as exc2:
        enrich_provenance_from_register(
            {
                "author": "a",
                "created_at": "2026-10-01",
                "sources": [
                    {
                        "source_id": "test-blocked",
                        "name": "x",
                        "licence": "CC BY-NC 4.0",
                        "uri_or_citation": "c",
                        "retrieved_at": "2026-10-01",
                    }
                ],
            },
            _REGISTER_FIXTURE,
        )
    assert exc2.value.code == "SOURCE_UNLICENSED"


def test_reviewer_panel_and_complete_status() -> None:
    kit = _fill_kit_sections(_minimal_kit())
    assert panel_meets_requirements(kit["reviewer_panel"])
    assert kit["status"] == "complete"
    assert compute_open_tasks(kit) == []
    validate_language_kit(kit)

    partial = with_updated_section(_minimal_kit(), "reviewer_panel", _qualified_panel()[:2])
    try_mark_complete(partial)
    assert partial["status"] == "open"


def test_week_timeline_overdue() -> None:
    kit = _minimal_kit()
    fields = evaluate_week_timeline(kit, as_of="2026-10-20")
    assert fields["days_elapsed"] == 19
    assert fields["overdue"] is True
    apply_timeline_fields(kit, as_of="2026-10-20")
    assert kit["overdue"] is True

    complete = _fill_kit_sections(_minimal_kit())
    fields_done = evaluate_week_timeline(complete, as_of="2026-11-15")
    assert fields_done["overdue"] is False


def test_ai_bootstrap_blocked_without_tone_system() -> None:
    kit = _minimal_kit()
    with pytest.raises(LanguageKitError) as exc:
        assert_ai_bootstrap_allowed(kit)
    assert exc.value.code == "TONE_SYSTEM_MISSING"

    sw_entry = next(e for e in load_language_registry()["entries"] if e["entry_id"] == "sw")
    sw_kit = create_kit(sw_entry, started_at=str(date.today()))
    assert sw_kit["is_tonal"] is False
    with pytest.raises(LanguageKitError) as exc2:
        assert_ai_bootstrap_allowed(sw_kit)
    assert exc2.value.code == "KIT_INCOMPLETE"

    ready = _fill_kit_sections(_minimal_kit())
    assert_ai_bootstrap_allowed(ready)
