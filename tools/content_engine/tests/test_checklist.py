"""Tests for licence compatibility checklist and discovery-only sources."""

from __future__ import annotations

import copy
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    check_items,
    load_compat_checklist,
    load_register_csv,
    require_checklist,
    validate_rows,
)

_LICENCES_DIR = _REPO_ROOT / "tools" / "content_engine" / "licences"
_REGISTER_CSV = _LICENCES_DIR / "register.csv"
_CHECKLIST_YAML = _LICENCES_DIR / "compat_checklist.yaml"


def test_full_register_validates_with_checklist() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    validate_rows(rows)
    checklist = load_compat_checklist(_CHECKLIST_YAML)
    require_checklist(rows, checklist)


def test_lanfrica_discovery_only_forces_use_flags_false(tmp_path: Path) -> None:
    text = _REGISTER_CSV.read_text(encoding="utf-8")
    text = text.replace(
        "lanfrica,CURRICULUM.md#§2.2:L207-L210,n/a,See CURRICULUM §2.2 L207-L210,false,false,false,Discovery only; always verify the licence at the source.",
        "lanfrica,CURRICULUM.md#§2.2:L207-L210,n/a,See CURRICULUM §2.2 L207-L210,true,true,true,Discovery only; always verify the licence at the source.",
    )
    csv_path = tmp_path / "register.csv"
    csv_path.write_text(text, encoding="utf-8")
    rows = load_register_csv(csv_path)
    lanfrica = next(r for r in rows if r["source_id"] == "lanfrica")
    assert lanfrica.get("discovery_only") == "true"
    assert lanfrica["display"] == "false"
    assert lanfrica["evidence"] == "false"
    assert lanfrica["training"] == "false"


def test_check_items_on_lanfrica_raises_discovery_only() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [{"source_id": "lanfrica", "kind": "corpus"}]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(rows, items)
    assert exc_info.value.code == "DISCOVERY_ONLY"


def test_require_checklist_passes_on_shipped_yaml() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    checklist = load_compat_checklist(_CHECKLIST_YAML)
    require_checklist(rows, checklist)


def test_missing_source_in_checklist_raises_incomplete() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    checklist = load_compat_checklist(_CHECKLIST_YAML)
    broken = copy.deepcopy(checklist)
    sources = dict(broken["sources"])
    del sources["fsi-yoruba"]
    broken["sources"] = sources
    with pytest.raises(LicenceRegisterError) as exc_info:
        require_checklist(rows, broken)
    assert exc_info.value.code == "LICENCE_CHECKLIST_INCOMPLETE"
