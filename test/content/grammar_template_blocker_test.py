"""P5-003 grammar template blocker and typology."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.grammar_template_blocker import (  # noqa: E402
    CARD_ID,
    EXPECTED_LEGACY_LESSONS_WITH_GENERIC,
    PatternMissingError,
    RULE_GR001,
    assert_grammar_item_publishable,
    is_generic_grammar_template,
    language_typology,
    lint_grammar_string,
    load_typology,
    scan_legacy_bundles,
)

_GENERIC_A = "Pattern: subject → verb → object (default sentence order)."
_GENERIC_B = "Listen for the verb stem; affixes carry tense and person."
_REAL = "Yoruba uses preverbal particles for tense and aspect."


def test_card_id() -> None:
    assert CARD_ID == "P5-003"


def test_gr001_detects_both_generic_sentences() -> None:
    assert is_generic_grammar_template(_GENERIC_A)
    assert is_generic_grammar_template(_GENERIC_B)
    assert not is_generic_grammar_template(_REAL)


def test_gr001_lint_finding() -> None:
    hit = lint_grammar_string(_GENERIC_A, language="yoruba", field="grammar[0]")
    assert hit is not None
    assert hit.rule_id == RULE_GR001


def test_typology_somali_amharic_sov() -> None:
    languages = load_typology()
    assert languages["somali"]["word_order"] == "SOV"
    assert languages["amharic"]["word_order"] == "SOV"
    assert languages["somali"]["tense_aspect"] == "verb_morphology_or_particles"
    assert language_typology("somali") is not None


def test_typology_yoruba_particles_not_affixes() -> None:
    topo = language_typology("yoruba")
    assert topo is not None
    assert topo["tense_aspect"] == "preverbal_particles"
    assert topo.get("person_on_verb") is False
    hit = lint_grammar_string(_GENERIC_B, language="yoruba", field="g")
    assert hit is not None and hit.rule_id == RULE_GR001


def test_pattern_missing_on_publish() -> None:
    item = {"id": "yo.item.test", "section": "grammar", "text": _REAL, "pattern_id": "yo.pat.missing"}
    with pytest.raises(PatternMissingError):
        assert_grammar_item_publishable(
            item,
            pattern_library=({"id": "yo.pat.other"},),
            language="yoruba",
        )


def test_publish_with_pattern_library_entry() -> None:
    item = {
        "id": "yo.item.test",
        "section": "grammar",
        "text": _REAL,
        "pattern_id": "yo.pat.tense",
    }
    assert_grammar_item_publishable(
        item,
        pattern_library=({"id": "yo.pat.tense", "form": "..."},),
        language="yoruba",
    )


def test_legacy_scan_finds_gr001_across_bundles() -> None:
    findings = scan_legacy_bundles()
    gr001 = [f for f in findings if f.rule_id == RULE_GR001]
    assert len(gr001) >= EXPECTED_LEGACY_LESSONS_WITH_GENERIC
