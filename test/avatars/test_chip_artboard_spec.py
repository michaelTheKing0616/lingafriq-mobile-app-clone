"""P11-039: CharacterChip artboard design spec (ELEVATION §4.2 L906–L909)."""

from __future__ import annotations

import json
import re
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
_SPEC = _REPO / "docs/build/avatars/chip_artboard_spec.md"
_CONTRACT = _REPO / "assets/rive/lingafriq_cast.contract.json"


def test_spec_accepted_and_chip_sizes() -> None:
    text = _SPEC.read_text(encoding="utf-8")
    assert "P11-039" in text and "Accepted" in text
    assert "32" in text and "48" in text and "64" in text
    assert "exaggerated brows" in text.lower()
    assert "exaggerated mouth" in text.lower() or "mouth" in text.lower()


def test_minimum_stroke_and_no_thin_hair_strands() -> None:
    text = _SPEC.read_text(encoding="utf-8")
    assert re.search(r"≥\s*2\s*px", text) or ">= 2 px" in text
    assert "no thin hair" in text.lower() or "no individual strands" in text.lower()


def test_silhouette_procedure_covers_three_sizes() -> None:
    text = _SPEC.read_text(encoding="utf-8")
    assert "1-bit" in text.lower() or "silhouette" in text.lower()
    for size in ("32", "48", "64"):
        assert size in text


def test_spec_aligns_with_cast_contract() -> None:
    data = json.loads(_CONTRACT.read_text(encoding="utf-8"))
    chip = data["artboards"]["CharacterChip"]
    assert chip["displaySizes"] == [32, 48, 64]
    assert chip["size"] == [128, 128]
    for layer in ("L2 Face", "L4 Blink", "L5 Mouth", "L6 Build", "L7 Face Shape"):
        assert layer in chip["layers"]
