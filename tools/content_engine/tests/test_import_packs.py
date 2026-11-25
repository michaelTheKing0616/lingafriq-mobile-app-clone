"""Spec tests for canonical curriculum pack import (P4-169)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.curriculum.import_packs import (  # noqa: E402
    ImportRejectedError,
    assert_import_path_allowed,
    canonical_packs_dir,
    import_curriculum_item,
    import_pack_file,
    load_curriculum_register,
    load_item_validator,
    repo_root,
)

_VALID_ID = "yo.lex.b26da58d1800"


def _minimal_item(
    *,
    lang: str = "sw",
    text: str = "habari",
    item_id: str = "sw.lex.aaaaaaaaaaaa",
    source_id: str = "fsi",
    role: str = "shipped_text",
) -> dict[str, Any]:
    return {
        "id": item_id,
        "lang": lang,
        "type": "lexeme",
        "cefr": "A1",
        "can_do": ["A1.LEX: test"],
        "text": text,
        "provenance": {
            "sources": [
                {
                    "source_id": source_id,
                    "licence": "public domain",
                    "locator": "test",
                    "role": role,
                }
            ],
            "created_at": "2026-10-21",
            "ai_assisted": False,
        },
        "claims": [{"text": "test claim", "source_id": source_id, "locator": "x"}],
        "confidence": 0.9,
        "risk_tags": [],
        "status": "Beta",
        "label": "beta",
        "audio": [],
        "feature_hooks": {},
    }


def _canonical_pack_path(root: Path, lang: str = "sw", level: str = "A1") -> Path:
    return canonical_packs_dir(root) / lang / f"{level}.json"


def test_P4_169_AC5_legacy_mobile_curriculum_path_forbidden(tmp_path: Path) -> None:
    legacy = tmp_path / "curriculum" / "packs" / "sw" / "A1.json"
    legacy.parent.mkdir(parents=True)
    legacy.write_text("{}", encoding="utf-8")
    with pytest.raises(ImportRejectedError) as exc_info:
        assert_import_path_allowed(legacy, tmp_path)
    assert exc_info.value.code == "LEGACY_PATH_FORBIDDEN"


def test_P4_169_AC5_node_backend_content_packs_forbidden(tmp_path: Path) -> None:
    bad = tmp_path / "node-backend" / "data" / "content-packs" / "x.json"
    bad.parent.mkdir(parents=True)
    bad.write_text("{}", encoding="utf-8")
    with pytest.raises(ImportRejectedError) as exc_info:
        assert_import_path_allowed(bad, tmp_path)
    assert exc_info.value.code == "LEGACY_PATH_FORBIDDEN"


def test_P4_169_AC1_schema_failure_rejects(tmp_path: Path) -> None:
    pack = _canonical_pack_path(_REPO_ROOT)
    item = _minimal_item()
    del item["claims"]
    with pytest.raises(ImportRejectedError) as exc_info:
        import_curriculum_item(
            item,
            pack_path=pack,
            root=_REPO_ROOT,
            validator=load_item_validator(_REPO_ROOT),
            curriculum_register=load_curriculum_register(_REPO_ROOT),
        )
    assert exc_info.value.code == "SCHEMA_INVALID"


def test_P4_169_AC1_unshippable_source_rejects(tmp_path: Path) -> None:
    pack = _canonical_pack_path(_REPO_ROOT)
    item = _minimal_item(source_id="not-a-real-ship-source", role="shipped_text")
    with pytest.raises(ImportRejectedError) as exc_info:
        import_curriculum_item(
            item,
            pack_path=pack,
            root=_REPO_ROOT,
            validator=load_item_validator(_REPO_ROOT),
            curriculum_register=load_curriculum_register(_REPO_ROOT),
        )
    assert exc_info.value.code in {"LICENCE_NOT_SHIPPABLE", "UNREGISTERED_SOURCE"}


def test_P4_169_AC2_yoruba_linter_rejects_plain_for_marked_lexicon() -> None:
    pack = _canonical_pack_path(_REPO_ROOT, "yo")
    item = _minimal_item(
        lang="yo",
        text="esin",
        item_id="yo.lex.bbbbbbbbbbbb",
        source_id="fsi",
    )
    item["orthography"] = {"standard": "ẹṣin", "script": "Latn", "tone_marked": False}
    with pytest.raises(ImportRejectedError) as exc_info:
        import_curriculum_item(
            item,
            pack_path=pack,
            root=_REPO_ROOT,
            validator=load_item_validator(_REPO_ROOT),
            curriculum_register=load_curriculum_register(_REPO_ROOT),
        )
    assert exc_info.value.code == "YO_DOTBELOW"


def test_P4_169_AC2_yoruba_passes_when_surface_matches() -> None:
    pack = _canonical_pack_path(_REPO_ROOT, "yo")
    item = _minimal_item(
        lang="yo",
        text="ẹṣin",
        item_id="yo.lex.cccccccccccc",
        source_id="fsi",
    )
    result = import_curriculum_item(
        item,
        pack_path=pack,
        root=_REPO_ROOT,
        validator=load_item_validator(_REPO_ROOT),
        curriculum_register=load_curriculum_register(_REPO_ROOT),
    )
    assert result.publishable is True


def test_P4_169_AC3_hausa_rejects_plain_hook_substitution() -> None:
    pack = _canonical_pack_path(_REPO_ROOT, "ha")
    item = _minimal_item(
        lang="ha",
        text="baki",
        item_id="ha.lex.dddddddddddd",
        source_id="fsi",
    )
    item["orthography"] = {"standard": "ɓaki", "script": "Latn", "tone_marked": False}
    with pytest.raises(ImportRejectedError) as exc_info:
        import_curriculum_item(
            item,
            pack_path=pack,
            root=_REPO_ROOT,
            validator=load_item_validator(_REPO_ROOT),
            curriculum_register=load_curriculum_register(_REPO_ROOT),
        )
    assert exc_info.value.code.startswith("HA")


def test_P4_169_AC4_synth_pack_stays_draft_not_publishable() -> None:
    pack = _canonical_pack_path(_REPO_ROOT, "sw")
    item = _minimal_item()
    result = import_curriculum_item(
        item,
        pack_path=pack.with_name("B2.synth.json"),
        root=_REPO_ROOT,
        validator=load_item_validator(_REPO_ROOT),
        curriculum_register=load_curriculum_register(_REPO_ROOT),
        synth_pack=True,
    )
    assert result.synth is True
    assert result.publishable is False
    assert result.item["status"] == "needs-review"


def test_P4_169_integration_real_sw_pack_item_if_present() -> None:
    pack = _canonical_pack_path(_REPO_ROOT, "sw", "A1")
    if not pack.is_file():
        pytest.skip("canonical sw A1 pack not present")
    payload = json.loads(pack.read_text(encoding="utf-8"))
    first = payload["items"][0]
    result = import_curriculum_item(
        first,
        pack_path=pack,
        root=_REPO_ROOT,
        validator=load_item_validator(_REPO_ROOT),
        curriculum_register=load_curriculum_register(_REPO_ROOT),
    )
    assert result.item["id"] == first["id"]
