"""A1 pattern libraries for ig, ha, pcm, xh (P5-024)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.pattern_linter import lint_pattern_library  # noqa: E402
from tools.content_engine.linters.anglicisation import (  # noqa: E402
    make_fixture_client,
    run_anglicisation_rating,
)

_PATTERN_ROOT = _REPO_ROOT / "assets" / "data" / "patterns"
_FIXTURE_MODEL = "fixture-gpt-5-mini"

_LANG_SPECS: tuple[tuple[str, tuple[str, ...], tuple[str, ...]], ...] = (
    (
        "ig",
        ("ig.pat.progressive-na", "ig.pat.future-ga", "ig.pat.locative-no"),
        ("na-", "ga-", "nọ"),
    ),
    (
        "ha",
        ("ha.pat.copula-ne", "ha.pat.continuous-ina", "ha.pat.future-za"),
        ("ne", "ina", "za"),
    ),
    (
        "pcm",
        ("pcm.pat.progressive-de", "pcm.pat.perfect-don", "pcm.pat.future-go"),
        ("de", "don", "go"),
    ),
)


def _load(lang: str) -> dict:
    return json.loads((_PATTERN_ROOT / f"{lang}.json").read_text(encoding="utf-8"))


@pytest.mark.parametrize("lang,expected_ids,markers", _LANG_SPECS)
def test_P5_024_library_lints_clean(lang: str, expected_ids: tuple[str, ...], markers: tuple[str, ...]) -> None:
    document = _load(lang)
    findings, gaps = lint_pattern_library(document, root=_REPO_ROOT)
    assert findings == []
    assert gaps == []
    assert document["language"] == lang
    by_id = {row["id"]: row for row in document["patterns"]}
    assert tuple(by_id) == expected_ids
    for pattern_id, marker in zip(expected_ids, markers, strict=True):
        entry = by_id[pattern_id]
        assert entry["label"] == "expert_reviewed"
        assert entry["cefr"] == "A1"
        blob = " ".join([entry["form"], *entry["examples"], *entry["contrasts"]])
        assert marker in blob
        assert entry["common_errors"]
        sources = entry["provenance"]["sources"]
        assert sources and sources[0]["uri_or_citation"].strip()
        assert entry["claims"][0]["source_ref"].strip()


def test_P5_024_xh_fifteen_subject_concords() -> None:
    document = _load("xh")
    findings, gaps = lint_pattern_library(document, root=_REPO_ROOT)
    assert findings == []
    assert gaps == []
    expected = tuple(f"xh.pat.sc-c{n:02d}" for n in range(1, 16))
    by_id = {row["id"]: row for row in document["patterns"]}
    assert tuple(by_id) == expected
    for entry in document["patterns"]:
        assert entry["label"] == "expert_reviewed"
        assert entry["claims"][0]["source_ref"] == "register:sadilar-xhosa-annotated"


def test_P5_024_pcm_examples_pass_anglicisation_fixture(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_CROSSCHECK_MODEL", _FIXTURE_MODEL)
    client = make_fixture_client({_FIXTURE_MODEL: {"naturalness": 4, "anglicised": False}})
    document = _load("pcm")
    for row in document["patterns"]:
        for example in row["examples"]:
            item = {"id": f"{row['id']}:{example[:24]}", "language": "pcm", "text": example}
            result = run_anglicisation_rating(item, client)
            assert result["anglicised"] is False
