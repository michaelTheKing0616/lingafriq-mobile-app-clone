"""P5-002 placeholder linter and legacy quarantine manifest."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.placeholder_linter import (  # noqa: E402
    CARD_ID,
    lint_lesson,
    load_manifest,
    learner_surface_legacy_violations,
    run_quarantine_job,
)


def _lesson(**overrides: object) -> dict:
    body = {
        "id": "test-lesson-1",
        "vocab": [],
        "dialogue": {"script": []},
        "exercises": [],
    }
    body.update(overrides)
    return body


def test_ph001_rejects_generic_vocab() -> None:
    lesson = _lesson(
        vocab=[{"word": "example", "meaning": "sample", "pos": "noun"}],
    )
    result = lint_lesson(lesson, bundle_relpath="x.json", language="zulu", kit_lang="zu")
    rules = {f.rule_id for f in result.findings}
    assert "PH-001" in rules
    assert result.publishable is False


def test_ph002_rejects_word_slots() -> None:
    lesson = _lesson(vocab=[{"word": "word1a", "meaning": "gloss", "pos": "noun"}])
    result = lint_lesson(lesson, bundle_relpath="x.json", language="zulu", kit_lang="zu")
    assert any(f.rule_id == "PH-002" for f in result.findings)
    assert result.publishable is False


def test_ph003_rejects_example_sentence_template() -> None:
    lesson = _lesson(
        exercises=[{"type": "reading", "prompt": "Example sentence with Yor_word1a."}],
    )
    result = lint_lesson(lesson, bundle_relpath="x.json", language="yoruba", kit_lang="yo")
    assert any(f.rule_id == "PH-003" for f in result.findings)


def test_ph004_rejects_unit_cultural_template() -> None:
    lesson = _lesson()
    result = lint_lesson(
        lesson,
        bundle_relpath="auth.json",
        language="yoruba",
        kit_lang="yo",
        unit_cultural_notes="Yoruba cultural immersion for Discovery & Sound.",
    )
    assert any(f.rule_id == "PH-004" for f in result.findings)
    assert result.publishable is False


def test_unanchored_diacritics_cap_quality_label() -> None:
    lesson = _lesson(
        vocab=[{"word": "Mo ń kọ́ èdè Yorùbá", "meaning": "phrase", "pos": "phrase"}],
    )
    result = lint_lesson(lesson, bundle_relpath="auth.json", language="yoruba", kit_lang="yo")
    assert result.publishable is True
    assert result.max_quality_label == "beta-eligible-pending"
    assert any(f.severity == "unverified" for f in result.findings)


def test_lexicon_lookup_anchors_phrase() -> None:
    phrase = "Mo ń kọ́ èdè Yorùbá"

    def lookup(lang: str, text: str) -> dict:
        assert lang == "yo"
        assert text == phrase
        return {"anchoring_status": "anchored"}

    lesson = _lesson(vocab=[{"word": phrase, "meaning": "I am learning Yoruba", "pos": "phrase"}])
    result = lint_lesson(
        lesson,
        bundle_relpath="auth.json",
        language="yoruba",
        kit_lang="yo",
        lookup=lookup,
    )
    assert not any(f.severity == "unverified" for f in result.findings)


def test_quarantine_job_writes_manifest(tmp_path: Path) -> None:
    bundle = tmp_path / "curriculum_bundle" / "curriculum" / "yo.json"
    bundle.parent.mkdir(parents=True)
    bundle.write_text(
        json.dumps(
            {
                "meta": {"code": "yoruba"},
                "units": [
                    {
                        "cultural_notes": "Yoruba cultural immersion for Unit 1.",
                        "lessons": [
                            {
                                "id": "Y-A1-u1-l1",
                                "vocab": [{"word": "word1a", "meaning": "example meaning"}],
                            }
                        ],
                    }
                ],
            }
        )
        + "\n",
        encoding="utf-8",
    )
    payload = run_quarantine_job(tmp_path, write=True)
    assert payload["card"] == CARD_ID
    assert payload["lesson_count"] == 1
    assert payload["publishable_lessons"] == 0
    manifest = load_manifest(tmp_path)
    assert manifest is not None
    assert manifest["lessons"][0]["publishable"] is False


def test_learner_surface_grep_no_unlisted_legacy_refs() -> None:
    violations = learner_surface_legacy_violations(_REPO_ROOT)
    assert violations == [], f"unexpected legacy refs: {violations}"


def test_committed_manifest_lists_zero_publishable() -> None:
    manifest = load_manifest(_REPO_ROOT)
    if manifest is None:
        pytest.skip("legacy_quarantine.json not generated in this checkout")
    assert manifest.get("card") == CARD_ID
    assert manifest.get("publishable_lessons") == 0
