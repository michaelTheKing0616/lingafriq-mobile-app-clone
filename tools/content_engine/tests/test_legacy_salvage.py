"""Spec tests for legacy phrase salvage (P4-082)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.salvage import (  # noqa: E402
    build_pipeline_record,
    is_real_phrase,
    iter_candidates,
    pipeline_input_dir,
    run_salvage,
    SalvageCandidate,
)


def _mini_curriculum() -> dict:
    return {
        "languages": {
            "yoruba": {
                "A1": [
                    {
                        "lessons": [
                            {
                                "id": "Yoruba-A1-u1-l1",
                                "vocab": [
                                    {
                                        "word": "Ó dára",
                                        "meaning": "fine",
                                        "example": "Ó dára — It is good.",
                                    },
                                    {
                                        "word": "word1a",
                                        "meaning": "meaning 1a",
                                        "example": "example meaning",
                                    },
                                ],
                                "dialogue": {
                                    "script": [
                                        {"speaker": "A", "text": "Mo ń kọ́ èdè Yorùbá"},
                                        {"speaker": "B", "text": "word2b"},
                                    ]
                                },
                                "exercises": [
                                    {
                                        "type": "flashcards",
                                        "items": [
                                            "Orúkọ mi ni — My name is…",
                                            "TODO — fix later",
                                        ],
                                    }
                                ],
                            }
                        ]
                    }
                ]
            },
            "afrikaans": {"A1": [{"lessons": [{"id": "af-1", "vocab": [{"word": "hallo"}]}]}]},
        }
    }


def _write_curriculum(tmp_path: Path, payload: dict) -> Path:
    rel = "assets/data/lingafriq_authentic_curriculum_a1_c2.json"
    path = tmp_path / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_P4_082_is_real_phrase_rejects_placeholders() -> None:
    assert is_real_phrase("Ó dára")
    assert not is_real_phrase("word1a")
    assert not is_real_phrase("")
    assert not is_real_phrase("Listen for affixes carry tense and person.")


def test_P4_082_AC1_dry_run_lists_counts_without_writing(tmp_path: Path) -> None:
    curriculum_path = _write_curriculum(tmp_path, _mini_curriculum())
    out_dir = pipeline_input_dir(tmp_path)
    result = run_salvage(
        tmp_path,
        dry_run=True,
        curriculum_path=curriculum_path,
    )
    assert result.stats.extracted == 3
    assert result.stats.dropped_non_real == 3
    assert not out_dir.exists()


def test_P4_082_AC1_extracts_with_source_id_and_writes_input(tmp_path: Path) -> None:
    curriculum_path = _write_curriculum(tmp_path, _mini_curriculum())
    result = run_salvage(tmp_path, dry_run=False, curriculum_path=curriculum_path)
    assert result.stats.extracted == 3
    assert result.input_path.is_file()
    lines = result.input_path.read_text(encoding="utf-8").strip().splitlines()
    assert len(lines) == 3
    records = [json.loads(line) for line in lines]
    source_ids = {r["source_id"] for r in records}
    assert source_ids == {"Yoruba-A1-u1-l1"}
    assert all(r["provenance"]["source"] == "legacy" for r in records)
    assert all("legacy_locator" in r for r in records)


def test_P4_082_AC2_unanchored_is_unverified_not_published(tmp_path: Path) -> None:
    candidate = SalvageCandidate(
        "lesson-1",
        "yoruba",
        "yo",
        "A1",
        "vocab[0].word",
        "Ó dára",
    )
    record = build_pipeline_record(candidate, lookup=lambda _lang, _form: None)
    assert record["queue_status"] == "unverified"
    assert record["published"] is False
    assert record["lexicon_anchor"] == "missing"


def test_P4_082_AC2_anchored_not_auto_published(tmp_path: Path) -> None:
    lexeme = {
        "sources": [
            {
                "tone_pattern": "H",
                "ipa": "/a/",
                "pos": "interj",
                "noun_class": "n/a",
                "plural": "n/a",
            },
            {
                "tone_pattern": "H",
                "ipa": "/a/",
                "pos": "interj",
                "noun_class": "n/a",
                "plural": "n/a",
            },
        ]
    }

    def lookup(_lang: str, form: str):
        return lexeme if form == "Ó dára" else None

    candidate = SalvageCandidate(
        "lesson-1",
        "yoruba",
        "yo",
        "A1",
        "vocab[0].word",
        "Ó dára",
    )
    record = build_pipeline_record(candidate, lookup)
    assert record["lexicon_anchor"] == "anchored"
    assert record["queue_status"] == "needs-review"
    assert record["published"] is False


def test_P4_082_integration_rerun_is_idempotent(tmp_path: Path) -> None:
    curriculum_path = _write_curriculum(tmp_path, _mini_curriculum())
    first = run_salvage(tmp_path, dry_run=False, curriculum_path=curriculum_path)
    second = run_salvage(tmp_path, dry_run=False, curriculum_path=curriculum_path)
    assert first.input_path.read_text(encoding="utf-8") == second.input_path.read_text(
        encoding="utf-8"
    )
    assert first.stats == second.stats


def test_P4_082_iter_candidates_skips_non_kit_languages() -> None:
    candidates = iter_candidates(_mini_curriculum())
    langs = {c.lang for c in candidates}
    assert langs == {"yoruba"}
    assert "afrikaans" not in langs
