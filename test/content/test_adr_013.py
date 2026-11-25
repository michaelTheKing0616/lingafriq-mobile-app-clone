"""ADR-013 conformance: two-layer living lexicon (P7-901 AC1)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-013-two-layer-living-lexicon.md"
_LEXEME_SCHEMA = _REPO_ROOT / "schemas/v2/content/lexeme.schema.json"


def test_adr_013_exists_and_records_layers() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text
    assert "Verified Lexicon" in text and "My Words" in text
    assert "verified_lexeme_id" in text
    assert "lexeme.schema.json" in text
    assert _LEXEME_SCHEMA.is_file()
    assert "Alternatives considered" in text
    for phrase in ("Living loop", "Link rules", "P7-920", "share-alike"):
        assert phrase in text
