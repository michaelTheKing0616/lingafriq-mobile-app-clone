"""P11-034: avatar cultural design bible (EP-§4.2-31…38, §4.4-09)."""

from __future__ import annotations

import re
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_BIBLE = _REPO_ROOT / "docs/build/avatars/cultural_design_bible.md"

_REQUIRED_HAIR = (
    "Fulani braids",
    "Shuku",
    "Bantu knots",
    "Irun kiko",
    "cornrows",
)
_REQUIRED_HEADWEAR = (
    "Gele",
    "Fila",
    "Kufi",
    "Duku",
    "Maasai",
    "Hausa hula",
)
_REQUIRED_TEXTILES = ("Aṣọ-òkè", "Kente", "Àdìrẹ", "boubou")


def test_bible_accepted_and_lists_named_hair_and_headwear() -> None:
    text = _BIBLE.read_text(encoding="utf-8")
    assert "Accepted" in text and "P11-034" in text
    lower = text.lower()
    for name in _REQUIRED_HAIR:
        assert name.lower() in lower
    for name in _REQUIRED_HEADWEAR:
        assert name.lower() in lower
    assert "dìrẹ" in lower or "adire" in lower
    assert "boubou" in lower


def test_skin_tone_table_has_at_least_ten_hex_swatches_with_undertones() -> None:
    text = _BIBLE.read_text(encoding="utf-8")
    assert "undertone" in text.lower()
    hexes = re.findall(r"`#[0-9A-Fa-f]{6}`", text)
    assert len(hexes) >= 10
    assert "albinism" in text.lower()


def test_disability_representation_covers_required_needs() -> None:
    lower = _BIBLE.read_text(encoding="utf-8").lower()
    for term in ("glasses", "hearing aids", "wheelchair", "vitiligo", "albinism"):
        assert term in lower


def test_region_authentic_outfits_require_consultant_review_line() -> None:
    text = _BIBLE.read_text(encoding="utf-8")
    assert "EXT-14" in text
    assert "Consultant review" in text
    assert "Cultural note" in text
    assert text.count("EXT-14 pending") >= 5


def test_scarification_deferred_to_adr_035() -> None:
    text = _BIBLE.read_text(encoding="utf-8")
    assert "ADR-035" in text
    assert "P11-033" in text
