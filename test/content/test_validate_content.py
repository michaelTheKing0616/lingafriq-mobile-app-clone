"""Content validator and CI linters (P4-106)."""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.placeholder_patterns import scan_file  # noqa: E402
from tools.content_pipeline.validate_content import (  # noqa: E402
    ValidationFinding,
    check_lexeme_tone_marks,
    check_release_review,
    main,
    validate_content_tree,
    validate_object,
)
from tools.content_engine.legacy.structure import audio_content_hash  # noqa: E402


def _lexeme(**overrides: object) -> dict:
    body = {
        "id": "yo.lex.oko.vehicle",
        "language": "yo",
        "lemma": "ọkọ̀",
        "review": {"status": "approved", "reviewers": []},
        "audio": [],
    }
    body.update(overrides)
    return body


def test_missing_tone_marks_names_object_id() -> None:
    finding = check_lexeme_tone_marks(_lexeme(lemma="oko"))
    assert finding is not None
    assert finding.code == "MISSING_TONE_MARKS"
    assert finding.object_id == "yo.lex.oko.vehicle"


def test_audio_mismatch_on_dialogue_turn() -> None:
    text = "Ẹ kú àárọ̀"
    bad_hash = "0000000000000000"
    dialogue = {
        "id": "yo.dlg.market",
        "turns": [
            {
                "text": text,
                "audio": {
                    "uri": f"audio/yo/{bad_hash}.ogg",
                    "text_hash": bad_hash,
                    "kind": "human",
                },
            }
        ],
    }
    findings = validate_object(dialogue)
    assert any(f.code == "AUDIO_MISMATCH" for f in findings)


def test_audio_match_when_hash_correct() -> None:
    text = "Ẹ kú àárọ̀"
    good = audio_content_hash(text)
    dialogue = {
        "id": "yo.dlg.market",
        "turns": [
            {
                "text": text,
                "audio": {
                    "uri": f"audio/yo/{good}.ogg",
                    "text_hash": good,
                    "kind": "human",
                },
            }
        ],
    }
    findings = validate_object(dialogue)
    assert not any(f.code == "AUDIO_MISMATCH" for f in findings)


def test_unreviewed_item_in_release_pack() -> None:
    item = _lexeme(review={"status": "pending", "reviewers": []})
    finding = check_release_review(item, release_pack=True)
    assert finding is not None
    assert finding.code == "UNREVIEWED_ITEM"


def test_placeholder_scan_reports_file_and_line() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "bad.json"
        path.write_text('{"gloss": "word1 placeholder"}\n', encoding="utf-8")
        hits = scan_file(path)
        assert len(hits) == 1
        assert hits[0].line == 1
        findings = validate_content_tree(Path(tmp))
        assert any(f.code == "PLACEHOLDER_TEXT" for f in findings)


def test_cli_nonzero_on_failure() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "lex.json"
        path.write_text(json.dumps(_lexeme(lemma="oko")), encoding="utf-8")
        assert main([str(path)]) == 1


def test_cli_passes_clean_lexeme() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "lex.json"
        path.write_text(json.dumps(_lexeme()), encoding="utf-8")
        assert main([str(path)]) == 0
