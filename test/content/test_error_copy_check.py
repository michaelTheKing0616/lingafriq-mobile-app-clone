"""P10-940: Three-part errors and village-voice scope."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.copy.error_copy_check import (  # noqa: E402
    lint_arb,
    lint_three_part_error,
    lint_village_voice_scope,
    load_village_markers,
)
from scripts.copy.lint_ui_strings import parse_arb  # noqa: E402

_EN_ARB = _REPO_ROOT / "lib" / "l10n" / "app_en.arb"
_MARKERS = _REPO_ROOT / "scripts" / "copy" / "village_voice_markers.txt"


def _arb(tmp_path: Path, entries: dict[str, str], meta: dict[str, dict] | None = None) -> Path:
    path = tmp_path / "app_en.arb"
    payload: dict = {"@@locale": "en", **entries}
    if meta:
        for key, block in meta.items():
            payload[f"@{key}"] = block
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def test_three_part_error_pass() -> None:
    good = (
        "Couldn't score that recording. It was too quiet. Try again closer to the mic."
    )
    assert lint_three_part_error("k", good) is None


def test_three_part_error_fail_too_short() -> None:
    assert lint_three_part_error("k", "Session failed") is not None


def test_village_voice_blocked_on_system_label() -> None:
    markers = load_village_markers(_MARKERS)
    meta = {"welcome": {"description": "Welcome label"}}
    hit = lint_village_voice_scope("welcome", "Eh, friend, tap Start lesson.", meta, markers)
    assert hit is not None and hit.rule == "VILLAGE_VOICE_SYSTEM"


def test_village_voice_allowed_on_character_dialogue(tmp_path: Path) -> None:
    path = _arb(
        tmp_path,
        {"persona_dialogue_welcome": "Eh, welcome back, friend. The road is long."},
        meta={
            "persona_dialogue_welcome": {
                "description": "Persona line",
                "voice": "character",
            }
        },
    )
    assert lint_arb(path, _MARKERS) == []


def test_integration_full_app_en_arb_passes() -> None:
    assert lint_arb(_EN_ARB, _MARKERS) == []


def test_voice_scope_sample_keys() -> None:
    strings, meta = parse_arb(_EN_ARB)
    markers = load_village_markers(_MARKERS)
    assert "persona_dialogue_welcome" in strings
    assert meta.get("persona_dialogue_welcome", {}).get("voice") == "character"
    assert lint_village_voice_scope(
        "persona_dialogue_welcome", strings["persona_dialogue_welcome"], meta, markers
    ) is None
