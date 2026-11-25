"""P11-037: Polie rig integrated in lingafriq_cast.riv (contract + pin gate)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
_CONTRACT = _REPO / "assets/rive/lingafriq_cast.contract.json"
_RIV = _REPO / "assets/rive/lingafriq_cast.riv"
_CHECK = _REPO / "scripts/avatars/check_riv_version.py"

_REQUIRED_ARTBOARDS = ("Character", "CharacterChip", "Bust")
_REQUIRED_SM_LAYERS = (
    "L1 Body",
    "L2 Face",
    "L3 Gaze/Head",
    "L4 Blink",
    "L5 Mouth",
)
_MODULAR_SLOTS = ("hair", "headwear", "top", "bottom")
_POLIE_PARTS = (
    "Headwear/PolieCrest",
    "Top/PolieSuit",
    "Bottom/PolieHover",
    "Accessory/PolieOrbit",
)


def _contract() -> dict:
    return json.loads(_CONTRACT.read_text(encoding="utf-8"))


def test_riv_pin_gate_passes() -> None:
    proc = subprocess.run(
        [sys.executable, str(_CHECK), "--gate"],
        cwd=_REPO,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_ac1_artboards_and_modular_hierarchy() -> None:
    data = _contract()
    boards = data["artboards"]
    for name in _REQUIRED_ARTBOARDS:
        assert name in boards, f"missing artboard {name}"
    char_layers = boards["Character"]["layers"]
    for slot in ("L6 Build", "L7 Face Shape"):
        assert slot in char_layers, "Character needs build + face-shape layers for modular rig"
    props = {p["name"]: p for p in data["properties"]}
    for slot in _MODULAR_SLOTS:
        assert props[slot]["type"] == "Artboard", slot
        assert props[slot]["options"], slot
    chip = boards["CharacterChip"]
    assert chip["displaySizes"] == [32, 48, 64]
    assert "Polie" in data["instances"]


def test_ac2_character_sm_layers_l1_through_l5() -> None:
    data = _contract()
    assert data["stateMachine"] == "CharacterSM"
    ownership = data["layerOwnership"]
    for layer in _REQUIRED_SM_LAYERS:
        assert layer in ownership, layer
    char_layers = data["artboards"]["Character"]["layers"]
    for layer in _REQUIRED_SM_LAYERS:
        assert layer in char_layers, layer


def test_ac3_enums_not_legacy_numeric_codes() -> None:
    data = _contract()
    props = data["properties"]
    names = [p["name"] for p in props]
    assert "isListening" not in names
    assert "isSpeaking" not in names
    for p in props:
        if p["type"] == "Enum":
            assert p["name"] in data["enums"]
    activity = next(p for p in props if p["name"] == "activity")
    assert activity["type"] == "Enum"
    assert activity["default"] == "idle"


def test_polie_preset_parts_in_contract() -> None:
    data = _contract()
    by_name = {p["name"]: p for p in data["properties"] if p.get("type") == "Artboard"}
    for part in _POLIE_PARTS:
        category = part.split("/")[0].lower()
        slot = {
            "headwear": "headwear",
            "top": "top",
            "bottom": "bottom",
            "accessory": "accessory",
        }[category]
        assert part in by_name[slot]["options"]


def test_cast_file_within_budget() -> None:
    data = _contract()
    budget = data["budget"]["bytesPerCharacterFile"]
    size = _RIV.stat().st_size
    assert size <= budget
