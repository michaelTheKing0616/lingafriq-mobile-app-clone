"""Tests for language kit schema and loader (CURRICULUM §3.1)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest
import yaml

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.kits.kit_schema import KitError  # noqa: E402
from tools.content_engine.kits.loader import load_kit, start_pipeline  # noqa: E402

REQUIRED_KEYS = (
    "character_set",
    "nfc",
    "tone_marking",
    "phone_inventory",
    "g2p",
    "noun_class",
    "concord",
    "dialect",
    "honorifics",
)


def _complete_kit() -> dict[str, Any]:
    return {
        "character_set": ["a", "b", "ẹ"],
        "nfc": "NFC",
        "tone_marking": "pedagogical tone marks required",
        "phone_inventory": ["a", "b"],
        "g2p": [{"g": "a", "p": "a"}],
        "noun_class": {"1": "umu-"},
        "concord": ["subject", "object"],
        "dialect": "standard",
        "honorifics": {"elder": "ẹ"},
    }


def _write_kit(kit_dir: Path, language: str, data: dict[str, Any]) -> Path:
    path = kit_dir / f"{language}.yaml"
    path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
    return path


def test_complete_kit_loads(tmp_path: Path) -> None:
    kit = _complete_kit()
    _write_kit(tmp_path, "yo", kit)
    loaded = load_kit("yo", tmp_path)
    assert loaded["character_set"] == kit["character_set"]
    assert loaded["nfc"] == "NFC"
    assert loaded["tone_marking"] == kit["tone_marking"]
    assert loaded["phone_inventory"] == kit["phone_inventory"]
    assert loaded["g2p"] == kit["g2p"]
    assert loaded["noun_class"] == kit["noun_class"]
    assert loaded["concord"] == kit["concord"]
    assert loaded["dialect"] == kit["dialect"]
    assert loaded["honorifics"] == kit["honorifics"]


@pytest.mark.parametrize("key", REQUIRED_KEYS)
def test_missing_section_raises_kit_section_missing(tmp_path: Path, key: str) -> None:
    kit = _complete_kit()
    del kit[key]
    _write_kit(tmp_path, "yo", kit)
    with pytest.raises(KitError) as exc_info:
        load_kit("yo", tmp_path)
    assert exc_info.value.code == "KIT_SECTION_MISSING"
    assert key in str(exc_info.value)


def test_empty_character_set_raises_kit_section_missing(tmp_path: Path) -> None:
    kit = _complete_kit()
    kit["character_set"] = []
    _write_kit(tmp_path, "yo", kit)
    with pytest.raises(KitError) as exc_info:
        load_kit("yo", tmp_path)
    assert exc_info.value.code == "KIT_SECTION_MISSING"
    assert "character_set" in str(exc_info.value)


def test_nfc_nfd_raises_kit_section_missing(tmp_path: Path) -> None:
    kit = _complete_kit()
    kit["nfc"] = "NFD"
    _write_kit(tmp_path, "yo", kit)
    with pytest.raises(KitError) as exc_info:
        load_kit("yo", tmp_path)
    assert exc_info.value.code == "KIT_SECTION_MISSING"
    assert "nfc" in str(exc_info.value)


def test_start_pipeline_missing_file_does_not_generate(tmp_path: Path) -> None:
    called: list[object] = []

    def generate(kit: dict[str, Any]) -> dict[str, Any]:
        called.append(kit)
        return kit

    with pytest.raises(KitError) as exc_info:
        start_pipeline("yo", tmp_path, generate)
    assert exc_info.value.code == "KIT_NOT_FOUND"
    assert called == []


def test_start_pipeline_missing_dialect_does_not_generate(tmp_path: Path) -> None:
    kit = _complete_kit()
    del kit["dialect"]
    _write_kit(tmp_path, "yo", kit)
    called: list[object] = []

    def generate(loaded: dict[str, Any]) -> dict[str, Any]:
        called.append(loaded)
        return loaded

    with pytest.raises(KitError) as exc_info:
        start_pipeline("yo", tmp_path, generate)
    assert exc_info.value.code == "KIT_SECTION_MISSING"
    assert "dialect" in str(exc_info.value)
    assert called == []
